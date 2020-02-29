defmodule Ralph.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Ralph.Bot
    ]

    opts = [strategy: :one_for_one, name: Ralph.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
