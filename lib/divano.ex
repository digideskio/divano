defmodule Divano do

  def start_link(database_url, opts \\ []) do
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
    doc = map_to_doc(id, attributes)
    case :couchbeam.save_doc(database, doc, opts) do
      {:ok, doc} -> {:ok, doc_to_map(doc)}
           error -> error
    end
  end

  def open_doc(pid, id, opts \\ []) do
    database = Agent.get(pid, fn state -> state[:database] end)
    case :couchbeam.open_doc(database, id, opts) do
      {:ok, doc} -> {:ok, doc_to_map(doc)}
           error -> error
    end
  end

  def delete_doc(pid, id, opts \\ []) do
    database = Agent.get(pid, fn state -> state[:database] end)
    case :couchbeam.open_doc(database, id, []) do
      {:ok, doc} -> case :couchbeam.delete_doc(database, doc, opts) do
        {:ok, _} -> :ok
           error -> error
      end
           error -> error
    end
  end

  defp doc_to_map({attrs}) do
    kwlist_to_map(attrs)
  end

  defp map_to_doc(id, map) do
    attrs = if Map.has_key?(map, "_id") do
      map_to_kwlist(map)
    else
      [{"_id", id} | map_to_kwlist(map)]
    end
    {attrs}
  end

  defp kwlist_to_map(kwlist) when is_list(kwlist) and length(kwlist) > 0 do
    case kwlist |> List.first do
      {_, _} ->
        Enum.reduce(kwlist, %{}, fn(tuple, acc) ->
          {key, value} = tuple
          Map.put(acc, key, kwlist_to_map(value))
        end)
      _ ->
        kwlist
    end
  end

  defp kwlist_to_map(value), do: value

  defp map_to_kwlist(map) when is_map(map) do
    Enum.reduce(map, [], fn(tuple, acc) ->
      {key, value} = tuple
      [{key, map_to_kwlist(value)} | acc]
    end)
  end

  defp map_to_kwlist(value), do: value

  defp parse_url(server_url) do
    uri = URI.parse(server_url)
    [host: uri.host, port: uri.port, scheme: uri.scheme, path: uri.path]
  end

  defp db_name(nil), do: nil
  defp db_name("/"), do: nil
  defp db_name("/" <> db), do: db
end
