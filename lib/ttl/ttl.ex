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

  alias MeshxConsul.Ttl.{Supervisor, Worker}

  @doc """
  Starts TTL check worker for `service_id` service using `ttl_opts`.
  """
  @spec start(service_id :: atom() | String.t(), ttl_opts :: map()) :: DynamicSupervisor.on_start_child() | {:ok, nil}
  defdelegate start(service_id, ttl_opts), to: Supervisor

  @doc """
  Stops TTL check worker for `service_id` service.
  """
  @spec stop(service_id :: atom() | String.t()) :: :ok | {:error, :not_found}
  defdelegate stop(service_id), to: Supervisor

  @doc """
  Gets TTL check worker status for `service_id` service.
  """
  @spec get_status(service_id :: atom() | String.t()) :: String.t()
  def get_status(service_id), do: Worker.get_status(Supervisor.id(service_id))

  @doc """
  Sets TTL check worker `status` for `service_id` service.
  """
  @spec set_status(service_id :: atom() | String.t(), status :: String.t()) :: :ok
  def set_status(service_id, status), do: Worker.set_status(Supervisor.id(service_id), status)
end
