defmodule SnippetSaver.Appointments do
  @moduledoc """
  The Appointments context.
  """

  import Ecto.Query, warn: false
  alias SnippetSaver.Repo

  alias SnippetSaver.Appointments.Appointment

  @doc """
  Returns the list of appointments.

  ## Examples

      iex> list_appointments()
      [%Appointment{}, ...]

  """
  def list_appointments do
    Repo.all(Appointment)
  end

  @appointment_calendar_preloads [
    :patient,
    :doctor_contact,
    :owner_contact,
    :appointment_type,
    :appointment_status,
    :recurring_appointment
  ]

  @doc """
  Lists appointments that overlap `[utc_start, utc_end)` (half-open on end),
  with associations needed for calendar display.
  """
  def list_appointments_between(%DateTime{} = utc_start, %DateTime{} = utc_end) do
    from(a in Appointment,
      where: a.appointment_datetime < ^utc_end,
      where:
        fragment(
          "? + (COALESCE(?, 0) * interval '1 minute') > ?",
          a.appointment_datetime,
          a.duration_minutes,
          ^utc_start
        ),
      order_by: [asc: a.appointment_datetime]
    )
    |> preload(^@appointment_calendar_preloads)
    |> Repo.all()
  end

  @doc """
  Returns cards for appointment dashboard swimlanes, grouped by lane.

  Structure:

      %{
        "UPCOMING" => [%{title: ..., time: ..., detail: ..., status: ...}, ...],
        "TODAY" => [...],
        "NEEDS RESCHEDULE" => [...],
        "READY FOR BILLING" => [...]
      }
  """
  def appointment_swimlane_cards do
    %{
      "UPCOMING" => upcoming_cards(),
      "TODAY" => today_cards(),
      "NEEDS RESCHEDULE" => needs_reschedule_cards(),
      "READY FOR BILLING" => ready_for_billing_cards()
    }
  end

  defp upcoming_cards do
    now = DateTime.utc_now()
    in_48h = DateTime.add(now, 48 * 60 * 60, :second)

    base_appointment_query()
    |> where([a, _p, _owner, _doctor, _atype, s], a.appointment_datetime >= ^now)
    |> where([a, _p, _owner, _doctor, _atype, s], a.appointment_datetime < ^in_48h)
    |> order_by([a, _p, _owner, _doctor, _atype, _s], asc: a.appointment_datetime)
    |> Repo.all()
    |> Enum.map(&to_dashboard_card/1)
  end

  defp today_cards do
    today = Date.utc_today()

    start_of_day = DateTime.new!(today, ~T[00:00:00], "Etc/UTC")
    end_of_day = DateTime.new!(today, ~T[23:59:59], "Etc/UTC")

    base_appointment_query()
    |> where([a, _p, _owner, _doctor, _atype, s], a.appointment_datetime >= ^start_of_day)
    |> where([a, _p, _owner, _doctor, _atype, s], a.appointment_datetime <= ^end_of_day)
    |> order_by([a, _p, _owner, _doctor, _atype, _s], asc: a.appointment_datetime)
    |> Repo.all()
    |> Enum.map(&to_dashboard_card/1)
  end

  defp needs_reschedule_cards do
    now = DateTime.utc_now()

    base_appointment_query()
    |> where([a, _p, _owner, _doctor, _atype, s], a.appointment_datetime < ^now)
    |> order_by([a, _p, _owner, _doctor, _atype, _s], desc: a.appointment_datetime)
    |> Repo.all()
    |> Enum.map(&to_dashboard_card/1)
  end

  defp ready_for_billing_cards do
    today = Date.utc_today()
    seven_days_ago = Date.add(today, -7)
    start = DateTime.new!(seven_days_ago, ~T[00:00:00], "Etc/UTC")

    base_appointment_query()
    |> where([a, _p, _owner, _doctor, _atype, _s], a.appointment_datetime >= ^start)
    |> order_by([a, _p, _owner, _doctor, _atype, _s], desc: a.appointment_datetime)
    |> Repo.all()
    |> Enum.map(&to_dashboard_card/1)
  end

  # Shared query used by all swimlane helpers
  defp base_appointment_query do
    from(a in Appointment,
      join: p in assoc(a, :patient),
      left_join: owner in assoc(a, :owner_contact),
      left_join: doctor in assoc(a, :doctor_contact),
      left_join: atype in assoc(a, :appointment_type),
      left_join: s in assoc(a, :appointment_status),
      select: {
        a,
        p.patient_name,
        owner.first_name,
        owner.last_name,
        doctor.first_name,
        doctor.last_name,
        atype.name,
        s.name
      }
    )
  end

  defp to_dashboard_card(
         {appointment, patient_name, owner_first, owner_last, doctor_first, doctor_last,
          appointment_type_name, status_name}
       ) do
    owner_full =
      Enum.join(
        Enum.reject([owner_first, owner_last], &is_nil_or_empty/1),
        " "
      )

    doctor_full =
      Enum.join(
        Enum.reject([doctor_first, doctor_last], &is_nil_or_empty/1),
        " "
      )

    time = Calendar.strftime(appointment.appointment_datetime, "%Y-%m-%d %H:%M")

    detail_parts = [
      owner_full != "" && "Owner: #{owner_full}",
      doctor_full != "" && "Dr. #{doctor_full}",
      appointment_type_name
    ]

    detail =
      detail_parts
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" • ")

    %{
      title: patient_name || "(no patient)",
      time: time,
      detail: detail,
      status: status_name || ""
    }
  end

  defp is_nil_or_empty(nil), do: true
  defp is_nil_or_empty(""), do: true
  defp is_nil_or_empty(_), do: false

  @doc """
  Gets a single appointment with calendar-related associations preloaded.
  """
  def get_appointment_for_calendar!(id) do
    Appointment
    |> Repo.get!(id)
    |> Repo.preload(@appointment_calendar_preloads)
  end

  @doc """
  Gets a single appointment.

  Raises `Ecto.NoResultsError` if the Appointment does not exist.

  ## Examples

      iex> get_appointment!(123)
      %Appointment{}

      iex> get_appointment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_appointment!(id), do: Repo.get!(Appointment, id)

  @doc """
  Creates a appointment.

  ## Examples

      iex> create_appointment(%{field: value})
      {:ok, %Appointment{}}

      iex> create_appointment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_appointment(attrs) do
    %Appointment{}
    |> Appointment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a appointment.

  ## Examples

      iex> update_appointment(appointment, %{field: new_value})
      {:ok, %Appointment{}}

      iex> update_appointment(appointment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_appointment(%Appointment{} = appointment, attrs) do
    appointment
    |> Appointment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a appointment.

  ## Examples

      iex> delete_appointment(appointment)
      {:ok, %Appointment{}}

      iex> delete_appointment(appointment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_appointment(%Appointment{} = appointment) do
    Repo.delete(appointment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking appointment changes.

  ## Examples

      iex> change_appointment(appointment)
      %Ecto.Changeset{data: %Appointment{}}

  """
  def change_appointment(%Appointment{} = appointment, attrs \\ %{}) do
    Appointment.changeset(appointment, attrs)
  end

  alias SnippetSaver.Appointments.AppointmentNote

  @doc """
  Returns the list of appointment_notes.

  ## Examples

      iex> list_appointment_notes()
      [%AppointmentNote{}, ...]

  """
  def list_appointment_notes do
    Repo.all(AppointmentNote)
  end

  @doc """
  Gets a single appointment_note.

  Raises `Ecto.NoResultsError` if the Appointment note does not exist.

  ## Examples

      iex> get_appointment_note!(123)
      %AppointmentNote{}

      iex> get_appointment_note!(456)
      ** (Ecto.NoResultsError)

  """
  def get_appointment_note!(id), do: Repo.get!(AppointmentNote, id)

  @doc """
  Creates a appointment_note.

  ## Examples

      iex> create_appointment_note(%{field: value})
      {:ok, %AppointmentNote{}}

      iex> create_appointment_note(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_appointment_note(attrs) do
    %AppointmentNote{}
    |> AppointmentNote.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a appointment_note.

  ## Examples

      iex> update_appointment_note(appointment_note, %{field: new_value})
      {:ok, %AppointmentNote{}}

      iex> update_appointment_note(appointment_note, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_appointment_note(%AppointmentNote{} = appointment_note, attrs) do
    appointment_note
    |> AppointmentNote.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a appointment_note.

  ## Examples

      iex> delete_appointment_note(appointment_note)
      {:ok, %AppointmentNote{}}

      iex> delete_appointment_note(appointment_note)
      {:error, %Ecto.Changeset{}}

  """
  def delete_appointment_note(%AppointmentNote{} = appointment_note) do
    Repo.delete(appointment_note)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking appointment_note changes.

  ## Examples

      iex> change_appointment_note(appointment_note)
      %Ecto.Changeset{data: %AppointmentNote{}}

  """
  def change_appointment_note(%AppointmentNote{} = appointment_note, attrs \\ %{}) do
    AppointmentNote.changeset(appointment_note, attrs)
  end

  alias SnippetSaver.Appointments.RecurringAppointment

  @doc """
  Returns the list of recurring_appointments.

  ## Examples

      iex> list_recurring_appointments()
      [%RecurringAppointment{}, ...]

  """
  def list_recurring_appointments do
    Repo.all(RecurringAppointment)
  end

  @doc """
  Gets a single recurring_appointment.

  Raises `Ecto.NoResultsError` if the Recurring appointment does not exist.

  ## Examples

      iex> get_recurring_appointment!(123)
      %RecurringAppointment{}

      iex> get_recurring_appointment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_recurring_appointment!(id), do: Repo.get!(RecurringAppointment, id)

  @doc """
  Creates a recurring_appointment.

  ## Examples

      iex> create_recurring_appointment(%{field: value})
      {:ok, %RecurringAppointment{}}

      iex> create_recurring_appointment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_recurring_appointment(attrs) do
    %RecurringAppointment{}
    |> RecurringAppointment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a recurring_appointment.

  ## Examples

      iex> update_recurring_appointment(recurring_appointment, %{field: new_value})
      {:ok, %RecurringAppointment{}}

      iex> update_recurring_appointment(recurring_appointment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_recurring_appointment(%RecurringAppointment{} = recurring_appointment, attrs) do
    recurring_appointment
    |> RecurringAppointment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a recurring_appointment.

  ## Examples

      iex> delete_recurring_appointment(recurring_appointment)
      {:ok, %RecurringAppointment{}}

      iex> delete_recurring_appointment(recurring_appointment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_recurring_appointment(%RecurringAppointment{} = recurring_appointment) do
    Repo.delete(recurring_appointment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking recurring_appointment changes.

  ## Examples

      iex> change_recurring_appointment(recurring_appointment)
      %Ecto.Changeset{data: %RecurringAppointment{}}

  """
  def change_recurring_appointment(%RecurringAppointment{} = recurring_appointment, attrs \\ %{}) do
    RecurringAppointment.changeset(recurring_appointment, attrs)
  end
end
