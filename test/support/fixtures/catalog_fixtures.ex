defmodule SnippetSaver.CatalogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SnippetSaver.Catalog` context.
  """

  @doc """
  Generate a hear_about_option.
  """
  def hear_about_option_fixture(attrs \\ %{}) do
    {:ok, hear_about_option} =
      attrs
      |> Enum.into(%{
        name: "some value",
        is_active: true,
        category: "referral"
      })
      |> SnippetSaver.Catalog.create_hear_about_option()

    hear_about_option
  end

  @doc """
  Generate a vendor_contact.
  """
  def vendor_contact_fixture(attrs \\ %{}) do
    {:ok, vendor_contact} =
      attrs
      |> Enum.into(%{
        name: "some value",
        role: "some value"
      })
      |> SnippetSaver.Catalog.create_vendor_contact()

    vendor_contact
  end

  @doc """
  Generate a vendor.
  """
  def vendor_fixture(attrs \\ %{}) do
    {:ok, vendor} =
      attrs
      |> Enum.into(%{
        company_name: "some value"
      })
      |> SnippetSaver.Catalog.create_vendor()

    vendor
  end

  # GEN_RESOURCE_INSERT_POINT
end
