defmodule TestBot do
  use Ralph.IRC

  network :test do
    server "localhost"
    nick "test_nick"

    channel "#test" do
      on_join fn ctx ->
        privmsg ctx, "i joined #test!"
      end
    end

    channel "#test2" do
      on_join fn ctx ->
        privmsg ctx, "i joined #test2!"
      end
    end

    on_join fn %{channel: channel} = ctx ->
      privmsg ctx, "i joined a channel: #{channel}"
    end
  end
end

defmodule RalphTest do
  use ExUnit.Case

  setup do
    {:ok, _} = Ralph.IRC.MockServer.start_link()
    {:ok, _} = TestBot.start_link([])

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
    :ok = Ralph.IRC.MockClient.write(mock_client, ":foo JOIN #test2")

    assert_receive {:line, {_, "PRIVMSG", ["#test", "i joined #test!"]}}, 100
    assert_receive {:line, {_, "PRIVMSG", ["#test", "i joined a channel: #test"]}}, 100

    assert_receive {:line, {_, "PRIVMSG", ["#test2", "i joined #test2!"]}}, 100
    assert_receive {:line, {_, "PRIVMSG", ["#test2", "i joined a channel: #test2"]}}, 100
  end
end
