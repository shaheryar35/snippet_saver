defmodule SnippetSaver.Contacts.ContactRoleType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contact_role_types" do
    field :name, :string

    # Associations
    has_many :contact_roles, SnippetSaver.Contacts.ContactRole

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(contact_role_type, attrs) do
    contact_role_type
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
