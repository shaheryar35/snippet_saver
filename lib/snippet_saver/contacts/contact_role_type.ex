defmodule SnippetSaver.Contacts.ContactRoleType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contact_role_types" do
    field :name, :string
    field :archived, :boolean, default: false

    belongs_to :inserted_by, SnippetSaver.Accounts.User, foreign_key: :inserted_by_id
    belongs_to :updated_by, SnippetSaver.Accounts.User, foreign_key: :updated_by_id

    has_many :contact_roles, SnippetSaver.Contacts.ContactRole

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(contact_role_type, attrs) do
    contact_role_type
    |> cast(attrs, [:name, :archived])
    |> validate_required([:name])
    |> validate_inclusion(:archived, [true, false])
    |> unique_constraint(:name,
      name: "contact_role_types_name_active_unique_index",
      message: "has already been taken"
    )
  end
end
