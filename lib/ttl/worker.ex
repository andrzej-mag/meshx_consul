defmodule MeshxConsul.Ttl.Worker do
  @moduledoc false
  use GenServer
  alias MeshxConsul.Service.Reg

  defstruct [:id, status: "passing", ttl: 10_000]

  @allowed_status ["passing", "warning", "critical"]

  def start_link([id, ttl_opts]), do: GenServer.start_link(__MODULE__, ttl_opts, name: id)

  def get_status(id), do: GenServer.call(id, :get_status)
  def set_status(id, status) when status in @allowed_status, do: GenServer.cast(id, {:set_status, status})
  def cleanup(id), do: GenServer.cast(id, :cleanup)

  @impl true
  def init(ttl_args) do
    Process.send_after(self(), :run_check, 100, [])
    {:ok, Map.merge(%__MODULE__{}, ttl_args)}
  end

  @impl true
  def handle_info(:run_check, %__MODULE__{} = state) do
    Reg.update_check(state.id, state.status)
    Process.send_after(self(), :run_check, state.ttl, [])
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_status, _from, %__MODULE__{} = state), do: {:reply, state.status, state}

  @impl true
  def handle_cast({:set_status, status}, %__MODULE__{} = state) when status in @allowed_status do
    Reg.update_check(state.id, status)
    {:noreply, %__MODULE__{state | status: status}}
  end

  @impl true
  def handle_cast(:cleanup, %__MODULE__{} = state) do
    Reg.deregister_check(state.id)
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, %__MODULE__{} = state), do: Reg.deregister_check(state.id)
end
