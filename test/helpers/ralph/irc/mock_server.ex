defmodule Ralph.IRC.MockServer do
  use GenServer

  ## Client

  def start_link do
    GenServer.start_link(__MODULE__, self())
  end

  ## Server

  def init(notify_pid) do
    Process.flag(:trap_exit, true)
    pid = self()

    {:ok, conn} =
      :gen_tcp.listen(6667, [
        :binary,
        ip: {127, 0, 0, 1},
        reuseaddr: true,
        active: false,
        packet: :line
      ])

    {:ok, accept_pid} = Task.start_link(fn -> accept_loop(pid, conn) end)

    {:ok, {conn, accept_pid, notify_pid}}
  end

  def handle_info({:client_connected, conn}, {_, _, notify_pid} = state) do
    :ok = :gen_tcp.controlling_process(conn, notify_pid)
    send(notify_pid, {:client_connected, conn})

    {:noreply, state}
  end

  # def handle_info(_, state) do
  #   {:noreply, state}
  # end

  def terminate(_reason, {conn, _, _}) do
    :gen_tcp.close(conn)
  end

  ## Helpers

  defp accept_loop(pid, conn) do
    {:ok, client} = :gen_tcp.accept(conn)
    :ok = :gen_tcp.controlling_process(client, pid)

    send(pid, {:client_connected, client})
    accept_loop(pid, conn)
  end
end

defmodule Ralph.IRC.MockClient do
  use GenServer

  def start_link(sock) do
    GenServer.start_link(__MODULE__, {sock, self()})
  end

  def write(pid, line) do
    GenServer.call(pid, {:write, line})
  end

  ## Client

  def init({sock, pid}) do
    :inet.setopts(sock, active: :once)

    Process.flag(:trap_exit, true)

    {:ok, {sock, pid}}
  end

  def handle_call({:write, line}, _from, {conn, _} = state) do
    :ok = :gen_tcp.send(conn, [line, "\r\n"])

    {:reply, :ok, state}
  end

  def handle_info({:tcp, _, line}, {conn, pid} = state) do
    :inet.setopts(conn, active: :once)
    line = Ralph.IRC.Protocol.parse_line(line)
    send(pid, {:line, line})

    {:noreply, state}
  end

  def terminate(_reason, {conn, _}) do
    :gen_tcp.close(conn)
  end
end
