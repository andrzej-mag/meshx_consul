defmodule ServiceOtherTest do
  use ExUnit.Case

  test "list/0: no services" do
    assert MeshxConsul.list() == []
  end

  test "list_upstream/1: no upstream service" do
    assert MeshxConsul.list_upstream() == {:error, :service_not_owned}
    assert MeshxConsul.list_upstream("invalid") == {:error, :service_not_owned}
    assert MeshxConsul.list_upstream(:invalid) == {:error, :service_not_owned}
  end
end
