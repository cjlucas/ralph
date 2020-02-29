defmodule Ralph.Bot do
  use Ralph.IRC

  network :freenode do
    server("irc.freenode.net")
    nick("hithere")

    on_kick(fn ctx ->
      IO.puts("whoaaaa #{inspect(ctx)}")
    end)

    on_message(fn ctx ->
      IO.puts("getting messages too?! whoa. #{inspect(ctx)}")
    end)
  end

  # TODO: this should not raise a warning
  network :freenode2 do
    server("irc.freenode.net")
    nick("hithere2")

    channel "\#omghithere" do
      on_message(fn ctx ->
        IO.inspect("tight2. #{inspect(ctx)}")
        privmsg(ctx, ctx.channel, "sup bruh")
      end)
    end

    channel "\#omghithere2" do
      on_message(fn ctx ->
        IO.inspect("omgdfjsaio. #{inspect(ctx)}")
        privmsg(ctx, "sup brug")
      end)
    end

    on_message(fn ctx ->
      IO.inspect("omgdfjsaio. #{inspect(ctx)}")
      privmsg(ctx, "i'm listening to both channels bruhggg!")
    end)
  end

  # on_kick(channel, tgt, reason, fn ->
  #   IO.puts("I been kicked")
  # end)

  # server "foo" # TODO: This should explode
end
