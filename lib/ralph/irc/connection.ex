defmodule Ralph.IRC.Connection do
  use GenServer

  def start_link([bot, registry, config]) do
    GenServer.start_link(__MODULE__, {bot, registry, config})
  end

  def write(pid, data) do
    GenServer.call(pid, {:write, data})
  end

  def do_write(conn, data) do
    :gen_tcp.send(conn, data) |> IO.inspect()
  end

  def init({bot, registry, config}) do
    IO.inspect(config, label: "in init")
    {:ok, _} = Ralph.IRC.NetworkRegistry.register(registry, config.name)

    server = List.first(config.servers) |> String.to_charlist()
    {:ok, conn} = :gen_tcp.connect(server, 6667, [])
    # {:ok, conn} = :gen_tcp.connect('localhost', 43269, [])
    :ok = :inet.setopts(conn, active: true, mode: :binary, packet: :line, nodelay: true)

    data = Ralph.IRC.Protocol.nick(config.nick || "foobar")
    do_write(conn, data)
    do_write(conn, "\r\n")

    data = Ralph.IRC.Protocol.user("chris", "chris", "chris", "chris")
    do_write(conn, data)
    do_write(conn, "\r\n")

    # do_write(conn, "PASS admin:admin")
    # do_write(conn, "\r\n")

    Enum.each(config.channels, fn %{name: name} ->
      do_write(conn, "JOIN #{name}")
      do_write(conn, "\r\n")
    end)

    do_write(conn, "PRIVMSG \#omghithere :howdy!")
    do_write(conn, "\r\n")

    {:ok, {conn, bot, [], config.name}}
  end

  def handle_call({:write, data}, _from, {conn, bot, acc, _} = state) do
    do_write(conn, data)

    {:reply, :ok, state}
  end

  def handle_info({:tcp, _sock, data}, {conn, bot, acc, network_name} = state) do
    pid = self()

    data = data |> String.trim() |> parse_line

    Task.start_link(fn ->
      bot.on_line({network_name, pid}, data)
    end)

    {:noreply, state}
  end

  def parse_line(line) do
    [prefix, line] =
      if String.starts_with?(line, ":") do
        line = line |> String.split_at(1) |> elem(1)
        String.split(line, " ", parts: 2)
      else
        [nil, line]
      end

    [command, params] = String.split(line, " ", parts: 2)

    params = String.split(params)

    params =
      case Enum.find_index(params, fn param -> String.starts_with?(param, ":") end) do
        nil ->
          params

        idx ->
          {word_params, trailing_param} = Enum.split(params, idx)
          trailing_param = trailing_param |> Enum.join(" ") |> String.split_at(1) |> elem(1)
          word_params ++ [trailing_param]
      end

    {prefix, command, params}
  end
end
