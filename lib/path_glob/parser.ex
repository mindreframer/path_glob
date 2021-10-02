defmodule PathGlob.Parser do
  import NimbleParsec

  defp question() do
    string("?")
    |> tag(:question)
  end

  defp double_star_slash() do
    string("**/")
    |> repeat(string("/"))
    |> tag(:double_star_slash)
  end

  defp double_star() do
    string("**")
    |> repeat(string("/"))
    |> tag(:double_star)
  end

  defp star() do
    string("*")
    |> tag(:star)
  end

  defp alternatives_item(combinator \\ empty()) do
    choice(combinator, [
      times(non_alteratives([?}, ?,]), min: 1),
      empty()
    ])
  end

  defp alternatives() do
    ignore(string("{"))
    |> repeat(alternatives_item() |> ignore(string(",")))
    |> alternatives_item()
    |> ignore(string("}"))
    |> tag(:alternatives)
  end

  defp character_item(combinator \\ empty(), exclude) do
    combinator
    |> tag(utf8_string(map_exclude(exclude), 1), :literal)
  end

  defp character_list(exclude) do
    times(character_item(exclude), min: 1)
    |> tag(:character_list)
  end

  defp character_range(exclude) do
    exclude = [?- | exclude]

    character_item(exclude)
    |> ignore(string("-"))
    |> character_item(exclude)
    |> tag(:character_range)
  end

  defp character(combinator \\ empty(), exclude) do
    combinator
    |> times(
      choice([
        character_range(exclude),
        character_list(exclude)
      ]),
      min: 1
    )
    |> tag(:character)
  end

  defp characters() do
    ignore(string("["))
    |> repeat(character([?,, ?]]) |> ignore(string(",")))
    |> character([?]])
    |> ignore(string("]"))
  end

  @special_chars [??, ?*, ?{, ?}, ?[, ?], ?,]

  defp map_exclude(chars) do
    Enum.map(chars, &{:not, &1})
  end

  defp literal() do
    @special_chars
    |> map_exclude()
    |> utf8_string(min: 1)
    |> tag(:literal)
  end

  defp special_literal(exclude) do
    (@special_chars -- exclude)
    |> utf8_string(1)
    |> tag(:literal)
  end

  defp non_alteratives() do
    non_alteratives([])
  end

  defp non_alteratives(exclude) do
    non_alteratives(empty(), exclude)
  end

  defp non_alteratives(combinator, exclude) do
    choice(combinator, [
      question(),
      double_star_slash(),
      double_star(),
      star(),
      characters(),
      literal(),
      special_literal([?{ | exclude])
    ])
  end

  defp term() do
    choice([
      alternatives(),
      non_alteratives()
    ])
  end

  def glob do
    repeat(term())
    |> eos()
    |> tag(:glob)
  end
end
