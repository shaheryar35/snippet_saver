defmodule SnippetSaver.Catalog.VendorContact do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vendor_contacts" do
    field :name, :string
    field :role, :string
    field :vendor_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vendor_contact, attrs) do
    vendor_contact
    |> cast(attrs, [:name, :role, :vendor_id])
    |> validate_required([:name])
  end
end
