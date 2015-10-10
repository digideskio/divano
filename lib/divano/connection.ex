defmodule Divano.Connection do
  use GenServer

  def start_link(database, opts) do
    GenServer.start_link(__MODULE__, {database, opts}, name: opts[:name])
  end

  def init({database, opts}) do
    database_url = "#{opts[:scheme]}://#{opts[:host]}:#{opts[:port]}"
    server = :couchbeam.server_connection(database_url, opts)
    {:ok, _} = :couchbeam.server_info(server)
    {:ok, db} = :couchbeam.open_or_create_db(server, database, opts)
    {:ok, {db, server}}
  end
end
