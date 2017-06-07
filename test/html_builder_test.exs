defmodule HtmlBuilderTest do
  use ExUnit.Case
  doctest HtmlBuilder

  defmodule HtmlTemplate do
    import HtmlBuilder

    def render_without_attr do
      markup do
        div do
          h1 do
            text "Winter"
          end
        end
        div do
          p do
            text "is coming!"
          end
        end
      end
    end

    def render_with_attr do
      markup do
        div class: "front" do
          h1 id: "header" do
            p class: "paragraph", id: "first_paragraph" do
              text "Say my name!"
            end
          end
        end
        div class: "back" do
          text "Heisenberg."
        end
      end
    end

    def render_with_sanitization do
      markup do
        div class: "front", id: "clean" do
          h1 class: "header" do
            text "It's a trap!"
          end
        end
        div class: "back", id: "dirty" do
          div do
            p do: text "XSS Protection <script>alert('vulnerable?');</script>"
          end
        end
      end
    end
  end

  describe "Integration tests" do
    test "it renders nested HTML elements" do
      assert HtmlTemplate.render_without_attr == "<div>\n  <h1>\n     Winter\n  </h1>\n</div><div>\n  <p>\n     is coming!\n  </p>\n</div>"
    end

    test "it supports HTML attributes" do
      assert HtmlTemplate.render_with_attr == "<div class=\"front\">\n  <h1 id=\"header\">\n    <p class=\"paragraph\" id=\"first_paragraph\">\n       Say my name!\n    </p>\n  </h1>\n</div><div class=\"back\">\n   Heisenberg.\n</div>"
    end

    test "it sanitizes HTML text" do
      assert HtmlTemplate.render_with_sanitization == "<div class=\"front\" id=\"clean\">\n  <h1 class=\"header\">\n     It&apos;s a trap!\n  </h1>\n</div><div class=\"back\" id=\"dirty\">\n  <div>\n    <p>\n       XSS Protection &lt;script&gt;alert(&apos;vulnerable?&apos;);&lt;/script&gt;\n    </p>\n  </div>\n</div>"
    end
  end
end
