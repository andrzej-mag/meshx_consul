defmodule MeshxConsul.Ttl do
  @moduledoc """
  Manages TTL (Time To Live) health check workers used by mesh services.

  todo: Documentation will be provided at a later date.
  """

  use DynamicSupervisor

  @worker_mod MeshxConsul.Ttl.Worker

  @doc false
  def start_link(init_arg), do: DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

  def start(_service_name, ttl_opts) when is_nil(ttl_opts), do: {:ok, nil}

  def start(service_name, ttl_opts) do
    id = id(service_name)
    spec = Supervisor.child_spec({@worker_mod, [id, ttl_opts]}, [])

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

  def get_status(service_name), do: @worker_mod.get_status(id(service_name))
  def set_status(service_name, status), do: @worker_mod.set_status(id(service_name), status)

  @impl true
  def init(_init_arg), do: DynamicSupervisor.init(strategy: :one_for_one)
  defp id(service_name), do: Module.concat([__MODULE__, service_name])
end
