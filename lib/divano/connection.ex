defmodule Divano.Connection do
  use GenServer

  def start_link(database, opts) do
    GenServer.start_link(__MODULE__, {database, opts}, name: opts[:name] || String.to_atom(database))
  end

  def init({database, opts}) do
    database_url = "#{opts[:scheme]}://#{opts[:host]}:#{opts[:port]}"
    server = :couchbeam.server_connection(database_url, opts)
    {:ok, _} = :couchbeam.server_info(server)
    {:ok, db} = :couchbeam.open_or_create_db(server, database, opts)
    {:ok, {db, server}}
  end

  def handle_call(:server_info, _from, state = {_, server}) do
    {:reply, :couchbeam.server_info(server), state}
  end

  def handle_call({method, params, opts}, _from, state = {database, _}) do
    result = :erlang.apply(:couchbeam, method, [database, params, opts])
    {:reply, result, state}
  end
end
