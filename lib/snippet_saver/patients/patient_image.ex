defmodule SnippetSaver.Patients.PatientImage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "patient_images" do
    field :image_url, :string
    field :file_name, :string
    field :patient_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(patient_image, attrs) do
    patient_image
    |> cast(attrs, [:image_url, :file_name])
    |> validate_required([:image_url, :file_name])
  end
end
