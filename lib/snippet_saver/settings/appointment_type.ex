defmodule SnippetSaver.Settings.AppointmentType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "appointment_types" do
    field :name, :string
    field :duration_minutes, :integer
    field :color, :string
    field :is_active, :boolean, default: false
    field :archived, :boolean, default: false

    belongs_to :inserted_by, SnippetSaver.Accounts.User, foreign_key: :inserted_by_id
    belongs_to :updated_by, SnippetSaver.Accounts.User, foreign_key: :updated_by_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(appointment_type, attrs) do
    appointment_type
    |> cast(attrs, [:name, :duration_minutes, :color, :is_active, :archived])
    |> validate_required([:name, :duration_minutes, :color, :is_active])
    |> validate_number(:duration_minutes, greater_than: 0)
    |> validate_inclusion(:archived, [true, false])
    |> validate_inclusion(:is_active, [true, false])
  end
end
