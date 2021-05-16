defmodule MeshxConsul.Proxy.Worker do
  @moduledoc false
  use GenServer
  require Logger
  alias MeshxConsul.App.C

  @stop_timeout 1_000
  @kill_signal 15

  defstruct [:svc_name, :cmd, :opts, :pid, restarts: 0]

  def start_link([service_name, id, cmd]), do: GenServer.start_link(__MODULE__, [service_name, cmd], name: id)
  def restart(id), do: GenServer.cast(id, :restart)
  def cleanup(id), do: GenServer.cast(id, :cleanup)
  def info(id), do: GenServer.call(id, :info)

  @impl true
  def init([service_name, cmd]),
    do:
      {:ok,
       %__MODULE__{
         svc_name: service_name,
         cmd: cmd,
         opts: [
           :monitor,
           env: C.cli_env(),
           stdout: fn dev, _pid, msg -> C.proxy_stdout_fun().(service_name, dev, msg) end,
           stderr: fn dev, _pid, msg -> C.proxy_stderr_fun().(service_name, dev, msg) end
         ],
         pid: nil
       }, {:continue, :run}}

  @impl true
  def handle_continue(:run, %__MODULE__{} = state) do
    {:ok, pid, _ospid} = :exec.run(state.cmd, state.opts)
    {:noreply, %__MODULE__{state | pid: pid}}
  end

  @impl true
  def handle_info({:DOWN, ospid, :process, pid, reason}, %__MODULE__{} = state) do
    restarts = state.restarts
    C.proxy_down_fun().(state.svc_name, pid, ospid, reason, restarts)

    pid =
      if restarts < C.max_proxy_restarts() do
        {:ok, pid, _ospid} = :exec.run(state.cmd, state.opts)
        pid
      else
        nil
      end

    {:noreply, %__MODULE__{state | restarts: restarts + 1, pid: pid}}
  end

  @impl true
  def handle_cast(:restart, %__MODULE__{} = state) do
    :ok = stop_proxy(state)
    {:ok, pid, _ospid} = :exec.run(state.cmd, state.opts)
    {:noreply, %__MODULE__{state | pid: pid, restarts: 0}}
  end

  @impl true
  def handle_cast(:cleanup, %__MODULE__{} = state) do
    :ok = stop_proxy(state)
    {:noreply, state}
  end

  @impl true
  def handle_call(:info, _from, %__MODULE__{} = state),
    do: {:reply, %{cmd: state.cmd, restarts: state.restarts}, state}

  @impl true
  def terminate(_reason, %__MODULE__{} = state), do: :ok = stop_proxy(state)

  def stdout(_service_name, _dev, msg) when msg in ["", "\n"], do: nil
  def stdout(service_name, dev, msg), do: Logger.debug("[#{service_name}][#{dev}]: #{msg}")
  def stderr(_service_name, :stderr = _dev, msg) when msg in ["", "\n"], do: nil
  def stderr(service_name, :stderr = dev, msg) when msg not in ["", "\n"], do: Logger.error("[#{service_name}][#{dev}]: #{msg}")
  def stderr(_service_name, _dev, msg) when msg in ["", "\n"], do: nil
  def stderr(service_name, dev, msg) when msg not in ["", "\n"], do: Logger.info("[#{service_name}][#{dev}]: #{msg}")

  def down_fun(service_name, pid, ospid, reason, restarts),
    do:
      Logger.error(
        "Proxy: [#{service_name}], pid: [#{inspect(pid)}], ospid: [#{inspect(ospid)}] is down because of: #{inspect(reason)} for the [#{
          restarts + 1
        }] time(s). Restarting proxy."
      )

  defp stop_proxy(%__MODULE__{} = state) do
    case :exec.stop_and_wait(state.pid, @stop_timeout) do
      {:error, :timeout} -> :exec.kill(state.pid, @kill_signal)
      _ -> :ok
    end
  end
end
