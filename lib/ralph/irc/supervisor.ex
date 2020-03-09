defmodule Ralph.IRC.Supervisor do
  @moduledoc false

  def start_link(config) do
    registry = Module.concat([config.mod, Registry])
    reply_manager = Module.concat([config.mod, ReplyManager])

    children = [
      {Ralph.IRC.NetworkRegistry, registry},
      {Ralph.IRC.ReplyManager, reply_manager}
    ]

    connections =
      Enum.map(config.networks, fn network ->
        spec = {Ralph.IRC.Connection, [config.mod, registry, network]}
        Supervisor.child_spec(spec, id: network.name)
      end)

    Supervisor.start_link(children ++ connections, strategy: :one_for_one)
  end
end
