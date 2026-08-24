defmodule SnippetSaver.Catalog.Vendor do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vendors" do
    field :company_name, :string

    field :archived, :boolean, default: false
    belongs_to :inserted_by, SnippetSaver.Accounts.User, foreign_key: :inserted_by_id
    belongs_to :updated_by, SnippetSaver.Accounts.User, foreign_key: :updated_by_id
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vendor, attrs) do
    vendor
    |> cast(attrs, [:company_name, :archived])
    |> validate_required([:company_name])
  end
end
