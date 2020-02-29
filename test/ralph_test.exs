defmodule TestBot do
  use Ralph.IRC

  network :test do
    server "localhost"
    nick "test_nick"

    channel "#test" do
      on_join fn ctx ->
        privmsg ctx, "hi there!"
      end
    end
  end
end

defmodule RalphTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = Ralph.IRC.MockServer.start_link()

    on_exit(fn ->
      if Process.alive?(pid) do
        GenServer.stop(pid)
      end
    end)

    {:ok, _pid} = TestBot.start_link([])

    {:ok, pid} =
      receive do
        {:client_connected, conn} ->
          {:ok, pid} = Ralph.IRC.MockClient.start_link(conn)
          :ok = :gen_tcp.controlling_process(conn, pid)

          {:ok, pid}
      after
        5000 ->
          raise "failed to connect"
      end

    [mock_client: pid]
  end

  test "greets the world", %{mock_client: mock_client} do
    assert_receive {:line, {_, "NICK", ["test_nick"]}}, 100
    assert_receive {:line, {_, "USER", ["chris", "chris", "chris", "chris"]}}, 100
    assert_receive {:line, {_, "JOIN", ["#test"]}}, 100

    :ok = Ralph.IRC.MockClient.write(mock_client, ":foo JOIN #test")
    assert_receive {:line, {_, "PRIVMSG", ["#test", "hi there!"]}}, 100
  end
end
