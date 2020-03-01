defmodule Ralph.IRC.NetworkRegistry do
  @moduledoc false

  def child_spec(name) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [name]}}
  end

  def start_link(name) do
    Registry.start_link(keys: :unique, name: name)
  end

  def register(registry, network) do
    Registry.register(registry, network, [])
  end

  def lookup(registry, network, block) do
    [{pid, _}] = Registry.lookup(registry, network)
    block.(pid)
  end
end
