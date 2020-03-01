defmodule Ralph.Application do
  @moduledoc false

  use Application

  def start(_type, opts) do
    opts =
      opts
      |> Keyword.put_new(:bots, [])

    children = opts[:bots]

    opts = [strategy: :one_for_one, name: Ralph.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
