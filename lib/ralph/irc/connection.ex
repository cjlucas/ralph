defmodule Ralph.IRC.Connection do
  use GenServer

  def start_link([bot]) do
    GenServer.start_link(__MODULE__, bot)
  end

  def write(conn, data) do
    IO.inspect "--> #{data}"
    :gen_tcp.send(conn, data) |> IO.inspect
  end

  def init(bot) do
    # {:ok, conn} = :gen_tcp.connect('vps275269.vps.ovh.ca', 6667, [])
    {:ok, conn} = :gen_tcp.connect('localhost', 43269, [])
    :ok = :inet.setopts(conn, active: true, mode: :binary, packet: :line)

    data = Ralph.IRC.Protocol.cap(self())
    write(conn, data)

    {:ok, {conn, bot}}
  end

  def handle_info({:tcp, _sock, data}, {conn, bot} = state) do
    bot.on_line(conn, data)

    {:noreply, state}
  end
end
