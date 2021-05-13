defmodule MeshxConsul.Service.GenTcpPort do
  @moduledoc """
  Generates TCP port numbers used by mesh service and upstream endpoints.

  todo: Documentation will be provided at a later date.
  """

  use GenServer

  @tcp_opts [
    ip: [
      type: {:custom, __MODULE__, :validate_ip, []},
      default: {127, 0, 0, 1}
    ],
    port_range: [
      type: {:custom, __MODULE__, :validate_port, [1, 65535]},
      default: 1024..65535
    ]
  ]

  defstruct [:ip, :lo, :hi, :min, :max]

  @doc false
  def start_link(args), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  def new(range \\ :lo, server \\ __MODULE__, timeout \\ 5_000) when range in [:lo, :hi],
    do: GenServer.call(server, {:new, range}, timeout)

  @impl true
  def init(args) do
    args = NimbleOptions.validate!(args, @tcp_opts)
    min = Keyword.fetch!(args, :port_range) |> Enum.min()
    max = Keyword.fetch!(args, :port_range) |> Enum.max()
    state = %__MODULE__{ip: Keyword.fetch!(args, :ip), lo: min, hi: max, min: min, max: max}

    {:ok, state}
  end

  @impl true
  def handle_call({:new, range}, _from, %__MODULE__{} = state) do
    {port, state} = find_port(range, state)
    {:reply, {:tcp, state.ip, port}, state}
  end

  defp find_port(range, %__MODULE__{} = state) do
    port = Map.fetch!(state, range)

    state =
      case range do
        :lo ->
          if state.lo + 1 < state.hi, do: %{state | lo: port + 1}, else: %{state | lo: state.min, hi: state.max}

        :hi ->
          if state.lo < state.hi - 1, do: %{state | hi: port - 1}, else: %{state | lo: state.min, hi: state.max}
      end

    # possible implementation option: fallback to random port instead of infinite loop
    if connected?(state.ip, port), do: find_port(range, state), else: {port, state}
  end

  defp connected?(ip, port) do
    case :gen_tcp.connect(ip, port, [:binary, active: false]) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        true

      {:error, :einval} ->
        exit("Invalid tcp address: [#{ip}] or port: [#{port}].")

      _ ->
        false
    end
  end

  @doc false
  def validate_ip(ip) do
    case :inet.ntoa(ip) do
      {:error, _e} -> {:error, "Expected ip address as tuple, eg.: {127, 0, 0, 1}. Got: #{inspect(ip)}."}
      _ip -> {:ok, ip}
    end
  end

  @doc false
  def validate_port(%Range{} = r, min, max) do
    if Enum.min(r) >= min and Enum.max(r) <= max and min < max,
      do: {:ok, r},
      else: {:error, "Expected range in: #{min}..#{max}. Got: #{inspect(r)}."}
  end
end
