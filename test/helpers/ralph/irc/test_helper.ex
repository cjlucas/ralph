defmodule Ralph.IRC.TestHelper do
  defmacro __using__(_opts) do
    quote do
      import Ralph.IRC.TestHelper
    end
  end

  defmacro bot(do: block) do
    quote do
      defmodule @scenario_name do
        use Ralph.IRC

        unquote(block)
      end
    end
  end

  defmacro bot_with_test_network(do: block) do
    quote do
      bot do
        network :test do
          server "localhost"
          nick "test_nick"

          unquote(block)
        end
      end
    end
  end

  defmacro scenario(scenario, do: block) do
    quote do
      @scenario_name String.to_atom(unquote(scenario))

      describe unquote(scenario) do
        unquote(block)
      end
    end
  end

  defmacro setup_server! do
    quote do
      setup do
        {:ok, _} = Ralph.IRC.MockServer.start_link()
        {:ok, _} = @scenario_name.start_link([])

        {:ok, pid} =
          receive do
            {:client_connected, conn} ->
              {:ok, pid} = Ralph.IRC.MockClient.start_link(conn)
              :ok = :gen_tcp.controlling_process(conn, pid)

              {:ok, pid}
          after
            5000 ->
              raise "failed to connect"
          end

        [mock_client: pid]
      end
    end
  end

  defmacro run_scenario(opts \\ [], do: block) do
    opts =
      opts
      |> Keyword.put_new(:ignore_prelude, true)
      |> Keyword.put_new(:exhaustive, true)

    quote do
      test "run scenario", %{mock_client: var!(mock_client)} do
        if unquote(opts[:ignore_prelude]) do
          assert_line "NICK", [_]
          assert_line "USER", [_, _, _, _]
          assert_line "JOIN", [_]
        end

        unquote(block)

        if unquote(opts[:exhaustive]) do
          assert {:messages, []} == :erlang.process_info(self(), :messages)
        end
      end
    end
  end

  defmacro write_line(line) do
    quote do
      :ok = Ralph.IRC.MockClient.write(var!(mock_client), unquote(line))
    end
  end

  defmacro assert_line(command, params) do
    quote do
      assert_receive {:line, {_, unquote(command), unquote(params)}}, 100
    end
  end
end
