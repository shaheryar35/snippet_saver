defmodule SnippetSaverWeb.PageController do
  use SnippetSaverWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def testing(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :testing, layout: false)
  end
end
