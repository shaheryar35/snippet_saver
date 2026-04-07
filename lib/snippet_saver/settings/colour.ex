defmodule SnippetSaver.Settings.Colour do
  use Ecto.Schema
  import Ecto.Changeset

  schema "colours" do
    field :name, :string
    field :archived, :boolean, default: false

    belongs_to :inserted_by, SnippetSaver.Accounts.User, foreign_key: :inserted_by_id
    belongs_to :updated_by, SnippetSaver.Accounts.User, foreign_key: :updated_by_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(colour, attrs) do
    colour
    |> cast(attrs, [:name, :archived])
    |> validate_required([:name])
    |> validate_inclusion(:archived, [true, false])
  end
end
