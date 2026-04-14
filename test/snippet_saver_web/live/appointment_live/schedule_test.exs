defmodule SnippetSaverWeb.AppointmentLive.ScheduleTest do
  use SnippetSaverWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  describe "Schedule" do
    test "renders calendar and header", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/appointments")

      assert html =~ "Appointments"
      assert html =~ "schedule-calendar"
    end
  end
end
