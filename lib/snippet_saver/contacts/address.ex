defmodule SnippetSaver.Contacts.Address do
  use Ecto.Schema
  import Ecto.Changeset

  schema "addresses" do
    field :type, :string
    field :street_address, :string
    field :suburb, :string
    field :postcode, :string
    field :city, :string
    field :country, :string
    field :longitude, :decimal
    field :latitude, :decimal
    field :address_name, :string
    timestamps(type: :utc_datetime)
    # Associations
    belongs_to :contact, SnippetSaver.Contacts.Contact
  end

  @doc false
  def changeset(address, attrs) do
    address
    |> cast(attrs, [
      :contact_id,
      :type,
      :street_address,
      :suburb,
      :postcode,
      :city,
      :country,
      :longitude,
      :latitude,
      :address_name
    ])
    |> validate_required([
      :contact_id,
      :type,
      :street_address,
      :suburb,
      :postcode,
      :city,
      :country,
      :longitude,
      :latitude,
      :address_name
    ])
  end
end
