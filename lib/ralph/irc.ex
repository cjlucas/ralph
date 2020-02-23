defmodule Ralph.IRC do
  ## Configuration

  defmodule RootConfig do
    defstruct mod: nil, networks: [], hooks: []
  end

  defmodule NetworkConfig do
    defstruct name: nil, servers: [], nick: nil, hooks: []
  end

  defmacro __using__(_opts) do
    quote do
      import Ralph.IRC

      Module.register_attribute(__MODULE__, :context, persist: true)
      Module.register_attribute(__MODULE__, :hook_idx, persist: true, accumulate: true)

      Module.put_attribute(__MODULE__, :context, %RootConfig{mod: __MODULE__})

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def child_spec(opts) do
        %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}
      end

      def start_link(_opts) do
        IO.puts("hithere")
        IO.inspect(@context)

        Ralph.IRC.Supervisor.start_link(@context)
      end

      # on_command?
      def on_line({network, pid}, {prefix, command, params}) do
        case command do
          "KICK" ->
            [chan, tgt, reason] = params
            Ralph.IRC.Connection.write(pid, "JOIN #{chan}\r\n")

          _ ->
            nil
        end

        Enum.each(@context.hooks, fn hook ->
          apply(__MODULE__, hook, [network, {prefix, command, params}])
        end)
      end
    end
  end

  ## Message Hooks

  defmacro on_command(command, handler, param_names) do
    handler_name = :"fuck i dunno #{command}"

    quote do
      IO.inspect(@context, label: "what fuckin context")

      def unquote(handler_name)(context, {prefix, cmd, params}) do
        if cmd == unquote(command) do
          params = Enum.zip(unquote(param_names), params) |> Enum.into(%{})
          context = Map.merge(context, params)

          unquote(handler).(context)
        end
      end

      add_hook(unquote(handler_name))
    end
  end

  defmacro on_kick(handler) do
    quote do
      on_command("KICK", unquote(handler), [:channel, :target, :reason])
    end
  end

  defmacro on_message(handler) do
    quote do
      on_command("PRIVMSG", unquote(handler), [:target, :message])
    end
  end

  ## Network

  defmacro network(name, block) do
    handler_name = :"__#{name}_on_line_handler"

    quote do
      %{networks: networks} = parent_ctx = Module.get_attribute(__MODULE__, :context)
      Module.put_attribute(__MODULE__, :context, %NetworkConfig{name: unquote(name)})

      unquote(block)

      network_ctx = Module.get_attribute(__MODULE__, :context)
      parent_ctx = %{parent_ctx | networks: [network_ctx | networks]}
      Module.put_attribute(__MODULE__, :context, parent_ctx)
      Module.put_attribute(__MODULE__, :network_config, network_ctx)

      def unquote(handler_name)(network, message) do
        if network == unquote(name) do
          IO.puts("whoa a thing happened on my network! #{network}")
          # TODO: go through network hooks

          Enum.each(@network_config.hooks, fn hook ->
            apply(__MODULE__, hook, [%{network: unquote(name)}, message])
          end)
        end
      end

      add_hook(unquote(handler_name))
    end
  end

  defmacro update_context(attrs) do
    quote do
      attrs = unquote(attrs) |> Enum.into(%{})

      context =
        Module.get_attribute(__MODULE__, :context)
        |> Map.merge(attrs)

      Module.put_attribute(__MODULE__, :context, context)
    end
  end

  defmacro add_hook(hook) do
    quote do
      context =
        __MODULE__
        |> Module.get_attribute(:context)
        |> Map.update!(:hooks, fn hooks -> [unquote(hook) | hooks] end)

      Module.put_attribute(__MODULE__, :context, context)
    end
  end

  ## Network Settings

  defmacro server(host) do
    quote do
      servers([unquote(host)])
    end
  end

  defmacro servers(hosts) do
    quote do
      update_context(servers: unquote(hosts))
    end
  end

  defmacro nick(nick) do
    quote do
      update_context(nick: unquote(nick))
    end
  end
end
