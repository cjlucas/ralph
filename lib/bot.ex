defmodule Ralph.Bot do
  use Ralph.IRC

  @moduledoc false

  # network :freenode do
  #   server "irc.freenode.net"
  #   nick "hithere"
  #
  #   on_kick fn ctx ->
  #     IO.puts("whoaaaa #{inspect(ctx)}")
  #   end
  #
  #   on_privmsg fn ctx ->
  #     IO.puts("getting messages too?! whoa. #{inspect(ctx)}")
  #   end
  # end

  network :freenode2 do
    server "irc.freenode.net"
    nick "hithere2"

    channel "#omghithere" do
      on_privmsg fn ctx ->
        privmsg ctx, ctx.channel, "sup bruh"
      end
    end

    channel "#omghithere2" do
      on_privmsg fn ctx ->
        privmsg ctx, "sup brug"
      end
    end

    on_privmsg fn ctx ->
      privmsg ctx, "i'm listening to both channels bruhggg!"
    end

    on_join fn %{channel: channel} = ctx ->
      privmsg ctx, "greetings! welcome to #{channel}"
      IO.inspect("sending names for #{channel}")
      IO.inspect(names(ctx, channel), label: "holy. shit. #{channel}")
    end

    on_part fn ctx ->
      privmsg ctx, "good riddance!"
    end

    on_invite fn %{channel: channel} = ctx ->
      x = join ctx, channel
      IO.inspect(x, label: "on_invite join")
    end
  end
end
