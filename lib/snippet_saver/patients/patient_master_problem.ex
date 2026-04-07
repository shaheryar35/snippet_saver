defmodule SnippetSaver.Patients.PatientMasterProblem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "patient_master_problems" do
    field :notes, :string
    field :patient_id, :id
    field :master_problem_template_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(patient_master_problem, attrs) do
    patient_master_problem
    |> cast(attrs, [:notes, :patient_id, :master_problem_template_id])
    |> validate_required([:patient_id, :master_problem_template_id])
  end
end
