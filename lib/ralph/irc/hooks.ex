defmodule Ralph.IRC.Hooks do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      import Ralph.IRC.Hooks
    end
  end

  defmacro on_command(command, handler, param_names) do
    handler_name = :"_on_command_hook__line_#{__CALLER__.line}"

    quote do
      def unquote(handler_name)(context, {prefix, cmd, params}) do
        if cmd == unquote(command) do
          params =
            if is_function(unquote(param_names)) do
              unquote(param_names).(params)
            else
              Enum.zip(unquote(param_names), params) |> Enum.into(%{})
            end

          context = Map.merge(context, params)

          unquote(handler).(context)
        end
      end

      add_hook(unquote(handler_name))
    end
  end

  defmacro on_join(handler) do
    quote do
      on_command("JOIN", unquote(handler), [:channel])
    end
  end

  defmacro on_part(handler) do
    quote do
      on_command("PART", unquote(handler), [:channel])
    end
  end

  defmacro on_kick(handler) do
    quote do
      on_command("KICK", unquote(handler), [:channel, :target, :reason])
    end
  end

  defmacro on_invite(handler) do
    quote do
      on_command("INVITE", unquote(handler), [:target, :channel])
    end
  end

  defmacro on_privmsg(handler) do
    quote do
      on_command("PRIVMSG", unquote(handler), fn [target, message] ->
        %{channel: target, target: target, message: message}
      end)
    end
  end
end
