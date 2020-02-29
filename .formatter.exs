# Used by "mix format"

locals_without_parens = [
  # Command Handlers
  on_privmsg: 1,
  on_kick: 1,
  on_join: 1,
  on_invite: 1,
  on_part: 1,

  # Commands
  send_message: 2,
  privmsg: :*,
  join: 2,

  # Network
  network: 1,
  server: 1,
  servers: 1,
  nick: 1,

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
