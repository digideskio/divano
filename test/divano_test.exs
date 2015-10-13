defmodule DivanoTest do
  use ExUnit.Case

  setup_all do
    # Delete existing database before of start tests
    server = :couchbeam.server_connection("http://localhost:5984", [])
    :couchbeam.delete_db(server, "divanotest")

    Divano.start_link("http://localhost:5984/divanotest", name: :divano_test)
    :ok
  end

  test "start_link without database name" do
    {:ok, _} = Divano.start_link("http://localhost:5984", name: :testdb)
    db_info = Agent.get(:testdb, fn db_info -> db_info end)
    {:server, server, _} = db_info[:server]

    assert "http://localhost:5984" == server
    assert nil == db_info[:database]
  end

  test "start_link with database name" do
    {:ok, _} = Divano.start_link("http://localhost:5984/testdb2", name: :testdb2)
    db_info = Agent.get(:testdb2, fn db_info -> db_info end)
    {:server, server, _} = db_info[:server]
    {:db, _, db_name, _} = db_info[:database]

    assert "http://localhost:5984" == server
    assert "testdb2" == db_name

    :couchbeam.delete_db(db_info[:server], db_name)
  end

  test "save_doc" do
    {:ok, doc} = Divano.save_doc(:divano_test, "user-1", %{"name" => "Guillermo Iguaran", "username" => "guilleiguaran"})

    assert "Guillermo Iguaran" == doc["name"]
    assert "guilleiguaran" == doc["username"]
  end

  test "open_doc" do
    {:ok, _} = Divano.save_doc(:divano_test, "user-2", %{"name" => "Guillermo Iguaran", "username" => "guilleiguaran"})
    {:ok, doc} = Divano.open_doc(:divano_test, "user-2")

    assert "Guillermo Iguaran" == doc["name"]
    assert "guilleiguaran" == doc["username"]
  end

  test "delete_doc" do
    {:ok, _} = Divano.save_doc(:divano_test, "user-3", %{"name" => "Guillermo Iguaran", "username" => "guilleiguaran"})
    :ok = Divano.delete_doc(:divano_test, "user-3")

    assert {:error, :not_found} == Divano.open_doc(:divano_test, "user-3")
  end
end
