defmodule SnippetSaver.PatientsTest do
  use SnippetSaver.DataCase

  alias SnippetSaver.Patients

  describe "patients" do
    alias SnippetSaver.Patients.Patient

    import SnippetSaver.PatientsFixtures

    @invalid_attrs %{code: nil, patient_name: nil, microchip_number: nil, weight: nil, weight_unit: nil, age: nil, age_estimated: nil, date_of_birth: nil, sex: nil, resuscitate: nil, bill_to_other: nil, is_animal_group: nil, lives_away_from_owner: nil, insurance_supplier_id: nil, insurance_number: nil, general_tags: nil, reminder_tags: nil}

    test "list_patients/0 returns all patients" do
      patient = patient_fixture()
      assert Patients.list_patients() == [patient]
    end

    test "get_patient!/1 returns the patient with given id" do
      patient = patient_fixture()
      assert Patients.get_patient!(patient.id) == patient
    end

    test "create_patient/1 with valid data creates a patient" do
      valid_attrs = %{code: "some code", patient_name: "some patient_name", microchip_number: "some microchip_number", weight: "120.5", weight_unit: "some weight_unit", age: 42, age_estimated: true, date_of_birth: ~D[2026-04-04], sex: "some sex", resuscitate: "some resuscitate", bill_to_other: true, is_animal_group: true, lives_away_from_owner: true, insurance_supplier_id: 42, insurance_number: "some insurance_number", general_tags: %{}, reminder_tags: %{}}

      assert {:ok, %Patient{} = patient} = Patients.create_patient(valid_attrs)
      assert patient.code == "some code"
      assert patient.patient_name == "some patient_name"
      assert patient.microchip_number == "some microchip_number"
      assert patient.weight == Decimal.new("120.5")
      assert patient.weight_unit == "some weight_unit"
      assert patient.age == 42
      assert patient.age_estimated == true
      assert patient.date_of_birth == ~D[2026-04-04]
      assert patient.sex == "some sex"
      assert patient.resuscitate == "some resuscitate"
      assert patient.bill_to_other == true
      assert patient.is_animal_group == true
      assert patient.lives_away_from_owner == true
      assert patient.insurance_supplier_id == 42
      assert patient.insurance_number == "some insurance_number"
      assert patient.general_tags == %{}
      assert patient.reminder_tags == %{}
    end

    test "create_patient/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Patients.create_patient(@invalid_attrs)
    end

    test "update_patient/2 with valid data updates the patient" do
      patient = patient_fixture()
      update_attrs = %{code: "some updated code", patient_name: "some updated patient_name", microchip_number: "some updated microchip_number", weight: "456.7", weight_unit: "some updated weight_unit", age: 43, age_estimated: false, date_of_birth: ~D[2026-04-05], sex: "some updated sex", resuscitate: "some updated resuscitate", bill_to_other: false, is_animal_group: false, lives_away_from_owner: false, insurance_supplier_id: 43, insurance_number: "some updated insurance_number", general_tags: %{}, reminder_tags: %{}}

      assert {:ok, %Patient{} = patient} = Patients.update_patient(patient, update_attrs)
      assert patient.code == "some updated code"
      assert patient.patient_name == "some updated patient_name"
      assert patient.microchip_number == "some updated microchip_number"
      assert patient.weight == Decimal.new("456.7")
      assert patient.weight_unit == "some updated weight_unit"
      assert patient.age == 43
      assert patient.age_estimated == false
      assert patient.date_of_birth == ~D[2026-04-05]
      assert patient.sex == "some updated sex"
      assert patient.resuscitate == "some updated resuscitate"
      assert patient.bill_to_other == false
      assert patient.is_animal_group == false
      assert patient.lives_away_from_owner == false
      assert patient.insurance_supplier_id == 43
      assert patient.insurance_number == "some updated insurance_number"
      assert patient.general_tags == %{}
      assert patient.reminder_tags == %{}
    end

    test "update_patient/2 with invalid data returns error changeset" do
      patient = patient_fixture()
      assert {:error, %Ecto.Changeset{}} = Patients.update_patient(patient, @invalid_attrs)
      assert patient == Patients.get_patient!(patient.id)
    end

    test "delete_patient/1 deletes the patient" do
      patient = patient_fixture()
      assert {:ok, %Patient{}} = Patients.delete_patient(patient)
      assert_raise Ecto.NoResultsError, fn -> Patients.get_patient!(patient.id) end
    end

    test "change_patient/1 returns a patient changeset" do
      patient = patient_fixture()
      assert %Ecto.Changeset{} = Patients.change_patient(patient)
    end
  end

  describe "patient_other_contacts" do
    alias SnippetSaver.Patients.PatientOtherContact

    import SnippetSaver.PatientsFixtures

    @invalid_attrs %{}

    test "list_patient_other_contacts/0 returns all patient_other_contacts" do
      patient_other_contact = patient_other_contact_fixture()
      assert Patients.list_patient_other_contacts() == [patient_other_contact]
    end

    test "get_patient_other_contact!/1 returns the patient_other_contact with given id" do
      patient_other_contact = patient_other_contact_fixture()
      assert Patients.get_patient_other_contact!(patient_other_contact.id) == patient_other_contact
    end

    test "create_patient_other_contact/1 with valid data creates a patient_other_contact" do
      valid_attrs = %{}

      assert {:ok, %PatientOtherContact{} = patient_other_contact} = Patients.create_patient_other_contact(valid_attrs)
    end

    test "create_patient_other_contact/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Patients.create_patient_other_contact(@invalid_attrs)
    end

    test "update_patient_other_contact/2 with valid data updates the patient_other_contact" do
      patient_other_contact = patient_other_contact_fixture()
      update_attrs = %{}

      assert {:ok, %PatientOtherContact{} = patient_other_contact} = Patients.update_patient_other_contact(patient_other_contact, update_attrs)
    end

    test "update_patient_other_contact/2 with invalid data returns error changeset" do
      patient_other_contact = patient_other_contact_fixture()
      assert {:error, %Ecto.Changeset{}} = Patients.update_patient_other_contact(patient_other_contact, @invalid_attrs)
      assert patient_other_contact == Patients.get_patient_other_contact!(patient_other_contact.id)
    end

    test "delete_patient_other_contact/1 deletes the patient_other_contact" do
      patient_other_contact = patient_other_contact_fixture()
      assert {:ok, %PatientOtherContact{}} = Patients.delete_patient_other_contact(patient_other_contact)
      assert_raise Ecto.NoResultsError, fn -> Patients.get_patient_other_contact!(patient_other_contact.id) end
    end

    test "change_patient_other_contact/1 returns a patient_other_contact changeset" do
      patient_other_contact = patient_other_contact_fixture()
      assert %Ecto.Changeset{} = Patients.change_patient_other_contact(patient_other_contact)
    end
  end

  describe "patient_notes" do
    alias SnippetSaver.Patients.PatientNote

    import SnippetSaver.PatientsFixtures

    @invalid_attrs %{notes: nil, notes_important: nil}

    test "list_patient_notes/0 returns all patient_notes" do
      patient_note = patient_note_fixture()
      assert Patients.list_patient_notes() == [patient_note]
    end

    test "get_patient_note!/1 returns the patient_note with given id" do
      patient_note = patient_note_fixture()
      assert Patients.get_patient_note!(patient_note.id) == patient_note
    end

    test "create_patient_note/1 with valid data creates a patient_note" do
      valid_attrs = %{notes: "some notes", notes_important: true}

      assert {:ok, %PatientNote{} = patient_note} = Patients.create_patient_note(valid_attrs)
      assert patient_note.notes == "some notes"
      assert patient_note.notes_important == true
    end

    test "create_patient_note/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Patients.create_patient_note(@invalid_attrs)
    end

    test "update_patient_note/2 with valid data updates the patient_note" do
      patient_note = patient_note_fixture()
      update_attrs = %{notes: "some updated notes", notes_important: false}

      assert {:ok, %PatientNote{} = patient_note} = Patients.update_patient_note(patient_note, update_attrs)
      assert patient_note.notes == "some updated notes"
      assert patient_note.notes_important == false
    end

    test "update_patient_note/2 with invalid data returns error changeset" do
      patient_note = patient_note_fixture()
      assert {:error, %Ecto.Changeset{}} = Patients.update_patient_note(patient_note, @invalid_attrs)
      assert patient_note == Patients.get_patient_note!(patient_note.id)
    end

    test "delete_patient_note/1 deletes the patient_note" do
      patient_note = patient_note_fixture()
      assert {:ok, %PatientNote{}} = Patients.delete_patient_note(patient_note)
      assert_raise Ecto.NoResultsError, fn -> Patients.get_patient_note!(patient_note.id) end
    end

    test "change_patient_note/1 returns a patient_note changeset" do
      patient_note = patient_note_fixture()
      assert %Ecto.Changeset{} = Patients.change_patient_note(patient_note)
    end
  end

  describe "patient_master_problems" do
    alias SnippetSaver.Patients.PatientMasterProblem

    import SnippetSaver.PatientsFixtures

    @invalid_attrs %{notes: nil}

    test "list_patient_master_problems/0 returns all patient_master_problems" do
      patient_master_problem = patient_master_problem_fixture()
      assert Patients.list_patient_master_problems() == [patient_master_problem]
    end

    test "get_patient_master_problem!/1 returns the patient_master_problem with given id" do
      patient_master_problem = patient_master_problem_fixture()
      assert Patients.get_patient_master_problem!(patient_master_problem.id) == patient_master_problem
    end

    test "create_patient_master_problem/1 with valid data creates a patient_master_problem" do
      valid_attrs = %{notes: "some notes"}

      assert {:ok, %PatientMasterProblem{} = patient_master_problem} = Patients.create_patient_master_problem(valid_attrs)
      assert patient_master_problem.notes == "some notes"
    end

    test "create_patient_master_problem/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Patients.create_patient_master_problem(@invalid_attrs)
    end

    test "update_patient_master_problem/2 with valid data updates the patient_master_problem" do
      patient_master_problem = patient_master_problem_fixture()
      update_attrs = %{notes: "some updated notes"}

      assert {:ok, %PatientMasterProblem{} = patient_master_problem} = Patients.update_patient_master_problem(patient_master_problem, update_attrs)
      assert patient_master_problem.notes == "some updated notes"
    end

    test "update_patient_master_problem/2 with invalid data returns error changeset" do
      patient_master_problem = patient_master_problem_fixture()
      assert {:error, %Ecto.Changeset{}} = Patients.update_patient_master_problem(patient_master_problem, @invalid_attrs)
      assert patient_master_problem == Patients.get_patient_master_problem!(patient_master_problem.id)
    end

    test "delete_patient_master_problem/1 deletes the patient_master_problem" do
      patient_master_problem = patient_master_problem_fixture()
      assert {:ok, %PatientMasterProblem{}} = Patients.delete_patient_master_problem(patient_master_problem)
      assert_raise Ecto.NoResultsError, fn -> Patients.get_patient_master_problem!(patient_master_problem.id) end
    end

    test "change_patient_master_problem/1 returns a patient_master_problem changeset" do
      patient_master_problem = patient_master_problem_fixture()
      assert %Ecto.Changeset{} = Patients.change_patient_master_problem(patient_master_problem)
    end
  end

  describe "patient_images" do
    alias SnippetSaver.Patients.PatientImage

    import SnippetSaver.PatientsFixtures

    @invalid_attrs %{file_name: nil, image_url: nil}

    test "list_patient_images/0 returns all patient_images" do
      patient_image = patient_image_fixture()
      assert Patients.list_patient_images() == [patient_image]
    end

    test "get_patient_image!/1 returns the patient_image with given id" do
      patient_image = patient_image_fixture()
      assert Patients.get_patient_image!(patient_image.id) == patient_image
    end

    test "create_patient_image/1 with valid data creates a patient_image" do
      valid_attrs = %{file_name: "some file_name", image_url: "some image_url"}

      assert {:ok, %PatientImage{} = patient_image} = Patients.create_patient_image(valid_attrs)
      assert patient_image.file_name == "some file_name"
      assert patient_image.image_url == "some image_url"
    end

    test "create_patient_image/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Patients.create_patient_image(@invalid_attrs)
    end

    test "update_patient_image/2 with valid data updates the patient_image" do
      patient_image = patient_image_fixture()
      update_attrs = %{file_name: "some updated file_name", image_url: "some updated image_url"}

      assert {:ok, %PatientImage{} = patient_image} = Patients.update_patient_image(patient_image, update_attrs)
      assert patient_image.file_name == "some updated file_name"
      assert patient_image.image_url == "some updated image_url"
    end

    test "update_patient_image/2 with invalid data returns error changeset" do
      patient_image = patient_image_fixture()
      assert {:error, %Ecto.Changeset{}} = Patients.update_patient_image(patient_image, @invalid_attrs)
      assert patient_image == Patients.get_patient_image!(patient_image.id)
    end

    test "delete_patient_image/1 deletes the patient_image" do
      patient_image = patient_image_fixture()
      assert {:ok, %PatientImage{}} = Patients.delete_patient_image(patient_image)
      assert_raise Ecto.NoResultsError, fn -> Patients.get_patient_image!(patient_image.id) end
    end

    test "change_patient_image/1 returns a patient_image changeset" do
      patient_image = patient_image_fixture()
      assert %Ecto.Changeset{} = Patients.change_patient_image(patient_image)
    end
  end
end
