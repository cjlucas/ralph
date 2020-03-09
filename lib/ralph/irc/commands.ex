defmodule Ralph.IRC.Commands do
  @moduledoc false

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

  defmacro send_message_cast(ctx, intermediate_codes, end_codes, data) do
    quote do
      %{mod: mod, network: network} = unquote(ctx)
      registry = Module.concat([mod, Registry])

      Ralph.IRC.NetworkRegistry.lookup(registry, network, fn pid ->
        Ralph.IRC.Connection.cast_write(
          pid,
          unquote(intermediate_codes),
          unquote(end_codes),
          unquote(data)
        )
      end)
    end
  end

  defmacro privmsg(ctx, target, message) do
    quote do
      data = Ralph.IRC.Protocol.privmsg(unquote(target), unquote(message))
      send_message unquote(ctx), data
    end
  end

  def privmsg(ctx, message), do: privmsg(ctx, ctx.channel, message)

  defmacro join(ctx, channel) do
    quote do
      data = Ralph.IRC.Protocol.join(unquote(channel))
      reply_manager = Module.concat([unquote(ctx).mod, ReplyManager])

      IO.puts("REGISTERED!")

      case send_message_cast(unquote(ctx), [], ["473", "474", "JOIN"], data) do
        [{_, "JOIN", [^unquote(channel)]}] -> :ok
        [{_, "473", _}] -> {:error, :invite_only}
        [{_, "474", _}] -> {:error, :banned}
      end
    end
  end

  defmacro names(ctx, channel) do
    quote do
      data = "NAMES #{unquote(channel)}"

      send_message_cast(unquote(ctx), ["353"], ["366"], data)
      |> Enum.drop(1)
      |> Enum.reverse()
      |> Enum.flat_map(fn {_, _, params} -> List.last(params) |> String.split(" ") end)
    end
  end
end
