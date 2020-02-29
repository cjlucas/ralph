defmodule Ralph.Bot do
  use Ralph.IRC

  network :freenode do
    server "irc.freenode.net" 
    nick "hithere"

    on_kick fn ctx ->
      IO.puts("whoaaaa #{inspect(ctx)}")
    end

    on_message fn ctx ->
      IO.puts("getting messages too?! whoa. #{inspect(ctx)}")
    end
  end

  network :freenode2 do
    server "irc.freenode.net"
    nick "hithere2"

    channel "#omghithere" do
      on_message fn ctx ->
        privmsg ctx, ctx.channel, "sup bruh"
      end
    end

    channel "#omghithere2" do
      on_message fn ctx ->
        privmsg ctx, "sup brug"
      end
    end

    on_message fn ctx ->
      privmsg ctx, "i'm listening to both channels bruhggg!"
    end

    on_join fn %{channel: channel} = ctx ->
      privmsg ctx, "greetings! welcome to #{channel}"
    end
  end
end
