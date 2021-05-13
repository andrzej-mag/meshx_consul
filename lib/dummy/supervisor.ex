defmodule MeshxConsul.Dummy do
  @moduledoc false
  use DynamicSupervisor

  @worker_mod MeshxConsul.Dummy.Worker

  def start_link(init_arg), do: DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

  def start(service_name, address) do
    id = id(service_name)
    spec = Supervisor.child_spec({@worker_mod, [id, address]}, [])

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} -> {:ok, pid}
      {:ok, pid, _info} -> {:ok, pid}
      err -> err
    end
  end

  def stop(service_name) do
    id = id(service_name)
    @worker_mod.cleanup(id)

    if is_pid(Process.whereis(__MODULE__)) do
      w_id = Process.whereis(id)
      if is_pid(w_id), do: DynamicSupervisor.terminate_child(__MODULE__, w_id), else: :ok
    else
      {:error, :not_found}
    end
  end

  @impl true
  def init(_init_arg), do: DynamicSupervisor.init(strategy: :one_for_one)
  defp id(service_name), do: Module.concat([__MODULE__, service_name])
end
