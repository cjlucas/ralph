defmodule Ralph.IRC.Client do
  defmacro __using__(_opts) do
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
end
