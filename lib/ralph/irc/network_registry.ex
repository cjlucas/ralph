defmodule Ralph.IRC.NetworkRegistry do
  def child_spec(name) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [name]}}
  end

  def start_link(name) do
    Registry.start_link(keys: :unique, name: name)
  end
end
