defmodule Divano do
  @default_opts [
    host: "localhost",
    port: 5984,
    scheme: "http",
    database: ""
  ]

  def start_link(server, database, opts) do
    server_opts = parse_url(server)
    opts = Keyword.merge(opts, server_opts)
    start_link(database, opts)
  end

  def start_link(database) do
    start_link(database, [])
  end

  def start_link(database, opts) when is_list(opts) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Divano.Connection, [database, Keyword.merge(@default_opts, opts)])
    ]

    opts = [strategy: :one_for_one, name: Divano.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp parse_url(server_url) do
    uri = URI.parse(server_url)
    [host: uri.host, port: uri.port, scheme: uri.scheme]
  end
end
