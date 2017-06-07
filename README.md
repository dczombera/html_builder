# HtmlBuilder
A small HTML library that uses its own Domain Specific Language (DSL) for easily creating HTML tags. It is also extensible thanks to Elixirs ability to generate functions from external data (in this case the `tags.txt`)
Besides HTML tag generation, the library also supports HTML attributes.

## How does the library work?
It reads all available tags from the `tags.txt` file and  walks the
Abstract Syntax Tree (AST) during compile-time, converting AST nodes like
```elixir
{:div, [], [[do: {:p, [], [[do: {:text, [], ["Han shot first!"]}]]}]]}
```
into macro calls such as
```elixir
tag(:div, []) do
  tag(:p, []) do
    put_buffer(var!(buffer, Html), to_string("Han shot first!"))  
  end
end
```

## Installlation
This library is not available in [Hex](https://hex.pm/docs/publish) since I'm not planning to maintain it.
However, if you want to use it, you can instead add this repository as your dependecy to your Elixir project:

```elixir
def deps do
  [{:html_builder, git: "git://github.com/dczombera/html_builder.git"}]
end
```

## Usage
The `HtmlBuilder` has to be imported into your module to take advantage of the DSL.
Then, simply start a new block with `markup do` and use the the names of the HTML tags you need.
In order to use HTML attributes, you just have to pass a key value pair representing the attribute to the HTML tag macro.

For example, the `HtmlTemplate` module importing the `HtmlBuilder` would generate following HTML string in `iex`:
```elixir
  defmodule HtmlTemplate do
    import HtmlBuilder

    def render do
      markup do
        div class: "front" do
          h1 id: "header" do
            p class: "paragraph", id: "bad_ass" do
              text "Say my name!"
            end
          end
        end
        div class: "answer" do
          text "Heisenberg."
        end
      end
    end
  end
```

```elixir
iex> HtmlTemplate.render
"<div class=\"front\">\n<h1 id=\"header\">\n<p class=\"paragraph\" id=\"bad_ass\">\nSay my name!\n</p>\n  </h1>\n</div><div class=\"back\">\nHeisenberg.\n</div>"
```

## License
MIT
