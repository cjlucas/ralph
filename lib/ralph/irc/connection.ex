defmodule Ralph.IRC.Connection do
  use GenServer

  defmodule State do
    defstruct bot: nil, conn: nil, config: nil
  end

  def start_link([bot, registry, config]) do
    GenServer.start_link(__MODULE__, {bot, registry, config})
  end

  def write(pid, data) do
    GenServer.call(pid, {:write, data})
  end

  def do_write(conn, data) do
    :gen_tcp.send(conn, [data, "\r\n"])
  end

  def init({bot, registry, config}) do
    {:ok, _} = Ralph.IRC.NetworkRegistry.register(registry, config.name)
    state = %State{bot: bot, config: config}

    {:ok, state, {:continue, :ok}}
  end

  def handle_continue(:ok, %{config: config} = state) do
    server = List.first(config.servers) |> String.to_charlist()
    {:ok, conn} = :gen_tcp.connect(server, 6667, [])
    :ok = :inet.setopts(conn, active: true, mode: :binary, packet: :line, nodelay: true)

    data = Ralph.IRC.Protocol.nick(config.nick)
    do_write(conn, data)

    data = Ralph.IRC.Protocol.user("chris", "chris", "chris", "chris")
    do_write(conn, data)

    Enum.each(config.channels, fn %{name: name} ->
      data = Ralph.IRC.Protocol.join(name)
      do_write(conn, data)
    end)

    {:noreply, %{state | conn: conn}}
  end

  def handle_call({:write, data}, _from, %{conn: conn} = state) do
    do_write(conn, data)

    {:reply, :ok, state}
  end

  def handle_info({:tcp, _sock, data}, %{bot: bot, config: config} = state) do
    pid = self()

    data = data |> String.trim() |> Ralph.IRC.Protocol.parse_line

    Task.start_link(fn ->
      bot.on_line({config.name, pid}, data)
    end)

    {:noreply, state}
  end
end
