defmodule MeshxConsul.Proxy.Supervisor do
  @moduledoc false
  use DynamicSupervisor
  alias MeshxConsul.Proxy.Worker

  def start_link(init_arg), do: DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

  @impl true
  def init(_init_arg), do: DynamicSupervisor.init(strategy: :one_for_one)

  def start(_service_id, cmd) when is_nil(cmd), do: {:ok, nil}

  def start(service_id, cmd) do
    id = id(service_id)
    spec = Supervisor.child_spec({Worker, [service_id, id, cmd]}, [])

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} -> {:ok, pid}
      {:ok, pid, _info} -> {:ok, pid}
      err -> err
    end
  end

  def stop(service_id) do
    id = id(service_id)
    Worker.cleanup(id)

    if is_pid(Process.whereis(__MODULE__)) do
      w_id = Process.whereis(id)
      if is_pid(w_id), do: DynamicSupervisor.terminate_child(__MODULE__, w_id), else: :ok
    else
      {:error, :not_found}
    end
  end

  def id(service_id), do: Module.concat([__MODULE__, service_id])
end
