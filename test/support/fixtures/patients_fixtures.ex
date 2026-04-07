defmodule SnippetSaver.PatientsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SnippetSaver.Patients` context.
  """

  @doc """
  Generate a patient.
  """
  def patient_fixture(attrs \\ %{}) do
    {:ok, patient} =
      attrs
      |> Enum.into(%{
        age: 42,
        age_estimated: true,
        bill_to_other: true,
        code: "some code",
        date_of_birth: ~D[2026-04-04],
        general_tags: %{},
        insurance_number: "some insurance_number",
        insurance_supplier_id: 42,
        is_animal_group: true,
        lives_away_from_owner: true,
        microchip_number: "some microchip_number",
        patient_name: "some patient_name",
        reminder_tags: %{},
        resuscitate: "some resuscitate",
        sex: "some sex",
        weight: "120.5",
        weight_unit: "some weight_unit"
      })
      |> SnippetSaver.Patients.create_patient()

    patient
  end

  @doc """
  Generate a patient_other_contact.
  """
  def patient_other_contact_fixture(attrs \\ %{}) do
    {:ok, patient_other_contact} =
      attrs
      |> Enum.into(%{

      })
      |> SnippetSaver.Patients.create_patient_other_contact()

    patient_other_contact
  end

  @doc """
  Generate a patient_note.
  """
  def patient_note_fixture(attrs \\ %{}) do
    {:ok, patient_note} =
      attrs
      |> Enum.into(%{
        notes: "some notes",
        notes_important: true
      })
      |> SnippetSaver.Patients.create_patient_note()

    patient_note
  end

  @doc """
  Generate a patient_master_problem.
  """
  def patient_master_problem_fixture(attrs \\ %{}) do
    {:ok, patient_master_problem} =
      attrs
      |> Enum.into(%{
        notes: "some notes"
      })
      |> SnippetSaver.Patients.create_patient_master_problem()

    patient_master_problem
  end

  @doc """
  Generate a patient_image.
  """
  def patient_image_fixture(attrs \\ %{}) do
    {:ok, patient_image} =
      attrs
      |> Enum.into(%{
        file_name: "some file_name",
        image_url: "some image_url"
      })
      |> SnippetSaver.Patients.create_patient_image()

    patient_image
  end
end
