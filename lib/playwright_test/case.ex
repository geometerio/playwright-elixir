defmodule PlaywrightTest.Case do
  @moduledoc """
  Use `PlaywrightTest.Case` in an ExUnit test module to start a Playwright server and put it into the test context.

  ## Examples

      defmodule Example.PageTest do
        use PlaywrightTest.Case

        describe "features w/ default context" do
          test "goes to a page", %{page: page} do
            text =
              page
              |> Playwright.Page.goto("https://playwright.dev")
              |> Playwright.Page.text_content(".navbar__title")

            assert text == "Playwright"
          end
        end
      end

      defmodule Example.BrowserTest do
        use PlaywrightTest.Case

        describe "features w/out `page` context" do
          @tag exclude: [:page]
          test "goes to a page", %{browser: browser} do
            page =
              browser
              |> Playwright.Browser.new_page()

            text =
              page
              |> Playwright.Page.goto("https://playwright.dev")
              |> Playwright.Page.text_content(".navbar__title")

            assert text == "Playwright"

            # must close test-created `page`
            Playwright.Page.close(page)
          end
        end
      end
  """

  defmacro __using__(options \\ %{}) do
    quote location: :keep do
      alias Playwright.Runner.Config

      setup_all(context) do
        inline_options = unquote(options) |> Enum.into(%{})
        launch_options = Map.merge(Config.launch_options(), inline_options)
        runner_options = Map.merge(Config.playwright_test(), inline_options)

        Application.put_env(:playwright, LaunchOptions, launch_options)
        {:ok, _} = Application.ensure_all_started(:playwright)

        browser_pool = PlaywrightTest.Pool.start_link()

        # {connection, browser} = setup_browser(runner_options)
        # [browser: browser, connection: connection, transport: runner_options.transport]
        [browser_pool: browser_pool, transport: runner_options.transport]
      end

      setup(context) do
        tagged_exclude = Map.get(context, :exclude, [])

        connection = :poolboy.checkout(:playwright)
        browser = Playwright.BrowserType.chromium(connection)

        case Enum.member?(tagged_exclude, :page) do
          true ->
            [browser: browser, connection: connection]

          false ->
            page = Playwright.Browser.new_page(browser)

            on_exit(:ok, fn ->
              Playwright.Page.close(page)
            end)

            Map.put(context, :page, page)
            [page: page, browser: browser, connection: connection]
        end
      end

      # ---

      defp setup_browser(runner_options) do
        case runner_options.transport do
          :driver ->
            options = Config.launch_options()
            Playwright.BrowserType.launch(options)

          :websocket ->
            options = Config.connect_options()
            Playwright.BrowserType.connect(options.ws_endpoint)
        end
      end
    end
  end
end
