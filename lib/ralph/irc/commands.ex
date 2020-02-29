defmodule Ralph.IRC.Commands do
  defmacro __using__(_opts) do
    quote do
      import Ralph.IRC.Commands
    end
  end

  # TODO: This should stay public. We should also pick a name that's consistent with the IRC nomenclature.
  defmacro send_message(ctx, data) do
    quote do
      %{mod: mod, network: network} = unquote(ctx)
      registry = Module.concat([mod, Registry])

      Ralph.IRC.NetworkRegistry.lookup(registry, network, fn pid ->
        Ralph.IRC.Connection.write(pid, unquote(data))
      end)
    end
  end

  defmacro privmsg(ctx, target, message) do
    quote do
      data = Ralph.IRC.Protocol.privmsg(unquote(target), unquote(message))
      send_message(unquote(ctx), data)
    end
  end
  def privmsg(ctx, message), do: privmsg(ctx, ctx.channel, message)

  defmacro join(ctx, channel) do
    quote do
      data = Ralph.IRC.Protocol.join(unquote(channel))
      send_message(unquote(ctx), data)
    end
  end
end
