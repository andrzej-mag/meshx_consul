defmodule ServiceConnectTest do
  use ExUnit.Case
  @moduletag capture_log: true

  defp connect_defaults(name_in, name_out) do
    assert MeshxConsul.Service.Reg.passing?(name_out) == false
    assert {:ok, _addresses} = MeshxConsul.connect(name_in)
    assert MeshxConsul.Service.Reg.passing?(name_out) == true

    assert MeshxConsul.list() == [name_out]
    assert MeshxConsul.list_upstream(name_out) == Enum.map(name_in, &to_string/1)
    proxy_id = "#{name_out}-sidecar-proxy"
    assert {:ok, %{"ID" => ^proxy_id}} = MeshxConsul.info(proxy_id)

    assert MeshxConsul.Ttl.get_status(name_out) == "passing"

    assert MeshxConsul.Proxy.info(name_out) == %{
             cmd: ["/bin/sh", "-c", "consul connect proxy -log-level err -sidecar-for #{name_out}"],
             restarts: 0
           }

    assert MeshxConsul.stop(name_out) == :ok
    assert MeshxConsul.stop(name_out) == {:error, :service_not_owned}
  end

  def hostname() do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end

  test ~s<connect([:service1])>, do: connect_defaults([:service1], "upstream-" <> hostname())
  test ~s<connect(["service1"])>, do: connect_defaults(["service1"], "upstream-" <> hostname())
  test ~s<connect([:service1, :service2])>, do: connect_defaults([:service1, :service2], "upstream-" <> hostname())
  test ~s<connect(["service1", "service2"])>, do: connect_defaults(["service1", "service2"], "upstream-" <> hostname())
end
