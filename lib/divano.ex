defmodule Divano do

  def start_link(database_url, opts) do
    url_opts = database_url |> parse_url
    database_url = "#{url_opts[:scheme]}://#{url_opts[:host]}:#{url_opts[:port]}"
    database_name = db_name(url_opts[:path])

    server = :couchbeam.server_connection(database_url, opts)

    if database_name do
      couchbeam_opts = opts[:couchbeam_options] || []
      {:ok, database} = :couchbeam.open_or_create_db(server, database_name, couchbeam_opts)
      Agent.start_link(fn -> %{server: server, database: database} end, opts)
    else
      Agent.start_link(fn -> %{server: server} end, opts)
    end
  end

  def server_info(pid) do
    server = Agent.get(pid, fn state -> state[:server] end)
    :couchbeam.server_info(server)
  end

  def save_doc(pid, id, attributes \\ [], opts \\ []) do
    database = Agent.get(pid, fn state -> state[:database] end)
    attributes = {[{"_id", id} | Enum.to_list(attributes)]}
    :couchbeam.save_doc(database, attributes, opts)
  end

  def open_doc(pid, id, opts \\ []) do
    database = Agent.get(pid, fn state -> state[:database] end)
    {:ok, {doc}} = :couchbeam.open_doc(database, id, opts)
    Enum.into(doc, %{})
  end

  def delete_doc(pid, id, opts \\ []) do
    database = Agent.get(pid, fn state -> state[:database] end)
    {:ok, doc} = :couchbeam.open_doc(database, id, [])
    :couchbeam.delete_doc(database, doc, opts)
  end

  defp parse_url(server_url) do
    uri = URI.parse(server_url)
    [host: uri.host, port: uri.port, scheme: uri.scheme, path: uri.path]
  end

  defp db_name(nil), do: nil
  defp db_name("/"), do: nil
  defp db_name("/" <> db), do: db
end
