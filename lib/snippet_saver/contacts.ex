defmodule SnippetSaver.Contacts do
  @moduledoc """
  The Contacts context.
  """

  import Ecto.Query, warn: false
  alias SnippetSaver.Repo

  alias SnippetSaver.Contacts.Contact

  @doc """
  Returns the list of contacts.

  ## Examples

      iex> list_contacts()
      [%Contact{}, ...]

  """
  def list_contacts do
    Repo.all(Contact)
  end

  @doc """
  Gets a single contact.

  Raises `Ecto.NoResultsError` if the Contact does not exist.

  ## Examples

      iex> get_contact!(123)
      %Contact{}

      iex> get_contact!(456)
      ** (Ecto.NoResultsError)

  """
  def get_contact!(id), do: Repo.get!(Contact, id)

  def get_contact_with_assocs!(id) do
    Contact
    |> Repo.get!(id)
    |> Repo.preload([
      :contact_roles,
      :contact_methods,
      :addresses,
      :general_info,
      contact_roles: :contact_role_type
    ])
  end

  @doc """
  Creates a contact.

  ## Examples

      iex> create_contact(%{field: value})
      {:ok, %Contact{}}

      iex> create_contact(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_contact(attrs) do
    %Contact{}
    |> Contact.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a contact.

  ## Examples

      iex> update_contact(contact, %{field: new_value})
      {:ok, %Contact{}}

      iex> update_contact(contact, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_contact(%Contact{} = contact, attrs) do
    contact
    |> Contact.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a contact.

  ## Examples

      iex> delete_contact(contact)
      {:ok, %Contact{}}

      iex> delete_contact(contact)
      {:error, %Ecto.Changeset{}}

  """
  def delete_contact(%Contact{} = contact) do
    Repo.delete(contact)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking contact changes.

  ## Examples

      iex> change_contact(contact)
      %Ecto.Changeset{data: %Contact{}}

  """
  def change_contact(%Contact{} = contact, attrs \\ %{}) do
    Contact.changeset(contact, attrs)
  end

  alias SnippetSaver.Contacts.ContactRole

  @doc """
  Returns the list of contact_roles.

  ## Examples

      iex> list_contact_roles()
      [%ContactRole{}, ...]

  """
  def list_contact_roles do
    Repo.all(ContactRole)
  end

  def list_contact_roles_for_contact(contact_id) do
    ContactRole
    |> where([cr], cr.contact_id == ^contact_id)
    |> preload(:contact_role_type)
    |> Repo.all()
  end

  @doc """
  Gets a single contact_role.

  Raises `Ecto.NoResultsError` if the Contact role does not exist.

  ## Examples

      iex> get_contact_role!(123)
      %ContactRole{}

      iex> get_contact_role!(456)
      ** (Ecto.NoResultsError)

  """
  def get_contact_role!(id), do: Repo.get!(ContactRole, id)

  @doc """
  Creates a contact_role.

  ## Examples

      iex> create_contact_role(%{field: value})
      {:ok, %ContactRole{}}

      iex> create_contact_role(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_contact_role(attrs) do
    %ContactRole{}
    |> ContactRole.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a contact_role.

  ## Examples

      iex> update_contact_role(contact_role, %{field: new_value})
      {:ok, %ContactRole{}}

      iex> update_contact_role(contact_role, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_contact_role(%ContactRole{} = contact_role, attrs) do
    contact_role
    |> ContactRole.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a contact_role.

  ## Examples

      iex> delete_contact_role(contact_role)
      {:ok, %ContactRole{}}

      iex> delete_contact_role(contact_role)
      {:error, %Ecto.Changeset{}}

  """
  def delete_contact_role(%ContactRole{} = contact_role) do
    Repo.delete(contact_role)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking contact_role changes.

  ## Examples

      iex> change_contact_role(contact_role)
      %Ecto.Changeset{data: %ContactRole{}}

  """
  def change_contact_role(%ContactRole{} = contact_role, attrs \\ %{}) do
    ContactRole.changeset(contact_role, attrs)
  end

  alias SnippetSaver.Contacts.ContactMethod

  @doc """
  Returns the list of contact_methods.

  ## Examples

      iex> list_contact_methods()
      [%ContactMethod{}, ...]

  """
  def list_contact_methods do
    Repo.all(ContactMethod)
  end

  def list_contact_methods_for_contact(contact_id) do
    ContactMethod
    |> where([cm], cm.contact_id == ^contact_id)
    |> Repo.all()
  end

  @doc """
  Gets a single contact_method.

  Raises `Ecto.NoResultsError` if the Contact method does not exist.

  ## Examples

      iex> get_contact_method!(123)
      %ContactMethod{}

      iex> get_contact_method!(456)
      ** (Ecto.NoResultsError)

  """
  def get_contact_method!(id), do: Repo.get!(ContactMethod, id)

  @doc """
  Creates a contact_method.

  ## Examples

      iex> create_contact_method(%{field: value})
      {:ok, %ContactMethod{}}

      iex> create_contact_method(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_contact_method(attrs) do
    %ContactMethod{}
    |> ContactMethod.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a contact_method.

  ## Examples

      iex> update_contact_method(contact_method, %{field: new_value})
      {:ok, %ContactMethod{}}

      iex> update_contact_method(contact_method, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_contact_method(%ContactMethod{} = contact_method, attrs) do
    contact_method
    |> ContactMethod.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a contact_method.

  ## Examples

      iex> delete_contact_method(contact_method)
      {:ok, %ContactMethod{}}

      iex> delete_contact_method(contact_method)
      {:error, %Ecto.Changeset{}}

  """
  def delete_contact_method(%ContactMethod{} = contact_method) do
    Repo.delete(contact_method)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking contact_method changes.

  ## Examples

      iex> change_contact_method(contact_method)
      %Ecto.Changeset{data: %ContactMethod{}}

  """
  def change_contact_method(%ContactMethod{} = contact_method, attrs \\ %{}) do
    ContactMethod.changeset(contact_method, attrs)
  end

  alias SnippetSaver.Contacts.Address

  @doc """
  Returns the list of addresses.

  ## Examples

      iex> list_addresses()
      [%Address{}, ...]

  """
  def list_addresses do
    Repo.all(Address)
  end

  def list_addresses_for_contact(contact_id) do
    Address
    |> where([a], a.contact_id == ^contact_id)
    |> Repo.all()
  end

  @doc """
  Gets a single address.

  Raises `Ecto.NoResultsError` if the Address does not exist.

  ## Examples

      iex> get_address!(123)
      %Address{}

      iex> get_address!(456)
      ** (Ecto.NoResultsError)

  """
  def get_address!(id), do: Repo.get!(Address, id)

  @doc """
  Creates a address.

  ## Examples

      iex> create_address(%{field: value})
      {:ok, %Address{}}

      iex> create_address(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_address(attrs) do
    %Address{}
    |> Address.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a address.

  ## Examples

      iex> update_address(address, %{field: new_value})
      {:ok, %Address{}}

      iex> update_address(address, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_address(%Address{} = address, attrs) do
    address
    |> Address.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a address.

  ## Examples

      iex> delete_address(address)
      {:ok, %Address{}}

      iex> delete_address(address)
      {:error, %Ecto.Changeset{}}

  """
  def delete_address(%Address{} = address) do
    Repo.delete(address)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking address changes.

  ## Examples

      iex> change_address(address)
      %Ecto.Changeset{data: %Address{}}

  """
  def change_address(%Address{} = address, attrs \\ %{}) do
    Address.changeset(address, attrs)
  end

  alias SnippetSaver.Contacts.GeneralInfo

  @doc """
  Returns the list of contact_general_info.

  ## Examples

      iex> list_contact_general_info()
      [%GeneralInfo{}, ...]

  """
  def list_contact_general_info do
    Repo.all(GeneralInfo)
  end

  def get_general_info_for_contact(contact_id) do
    GeneralInfo
    |> where([gi], gi.contact_id == ^contact_id)
    |> Repo.one()
  end

  @doc """
  Gets a single general_info.

  Raises `Ecto.NoResultsError` if the General info does not exist.

  ## Examples

      iex> get_general_info!(123)
      %GeneralInfo{}

      iex> get_general_info!(456)
      ** (Ecto.NoResultsError)

  """
  def get_general_info!(id), do: Repo.get!(GeneralInfo, id)

  @doc """
  Creates a general_info.

  ## Examples

      iex> create_general_info(%{field: value})
      {:ok, %GeneralInfo{}}

      iex> create_general_info(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_general_info(attrs) do
    %GeneralInfo{}
    |> GeneralInfo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a general_info.

  ## Examples

      iex> update_general_info(general_info, %{field: new_value})
      {:ok, %GeneralInfo{}}

      iex> update_general_info(general_info, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_general_info(%GeneralInfo{} = general_info, attrs) do
    general_info
    |> GeneralInfo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a general_info.

  ## Examples

      iex> delete_general_info(general_info)
      {:ok, %GeneralInfo{}}

      iex> delete_general_info(general_info)
      {:error, %Ecto.Changeset{}}

  """
  def delete_general_info(%GeneralInfo{} = general_info) do
    Repo.delete(general_info)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking general_info changes.

  ## Examples

      iex> change_general_info(general_info)
      %Ecto.Changeset{data: %GeneralInfo{}}

  """
  def change_general_info(%GeneralInfo{} = general_info, attrs \\ %{}) do
    GeneralInfo.changeset(general_info, attrs)
  end

  alias SnippetSaver.Contacts.ContactRoleType

  @doc """
  Returns the list of contact_role_types.

  ## Examples

      iex> list_contact_role_types()
      [%ContactRoleType{}, ...]

  """
  def list_contact_role_types do
    Repo.all(ContactRoleType)
  end

  @doc """
  Gets a single contact_role_type.

  Raises `Ecto.NoResultsError` if the Contact role type does not exist.

  ## Examples

      iex> get_contact_role_type!(123)
      %ContactRoleType{}

      iex> get_contact_role_type!(456)
      ** (Ecto.NoResultsError)

  """
  def get_contact_role_type!(id), do: Repo.get!(ContactRoleType, id)

  @doc """
  Creates a contact_role_type.

  ## Examples

      iex> create_contact_role_type(%{field: value})
      {:ok, %ContactRoleType{}}

      iex> create_contact_role_type(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_contact_role_type(attrs) do
    %ContactRoleType{}
    |> ContactRoleType.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a contact_role_type.

  ## Examples

      iex> update_contact_role_type(contact_role_type, %{field: new_value})
      {:ok, %ContactRoleType{}}

      iex> update_contact_role_type(contact_role_type, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_contact_role_type(%ContactRoleType{} = contact_role_type, attrs) do
    contact_role_type
    |> ContactRoleType.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a contact_role_type.

  ## Examples

      iex> delete_contact_role_type(contact_role_type)
      {:ok, %ContactRoleType{}}

      iex> delete_contact_role_type(contact_role_type)
      {:error, %Ecto.Changeset{}}

  """
  def delete_contact_role_type(%ContactRoleType{} = contact_role_type) do
    Repo.delete(contact_role_type)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking contact_role_type changes.

  ## Examples

      iex> change_contact_role_type(contact_role_type)
      %Ecto.Changeset{data: %ContactRoleType{}}

  """
  def change_contact_role_type(%ContactRoleType{} = contact_role_type, attrs \\ %{}) do
    ContactRoleType.changeset(contact_role_type, attrs)
  end
end
