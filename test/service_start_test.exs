defmodule ServiceStartTest do
  use ExUnit.Case
  @moduletag capture_log: true

  def start_defaults(name_in, name_out) do
    assert MeshxConsul.Service.Reg.passing?(name_out) == false
    assert {:ok, ^name_out, {:tcp, _ip, _port}} = MeshxConsul.start(name_in)
    assert MeshxConsul.Service.Reg.passing?(name_out) == true
    assert MeshxConsul.start(name_in) == {:ok, :already_started}
    assert MeshxConsul.list() == [name_out]
    assert MeshxConsul.list_upstream(name_out) == []
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

  test ~s<start(:service1)>, do: start_defaults(:service1, "service1-" <> hostname())
  test ~s<start("service1")>, do: start_defaults(:service1, "service1-" <> hostname())
  test ~s<start({:service1, :service1id})>, do: start_defaults({:service1, :service1id}, "service1id")
  test ~s<start({"service1", "service1id"})>, do: start_defaults({"service1", "service1id"}, "service1id")

  test ~s<start(:service1), no proxy> do
    name_in = :service1
    name_out = "service1-" <> hostname()
    assert {:ok, ^name_out, {:tcp, _ip, _port}} = MeshxConsul.start(name_in, proxy: nil)
    assert MeshxConsul.Service.Reg.passing?(name_out) == true
    assert MeshxConsul.Ttl.get_status(name_out) == "passing"

    # assert catch_exit(MeshxConsul.Proxy.info(name_out)) ==
    #          {:noproc, {GenServer, :call, [:("Elixir.MeshxConsul.Proxy.service1-" <> hostname()), :info, 5000]}}

    assert MeshxConsul.stop(name_out) == :ok
  end

  test ~s<start(:service1), no ttl> do
    name_in = :service1
    name_out = "service1-" <> hostname()
    assert {:error, :service_alive_timeout} = MeshxConsul.start(name_in, [ttl: nil], true, 1000)
    assert MeshxConsul.stop(name_out) == {:error, :service_not_owned}
  end
end
