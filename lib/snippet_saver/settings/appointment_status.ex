defmodule SnippetSaver.Settings.AppointmentStatus do
  use Ecto.Schema
  import Ecto.Changeset

  schema "appointment_status" do
    field :name, :string
    field :color, :string
    field :archived, :boolean, default: false

    belongs_to :inserted_by, SnippetSaver.Accounts.User, foreign_key: :inserted_by_id
    belongs_to :updated_by, SnippetSaver.Accounts.User, foreign_key: :updated_by_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(appointment_status, attrs) do
    appointment_status
    |> cast(attrs, [:name, :color, :archived])
    |> validate_required([:name, :color])
    |> validate_inclusion(:archived, [true, false])
  end
end
