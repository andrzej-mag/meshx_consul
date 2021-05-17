defmodule MeshxConsul.Service.Endpoint do
  @moduledoc """
  Consul agent http API endpoint.

  `MeshxConsul` is using OTP [`:httpc`](http://erlang.org/doc/man/httpc.html) HTTP client to access Consul agent HTTP API endpoint when managing services and upstreams. Required by `:httpc` configuration is described in `MeshxConsul` **Configuration options** section.

  #### Example
  Query [Consul KV store](https://www.consul.io/api/kv):
  ```elixir
  iex(1)> MeshxConsul.Service.Endpoint.put("/kv/my-key", "my-key_value")
  :ok
  iex(2)> MeshxConsul.Service.Endpoint.get("/kv/my-key", %{raw: true})
  'my-key_value'
  iex(3)> MeshxConsul.Service.Endpoint.delete("/kv/my-key")
  :ok
  iex(4)> MeshxConsul.Service.Endpoint.get("/kv/my-key")
  {:error,
   [
     {{'HTTP/1.1', 404, 'Not Found'},
      [
        ...
      ], []},
     "Get request uri: [http:///v1/kv/my-key?keys=true]"
   ]}
  ```
  """

  alias MeshxConsul.App.C

  @api "/v1"

  @doc """
  Returns configuration and member information of the local agent using [`/agent/self`](https://www.consul.io/api-docs/agent#read-configuration) Consul HTTP API endpoint.
  ```elixir
  iex(1)> MeshxConsul.Service.Endpoint.self()
  {:ok,
  %{
     "Config" => %{
      "Datacenter" => "my-dc",
      "NodeName" => "h11",
      ...
     }
   ...
   }
  }
  ```
  """
  @spec self() :: {:ok, map()} | {:error, reason :: term()}
  def self(), do: get("/agent/self")

  @doc """
  Returns `GET` request response at `path` API endpoint address.
  """
  @spec get(path :: String.t(), query :: map()) :: {:ok, map()} | {:error, reason :: term()}
  def get(path, query \\ %{}) do
    uri =
      C.uri()
      |> Map.put(:path, Path.join(@api, path))
      |> Map.put(:query, URI.encode_query(query))
      |> URI.to_string()
      |> to_charlist()

    case :httpc.request(:get, {uri, C.httpc_headers()}, C.httpc_request_http_options(), C.httpc_request_options()) do
      {:ok, {{_http_version, 200, _reason_phrase}, _headers, body}} ->
        if Map.get(query, :raw, false), do: body, else: Jason.decode(body)

      {:ok, {200, body}} ->
        if Map.get(query, :raw, false), do: body, else: Jason.decode(body)

      {:ok, err} ->
        {:error, [err, "Get request uri: [#{uri}]"]}

      err ->
        {:error, [err, "Get request uri: [#{uri}]"]}
    end
  end

  @doc """
  `PUT` `payload` at `path` API endpoint address.
  """
  @spec put(path :: String.t(), payload :: String.t() | map(), query :: map()) :: :ok | {:error, reason :: term()}
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

  @doc """
  Issues `DELETE` request at `path`.
  """
  @spec delete(path :: String.t(), query :: map()) :: :ok | {:error, reason :: term()}
  def delete(path, query \\ %{}) do
    uri =
      C.uri()
      |> Map.put(:path, Path.join(@api, path))
      |> Map.put(:query, URI.encode_query(query))
      |> URI.to_string()
      |> to_charlist()

    case :httpc.request(:delete, {uri, C.httpc_headers()}, C.httpc_request_http_options(), C.httpc_request_options()) do
      {:ok, {{_http_version, 200, _reason_phrase}, _headers, 'true'}} -> :ok
      {:ok, {200, 'true'}} -> :ok
      {:ok, err} -> {:error, [err, "Put request uri: [#{uri}]"]}
      err -> {:error, [err, "Put request uri: [#{uri}]"]}
    end
  end
end
