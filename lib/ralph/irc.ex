defmodule Ralph.IRC do
  def on_line(pid, line) do # on_command?
    IO.puts "GOT A LINE! #{line}"
    data = Ralph.IRC.Protocol.nick("omfdsai")
    Ralph.IRC.Connection.write(pid, data)
    data = Ralph.IRC.Protocol.user("chris", "chris", "vps275269.vps.ovh.ca", "Chris Lucas")
    Ralph.IRC.Connection.write(pid, data)
  end
end
