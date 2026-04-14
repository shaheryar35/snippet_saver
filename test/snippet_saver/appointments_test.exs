defmodule SnippetSaver.AppointmentsTest do
  use SnippetSaver.DataCase

  alias SnippetSaver.Appointments
  alias SnippetSaver.Appointments.CalendarEvent

  import SnippetSaver.AccountsFixtures
  import SnippetSaver.AppointmentsFixtures
  import SnippetSaver.SettingsFixtures

  describe "list_appointments_between/2" do
    test "returns appointments overlapping the query window" do
      user = user_fixture()
      uid = user.id

      {:ok, a1} =
        Appointments.create_appointment(%{
          appointment_datetime: ~U[2026-06-01 10:00:00Z],
          duration_minutes: 60,
          reason: "checkup",
          room: "A",
          created_by: uid,
          updated_by: uid
        })

      {:ok, a2} =
        Appointments.create_appointment(%{
          appointment_datetime: ~U[2026-06-15 12:00:00Z],
          duration_minutes: 30,
          reason: "follow-up",
          room: "B",
          created_by: uid,
          updated_by: uid
        })

      inside =
        Appointments.list_appointments_between(~U[2026-06-01 10:30:00Z], ~U[2026-06-01 11:30:00Z])

      assert Enum.map(inside, & &1.id) == [a1.id]

      after_end =
        Appointments.list_appointments_between(~U[2026-06-01 12:00:00Z], ~U[2026-06-02 00:00:00Z])

      refute a1.id in Enum.map(after_end, & &1.id)

      only_second =
        Appointments.list_appointments_between(~U[2026-06-15 12:00:00Z], ~U[2026-06-15 12:20:00Z])

      assert Enum.map(only_second, & &1.id) == [a2.id]
    end
  end

  describe "CalendarEvent.from_appointments/1" do
    test "builds event maps for the calendar" do
      user = user_fixture()
      uid = user.id

      {:ok, apt} =
        Appointments.create_appointment(%{
          appointment_datetime: ~U[2026-07-01 14:00:00Z],
          duration_minutes: 45,
          reason: "Vaccination",
          room: "2",
          created_by: uid,
          updated_by: uid
        })

      apt = Appointments.get_appointment_for_calendar!(apt.id)
      [event] = CalendarEvent.from_appointments([apt])

      assert event.id == apt.id
      assert event.title =~ "Vaccination"
      assert event.start == "2026-07-01T14:00:00Z"
      assert event.end == "2026-07-01T14:45:00Z"
      assert is_binary(event.color)
      assert event.backgroundColor == "transparent"
      assert event.textColor == "inherit"
      assert event.classNames == ["calendar-event"]
      assert Enum.any?(event.styles, &String.starts_with?(&1, "--event-color:"))
      assert Enum.any?(event.styles, &String.starts_with?(&1, "--event-bg:"))
    end

    test "uses appointment type color when status is unset and type has hex color" do
      user = user_fixture()
      uid = user.id

      atype =
        appointment_type_fixture(%{
          name: "cal-type-#{System.unique_integer([:positive])}",
          color: "#f97316",
          duration_minutes: 15
        })

      {:ok, apt} =
        Appointments.create_appointment(%{
          appointment_datetime: ~U[2026-08-01 11:00:00Z],
          duration_minutes: 20,
          reason: "Visit",
          room: "3",
          created_by: uid,
          updated_by: uid,
          appointment_type_id: atype.id
        })

      apt = Appointments.get_appointment_for_calendar!(apt.id)
      [event] = CalendarEvent.from_appointments([apt])

      assert event.color == "#f97316"
      assert "--event-color: #f97316" in event.styles
      assert "--event-bg: rgba(249, 115, 22, 0.08)" in event.styles
      assert event.extendedProps["calendarAccentHex"] == "#f97316"
    end

    test "prefers appointment type color over status when both are set" do
      user = user_fixture()
      uid = user.id

      atype =
        appointment_type_fixture(%{
          name: "cal-type2-#{System.unique_integer([:positive])}",
          color: "#3b82f6",
          duration_minutes: 10
        })

      status =
        appointment_status_fixture(%{
          name: "cal-st2-#{System.unique_integer([:positive])}",
          color: "#22c55e"
        })

      {:ok, apt} =
        Appointments.create_appointment(%{
          appointment_datetime: ~U[2026-08-02 10:00:00Z],
          duration_minutes: 15,
          reason: "Both",
          room: "1",
          created_by: uid,
          updated_by: uid,
          appointment_type_id: atype.id,
          appointment_status_id: status.id
        })

      apt = Appointments.get_appointment_for_calendar!(apt.id)
      [event] = CalendarEvent.from_appointments([apt])

      assert event.color == "#3b82f6"
      assert event.extendedProps["calendarAccentHex"] == "#3b82f6"
    end

    test "uses appointment status color when status is set and color is hex" do
      user = user_fixture()
      uid = user.id

      status =
        appointment_status_fixture(%{
          name: "cal-color-status-#{System.unique_integer([:positive])}",
          color: "#22c55e"
        })

      {:ok, apt} =
        Appointments.create_appointment(%{
          appointment_datetime: ~U[2026-07-02 09:00:00Z],
          duration_minutes: 30,
          reason: "Check",
          room: "1",
          created_by: uid,
          updated_by: uid,
          appointment_status_id: status.id
        })

      apt = Appointments.get_appointment_for_calendar!(apt.id)
      [event] = CalendarEvent.from_appointments([apt])

      assert event.color == "#22c55e"
      assert event.classNames == ["calendar-event"]
      assert "--event-color: #22c55e" in event.styles
      assert "--event-bg: rgba(34, 197, 94, 0.08)" in event.styles
      assert event.extendedProps["calendarAccentHex"] == "#22c55e"
    end
  end

  describe "appointments" do
    alias SnippetSaver.Appointments.Appointment

    @invalid_attrs %{
      reason: nil,
      appointment_datetime: nil,
      duration_minutes: nil,
      room: nil,
      created_by: nil,
      updated_by: nil
    }

    test "list_appointments/0 returns all appointments" do
      appointment = appointment_fixture()
      assert Appointments.list_appointments() == [appointment]
    end

    test "get_appointment!/1 returns the appointment with given id" do
      appointment = appointment_fixture()
      assert Appointments.get_appointment!(appointment.id) == appointment
    end

    test "create_appointment/1 with valid data creates a appointment" do
      valid_attrs = %{
        reason: "some reason",
        appointment_datetime: ~U[2026-04-06 21:11:00Z],
        duration_minutes: 42,
        room: "some room",
        created_by: 42,
        updated_by: 42
      }

      assert {:ok, %Appointment{} = appointment} = Appointments.create_appointment(valid_attrs)
      assert appointment.reason == "some reason"
      assert appointment.appointment_datetime == ~U[2026-04-06 21:11:00Z]
      assert appointment.duration_minutes == 42
      assert appointment.room == "some room"
      assert appointment.created_by == 42
      assert appointment.updated_by == 42
    end

    test "create_appointment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Appointments.create_appointment(@invalid_attrs)
    end

    test "update_appointment/2 with valid data updates the appointment" do
      appointment = appointment_fixture()

      update_attrs = %{
        reason: "some updated reason",
        appointment_datetime: ~U[2026-04-07 21:11:00Z],
        duration_minutes: 43,
        room: "some updated room",
        created_by: 43,
        updated_by: 43
      }

      assert {:ok, %Appointment{} = appointment} =
               Appointments.update_appointment(appointment, update_attrs)

      assert appointment.reason == "some updated reason"
      assert appointment.appointment_datetime == ~U[2026-04-07 21:11:00Z]
      assert appointment.duration_minutes == 43
      assert appointment.room == "some updated room"
      assert appointment.created_by == 43
      assert appointment.updated_by == 43
    end

    test "update_appointment/2 with invalid data returns error changeset" do
      appointment = appointment_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Appointments.update_appointment(appointment, @invalid_attrs)

      assert appointment == Appointments.get_appointment!(appointment.id)
    end

    test "delete_appointment/1 deletes the appointment" do
      appointment = appointment_fixture()
      assert {:ok, %Appointment{}} = Appointments.delete_appointment(appointment)
      assert_raise Ecto.NoResultsError, fn -> Appointments.get_appointment!(appointment.id) end
    end

    test "change_appointment/1 returns a appointment changeset" do
      appointment = appointment_fixture()
      assert %Ecto.Changeset{} = Appointments.change_appointment(appointment)
    end
  end

  describe "appointment_notes" do
    alias SnippetSaver.Appointments.AppointmentNote

    @invalid_attrs %{notes: nil, created_by: nil}

    test "list_appointment_notes/0 returns all appointment_notes" do
      appointment_note = appointment_note_fixture()
      assert Appointments.list_appointment_notes() == [appointment_note]
    end

    test "get_appointment_note!/1 returns the appointment_note with given id" do
      appointment_note = appointment_note_fixture()
      assert Appointments.get_appointment_note!(appointment_note.id) == appointment_note
    end

    test "create_appointment_note/1 with valid data creates a appointment_note" do
      valid_attrs = %{notes: "some notes", created_by: 42}

      assert {:ok, %AppointmentNote{} = appointment_note} =
               Appointments.create_appointment_note(valid_attrs)

      assert appointment_note.notes == "some notes"
      assert appointment_note.created_by == 42
    end

    test "create_appointment_note/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Appointments.create_appointment_note(@invalid_attrs)
    end

    test "update_appointment_note/2 with valid data updates the appointment_note" do
      appointment_note = appointment_note_fixture()
      update_attrs = %{notes: "some updated notes", created_by: 43}

      assert {:ok, %AppointmentNote{} = appointment_note} =
               Appointments.update_appointment_note(appointment_note, update_attrs)

      assert appointment_note.notes == "some updated notes"
      assert appointment_note.created_by == 43
    end

    test "update_appointment_note/2 with invalid data returns error changeset" do
      appointment_note = appointment_note_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Appointments.update_appointment_note(appointment_note, @invalid_attrs)

      assert appointment_note == Appointments.get_appointment_note!(appointment_note.id)
    end

    test "delete_appointment_note/1 deletes the appointment_note" do
      appointment_note = appointment_note_fixture()
      assert {:ok, %AppointmentNote{}} = Appointments.delete_appointment_note(appointment_note)

      assert_raise Ecto.NoResultsError, fn ->
        Appointments.get_appointment_note!(appointment_note.id)
      end
    end

    test "change_appointment_note/1 returns a appointment_note changeset" do
      appointment_note = appointment_note_fixture()
      assert %Ecto.Changeset{} = Appointments.change_appointment_note(appointment_note)
    end
  end

  describe "recurring_appointments" do
    alias SnippetSaver.Appointments.RecurringAppointment

    @invalid_attrs %{
      next_due_date: nil,
      interval_days: nil,
      reminder_days_before: nil,
      is_active: nil
    }

    test "list_recurring_appointments/0 returns all recurring_appointments" do
      recurring_appointment = recurring_appointment_fixture()
      assert Appointments.list_recurring_appointments() == [recurring_appointment]
    end

    test "get_recurring_appointment!/1 returns the recurring_appointment with given id" do
      recurring_appointment = recurring_appointment_fixture()

      assert Appointments.get_recurring_appointment!(recurring_appointment.id) ==
               recurring_appointment
    end

    test "create_recurring_appointment/1 with valid data creates a recurring_appointment" do
      valid_attrs = %{
        next_due_date: ~D[2026-04-06],
        interval_days: 42,
        reminder_days_before: 42,
        is_active: true
      }

      assert {:ok, %RecurringAppointment{} = recurring_appointment} =
               Appointments.create_recurring_appointment(valid_attrs)

      assert recurring_appointment.next_due_date == ~D[2026-04-06]
      assert recurring_appointment.interval_days == 42
      assert recurring_appointment.reminder_days_before == 42
      assert recurring_appointment.is_active == true
    end

    test "create_recurring_appointment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Appointments.create_recurring_appointment(@invalid_attrs)
    end

    test "update_recurring_appointment/2 with valid data updates the recurring_appointment" do
      recurring_appointment = recurring_appointment_fixture()

      update_attrs = %{
        next_due_date: ~D[2026-04-07],
        interval_days: 43,
        reminder_days_before: 43,
        is_active: false
      }

      assert {:ok, %RecurringAppointment{} = recurring_appointment} =
               Appointments.update_recurring_appointment(recurring_appointment, update_attrs)

      assert recurring_appointment.next_due_date == ~D[2026-04-07]
      assert recurring_appointment.interval_days == 43
      assert recurring_appointment.reminder_days_before == 43
      assert recurring_appointment.is_active == false
    end

    test "update_recurring_appointment/2 with invalid data returns error changeset" do
      recurring_appointment = recurring_appointment_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Appointments.update_recurring_appointment(recurring_appointment, @invalid_attrs)

      assert recurring_appointment ==
               Appointments.get_recurring_appointment!(recurring_appointment.id)
    end

    test "delete_recurring_appointment/1 deletes the recurring_appointment" do
      recurring_appointment = recurring_appointment_fixture()

      assert {:ok, %RecurringAppointment{}} =
               Appointments.delete_recurring_appointment(recurring_appointment)

      assert_raise Ecto.NoResultsError, fn ->
        Appointments.get_recurring_appointment!(recurring_appointment.id)
      end
    end

    test "change_recurring_appointment/1 returns a recurring_appointment changeset" do
      recurring_appointment = recurring_appointment_fixture()
      assert %Ecto.Changeset{} = Appointments.change_recurring_appointment(recurring_appointment)
    end
  end
end
