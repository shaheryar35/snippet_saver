defmodule SnippetSaver.Contacts.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contacts" do
    field :business_code, :string
    field :is_individual, :boolean, default: true
    field :title, :string
    field :first_name, :string
    field :last_name, :string
    field :notes, :string
    field :notes_important, :boolean, default: false
    field :preferred_contact_method_id, :integer
    field :hear_about_option_id, :integer
    field :discount_group_id, :integer
    field :financial_group_id, :integer

    # Associations
    has_many :contact_roles, SnippetSaver.Contacts.ContactRole
    has_many :contact_role_types, through: [:contact_roles, :contact_role_type]
    has_many :contact_methods, SnippetSaver.Contacts.ContactMethod
    has_many :addresses, SnippetSaver.Contacts.Address
    has_one :general_info, SnippetSaver.Contacts.GeneralInfo

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [
      :business_code,
      :is_individual,
      :title,
      :first_name,
      :last_name,
      :notes,
      :notes_important,
      :preferred_contact_method_id,
      :hear_about_option_id,
      :discount_group_id,
      :financial_group_id
    ])
    # Only require is_individual (has default anyway)
    |> validate_required([:is_individual])

    # Optional: Add conditional validation for individuals vs organizations
    # |> validate_required([:first_name, :last_name], when: &(&1.is_individual == true))
    # |> validate_required([:business_code], when: &(&1.is_individual == false))
  end
end
