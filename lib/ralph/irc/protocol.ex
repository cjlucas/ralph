defmodule Ralph.IRC.Protocol do
  def join(channel) do
    "JOIN #{channel}"
  end

  def nick(name) do
    "NICK #{name}"
  end

  def privmsg(target, message) do
    "PRIVMSG #{target} :#{message}"
  end

  def user(user_name, host_name, server_name, real_name) do
    "USER #{user_name} #{host_name} #{server_name} :#{real_name}"
  end
end
