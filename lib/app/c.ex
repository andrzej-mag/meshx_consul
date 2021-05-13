defmodule MeshxConsul.App.C do
  @moduledoc false

  @lib Mix.Project.config() |> Keyword.fetch!(:app)

  def lib, do: @lib

  def cli_env, do: Application.get_env(@lib, :cli_env, [])
  def uri, do: Application.get_env(@lib, :uri, %URI{scheme: "http", host: ""})
  def httpc_opts, do: Application.fetch_env!(@lib, :httpc_opts)
  def httpc_headers, do: Application.get_env(@lib, :httpc_headers, [])
  def httpc_request_http_options, do: Application.get_env(@lib, :httpc_request_http_options, [])
  def httpc_request_options, do: Application.get_env(@lib, :httpc_request_options, [])

  def service_template, do: Application.get_env(@lib, :service_template, [])
  def upstream_template, do: Application.get_env(@lib, :upstream_template)

  def proxy_stdout_fun, do: Application.get_env(@lib, :proxy_stdout_fun, &MeshxConsul.Proxy.Worker.stdout/3)
  def proxy_stderr_fun, do: Application.get_env(@lib, :proxy_stderr_fun, &MeshxConsul.Proxy.Worker.stderr/3)
  def proxy_down_fun, do: Application.get_env(@lib, :proxy_down_fun, &MeshxConsul.Proxy.Worker.down_fun/5)
  def max_proxy_restarts, do: Application.get_env(@lib, :max_proxy_restarts, 5)

  def tcp_address, do: Application.get_env(@lib, :tcp_address, [])
end
