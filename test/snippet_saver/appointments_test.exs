defmodule SnippetSaver.AppointmentsTest do
  use SnippetSaver.DataCase

  alias SnippetSaver.Appointments

  describe "appointments" do
    alias SnippetSaver.Appointments.Appointment

    import SnippetSaver.AppointmentsFixtures

    @invalid_attrs %{reason: nil, appointment_datetime: nil, duration_minutes: nil, room: nil, created_by: nil, updated_by: nil}

    test "list_appointments/0 returns all appointments" do
      appointment = appointment_fixture()
      assert Appointments.list_appointments() == [appointment]
    end

    test "get_appointment!/1 returns the appointment with given id" do
      appointment = appointment_fixture()
      assert Appointments.get_appointment!(appointment.id) == appointment
    end

    test "create_appointment/1 with valid data creates a appointment" do
      valid_attrs = %{reason: "some reason", appointment_datetime: ~U[2026-04-06 21:11:00Z], duration_minutes: 42, room: "some room", created_by: 42, updated_by: 42}

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
      update_attrs = %{reason: "some updated reason", appointment_datetime: ~U[2026-04-07 21:11:00Z], duration_minutes: 43, room: "some updated room", created_by: 43, updated_by: 43}

      assert {:ok, %Appointment{} = appointment} = Appointments.update_appointment(appointment, update_attrs)
      assert appointment.reason == "some updated reason"
      assert appointment.appointment_datetime == ~U[2026-04-07 21:11:00Z]
      assert appointment.duration_minutes == 43
      assert appointment.room == "some updated room"
      assert appointment.created_by == 43
      assert appointment.updated_by == 43
    end

    test "update_appointment/2 with invalid data returns error changeset" do
      appointment = appointment_fixture()
      assert {:error, %Ecto.Changeset{}} = Appointments.update_appointment(appointment, @invalid_attrs)
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

    import SnippetSaver.AppointmentsFixtures

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

      assert {:ok, %AppointmentNote{} = appointment_note} = Appointments.create_appointment_note(valid_attrs)
      assert appointment_note.notes == "some notes"
      assert appointment_note.created_by == 42
    end

    test "create_appointment_note/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Appointments.create_appointment_note(@invalid_attrs)
    end

    test "update_appointment_note/2 with valid data updates the appointment_note" do
      appointment_note = appointment_note_fixture()
      update_attrs = %{notes: "some updated notes", created_by: 43}

      assert {:ok, %AppointmentNote{} = appointment_note} = Appointments.update_appointment_note(appointment_note, update_attrs)
      assert appointment_note.notes == "some updated notes"
      assert appointment_note.created_by == 43
    end

    test "update_appointment_note/2 with invalid data returns error changeset" do
      appointment_note = appointment_note_fixture()
      assert {:error, %Ecto.Changeset{}} = Appointments.update_appointment_note(appointment_note, @invalid_attrs)
      assert appointment_note == Appointments.get_appointment_note!(appointment_note.id)
    end

    test "delete_appointment_note/1 deletes the appointment_note" do
      appointment_note = appointment_note_fixture()
      assert {:ok, %AppointmentNote{}} = Appointments.delete_appointment_note(appointment_note)
      assert_raise Ecto.NoResultsError, fn -> Appointments.get_appointment_note!(appointment_note.id) end
    end

    test "change_appointment_note/1 returns a appointment_note changeset" do
      appointment_note = appointment_note_fixture()
      assert %Ecto.Changeset{} = Appointments.change_appointment_note(appointment_note)
    end
  end

  describe "recurring_appointments" do
    alias SnippetSaver.Appointments.RecurringAppointment

    import SnippetSaver.AppointmentsFixtures

    @invalid_attrs %{next_due_date: nil, interval_days: nil, reminder_days_before: nil, is_active: nil}

    test "list_recurring_appointments/0 returns all recurring_appointments" do
      recurring_appointment = recurring_appointment_fixture()
      assert Appointments.list_recurring_appointments() == [recurring_appointment]
    end

    test "get_recurring_appointment!/1 returns the recurring_appointment with given id" do
      recurring_appointment = recurring_appointment_fixture()
      assert Appointments.get_recurring_appointment!(recurring_appointment.id) == recurring_appointment
    end

    test "create_recurring_appointment/1 with valid data creates a recurring_appointment" do
      valid_attrs = %{next_due_date: ~D[2026-04-06], interval_days: 42, reminder_days_before: 42, is_active: true}

      assert {:ok, %RecurringAppointment{} = recurring_appointment} = Appointments.create_recurring_appointment(valid_attrs)
      assert recurring_appointment.next_due_date == ~D[2026-04-06]
      assert recurring_appointment.interval_days == 42
      assert recurring_appointment.reminder_days_before == 42
      assert recurring_appointment.is_active == true
    end

    test "create_recurring_appointment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Appointments.create_recurring_appointment(@invalid_attrs)
    end

    test "update_recurring_appointment/2 with valid data updates the recurring_appointment" do
      recurring_appointment = recurring_appointment_fixture()
      update_attrs = %{next_due_date: ~D[2026-04-07], interval_days: 43, reminder_days_before: 43, is_active: false}

      assert {:ok, %RecurringAppointment{} = recurring_appointment} = Appointments.update_recurring_appointment(recurring_appointment, update_attrs)
      assert recurring_appointment.next_due_date == ~D[2026-04-07]
      assert recurring_appointment.interval_days == 43
      assert recurring_appointment.reminder_days_before == 43
      assert recurring_appointment.is_active == false
    end

    test "update_recurring_appointment/2 with invalid data returns error changeset" do
      recurring_appointment = recurring_appointment_fixture()
      assert {:error, %Ecto.Changeset{}} = Appointments.update_recurring_appointment(recurring_appointment, @invalid_attrs)
      assert recurring_appointment == Appointments.get_recurring_appointment!(recurring_appointment.id)
    end

    test "delete_recurring_appointment/1 deletes the recurring_appointment" do
      recurring_appointment = recurring_appointment_fixture()
      assert {:ok, %RecurringAppointment{}} = Appointments.delete_recurring_appointment(recurring_appointment)
      assert_raise Ecto.NoResultsError, fn -> Appointments.get_recurring_appointment!(recurring_appointment.id) end
    end

    test "change_recurring_appointment/1 returns a recurring_appointment changeset" do
      recurring_appointment = recurring_appointment_fixture()
      assert %Ecto.Changeset{} = Appointments.change_recurring_appointment(recurring_appointment)
    end
  end
end
