defmodule MeshxConsul.Service.Endpoint do
  @moduledoc """
  Consul agent http API endpoint.

  todo: Documentation will be provided at a later date.
  """

  alias MeshxConsul.App.C

  @api "/v1"
  def self(), do: get("/agent/self")

  def get(path, query \\ %{}) do
    uri =
      C.uri()
      |> Map.put(:path, Path.join(@api, path))
      |> Map.put(:query, URI.encode_query(query))
      |> URI.to_string()
      |> to_charlist()

    case :httpc.request(:get, {uri, C.httpc_headers()}, C.httpc_request_http_options(), C.httpc_request_options()) do
      {:ok, {{_http_version, 200, _reason_phrase}, _headers, body}} -> Jason.decode(body)
      {:ok, {200, body}} -> Jason.decode(body)
      {:ok, err} -> {:error, [err, "Get request uri: [#{uri}]"]}
      err -> {:error, [err, "Get request uri: [#{uri}]"]}
    end
  end

  def put(path, payload \\ "", query \\ %{})

  def put(path, payload, query) when is_map(payload) do
    case Jason.encode(payload) do
      {:ok, payload} -> put(path, payload, query)
      err -> err
    end
  end

  def put(path, payload, query) when is_bitstring(payload) do
    uri =
      C.uri()
      |> Map.put(:path, Path.join(@api, path))
      |> Map.put(:query, URI.encode_query(query))
      |> URI.to_string()
      |> to_charlist()

    case :httpc.request(
           :put,
           {uri, C.httpc_headers(), 'application/json', payload},
           C.httpc_request_http_options(),
           C.httpc_request_options()
         ) do
      {:ok, {{_http_version, 200, _reason_phrase}, _headers, _body}} -> :ok
      {:ok, {200, _body}} -> :ok
      {:ok, err} -> {:error, [err, "Put request uri: [#{uri}]"]}
      err -> {:error, [err, "Put request uri: [#{uri}]"]}
    end
  end
end
