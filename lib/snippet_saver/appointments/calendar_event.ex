defmodule SnippetSaver.Appointments.CalendarEvent do
  @moduledoc """
  Maps `%SnippetSaver.Appointments.Appointment{}` structs to EventCalendar event maps.

  Accent `color` is chosen in order (visit **type** drives the tile so Dental / Lab /
  Grooming match your `AppointmentType` colors; **status** is used when type has no
  valid hex):

  1. **`appointment_type.color`** when present and valid hex
  2. Else **`appointment_status.color`**
  3. Else a small **blue palette** by `appointment_type_id`

  The same hex is copied into **`extendedProps.calendarAccentHex`** and expanded into
  `--event-color`, `--event-bg`, and `--event-border` CSS variables so tiles remain
  color-correct in popovers and browsers with limited `color-mix()` support.
  """

  alias SnippetSaver.Appointments.Appointment

  @palette [
    "#1a73e8",
    "#1967d2",
    "#185abc",
    "#174ea6",
    "#8ab4f8",
    "#1a73e8",
    "#1967d2",
    "#185abc"
  ]

  @doc false
  def from_appointments(appointments) when is_list(appointments) do
    Enum.map(appointments, &to_event/1)
  end

  defp to_event(%Appointment{} = a) do
    duration = a.duration_minutes || 0
    end_at = DateTime.add(a.appointment_datetime, duration * 60, :second)
    accent = color_for(a) |> accent_css_hex()

    css_vars = event_css_vars(accent)

    %{
      id: a.id,
      title: build_title(a),
      start: DateTime.to_iso8601(a.appointment_datetime),
      end: DateTime.to_iso8601(end_at),
      color: accent,
      backgroundColor: "transparent",
      textColor: "inherit",
      classNames: ["calendar-event"],
      styles: css_vars,
      extendedProps: %{"calendarAccentHex" => accent}
    }
  end

  defp event_css_vars(accent) do
    case hex_to_rgb(accent) do
      {:ok, r, g, b} ->
        [
          "--event-color: #{accent}",
          "--event-bg: rgba(#{r}, #{g}, #{b}, 0.08)",
          "--event-border: rgba(#{r}, #{g}, #{b}, 0.18)",
          "--event-bg-hover: rgba(#{r}, #{g}, #{b}, 0.12)"
        ]

      :error ->
        ["--event-color: #{accent}"]
    end
  end

  defp accent_css_hex(hex) when is_binary(hex) do
    trimmed = String.trim(hex)

    cond do
      valid_hex_color?(trimmed) ->
        normalize_hex(trimmed)

      true ->
        normalize_hex(hd(@palette))
    end
  end

  defp normalize_hex(<<"#", r1, g1, b1>>) do
    <<"#", r1, r1, g1, g1, b1, b1>> |> String.downcase()
  end

  defp normalize_hex(<<"#", _::binary>> = hex), do: String.downcase(hex)

  defp hex_to_rgb(<<"#", r1, r2, g1, g2, b1, b2>>) do
    with {:ok, r} <- hex_pair(<<r1, r2>>),
         {:ok, g} <- hex_pair(<<g1, g2>>),
         {:ok, b} <- hex_pair(<<b1, b2>>) do
      {:ok, r, g, b}
    else
      _ -> :error
    end
  end

  defp hex_to_rgb(_), do: :error

  defp hex_pair(pair) do
    case Integer.parse(pair, 16) do
      {n, ""} -> {:ok, n}
      _ -> :error
    end
  end

  defp build_title(%Appointment{} = a) do
    patient_name = trim_or_nil(a.patient && a.patient.patient_name)
    type_name = trim_or_nil(a.appointment_type && a.appointment_type.name)
    reason = trim_or_nil(a.reason)

    [type_name, patient_name, reason]
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.join(" · ")
    |> case do
      "" -> "Appointment"
      t -> t
    end
  end

  defp trim_or_nil(nil), do: nil

  defp trim_or_nil(s) when is_binary(s) do
    case String.trim(s) do
      "" -> nil
      t -> t
    end
  end

  defp color_for(%Appointment{} = a) do
    case type_hex_color(a) do
      nil ->
        case status_hex_color(a) do
          nil -> palette_fallback(a)
          hex -> hex
        end

      hex ->
        hex
    end
  end

  defp type_hex_color(%Appointment{appointment_type: %{color: c}})
       when is_binary(c) do
    t = String.trim(c)
    if valid_hex_color?(t), do: t, else: nil
  end

  defp type_hex_color(_), do: nil

  defp status_hex_color(%Appointment{appointment_status: %{color: c}})
       when is_binary(c) do
    trimmed = String.trim(c)

    cond do
      valid_hex_color?(trimmed) ->
        trimmed

      true ->
        nil
    end
  end

  defp status_hex_color(_), do: nil

  defp valid_hex_color?(<<"#", rest::binary>>) when rest != "" do
    byte_size(rest) in [3, 6] and String.match?(rest, ~r/^[0-9A-Fa-f]+$/)
  end

  defp valid_hex_color?(_), do: false

  defp palette_fallback(%Appointment{appointment_type_id: id})
       when not is_nil(id) do
    Enum.at(@palette, rem(abs(id), length(@palette)))
  end

  defp palette_fallback(_), do: hd(@palette)
end
