defmodule Playwright.LocatorTest do
  use Playwright.TestCase, async: true

  alias Playwright.{ElementHandle, Locator, Page}
  alias Playwright.Runner.Channel.Error

  describe "Locator.all_inner_texts/1" do
    test "...", %{page: page} do
      Page.set_content(page, "<div>A</div><div>B</div><div>C</div>")

      texts =
        Page.locator(page, "div")
        |> Locator.all_inner_texts()

      assert {:ok, ["A", "B", "C"]} = texts
    end
  end

  describe "Locator.all_text_contents/1" do
    test "...", %{page: page} do
      Page.set_content(page, "<div>A</div><div>B</div><div>C</div>")

      texts =
        Page.locator(page, "div")
        |> Locator.all_text_contents()

      assert {:ok, ["A", "B", "C"]} = texts
    end
  end

  describe "Locator.check/2" do
    setup(%{assets: assets, page: page}) do
      options = %{timeout: 1_000}

      page |> Page.goto(assets.prefix <> "/empty.html")
      page |> Page.set_content("<input id='exists' type='checkbox'/>")

      [options: options]
    end

    test "returns :ok on a successful 'check'", %{options: options, page: page} do
      frame = Page.main_frame(page)

      locator = Locator.new(frame, "input#exists")
      assert :ok = Locator.check(locator, options)
    end

    test "returns a timeout error when unable to 'check'", %{options: options, page: page} do
      frame = Page.main_frame(page)

      locator = Locator.new(frame, "input#bogus")
      assert {:error, %Error{message: "Timeout 1000ms exceeded."}} = Locator.check(locator, options)
    end
  end

  describe "Locator.click/2" do
    setup(%{assets: assets, page: page}) do
      options = %{timeout: 1_000}

      page |> Page.goto(assets.prefix <> "/empty.html")
      page |> Page.set_content("<a id='exists' target=_blank rel=noopener href='/one-style.html'>yo</a>")

      [options: options]
    end

    test "returns :ok on a successful click", %{options: options, page: page} do
      frame = Page.main_frame(page)

      locator = Locator.new(frame, "a#exists")
      assert :ok = Locator.click(locator, options)
    end

    test "returns a timeout error when unable to click", %{options: options, page: page} do
      frame = Page.main_frame(page)

      locator = Locator.new(frame, "a#bogus")
      assert {:error, %Error{message: "Timeout 1000ms exceeded."}} = Locator.click(locator, options)
    end
  end

  describe "Locator.wait_for/2" do
    setup(%{assets: assets, page: page}) do
      options = %{timeout: 1_000}

      page |> Page.goto(assets.prefix <> "/empty.html")

      [options: options]
    end

    test "waiting for 'attached'", %{options: options, page: page} do
      frame = Page.main_frame(page)

      locator = Locator.new(frame, "a#exists")

      task =
        Task.async(fn ->
          assert :ok = Locator.wait_for(locator, Map.put(options, :state, "attached"))
        end)

      page |> Page.set_content("<a id='exists' target=_blank rel=noopener href='/one-style.html'>yo</a>")

      Task.await(task)
    end
  end

  describe "Locator.evaluate/4" do
    test "called with expression", %{page: page} do
      element = Locator.new(page, "input")
      Page.set_content(page, "<input type='checkbox' checked><div>Not a checkbox</div>")

      {:ok, checked} = Locator.is_checked(element)
      assert checked

      Locator.evaluate(element, "function (input) { return input.checked = false; }")

      {:ok, checked} = Locator.is_checked(element)
      refute checked
    end

    test "called with expression and an `ElementHandle` arg", %{page: page} do
      selector = "input"
      locator = Locator.new(page, selector)

      Page.set_content(page, "<input type='checkbox' checked><div>Not a checkbox</div>")

      {:ok, handle} = Page.wait_for_selector(page, selector)

      {:ok, checked} = Locator.is_checked(locator)
      assert checked

      Locator.evaluate(locator, "function (input) { return input.checked = false; }", handle)

      {:ok, checked} = Locator.is_checked(locator)
      refute checked
    end
  end

  describe "Locator.get_attribute/3" do
    test "...", %{assets: assets, page: page} do
      locator = Page.locator(page, "#outer")

      Page.goto(page, assets.dom)

      assert {:ok, "value"} = Locator.get_attribute(locator, "name")
      assert {:ok, nil} = Locator.get_attribute(locator, "bogus")
    end
  end

  describe "Locator.inner_html/2" do
    test "...", %{assets: assets, page: page} do
      content = ~s|<div id="inner">Text,\nmore text</div>|
      locator = Page.locator(page, "#outer")

      Page.goto(page, assets.dom)
      assert {:ok, ^content} = Locator.inner_html(locator)
    end
  end

  describe "Locator.inner_text/2" do
    test "...", %{assets: assets, page: page} do
      content = "Text, more text"
      locator = Page.locator(page, "#inner")

      Page.goto(page, assets.dom)
      assert {:ok, ^content} = Locator.inner_text(locator)
    end
  end

  describe "Locator.input_value/2" do
    test "...", %{assets: assets, page: page} do
      locator = Page.locator(page, "#input")

      Page.goto(page, assets.dom)
      Page.fill(page, "#input", "input value")

      assert {:ok, "input value"} = Locator.input_value(locator)
    end
  end

  describe "Locator.is_checked/1" do
    test "...", %{page: page} do
      locator = Page.locator(page, "input")

      Page.set_content(page, """
        <input type='checkbox' checked>
        <div>Not a checkbox</div>
      """)

      assert {:ok, true} = Locator.is_checked(locator)

      Locator.evaluate(locator, "input => input.checked = false")
      assert {:ok, false} = Locator.is_checked(locator)
    end
  end

  describe "Locator.is_editable/1" do
    test "...", %{page: page} do
      Page.set_content(page, """
        <input id=input1 disabled>
        <textarea readonly></textarea>
        <input id=input2>
      """)

      # ??? (why not just the attribute, as above?)
      # Page.eval_on_selector(page, "textarea", "t => t.readOnly = true")

      locator = Page.locator(page, "#input1")
      assert {:ok, false} = Locator.is_editable(locator)

      locator = Page.locator(page, "#input2")
      assert {:ok, true} = Locator.is_editable(locator)

      locator = Page.locator(page, "textarea")
      assert {:ok, false} = Locator.is_editable(locator)
    end
  end

  test "<aside>A more interesting version of the ... test above", %{page: page} do
    # create all the Locators in advance
    locatorA = Page.locator(page, "#input1")
    locatorB = Page.locator(page, "#input2")
    locatorC = Page.locator(page, "textarea")

    Page.set_content(page, """
      <input id=input1 disabled>
      <textarea readonly></textarea>
      <input id=input2>
    """)

    # make assertions, demonstrating that  the Locators matched dynamic content
    assert {:ok, false} = Locator.is_editable(locatorA)
    assert {:ok, true} = Locator.is_editable(locatorB)
    assert {:ok, false} = Locator.is_editable(locatorC)
  end

  describe "Locator.is_enabled/1 and is_disabled/1" do
    test "...", %{page: page} do
      Page.set_content(page, """
        <button disabled>button1</button>
        <button>button2</button>
        <div>div</div>
      """)

      locator = Page.locator(page, "div")
      assert {:ok, true} = Locator.is_enabled(locator)
      assert {:ok, false} = Locator.is_disabled(locator)

      locator = Page.locator(page, ":text('button1')")
      assert {:ok, false} = Locator.is_enabled(locator)
      assert {:ok, true} = Locator.is_disabled(locator)

      locator = Page.locator(page, ":text('button2')")
      assert {:ok, true} = Locator.is_enabled(locator)
      assert {:ok, false} = Locator.is_disabled(locator)
    end
  end

  describe "Locator.is_visible/1 and is_hidden/1" do
    test "...", %{page: page} do
      Page.set_content(page, "<div>Hi</div><span></span>")

      locator = Page.locator(page, "div")
      assert {:ok, true} = Locator.is_visible(locator)
      assert {:ok, false} = Locator.is_hidden(locator)

      locator = Page.locator(page, "span")
      assert {:ok, false} = Locator.is_visible(locator)
      assert {:ok, true} = Locator.is_hidden(locator)
    end
  end

  describe "Locator.locator/4" do
    test "returns values with previews", %{assets: assets, page: page} do
      Page.goto(page, assets.dom)

      outer = Page.locator(page, "#outer")
      inner = Locator.locator(outer, "#inner")
      check = Page.locator(page, "#check")
      text = Locator.evaluate_handle(inner, "e => e.firstChild")

      assert Locator.string(outer) == ~s|Locator@#outer|
      assert Locator.string(inner) == ~s|Locator@#outer >> #inner|
      assert Locator.string(check) == ~s|Locator@#check|
      assert ElementHandle.string(text) == ~s|JSHandle@#text=Text,↵more text|
    end
  end

  describe "Locator.text_content/2" do
    test "...", %{assets: assets, page: page} do
      locator = Page.locator(page, "#inner")

      Page.goto(page, assets.dom)
      assert {:ok, "Text,\nmore text"} = Locator.text_content(locator)
    end
  end
end