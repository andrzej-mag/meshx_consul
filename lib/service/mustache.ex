defmodule MeshxConsul.Service.Mustache do
  @moduledoc false
  @bbm_opts [:raise_on_context_miss, key_type: :binary]

  def ext_render(template, _data) when is_nil(template), do: {:ok, nil}
  def ext_render(template, data), do: render(template, data)

  def ext_render2map(template, data, keys \\ :strings)
  def ext_render2map(template, _data, _keys) when is_nil(template), do: {:ok, nil}
  def ext_render2map(template, data, keys), do: render2map(template, data, keys)

  def render(template, data) when is_map(template) do
    case Jason.encode(template) do
      {:ok, str_template} -> render(str_template, data)
      err -> err
    end
  end

  def render(template, data) when is_bitstring(template) do
    repl_template = String.replace(template, "\"{{$", "{{") |> String.replace("$}}\"", "}}")
    render = :bbmustache.render(repl_template, data, @bbm_opts)
    {:ok, render}
  end

  def render(template, data, acc \\ [])

  def render([template | tail], data, acc) do
    case render(template, data) do
      {:ok, r} -> render(tail, data, acc ++ [r])
      err -> err
    end
  end

  def render([], _data, acc), do: {:ok, acc}

  def render2map(template, data, keys \\ :strings) do
    case render(template, data) do
      {:ok, render} -> Jason.decode(render, keys: keys)
      err -> err
    end
  end
end
