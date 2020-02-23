defmodule Ralph.Connection do
  use GenServer

  ## Client

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  ## Server

  def init(opts) do
    IO.inspect(opts)

    host =
      opts
      |> Keyword.get(:servers, [])
      |> Enum.map(&String.to_charlist/1)
      |> List.first()

    {:ok, s} = :gen_tcp.connect(host, 6667, [])
    :inet.setopts(s, active: true)
    {:ok, {s, []}}
  end

  def handle_info({:tcp, s, data}, {_, buf} = state) do
    IO.puts("got a message")
    IO.inspect(s)
    IO.inspect(data)

    {:noreply, state}
  end
end
