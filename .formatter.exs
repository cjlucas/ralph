# Used by "mix format"

locals_without_parens = [
  # Command Handlers
  on_message: 1,
  on_kick: 1,
  on_join: 1,

  # Commands
  privmsg: :*,

  # Network
  network: 1,
  server: 1,
  servers: 1,
  nick: 1

  # Channel
  channel: 1
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
