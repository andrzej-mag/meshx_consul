defmodule MeshxConsul.Service.Reg do
  @moduledoc false
  alias MeshxConsul.Service.{Endpoint, Ets}

  def config(service_id), do: Endpoint.get("/agent/service/#{service_id}")

  def passing?(service_id) do
    case Endpoint.get("/agent/health/service/id/#{service_id}") do
      {:ok, _response} -> true
      _ -> false
    end
  end

  def register_service(service_reg, replace_checks \\ true)

  def register_service(service_reg, replace_checks) when is_map(service_reg) do
    case Jason.encode(service_reg) do
      {:ok, reg} -> register_service(reg, replace_checks)
      e -> e
    end
  end

  def register_service(service_reg, replace_checks) when is_bitstring(service_reg),
    do: Endpoint.put("/agent/service/register", service_reg, %{"replace-existing-checks" => replace_checks})

  def deregister_service(service_id), do: Endpoint.put("/agent/service/deregister/#{service_id}")

  def register_check(check_reg), do: Endpoint.put("/agent/check/register", check_reg)
  def deregister_check(check_id), do: Endpoint.put("/agent/check/deregister/#{check_id}")
  def update_check(check_id, status), do: Endpoint.put("/agent/check/update/#{check_id}", %{status: status})

  def deregister_proxy(service_id) do
    case find_proxy(service_id) do
      {:ok, {_name, id}} -> deregister_service(id)
      _ -> :ok
    end
  end

  def get_upstreams(service_id) do
    with true <- Ets.has_service?(service_id),
         {:ok, {proxy_name, proxy_id}} <- find_proxy(service_id),
         {:ok, proxy_conf} <- config(proxy_id) do
      upstreams = get_in(proxy_conf, ["Proxy", "Upstreams"]) || []
      {:ok, upstreams, proxy_name, proxy_id, proxy_conf}
    else
      false -> {:error, :service_not_owned}
      err -> err
    end
  end

  defp find_proxy(service_id) do
    s_id = to_string(service_id)

    case Endpoint.get("/agent/services", %{filter: ~s(Kind=="connect-proxy")}) do
      {:ok, services} ->
        proxy =
          Enum.map(services, fn {id, s} ->
            if get_in(s, ["Proxy", "DestinationServiceID"]) == s_id or get_in(s, ["Proxy", "DestinationServiceName"]) == s_id,
              do: {Map.fetch!(s, "Service"), id},
              else: nil
          end)
          |> Enum.reject(&is_nil/1)

        case length(proxy) do
          0 -> {:error, :proxy_not_found}
          1 -> {:ok, hd(proxy)}
          _ -> {:error, :multiple_proxies}
        end

      err ->
        err
    end
  end
end
