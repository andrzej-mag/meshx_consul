defmodule MeshxConsul.Service.Template do
  @moduledoc false
  require Logger

  @upstream_proxy_prefix "upstream-"

  @service_template [
    registration: [
      type: {:custom, __MODULE__, :validate_map, [["Name"]]},
      default: %{
        "ID" => "{{id}}",
        "Name" => "{{name}}",
        "Checks" => [
          %{
            "Name" => "TTL check",
            "CheckID" => "ttl:{{id}}",
            "TTL" => "10s"
          }
        ],
        "Connect" => %{
          "SidecarService" => %{
            "Proxy" => %{
              "LocalServiceAddress" => "{{address}}",
              "LocalServicePort" => "{{$port$}}"
            }
          }
        }
      }
    ],
    ttl: [
      type: {:or, [{:in, [%{}, nil, [], ""]}, {:custom, __MODULE__, :validate_map, [[:id]]}]},
      default: %{
        id: "ttl:{{id}}",
        status: "passing",
        ttl: 5_000
      }
    ],
    proxy: [
      type: {:or, [{:in, [nil, [], ""]}, {:list, :string}]},
      default: ["/bin/sh", "-c", "consul connect proxy -log-level err -sidecar-for {{id}}"]
    ]
  ]

  @upstream_template %{
    "DestinationName" => "{{name}}",
    "LocalBindAddress" => "{{address}}",
    "LocalBindPort" => "{{$port$}}"
  }

  def default_nodename() do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end

  def default_proxy(), do: {@upstream_proxy_prefix <> default_nodename(), @upstream_proxy_prefix <> default_nodename()}

  def validate_service!(service), do: NimbleOptions.validate!(service, @service_template)

  def validate_upstream!(), do: validate_upstream!(@upstream_template)
  def validate_upstream!(u) when u in [nil, %{}, []], do: validate_upstream!(@upstream_template)

  def validate_upstream!(upstream) do
    case validate_map(upstream, ["DestinationName", "LocalBindPort"]) do
      {:ok, v} -> v
      {:error, e} -> raise(inspect(e))
    end
  end

  def validate_map(val, required) when is_map(val) do
    valid? = Enum.map(required, fn r -> Map.has_key?(val, r) end) |> Enum.reject(fn v -> v == true end) |> Enum.empty?()

    if valid?,
      do: {:ok, val},
      else: {:error, "expected map with required keys: #{inspect(required)}, got: #{inspect(val)}."}
  end

  def validate_map(val, required),
    do: {:error, "expected map with required keys: #{inspect(required)}, got: #{inspect(val)}."}
end
