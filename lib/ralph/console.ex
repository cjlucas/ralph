defmodule Ralph.Console do
  def child_spec(_args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
    }
  end

  def start_link do
    IO.puts "omghere"

    Task.start_link fn ->
      IO.puts "here?"
      IO.stream(:stdin, :line) |> Enum.each(&IO.inspect/1)
      IO.inspect "what"
    end
  end
end
