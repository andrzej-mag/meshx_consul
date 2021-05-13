defmodule MustacheTest do
  use ExUnit.Case

  alias MeshxConsul.Service.Mustache

  @data %{"string_key" => "123abc", "int_key" => 123}
  @template_map %{"string" => "{{string_key}}", "int" => "{{$int_key$}}", "static" => "static_string"}
  @render %{"string" => "123abc", "int" => 123, "static" => "static_string"}

  test "ext_render/2" do
    assert Mustache.ext_render(nil, @data) == {:ok, nil}
    assert Mustache.ext_render2map(nil, @data) == {:ok, nil}
    assert Mustache.ext_render2map(@template_map, @data) == {:ok, @render}
  end
end
