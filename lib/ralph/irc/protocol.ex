defmodule Ralph.IRC.Protocol do
  def cap(pid) do
    "CAP LS\r\n"
  end

  def join(channel) do
    "JOIN #{channel}\r\n\r\n"
  end

  def nick(name) do
    "NICK #{name}\r\n\r\n"
  end

  def privmsg(target, message) do
    "PRIVMSG #{target} :#{message}\r\n\r\n"
  end

  def user(user_name, host_name, server_name, real_name) do
    "USER #{user_name} #{host_name} #{server_name} :#{real_name}\r\n\r\n"
  end

  defp write(data, pid) do
    Ralph.IRC.Connection.write(pid, data)
  end
end
