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

  def parse_line(line) do
    [prefix, line] =
      if String.starts_with?(line, ":") do
        line = line |> String.split_at(1) |> elem(1)
        String.split(line, " ", parts: 2)
      else
        [nil, line]
      end

    [command, params] = String.split(line, " ", parts: 2)

    params = String.split(params)

    params =
      case Enum.find_index(params, fn param -> String.starts_with?(param, ":") end) do
        nil ->
          params

        idx ->
          {word_params, trailing_param} = Enum.split(params, idx)
          trailing_param = trailing_param |> Enum.join(" ") |> String.split_at(1) |> elem(1)
          word_params ++ [trailing_param]
      end

    {prefix, command, params}
  end
end
