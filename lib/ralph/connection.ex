defmodule Ralph.Connection do
  use GenServer

  ## Client

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  ## Server

  def init(:ok) do
    {:ok, s} = :gen_tcp.connect('irc.freenode.net', 6667, [])
    :inet.setopts(s, active: true)
    {:ok, {s, []}}
  end

  def handle_info({:tcp, s, data}, {_, buf} = state) do
    IO.puts "got a message"
    IO.inspect s
    IO.inspect data

    {:noreply, state}
  end
end
