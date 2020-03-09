defmodule Ralph.IRC.ReplyManager do
  use GenServer

  ## Client

  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  def register_request(name, from, intermediate_codes, end_codes) do
    GenServer.call(name, {:register_request, from, intermediate_codes, end_codes})
  end

  def handle_reply(name, reply) do
    GenServer.call(name, {:handle_reply, reply})
  end

  ## Server

  def init(:ok) do
    state = %{requests: []}

    {:ok, state}
  end

  def handle_call(
        {:register_request, from, intermediate_codes, end_codes},
        _from,
        %{requests: requests} = state
      ) do
    # This should actually be a push onto a queue rather than a pop onto a stack
    requests = [{from, intermediate_codes, end_codes, []} | requests]

    {:reply, :ok, %{state | requests: requests}}
  end

  def handle_call({:handle_reply, reply}, _from, %{requests: requests} = state) do
    IO.inspect(requests, label: "huh")
    # Track the progress through the stack
    acc = {[], requests}

    {requests, _} =
      Enum.reduce_while(requests, acc, fn request, acc ->
        {_, code, _} = reply
        {from, intermediate_codes, end_codes, results} = request
        {seen, [_ | next]} = acc

        IO.puts("omghere #{code} #{inspect(end_codes)}")

        cond do
          code in intermediate_codes ->
            IO.puts("MADE IT HERE1")
            request = {from, intermediate_codes, end_codes, [reply | results]}
            {:halt, {seen ++ [request] ++ next, nil}}

          code in end_codes ->
            IO.puts("MADE IT HERE2")

            unless is_nil(from) do
              GenServer.reply(from, [reply | results])
            end

            {:halt, {seen ++ next, nil}}

          true ->
            IO.puts("MADE IT HERE3")
            acc = {[request | seen], next}
            {:cont, acc}
        end
      end)

    {:reply, :ok, %{state | requests: requests}}
  end
end
