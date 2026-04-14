alias SnippetSaver.Repo
alias SnippetSaver.Settings
alias SnippetSaver.Settings.AppointmentType

appointment_type_rows = [
  %{name: "General Checkup", duration_minutes: 15, color: "#22c55e"},
  %{name: "Vaccination", duration_minutes: 10, color: "#3b82f6"},
  %{name: "Emergency Visit", duration_minutes: 30, color: "#ef4444"},
  %{name: "Follow-Up Visit", duration_minutes: 10, color: "#8b5cf6"},
  %{name: "Surgery Consultation", duration_minutes: 20, color: "#f97316"},
  %{name: "Lab Test", duration_minutes: 10, color: "#eab308"},
  %{name: "Grooming", duration_minutes: 45, color: "#ec4899"},
  %{name: "Dental Check", duration_minutes: 20, color: "#14b8a6"},
  %{name: "Deworming", duration_minutes: 5, color: "#0ea5e9"},
  %{name: "Home Visit", duration_minutes: 60, color: "#a16207"}
]

{created, restored, skipped} =
  Enum.reduce(appointment_type_rows, {0, 0, 0}, fn row, {c, r, s} ->
    %{name: name, duration_minutes: duration_minutes, color: color} = row
    attrs = %{name: name, duration_minutes: duration_minutes, color: color, is_active: true, archived: false}

    case Repo.get_by(AppointmentType, name: name) do
      nil ->
        case Settings.create_appointment_type(attrs) do
          {:ok, _} ->
            {c + 1, r, s}

          {:error, changeset} ->
            IO.puts("Failed to create appointment type '#{name}': #{inspect(changeset.errors)}")
            {c, r, s}
        end

      %AppointmentType{archived: true} = appointment_type ->
        case Settings.update_appointment_type(appointment_type, attrs) do
          {:ok, _} ->
            {c, r + 1, s}

          {:error, changeset} ->
            IO.puts("Failed to restore appointment type '#{name}': #{inspect(changeset.errors)}")
            {c, r, s}
        end

      %AppointmentType{} ->
        {c, r, s + 1}
    end
  end)

IO.puts(
  "Appointment type seed complete: created=#{created}, restored=#{restored}, skipped=#{skipped}"
)
