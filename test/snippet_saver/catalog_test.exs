defmodule SnippetSaver.CatalogTest do
  use SnippetSaver.DataCase

  alias SnippetSaver.Catalog

  describe "hear_about_options" do
    alias SnippetSaver.Catalog.HearAboutOption

    import SnippetSaver.CatalogFixtures

    @invalid_attrs %{name: nil, is_active: nil}

    test "list_hear_about_options/0 returns all hear about option" do
      hear_about_option = hear_about_option_fixture()
      assert Catalog.list_hear_about_options() == [hear_about_option]
    end

    test "list_hear_about_options/0 excludes archived hear about option" do
      hear_about_option = hear_about_option_fixture()
      assert {:ok, _} = Catalog.archive_hear_about_option(hear_about_option)
      assert Catalog.list_hear_about_options() == []
    end

    test "get_hear_about_option!/1 returns the hear_about_option with given id" do
      hear_about_option = hear_about_option_fixture()
      assert Catalog.get_hear_about_option!(hear_about_option.id) == hear_about_option
    end

    test "create_hear_about_option/1 with valid data creates a hear_about_option" do
      valid_attrs = %{name: "some value", is_active: true, category: "referral"}
      assert {:ok, %HearAboutOption{}} = Catalog.create_hear_about_option(valid_attrs)
    end

    test "create_hear_about_option/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Catalog.create_hear_about_option(@invalid_attrs)
    end

    test "update_hear_about_option/2 with valid data updates the hear_about_option" do
      hear_about_option = hear_about_option_fixture()

      assert {:ok, %HearAboutOption{}} =
               Catalog.update_hear_about_option(hear_about_option, %{name: "some value"})
    end

    test "update_hear_about_option/2 with invalid data returns error changeset" do
      hear_about_option = hear_about_option_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Catalog.update_hear_about_option(hear_about_option, @invalid_attrs)

      assert hear_about_option == Catalog.get_hear_about_option!(hear_about_option.id)
    end

    test "archive_hear_about_option/1 removes the hear_about_option from the active list" do
      hear_about_option = hear_about_option_fixture()
      assert {:ok, _} = Catalog.archive_hear_about_option(hear_about_option)
    end

    test "change_hear_about_option/1 returns a hear_about_option changeset" do
      hear_about_option = hear_about_option_fixture()
      assert %Ecto.Changeset{} = Catalog.change_hear_about_option(hear_about_option)
    end
  end

  describe "vendor_contacts" do
    alias SnippetSaver.Catalog.VendorContact

    import SnippetSaver.CatalogFixtures

    @invalid_attrs %{name: nil}

    test "list_vendor_contacts/0 returns all vendor contact" do
      vendor_contact = vendor_contact_fixture()
      assert Catalog.list_vendor_contacts() == [vendor_contact]
    end

    test "get_vendor_contact!/1 returns the vendor_contact with given id" do
      vendor_contact = vendor_contact_fixture()
      assert Catalog.get_vendor_contact!(vendor_contact.id) == vendor_contact
    end

    test "create_vendor_contact/1 with valid data creates a vendor_contact" do
      valid_attrs = %{name: "some value", role: "some value"}
      assert {:ok, %VendorContact{}} = Catalog.create_vendor_contact(valid_attrs)
    end

    test "create_vendor_contact/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Catalog.create_vendor_contact(@invalid_attrs)
    end

    test "update_vendor_contact/2 with valid data updates the vendor_contact" do
      vendor_contact = vendor_contact_fixture()

      assert {:ok, %VendorContact{}} =
               Catalog.update_vendor_contact(vendor_contact, %{name: "some value"})
    end

    test "update_vendor_contact/2 with invalid data returns error changeset" do
      vendor_contact = vendor_contact_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Catalog.update_vendor_contact(vendor_contact, @invalid_attrs)

      assert vendor_contact == Catalog.get_vendor_contact!(vendor_contact.id)
    end

    test "delete_vendor_contact/1 removes the vendor_contact from the active list" do
      vendor_contact = vendor_contact_fixture()
      assert {:ok, _} = Catalog.delete_vendor_contact(vendor_contact)
    end

    test "change_vendor_contact/1 returns a vendor_contact changeset" do
      vendor_contact = vendor_contact_fixture()
      assert %Ecto.Changeset{} = Catalog.change_vendor_contact(vendor_contact)
    end
  end

  describe "vendors" do
    alias SnippetSaver.Catalog.Vendor

    import SnippetSaver.CatalogFixtures

    @invalid_attrs %{company_name: nil}

    test "list_vendors/0 returns all vendor" do
      vendor = vendor_fixture()
      assert Catalog.list_vendors() == [vendor]
    end

    test "list_vendors/0 excludes archived vendor" do
      vendor = vendor_fixture()
      assert {:ok, _} = Catalog.archive_vendor(vendor)
      assert Catalog.list_vendors() == []
    end

    test "get_vendor!/1 returns the vendor with given id" do
      vendor = vendor_fixture()
      assert Catalog.get_vendor!(vendor.id) == vendor
    end

    test "create_vendor/1 with valid data creates a vendor" do
      valid_attrs = %{company_name: "some value"}
      assert {:ok, %Vendor{}} = Catalog.create_vendor(valid_attrs)
    end

    test "create_vendor/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Catalog.create_vendor(@invalid_attrs)
    end

    test "update_vendor/2 with valid data updates the vendor" do
      vendor = vendor_fixture()
      assert {:ok, %Vendor{}} = Catalog.update_vendor(vendor, %{company_name: "some value"})
    end

    test "update_vendor/2 with invalid data returns error changeset" do
      vendor = vendor_fixture()
      assert {:error, %Ecto.Changeset{}} = Catalog.update_vendor(vendor, @invalid_attrs)
      assert vendor == Catalog.get_vendor!(vendor.id)
    end

    test "archive_vendor/1 removes the vendor from the active list" do
      vendor = vendor_fixture()
      assert {:ok, _} = Catalog.archive_vendor(vendor)
    end

    test "change_vendor/1 returns a vendor changeset" do
      vendor = vendor_fixture()
      assert %Ecto.Changeset{} = Catalog.change_vendor(vendor)
    end
  end

  # GEN_RESOURCE_INSERT_POINT
end
