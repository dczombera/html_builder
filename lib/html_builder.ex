defmodule HtmlBuilder do
  @moduledoc """
  The module holds the logic for building the HTML tree.
  Instead of creating and injecting functions for each tag
  into the caller's module, it post walks the AST and changes
  nodes that represent a HTML tag. The nodes will be changed to 
  call the `tag` macro with the appropriate 
  tag name, optional attributes and body. 
  """

  @external_resource tags_path = Path.join([__DIR__, "resources", "tags.txt"])
  @external_resource entities_path = Path.join([__DIR__, "resources", "entities.txt"])
  @tags (for line <- File.stream!(tags_path, [], :line) do
    line |> String.trim |> String.to_atom        
  end)
  @html_entities (for line <- File.stream!(entities_path, [], :line), into: %{} do
    [decoded, encoded] = line |> String.split(",") |> Enum.map(&String.trim(&1))    
    {decoded, encoded }
  end)

  defmacro markup(do: block) do
    quote do
      # Avoid clash with div macro for <div> tag
      import Kernel, except: [div: 2]
      {:ok, var!(buffer, Html)} = start_buffer([]) 
      {:ok, var!(whitespaces, Html)} = start_buffer([])
      unquote(Macro.postwalk(block, &postwalk/1))
      result = render(var!(buffer, Html))
      [:ok, :ok] = stop_buffers([var!(buffer, Html), var!(whitespaces, Html)])
      result
    end
  end

  def postwalk({:text, _meta, [string]}) do
    sanitized = string |> to_string |> sanitize
    quote do: put_buffer(var!(buffer, Html), " #{concate(var!(whitespaces, Html))}#{unquote(sanitized)}") 
  end

  def postwalk({tag_name, _meta, [[do: inner]]}) when tag_name in @tags do
    quote do: tag(unquote(tag_name), [], do: unquote(inner)) 
  end

  def postwalk({tag_name, _meta, [attrs, [do: inner]]}) when tag_name in @tags do
    quote do: tag(unquote(tag_name), unquote(attrs), do: unquote(inner)) 
  end

  def postwalk(ast), do: ast

  defmacro tag(name, attrs, do: inner) do
    quote do
      put_buffer(var!(buffer, Html), open_tag(unquote(name), concate(var!(whitespaces, Html)), unquote(attrs)))
      put_buffer(var!(whitespaces, Html), "  ")
      unquote(inner)
      pop_buffer(var!(whitespaces, Html))
      put_buffer(var!(buffer, Html), end_tag(unquote(name), concate(var!(whitespaces, Html))))
    end
  end

  def open_tag(name, whitespaces, []), do: "#{whitespaces}<#{name}>\n" 
  def open_tag(name, whitespaces, attrs) do
    attr_html = for {key, val} <- attrs, into: "", do: " #{key}=\"#{val}\"" 
    "#{whitespaces}<#{name}#{attr_html}>\n"
  end

  def end_tag(name, whitespaces), do: "\n#{whitespaces}</#{name}>"
  # Need to find a better way to dynamically create the regex using keys of @html_entities 
  def sanitize(string),          do: Regex.replace(~r/(<|>|&|"|'|¢|£|¥|€|©|®)/, string, fn e -> "#{encode_html_entity(e)}" end)
  def start_buffer(state),       do: Agent.start_link(fn -> state end)
  def put_buffer(buff, content), do: Agent.update(buff, &[content | &1])
  def pop_buffer(buff),          do: Agent.update(buff, &List.delete_at(&1, 0))
  def stop_buffers(buffs),       do: buffs |> Enum.map(&Agent.stop/1)
  def concate(buff),             do: render(buff)             
  def render(buff),              do: Agent.get(buff, &(&1)) |> Enum.reverse |> Enum.join("")
  def encode_html_entity(entity), do: @html_entities[to_string(entity)]
end
