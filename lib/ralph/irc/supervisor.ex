defmodule Ralph.IRC.Supervisor do
  @moduledoc false

  def start_link(config) do
    registry = Module.concat([config.mod, Registry])

    children = [
      {Ralph.IRC.NetworkRegistry, registry}
    ]

    connections =
      Enum.map(config.networks, fn network ->
        spec = {Ralph.IRC.Connection, [config.mod, registry, network]}
        Supervisor.child_spec(spec, id: network.name)
      end)

    Supervisor.start_link(children ++ connections, strategy: :one_for_one)
  end
end
