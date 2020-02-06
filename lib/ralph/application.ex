defmodule Ralph.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Ralph.Console
      {Ralph.IRC.Connection, [Ralph.IRC]}
    ]

    # IO.stream(:stdin, :line)
    # |> Enum.each(&IO.inspect/1)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ralph.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
