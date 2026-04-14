defmodule SnippetSaverWeb.AppointmentScheduleCalendar do
  @moduledoc """
  LiveView calendar container using a custom `phx-hook` that extends
  `calendar_component`'s LiveCalendar with extra interaction (e.g. `select`).

  API matches `LiveCalendar.Components.calendar/1` except the hook id.
  """
  use Phoenix.Component

  attr(:id, :string, required: true)
  attr(:events, :list, default: [])
  attr(:options, :map, default: %{})
  attr(:on_event_click, :any, default: nil)
  attr(:on_date_click, :any, default: nil)
  attr(:on_month_change, :any, default: nil)
  attr(:rest, :global)

  def appointment_schedule_calendar(assigns) do
    js_callbacks =
      %{}
      |> maybe_put_js("onEventClick", assigns[:on_event_click])
      |> maybe_put_js("onDateClick", assigns[:on_date_click])
      |> maybe_put_js("onMonthChange", assigns[:on_month_change])

    assigns =
      assigns
      |> assign(:events_json, Jason.encode!(assigns.events))
      |> assign(:options_json, Jason.encode!(assigns.options))
      |> assign(:js_callbacks_json, Jason.encode!(js_callbacks))

    ~H"""
    <div
      id={@id}
      phx-update="ignore"
      phx-hook="AppointmentScheduleCalendar"
      data-events={@events_json}
      data-options={@options_json}
      data-js-callbacks={@js_callbacks_json}
      {@rest}
    >
    </div>
    """
  end

  defp maybe_put_js(acc, _key, nil), do: acc

  defp maybe_put_js(acc, key, %Phoenix.LiveView.JS{} = js) do
    Map.put(acc, key, js |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary())
  end

  defp maybe_put_js(acc, key, other), do: Map.put(acc, key, other)
end
