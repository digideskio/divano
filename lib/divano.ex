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

  def server_info(pid) do
    GenServer.call(pid, :server_info)
  end

  def save_doc(pid, id, attributes \\ [], opts \\ []) do
    attributes = {[{"_id", id} | Enum.to_list(attributes)]}
    GenServer.call(pid, {:save_doc, attributes, opts})
  end

  def open_doc(pid, id, opts \\ []) do
    {:ok, {doc}} = GenServer.call(pid, {:open_doc, id, opts})
    Enum.into(doc, %{})
  end

  def delete_doc(pid, id, opts \\ []) do
    {:ok, doc} = GenServer.call(pid, {:open_doc, id, []})
    GenServer.call(pid, {:delete_doc, doc, opts})
  end

  defp parse_url(server_url) do
    uri = URI.parse(server_url)
    [host: uri.host, port: uri.port, scheme: uri.scheme]
  end
end
