defmodule SnippetSaver.Catalog.HearAboutOption do
  use Ecto.Schema
  import Ecto.Changeset

  schema "hear_about_options" do
    field :name, :string
    field :is_active, :boolean, default: true
    field :category, :string

    field :archived, :boolean, default: false
    belongs_to :inserted_by, SnippetSaver.Accounts.User, foreign_key: :inserted_by_id
    belongs_to :updated_by, SnippetSaver.Accounts.User, foreign_key: :updated_by_id
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(hear_about_option, attrs) do
    hear_about_option
    |> cast(attrs, [:name, :is_active, :category, :archived])
    |> validate_required([:name, :is_active])
    |> validate_inclusion(:is_active, [true, false])
  end
end
