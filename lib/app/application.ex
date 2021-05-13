defmodule MeshxConsul.Application do
  @moduledoc false
  use Application
  alias MeshxConsul.App.C
  alias MeshxConsul.Service.{Endpoint, Ets}

  @impl true
  def start(_type, _args) do
    case init_http() do
      {:ok, _consul_response} ->
        :ets.new(C.lib(), [:named_table, :public])

        children = [
          MeshxConsul.Dummy,
          MeshxConsul.Proxy,
          MeshxConsul.Ttl,
          {MeshxConsul.Service.GenTcpPort, C.tcp_address()}
        ]

        Supervisor.start_link(children, strategy: :one_for_one, name: MeshxConsul.Supervisor)

      err ->
        err
    end
  end

  @impl true
  def prep_stop(state) do
    for service <- Ets.list(), do: MeshxConsul.stop(service)
    state
  end

  defp init_http() do
    C.httpc_opts() |> :httpc.set_options()
    Endpoint.self()
  end
end
