defmodule SnippetSaver.Contacts.ContactRole do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contact_roles" do
    # Associations
    belongs_to :contact, SnippetSaver.Contacts.Contact
    belongs_to :contact_role_type, SnippetSaver.Contacts.ContactRoleType

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(contact_role, attrs) do
    contact_role
    |> cast(attrs, [:contact_id, :contact_role_type_id])
    |> validate_required([:contact_id, :contact_role_type_id])
    |> unique_constraint([:contact_id, :contact_role_type_id],
      name: :contact_roles_contact_id_contact_role_type_id_index
    )
  end
end
