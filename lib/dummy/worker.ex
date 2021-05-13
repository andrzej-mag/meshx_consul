defmodule MeshxConsul.Dummy.Worker do
  @moduledoc false
  require Logger
  use GenServer

  defstruct [:id, :address, :asocket, :lsocket]

  def start_link([id, address]), do: GenServer.start_link(__MODULE__, %__MODULE__{id: id, address: address}, name: id)
  def cleanup(id), do: GenServer.cast(id, :cleanup)

  @impl true
  def init(%__MODULE__{} = state), do: {:ok, state, {:continue, :accept}}

  @impl true
  def handle_continue(:accept, %__MODULE__{} = state), do: {:noreply, reaccept(state)}

  @impl true
  def handle_info({:tcp_closed, socket}, %__MODULE__{} = state), do: {:noreply, reaccept(state, socket)}

  @impl true
  def handle_info({:tcp, socket, payload}, %__MODULE__{} = state) do
    :inet.setopts(socket, active: :once)

    Logger.warn("""
    Unexpected incoming traffic for dummy service: #{state.id}, address: #{inspect(state.address)}.
    Payload inspect:
    #{inspect(payload)}
    """)

    {:noreply, reaccept(state, socket)}
  end

  @impl true
  def handle_info(event, %__MODULE__{} = state) do
    Logger.warn("[#{__MODULE__}]: #{inspect(event)}")
    {:noreply, reaccept(state)}
  end

  @impl true
  def handle_cast(:cleanup, %__MODULE__{} = state), do: {:noreply, close(state)}

  @impl true
  def terminate(_reason, %__MODULE__{} = state) do
    close(state)
    :ok
  end

  defp close(%__MODULE__{} = state, socket \\ nil) do
    if is_port(state.lsocket), do: :gen_tcp.close(state.lsocket)
    if is_port(state.asocket), do: :gen_tcp.close(state.asocket)
    if is_port(socket), do: :gen_tcp.close(socket)
    %__MODULE__{state | lsocket: nil, asocket: nil}
  end

  @opts [packet: 1, active: :once, reuseaddr: true]
  defp reaccept(%__MODULE__{} = state, socket \\ nil) do
    state = close(state, socket)

    l_socket_res =
      case state.address do
        {:tcp, ip, port} -> :gen_tcp.listen(port, [ip: ip] ++ @opts)
        {:uds, path} -> :gen_tcp.listen(0, [ifaddr: {:local, path}] ++ @opts)
      end

    with {:ok, l_socket} <- l_socket_res,
         {:ok, a_socket} <- :gen_tcp.accept(l_socket) do
      %__MODULE__{state | lsocket: l_socket, asocket: a_socket}
    else
      err ->
        Logger.warn("[#{__MODULE__}]: #{inspect(err)}")
        state
    end
  end
end
