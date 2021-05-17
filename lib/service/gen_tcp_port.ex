defmodule MeshxConsul.Service.GenTcpPort do
  @moduledoc """
  Generates TCP port numbers used by mesh service and upstream endpoints.

  Preparing mesh service and mesh upstream endpoints with `MeshxConsul.start/4` and `MeshxConsul.connect/3` requires creation of new TCP addresses used to connect user service providers and upstream clients with service mesh data plane.

  Worker producing unused TCP ports is initiated with `:tcp_address` key in `config.exs`. Default config value:
  ```elixir
  # config.exs
  config :meshx_consul,
    tcp_address: [ip: {127, 0, 0, 1}, port_range: 1024..65535]
  ```
    * `:ip` - network interface address. It should be defined as tuple and in most situations it should point at loopback interface. TCP traffic passing here is unencrypted, which means that unauthorized users should never have access to this interface.
    * `:port_range` - range in which available TCP ports will be allocated. Service ports are starting from lower range limit and are increasing, upstream ports are decreasing from upper range limit.
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

  @doc """
  Generates new TCP port address.

  `range` specifies which range should be used: `:lo` (lower) or `:hi` (higher).

  `timeout` - if worker is unable find available port in time limited by `timeout`, function call fails and the caller exits.

  ```elixir
  iex(1)> MeshxConsul.Service.GenTcpPort.new
  {:tcp, {127, 0, 0, 1}, 1024}
  iex(2)> MeshxConsul.Service.GenTcpPort.new(:hi)
  {:tcp, {127, 0, 0, 1}, 65535}
  ```
  """
  @spec new(range :: :lo | :hi, timeout :: timeout()) :: {:tcp, ip :: tuple(), port :: pos_integer()}
  def new(range \\ :lo, timeout \\ 5_000) when range in [:lo, :hi],
    do: GenServer.call(__MODULE__, {:new, range}, timeout)

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
