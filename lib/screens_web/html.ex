defmodule ScreensWeb.HTML do
  @moduledoc """
  Backported `sigil_E/2` and `sigil_e/2` which have since been deprecated
  upstream in favor of `sigil_H` and `sigil_h/2`.

  Source:
    https://github.com/phoenixframework/phoenix_html/blob/2a528e548ff27c8f6a60a54d2fb504da9ef922f7/lib/phoenix_html.ex#L93-L113
  """

  @doc """
  Provides `~e` sigil with HTML safe EEx syntax inside source files.

  Raises on attempts to interpolate with `\#{}`, so `~E` should be preferred.

      iex> ~e"\""
      ...> Hello <%= "world" %>
      ...> "\""
      {:safe, ["Hello ", "world", "\\n"]}

  """
  defmacro sigil_e(expr, opts) do
    handle_sigil(expr, opts, __CALLER__)
  end

  @doc """
  Provides `~E` sigil with HTML safe EEx syntax inside source files.

  Does not raise on attempts to interpolate with `\#{}`, but rather shows those
  characters literally, so it should be preferred over `~e`.

      iex> ~E"\""
      ...> Hello <%= "world" %>
      ...> "\""
      {:safe, ["Hello ", "world", "\\n"]}

  """
  defmacro sigil_E(expr, opts) do
    handle_sigil(expr, opts, __CALLER__)
  end

  defp handle_sigil({:<<>>, meta, [expr]}, [], caller) do
    options = [
      engine: Phoenix.HTML.Engine,
      file: caller.file,
      line: caller.line + 1,
      indentation: meta[:indentation] || 0
    ]

    EEx.compile_string(expr, options)
  end

  defp handle_sigil(_, _, _) do
    raise ArgumentError,
          "interpolation not allowed in ~e sigil. " <>
            "Remove the interpolation, use <%= %> to insert values, " <>
            "or use ~E to show the interpolation literally"
  end
end
