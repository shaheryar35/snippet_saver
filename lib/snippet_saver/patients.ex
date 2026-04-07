defmodule SnippetSaver.Patients do
  @moduledoc """
  The Patients context.
  """

  import Ecto.Query, warn: false
  alias SnippetSaver.Repo

  alias SnippetSaver.Patients.Patient

  @doc """
  Returns the list of patients.

  ## Examples

      iex> list_patients()
      [%Patient{}, ...]

  """
  def list_patients do
    Repo.all(Patient)
  end

  @doc """
  Gets a single patient.

  Raises `Ecto.NoResultsError` if the Patient does not exist.

  ## Examples

      iex> get_patient!(123)
      %Patient{}

      iex> get_patient!(456)
      ** (Ecto.NoResultsError)

  """
  def get_patient!(id), do: Repo.get!(Patient, id)

  @doc """
  Creates a patient.

  ## Examples

      iex> create_patient(%{field: value})
      {:ok, %Patient{}}

      iex> create_patient(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_patient(attrs) do
    %Patient{}
    |> Patient.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a patient.

  ## Examples

      iex> update_patient(patient, %{field: new_value})
      {:ok, %Patient{}}

      iex> update_patient(patient, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_patient(%Patient{} = patient, attrs) do
    patient
    |> Patient.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a patient.

  ## Examples

      iex> delete_patient(patient)
      {:ok, %Patient{}}

      iex> delete_patient(patient)
      {:error, %Ecto.Changeset{}}

  """
  def delete_patient(%Patient{} = patient) do
    Repo.delete(patient)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking patient changes.

  ## Examples

      iex> change_patient(patient)
      %Ecto.Changeset{data: %Patient{}}

  """
  def change_patient(%Patient{} = patient, attrs \\ %{}) do
    Patient.changeset(patient, attrs)
  end

  alias SnippetSaver.Patients.PatientOtherContact

  @doc """
  Returns the list of patient_other_contacts.

  ## Examples

      iex> list_patient_other_contacts()
      [%PatientOtherContact{}, ...]

  """
  def list_patient_other_contacts do
    Repo.all(PatientOtherContact)
  end

  @doc """
  Gets a single patient_other_contact.

  Raises `Ecto.NoResultsError` if the Patient other contact does not exist.

  ## Examples

      iex> get_patient_other_contact!(123)
      %PatientOtherContact{}

      iex> get_patient_other_contact!(456)
      ** (Ecto.NoResultsError)

  """
  def get_patient_other_contact!(id), do: Repo.get!(PatientOtherContact, id)

  @doc """
  Creates a patient_other_contact.

  ## Examples

      iex> create_patient_other_contact(%{field: value})
      {:ok, %PatientOtherContact{}}

      iex> create_patient_other_contact(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_patient_other_contact(attrs) do
    %PatientOtherContact{}
    |> PatientOtherContact.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a patient_other_contact.

  ## Examples

      iex> update_patient_other_contact(patient_other_contact, %{field: new_value})
      {:ok, %PatientOtherContact{}}

      iex> update_patient_other_contact(patient_other_contact, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_patient_other_contact(%PatientOtherContact{} = patient_other_contact, attrs) do
    patient_other_contact
    |> PatientOtherContact.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a patient_other_contact.

  ## Examples

      iex> delete_patient_other_contact(patient_other_contact)
      {:ok, %PatientOtherContact{}}

      iex> delete_patient_other_contact(patient_other_contact)
      {:error, %Ecto.Changeset{}}

  """
  def delete_patient_other_contact(%PatientOtherContact{} = patient_other_contact) do
    Repo.delete(patient_other_contact)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking patient_other_contact changes.

  ## Examples

      iex> change_patient_other_contact(patient_other_contact)
      %Ecto.Changeset{data: %PatientOtherContact{}}

  """
  def change_patient_other_contact(%PatientOtherContact{} = patient_other_contact, attrs \\ %{}) do
    PatientOtherContact.changeset(patient_other_contact, attrs)
  end

  alias SnippetSaver.Patients.PatientNote

  @doc """
  Returns the list of patient_notes.

  ## Examples

      iex> list_patient_notes()
      [%PatientNote{}, ...]

  """
  def list_patient_notes do
    Repo.all(PatientNote)
  end

  @doc """
  Gets a single patient_note.

  Raises `Ecto.NoResultsError` if the Patient note does not exist.

  ## Examples

      iex> get_patient_note!(123)
      %PatientNote{}

      iex> get_patient_note!(456)
      ** (Ecto.NoResultsError)

  """
  def get_patient_note!(id), do: Repo.get!(PatientNote, id)

  @doc """
  Creates a patient_note.

  ## Examples

      iex> create_patient_note(%{field: value})
      {:ok, %PatientNote{}}

      iex> create_patient_note(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_patient_note(attrs) do
    %PatientNote{}
    |> PatientNote.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a patient_note.

  ## Examples

      iex> update_patient_note(patient_note, %{field: new_value})
      {:ok, %PatientNote{}}

      iex> update_patient_note(patient_note, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_patient_note(%PatientNote{} = patient_note, attrs) do
    patient_note
    |> PatientNote.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a patient_note.

  ## Examples

      iex> delete_patient_note(patient_note)
      {:ok, %PatientNote{}}

      iex> delete_patient_note(patient_note)
      {:error, %Ecto.Changeset{}}

  """
  def delete_patient_note(%PatientNote{} = patient_note) do
    Repo.delete(patient_note)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking patient_note changes.

  ## Examples

      iex> change_patient_note(patient_note)
      %Ecto.Changeset{data: %PatientNote{}}

  """
  def change_patient_note(%PatientNote{} = patient_note, attrs \\ %{}) do
    PatientNote.changeset(patient_note, attrs)
  end

  alias SnippetSaver.Patients.PatientMasterProblem

  @doc """
  Returns the list of patient_master_problems.

  ## Examples

      iex> list_patient_master_problems()
      [%PatientMasterProblem{}, ...]

  """
  def list_patient_master_problems do
    Repo.all(PatientMasterProblem)
  end

  def list_patient_master_problems_for_patient(patient_id) do
    from(pmp in PatientMasterProblem,
      where: pmp.patient_id == ^patient_id,
      order_by: [asc: pmp.id]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single patient_master_problem.

  Raises `Ecto.NoResultsError` if the Patient master problem does not exist.

  ## Examples

      iex> get_patient_master_problem!(123)
      %PatientMasterProblem{}

      iex> get_patient_master_problem!(456)
      ** (Ecto.NoResultsError)

  """
  def get_patient_master_problem!(id), do: Repo.get!(PatientMasterProblem, id)

  @doc """
  Creates a patient_master_problem.

  ## Examples

      iex> create_patient_master_problem(%{field: value})
      {:ok, %PatientMasterProblem{}}

      iex> create_patient_master_problem(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_patient_master_problem(attrs) do
    %PatientMasterProblem{}
    |> PatientMasterProblem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a patient_master_problem.

  ## Examples

      iex> update_patient_master_problem(patient_master_problem, %{field: new_value})
      {:ok, %PatientMasterProblem{}}

      iex> update_patient_master_problem(patient_master_problem, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_patient_master_problem(%PatientMasterProblem{} = patient_master_problem, attrs) do
    patient_master_problem
    |> PatientMasterProblem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a patient_master_problem.

  ## Examples

      iex> delete_patient_master_problem(patient_master_problem)
      {:ok, %PatientMasterProblem{}}

      iex> delete_patient_master_problem(patient_master_problem)
      {:error, %Ecto.Changeset{}}

  """
  def delete_patient_master_problem(%PatientMasterProblem{} = patient_master_problem) do
    Repo.delete(patient_master_problem)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking patient_master_problem changes.

  ## Examples

      iex> change_patient_master_problem(patient_master_problem)
      %Ecto.Changeset{data: %PatientMasterProblem{}}

  """
  def change_patient_master_problem(%PatientMasterProblem{} = patient_master_problem, attrs \\ %{}) do
    PatientMasterProblem.changeset(patient_master_problem, attrs)
  end

  def replace_patient_master_problems(patient_id, rows) when is_list(rows) do
    Repo.transaction(fn ->
      from(pmp in PatientMasterProblem, where: pmp.patient_id == ^patient_id) |> Repo.delete_all()

      Enum.reduce_while(rows, :ok, fn row, _acc ->
        template_id =
          row["master_problem_template_id"] ||
            row[:master_problem_template_id] ||
            row["template_id"] ||
            row[:template_id]

        notes = row["notes"] || row[:notes] || ""

        if is_nil(template_id) || to_string(template_id) == "" do
          {:cont, :ok}
        else
          attrs = %{
            "patient_id" => patient_id,
            "master_problem_template_id" => template_id,
            "notes" => notes
          }

          case create_patient_master_problem(attrs) do
            {:ok, _} -> {:cont, :ok}
            {:error, changeset} -> {:halt, Repo.rollback(changeset)}
          end
        end
      end)
    end)
    |> case do
      {:ok, _} -> {:ok, :ok}
      {:error, reason} -> {:error, reason}
    end
  end

  alias SnippetSaver.Patients.PatientImage

  @doc """
  Returns the list of patient_images.

  ## Examples

      iex> list_patient_images()
      [%PatientImage{}, ...]

  """
  def list_patient_images do
    Repo.all(PatientImage)
  end

  @doc """
  Gets a single patient_image.

  Raises `Ecto.NoResultsError` if the Patient image does not exist.

  ## Examples

      iex> get_patient_image!(123)
      %PatientImage{}

      iex> get_patient_image!(456)
      ** (Ecto.NoResultsError)

  """
  def get_patient_image!(id), do: Repo.get!(PatientImage, id)

  @doc """
  Creates a patient_image.

  ## Examples

      iex> create_patient_image(%{field: value})
      {:ok, %PatientImage{}}

      iex> create_patient_image(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_patient_image(attrs) do
    %PatientImage{}
    |> PatientImage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a patient_image.

  ## Examples

      iex> update_patient_image(patient_image, %{field: new_value})
      {:ok, %PatientImage{}}

      iex> update_patient_image(patient_image, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_patient_image(%PatientImage{} = patient_image, attrs) do
    patient_image
    |> PatientImage.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a patient_image.

  ## Examples

      iex> delete_patient_image(patient_image)
      {:ok, %PatientImage{}}

      iex> delete_patient_image(patient_image)
      {:error, %Ecto.Changeset{}}

  """
  def delete_patient_image(%PatientImage{} = patient_image) do
    Repo.delete(patient_image)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking patient_image changes.

  ## Examples

      iex> change_patient_image(patient_image)
      %Ecto.Changeset{data: %PatientImage{}}

  """
  def change_patient_image(%PatientImage{} = patient_image, attrs \\ %{}) do
    PatientImage.changeset(patient_image, attrs)
  end
end
