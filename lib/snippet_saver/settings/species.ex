defmodule SnippetSaver.Settings.Species do
  use Ecto.Schema
  import Ecto.Changeset

  schema "species" do
    field :name, :string
    field :archived, :boolean, default: false

    belongs_to :inserted_by, SnippetSaver.Accounts.User, foreign_key: :inserted_by_id
    belongs_to :updated_by, SnippetSaver.Accounts.User, foreign_key: :updated_by_id

    has_many :breeds, SnippetSaver.Settings.Breed

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(species, attrs) do
    species
    |> cast(attrs, [:name, :archived])
    |> validate_required([:name])
    |> validate_inclusion(:archived, [true, false])
  end
end
