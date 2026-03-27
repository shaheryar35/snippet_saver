defmodule SnippetSaver.ContactsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SnippetSaver.Contacts` context.
  """

  @doc """
  Generate a contact.
  """
  def contact_fixture(attrs \\ %{}) do
    {:ok, contact} =
      attrs
      |> Enum.into(%{
        business_code: "some business_code",
        discount_group_id: 42,
        financial_group_id: 42,
        first_name: "some first_name",
        hear_about_option_id: 42,
        is_individual: true,
        last_name: "some last_name",
        notes: "some notes",
        notes_important: true,
        preferred_contact_method_id: 42,
        title: "some title"
      })
      |> SnippetSaver.Contacts.create_contact()

    contact
  end

  @doc """
  Generate a contact_role.
  """
  def contact_role_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{})
      |> Map.put_new_lazy(:contact_id, fn -> contact_fixture().id end)
      |> Map.put_new_lazy(:contact_role_type_id, fn -> contact_role_type_fixture().id end)

    {:ok, contact_role} = SnippetSaver.Contacts.create_contact_role(attrs)
    contact_role
  end

  @doc """
  Generate a contact_method.
  """
  def contact_method_fixture(attrs \\ %{}) do
    {:ok, contact_method} =
      attrs
      |> Enum.into(%{
        allow_email: true,
        allow_sms: true,
        is_primary: true,
        type: "some type",
        value: "some value"
      })
      |> SnippetSaver.Contacts.create_contact_method()

    contact_method
  end

  @doc """
  Generate a address.
  """
  def address_fixture(attrs \\ %{}) do
    {:ok, address} =
      attrs
      |> Enum.into(%{
        address_name: "some address_name",
        city: "some city",
        country: "some country",
        latitude: "120.5",
        longitude: "120.5",
        postcode: "some postcode",
        street_address: "some street_address",
        suburb: "some suburb",
        type: "some type"
      })
      |> SnippetSaver.Contacts.create_address()

    address
  end

  @doc """
  Generate a general_info.
  """
  def general_info_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        consolidate_invoices: true,
        contact_details_confirmed: true,
        credit_limit_name: "some credit_limit_name",
        date_of_birth: ~D[2026-03-25],
        driver_license_expiry: ~D[2026-03-25],
        driver_license_issuer: "some driver_license_issuer",
        driver_license_number: "some driver_license_number",
        hospital: "some hospital",
        national_id_number: "some national_id_number",
        passport_number: "some passport_number",
        pet_insurance_supplier: "some pet_insurance_supplier",
        website: "some website"
      })
      |> Map.put_new_lazy(:contact_id, fn -> contact_fixture().id end)

    {:ok, general_info} = SnippetSaver.Contacts.create_general_info(attrs)

    general_info
  end

  @doc """
  Generate a unique contact_role_type name.
  """
  def unique_contact_role_type_name, do: "some name#{System.unique_integer([:positive])}"

  @doc """
  Generate a contact_role_type.
  """
  def contact_role_type_fixture(attrs \\ %{}) do
    {:ok, contact_role_type} =
      attrs
      |> Enum.into(%{
        name: unique_contact_role_type_name()
      })
      |> SnippetSaver.Contacts.create_contact_role_type()

    contact_role_type
  end
end
