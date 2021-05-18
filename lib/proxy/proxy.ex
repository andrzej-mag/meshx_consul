defmodule MeshxConsul.Proxy do
  @moduledoc """
  Manages sidecar service proxy binary command.

  Service mesh data plane is using system of connected proxies managed by control plane application for service communication.
  Module is managing starting, stopping and restarting proxies binary commands.
  Proxies should be automatically started running `MeshxConsul.start/4` and stopped with `MeshxConsul.stop/1`.

  Command running proxy binary for given service is passed as service `template` argument to `MeshxConsul.start/4`.
  Default proxy command will start Consul Connect proxy with error log-level and will use `/bin/sh` as shell:
  ```elixir
  [proxy: ["/bin/sh", "-c", "consul connect proxy -log-level err -sidecar-for {{id}}"]]
  ```
  Command will be rendered using Mustache system, check `MeshxConsul` documentation for details.

  Example proxy command starting [Envoy Proxy](https://www.envoyproxy.io/):
  ```elixir
  [proxy: ["/bin/sh", "-c", "consul connect envoy -sidecar-for {{id}} -- -l error"]]
  ```
  **Note:** Consul application version must be compatible with provided Envoy binary, see: [Consul documentation](https://www.consul.io/docs/connect/proxies/envoy#supported-versions).

  Proxy binary command must be able to communicate with Consul: agent instance address and ACL token must be provided. Configuration may be provided as shell environment variable defined by `:cli_env` key in `config.exs` or directly using proxy command. Environment variable is preferred when passing secrets.
  """

  alias MeshxConsul.Proxy.{Supervisor, Worker}

  @doc """
  Starts long-running proxy binary `cmd` for `service_id` service.
  """
  @spec start(service_id :: atom() | String.t(), cmd :: [String.t()]) :: DynamicSupervisor.on_start_child() | {:ok, nil}
  defdelegate start(service_id, cmd), to: Supervisor

  @doc """
  Stops `service_id` service proxy.
  """
  @spec stop(service_id :: atom() | String.t()) :: :ok | {:error, :not_found}
  defdelegate stop(service_id), to: Supervisor

  @doc """
  Restarts proxy binary for `service_id` service.
  ```elixir
  iex(1)> MeshxConsul.start("service1")
  {:ok, "service1-h11", {:tcp, {127, 0, 0, 1}, 1024}}
  iex(2)> MeshxConsul.Proxy.restart("service1-h11")
  :ok
  ```
  """
  @spec restart(service_id :: atom() | String.t()) :: :ok
  def restart(service_id), do: Worker.restart(Supervisor.id(service_id))

  @doc """
  Returns info about `service_id` service proxy worker.

  Function result if successful is map with two keys:
    * `:cmd` - contains Mustache rendered command that was used to start proxy binary,
    * `:restarts` - equal to number of proxy restarts due to proxy command failure.

  Exits if `service_id` worker is not running.

  ```elixir
  iex(1)> MeshxConsul.start("service1")
  {:ok, "service1-h11", {:tcp, {127, 0, 0, 1}, 1024}}
  iex(2)> MeshxConsul.Proxy.info("service1-h11")
  %{
    cmd: ["/bin/sh", "-c",
      "consul connect proxy -log-level err -sidecar-for service1-h11"],
    restarts: 0
  }
  ```
  """
  @spec info(service_id :: atom() | String.t()) :: %{cmd: String.t(), restarts: non_neg_integer()}
  def info(service_id), do: Worker.info(Supervisor.id(service_id))
end
