defmodule MeshxConsul.Ttl do
  @moduledoc """
  Manages TTL health check workers used by mesh services.

  Consul agent can use multiple kinds of checks, e.g. script checks, HTTP and TCP checks, gRPC and [others](https://www.consul.io/docs/discovery/checks).

  `MeshxConsul` is using TTL (Time To Live) health checks for services started with `MeshxConsul.start/4`. Dedicated worker is used to periodically update service health check state over Consul agent HTTP interface.

  Service health checks are defined using `template` argument of `MeshxConsul.start/4`. Default health check specification:
  ```elixir
  [
    ttl: %{
      id: "ttl:{{id}}",
      status: "passing",
      ttl: 5_000
    }
  ]
  ```
  Health check keys:
    * `:id` - service id (value rendered using Mustache system),
    * `:status` - initial health check status,
    * `:ttl` - health check state update interval, milliseconds.

  Health check state can be one of following: `"passing"`, `"warning"` or `"critical"`.

  TTL checks are automatically started when running `MeshxConsul.start/4` and stopped with `MeshxConsul.stop/1`. Users usually should not directly use `start/2` and `stop/1` functions defined in this module.

  `set_status/2` can be used to set service status depending on external conditions. One can for example use [`:os_mon`](http://erlang.org/doc/man/os_mon_app.html) [`:cpu_sup`](http://erlang.org/doc/man/cpu_sup.html) to monitor CPU utilization and update service status accordingly.

  #### Example:
  ```elixir
  iex(1)> MeshxConsul.start("service1")
  {:ok, "service1-h11", {:tcp, {127, 0, 0, 1}, 1024}}
  iex(2)> MeshxConsul.Ttl.get_status("service1-h11")
  "passing"
  iex(3)> MeshxConsul.Ttl.set_status("service1-h11", "warning")
  :ok
  iex(4)> MeshxConsul.Ttl.get_status("service1-h11")
  "warning"
  ```
  """

  use DynamicSupervisor

  @worker_mod MeshxConsul.Ttl.Worker

  @doc false
  def start_link(init_arg), do: DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

  @doc """
  Starts TTL check worker for `service_id` service using `ttl_opts`.
  """
  @spec start(service_id :: atom() | String.t(), ttl_opts :: map()) :: DynamicSupervisor.on_start_child() | {:ok, nil}
  def start(_service_id, ttl_opts) when is_nil(ttl_opts), do: {:ok, nil}
  # FIXME:
  # def start(_service_id, ttl_opts) when is_nil(ttl_opts), do: :ignore

  def start(service_id, ttl_opts) do
    id = id(service_id)
    spec = Supervisor.child_spec({@worker_mod, [id, ttl_opts]}, [])

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} -> {:ok, pid}
      {:ok, pid, _info} -> {:ok, pid}
      err -> err
    end
  end

  @doc """
  Stops TTL check worker for `service_id` service.
  """
  @spec stop(service_id :: atom() | String.t()) :: :ok | {:error, :not_found}
  def stop(service_id) do
    id = id(service_id)
    @worker_mod.cleanup(id)

    if is_pid(Process.whereis(__MODULE__)) do
      w_id = Process.whereis(id)
      if is_pid(w_id), do: DynamicSupervisor.terminate_child(__MODULE__, w_id), else: :ok
    else
      {:error, :not_found}
    end
  end

  @doc """
  Gets TTL check worker status for `service_id` service.
  """
  @spec get_status(service_id :: atom() | String.t()) :: String.t()
  def get_status(service_id), do: @worker_mod.get_status(id(service_id))

  @doc """
  Sets TTL check worker `status` for `service_id` service.
  """
  @spec set_status(service_id :: atom() | String.t(), status :: String.t()) :: :ok
  def set_status(service_id, status), do: @worker_mod.set_status(id(service_id), status)

  @impl true
  def init(_init_arg), do: DynamicSupervisor.init(strategy: :one_for_one)
  defp id(service_id), do: Module.concat([__MODULE__, service_id])
end
