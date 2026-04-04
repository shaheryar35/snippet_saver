defmodule SnippetSaver.Contacts.ContactMethod do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contact_methods" do
    field :type, :string
    field :value, :string
    field :is_primary, :boolean, default: false
    field :allow_sms, :boolean, default: false
    field :allow_email, :boolean, default: false

    timestamps(type: :utc_datetime)
    # Associations
    belongs_to :contact, SnippetSaver.Contacts.Contact
  end

  @doc false
  def changeset(contact_method, attrs) do
    contact_method
    |> cast(attrs, [:contact_id, :type, :value, :is_primary, :allow_sms, :allow_email])
    |> validate_required([:contact_id, :type, :value, :is_primary, :allow_sms, :allow_email])
  end
end
