defmodule SnippetSaverWeb.UserRegistrationLiveTest do
  use SnippetSaverWeb.ConnCase, async: true

  describe "Registration page" do
    test "registration route is disabled", %{conn: conn} do
      conn = get(conn, "/users/register")
      assert html_response(conn, 404)
    end
  end
end
