defmodule Ralph.IRC do
  ## Configuration

  defmodule RootConfig do
    defstruct mod: nil, networks: [], hooks: []
  end

  defmodule NetworkConfig do
    defstruct name: nil, servers: [], channels: [], nick: nil, hooks: []
  end

  defmodule ChannelConfig do
    defstruct name: nil, hooks: []
  end

  defmacro __using__(_opts) do
    quote do
      use Ralph.IRC.Commands
      use Ralph.IRC.Hooks

      import Ralph.IRC

      require Logger

      Module.register_attribute(__MODULE__, :context, persist: true)
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
        Ralph.IRC.Supervisor.start_link(@context)
      end

      # on_command?
      def on_line({network, _}, {prefix, command, params} = message) do
        Logger.debug("Received message #{inspect message}")
        Enum.each(@context.hooks, fn hook ->
          hook_ctx = %{network: network, message: message}
          apply(__MODULE__, hook, [hook_ctx])
        end)
      end
    end
  end

  ## Network

  defmacro network(name, block) do
    handler_name = :"__on_network_hook_line_#{__CALLER__.line}"

    quote do
      %{networks: networks} = parent_ctx = Module.get_attribute(__MODULE__, :context)
      Module.put_attribute(__MODULE__, :context, %NetworkConfig{name: unquote(name)})

      unquote(block)
      network_ctx = Module.get_attribute(__MODULE__, :context)
      parent_ctx = %{parent_ctx | networks: [network_ctx | networks]}
      Module.put_attribute(__MODULE__, :context, parent_ctx)
      Module.put_attribute(__MODULE__, :network_config, network_ctx)

      def unquote(handler_name)(ctx) do
        %{name: network_name, hooks: hooks} = @network_config

        if ctx[:network] == network_name do
          Enum.each(hooks, fn hook ->
            apply(__MODULE__, hook, [%{mod: __MODULE__, network: network_name}, ctx[:message]])
          end)
        end
      end

      add_hook(unquote(handler_name))
    end
  end

  ## Channel

  defmacro channel(name, block) do
    handler_name = :"__on_channel_hook_line_#{__CALLER__.line}"

    quote do
      %{name: network_name, channels: channels} =
        parent_ctx = Module.get_attribute(__MODULE__, :context)

      Module.put_attribute(__MODULE__, :context, %ChannelConfig{name: unquote(name)})

      unquote(block)

      channel_ctx = Module.get_attribute(__MODULE__, :context)
      parent_ctx = %{parent_ctx | channels: [channel_ctx | channels]}
      Module.put_attribute(__MODULE__, :context, parent_ctx)
      Module.put_attribute(__MODULE__, :network_name, network_name)
      Module.put_attribute(__MODULE__, :channel_config, channel_ctx)

      def unquote(handler_name)(network, {_, cmd, [target | _]} = message) do
        %{name: channel_name, hooks: hooks} = @channel_config

        if cmd == "PRIVMSG" && target == channel_name do
          Enum.each(hooks, fn hook ->
            apply(__MODULE__, hook, [
              %{mod: __MODULE__, network: @network_name, channel: channel_name},
              message
            ])
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
