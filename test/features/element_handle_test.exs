defmodule Test.Features.ElementHandleTest do
  use ExUnit.Case
  use PlaywrightTest.Case, transport: :driver

  alias Playwright.ChannelOwner.ElementHandle

  def visit_button_fixture(%{browser: browser, server: server}) do
    page =
      browser
      |> Browser.new_page()
      |> Page.goto(server.prefix <> "/input/button.html")

    [page: page]
  end

  def visit_dom_fixture(%{browser: browser, server: server}) do
    page =
      browser
      |> Browser.new_page()
      |> Page.goto(server.prefix <> "/dom.html")

    [page: page]
  end

  describe "click" do
    setup :visit_button_fixture

    test "click/1", %{page: page} do
      element = page |> Page.query_selector("button")
      assert element |> ElementHandle.click()

      result = Page.evaluate(page, "function () { return window['result']; }")
      assert result == "Clicked"

      Page.close(page)
    end
  end

  describe "get_attribute" do
    setup :visit_dom_fixture

    test "get_attribute/2", %{page: page} do
      element = page |> Page.query_selector("#outer")
      assert element |> ElementHandle.get_attribute("name") == "value"
      assert element |> ElementHandle.get_attribute("foo") == nil
    end

    test "Page delegates to this get_attribute", %{page: page} do
      assert Page.get_attribute(page, "#outer", "name") == "value"
      assert Page.get_attribute(page, "#outer", "foo") == nil
    end
  end

  describe "text_content" do
    setup :visit_dom_fixture

    test "text_content/1", %{page: page} do
      assert page
             |> Page.query_selector("css=#inner")
             |> ElementHandle.text_content() == "Text,\nmore text"

      Page.close(page)
    end
  end
end