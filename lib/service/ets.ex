defmodule MeshxConsul.Service.Ets do
  @moduledoc false
  @tbl MeshxConsul.App.C.lib()

  def list(), do: :ets.tab2list(@tbl) |> Enum.map(fn {e} -> e end)
  def insert(service_name), do: :ets.insert(@tbl, {service_name})
  def delete(service_name), do: :ets.delete(@tbl, service_name)

  def has_service?(service_name) do
    if :ets.whereis(@tbl) == :undefined, do: false, else: :ets.member(@tbl, service_name)
  end
end
