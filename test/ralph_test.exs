defmodule RalphTest do
  use ExUnit.Case
  use Ralph.IRC.TestHelper

  scenario "prelude" do
    bot do
      network :test do
        server "localhost"
        nick "test_nick"

        channel "#test" do
        end

        channel "#test2" do
        end
      end
    end

    run_scenario ignore_prelude: false do
      assert_line "NICK", ["test_nick"]
      assert_line "USER", ["chris", "chris", "chris", "chris"]
      assert_line "JOIN", ["#test"]
      assert_line "JOIN", ["#test2"]
    end
  end

  scenario "connect and join" do
    bot_with_test_network do
      channel "#test" do
        on_join fn ctx ->
          privmsg ctx, "i joined #test!"
        end
      end

      channel "#test2" do
        on_join fn ctx ->
          privmsg ctx, "i joined #test2!"
        end
      end

      on_join fn %{channel: channel} = ctx ->
        privmsg ctx, "i joined a channel: #{channel}"
      end
    end

    run_scenario do
      write_line ":foo JOIN #test"
      write_line ":foo JOIN #test2"

      assert_line "PRIVMSG", ["#test", "i joined #test!"]
      assert_line "PRIVMSG", ["#test", "i joined a channel: #test"]

      assert_line "PRIVMSG", ["#test2", "i joined #test2!"]
      assert_line "PRIVMSG", ["#test2", "i joined a channel: #test2"]
    end
  end

  scenario "kick and rejoin" do
    bot_with_test_network do
      channel "#test" do
        on_kick fn %{channel: channel, reason: reason} = ctx ->
          join ctx, channel
          privmsg ctx, "you kicked me for reason: \"#{reason}\""
        end
      end

      on_kick fn ctx ->
        privmsg ctx, "general on_kick handler called"
      end
    end

    run_scenario do
      write_line ":foo JOIN #test"
      write_line ":foo KICK #test test_nick :and stay out!"

      assert_line "JOIN", ["#test"]
      assert_line "PRIVMSG", ["#test", "you kicked me for reason: \"and stay out!\""]
      assert_line "PRIVMSG", ["#test", "general on_kick handler called"]
    end
  end

  scenario "autojoin on invite" do
    bot_with_test_network do
      on_invite fn %{channel: channel} = ctx ->
        join ctx, channel
      end
    end

    run_scenario do
      write_line ":foo INVITE test_user #foobar"
      assert_line "JOIN", ["#foobar"]
    end
  end
end
