alias SnippetSaver.Repo
alias SnippetSaver.Settings
alias SnippetSaver.Settings.AppointmentStatus

appointment_status_rows = [
  %{name: "Scheduled", color: "#3b82f6"},
  %{name: "Confirmed", color: "#22c55e"},
  %{name: "Checked In", color: "#8b5cf6"},
  %{name: "In Progress", color: "#f97316"},
  %{name: "Completed", color: "#10b981"},
  %{name: "No Show", color: "#ef4444"},
  %{name: "Cancelled", color: "#6b7280"},
  %{name: "Rescheduled", color: "#eab308"}
]

{created, restored, skipped} =
  Enum.reduce(appointment_status_rows, {0, 0, 0}, fn row, {c, r, s} ->
    %{name: name, color: color} = row
    attrs = %{name: name, color: color, archived: false}

    case Repo.get_by(AppointmentStatus, name: name) do
      nil ->
        case Settings.create_appointment_status(attrs) do
          {:ok, _} ->
            {c + 1, r, s}

          {:error, changeset} ->
            IO.puts("Failed to create appointment status '#{name}': #{inspect(changeset.errors)}")
            {c, r, s}
        end

      %AppointmentStatus{archived: true} = appointment_status ->
        case Settings.update_appointment_status(appointment_status, attrs) do
          {:ok, _} ->
            {c, r + 1, s}

          {:error, changeset} ->
            IO.puts("Failed to restore appointment status '#{name}': #{inspect(changeset.errors)}")
            {c, r, s}
        end

      %AppointmentStatus{} ->
        {c, r, s + 1}
    end
  end)

IO.puts(
  "Appointment status seed complete: created=#{created}, restored=#{restored}, skipped=#{skipped}"
)
