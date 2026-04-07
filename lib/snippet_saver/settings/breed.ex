defmodule SnippetSaver.Settings.Breed do
  use Ecto.Schema
  import Ecto.Changeset

  schema "breeds" do
    field :name, :string
    field :archived, :boolean, default: false

    belongs_to :species, SnippetSaver.Settings.Species
    belongs_to :inserted_by, SnippetSaver.Accounts.User, foreign_key: :inserted_by_id
    belongs_to :updated_by, SnippetSaver.Accounts.User, foreign_key: :updated_by_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(breed, attrs) do
    breed
    |> cast(attrs, [:name, :species_id, :archived])
    |> validate_required([:name, :species_id])
    |> validate_inclusion(:archived, [true, false])
    |> foreign_key_constraint(:species_id)
  end
end
