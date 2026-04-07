defmodule SnippetSaver.AppointmentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SnippetSaver.Appointments` context.
  """

  @doc """
  Generate a appointment.
  """
  def appointment_fixture(attrs \\ %{}) do
    {:ok, appointment} =
      attrs
      |> Enum.into(%{
        appointment_datetime: ~U[2026-04-06 21:11:00Z],
        created_by: 42,
        duration_minutes: 42,
        reason: "some reason",
        room: "some room",
        updated_by: 42
      })
      |> SnippetSaver.Appointments.create_appointment()

    appointment
  end

  @doc """
  Generate a appointment_note.
  """
  def appointment_note_fixture(attrs \\ %{}) do
    {:ok, appointment_note} =
      attrs
      |> Enum.into(%{
        created_by: 42,
        notes: "some notes"
      })
      |> SnippetSaver.Appointments.create_appointment_note()

    appointment_note
  end

  @doc """
  Generate a recurring_appointment.
  """
  def recurring_appointment_fixture(attrs \\ %{}) do
    {:ok, recurring_appointment} =
      attrs
      |> Enum.into(%{
        interval_days: 42,
        is_active: true,
        next_due_date: ~D[2026-04-06],
        reminder_days_before: 42
      })
      |> SnippetSaver.Appointments.create_recurring_appointment()

    recurring_appointment
  end
end
