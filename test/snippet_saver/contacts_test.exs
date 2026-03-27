defmodule SnippetSaver.ContactsTest do
  use SnippetSaver.DataCase

  alias SnippetSaver.Contacts

  describe "contacts" do
    alias SnippetSaver.Contacts.Contact

    import SnippetSaver.ContactsFixtures

    @invalid_attrs %{title: nil, business_code: nil, is_individual: nil, first_name: nil, last_name: nil, notes: nil, notes_important: nil, preferred_contact_method_id: nil, hear_about_option_id: nil, discount_group_id: nil, financial_group_id: nil}

    test "list_contacts/0 returns all contacts" do
      contact = contact_fixture()
      assert Contacts.list_contacts() == [contact]
    end

    test "get_contact!/1 returns the contact with given id" do
      contact = contact_fixture()
      assert Contacts.get_contact!(contact.id) == contact
    end

    test "create_contact/1 with valid data creates a contact" do
      valid_attrs = %{title: "some title", business_code: "some business_code", is_individual: true, first_name: "some first_name", last_name: "some last_name", notes: "some notes", notes_important: true, preferred_contact_method_id: 42, hear_about_option_id: 42, discount_group_id: 42, financial_group_id: 42}

      assert {:ok, %Contact{} = contact} = Contacts.create_contact(valid_attrs)
      assert contact.title == "some title"
      assert contact.business_code == "some business_code"
      assert contact.is_individual == true
      assert contact.first_name == "some first_name"
      assert contact.last_name == "some last_name"
      assert contact.notes == "some notes"
      assert contact.notes_important == true
      assert contact.preferred_contact_method_id == 42
      assert contact.hear_about_option_id == 42
      assert contact.discount_group_id == 42
      assert contact.financial_group_id == 42
    end

    test "create_contact/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contacts.create_contact(@invalid_attrs)
    end

    test "update_contact/2 with valid data updates the contact" do
      contact = contact_fixture()
      update_attrs = %{title: "some updated title", business_code: "some updated business_code", is_individual: false, first_name: "some updated first_name", last_name: "some updated last_name", notes: "some updated notes", notes_important: false, preferred_contact_method_id: 43, hear_about_option_id: 43, discount_group_id: 43, financial_group_id: 43}

      assert {:ok, %Contact{} = contact} = Contacts.update_contact(contact, update_attrs)
      assert contact.title == "some updated title"
      assert contact.business_code == "some updated business_code"
      assert contact.is_individual == false
      assert contact.first_name == "some updated first_name"
      assert contact.last_name == "some updated last_name"
      assert contact.notes == "some updated notes"
      assert contact.notes_important == false
      assert contact.preferred_contact_method_id == 43
      assert contact.hear_about_option_id == 43
      assert contact.discount_group_id == 43
      assert contact.financial_group_id == 43
    end

    test "update_contact/2 with invalid data returns error changeset" do
      contact = contact_fixture()
      assert {:error, %Ecto.Changeset{}} = Contacts.update_contact(contact, @invalid_attrs)
      assert contact == Contacts.get_contact!(contact.id)
    end

    test "delete_contact/1 deletes the contact" do
      contact = contact_fixture()
      assert {:ok, %Contact{}} = Contacts.delete_contact(contact)
      assert_raise Ecto.NoResultsError, fn -> Contacts.get_contact!(contact.id) end
    end

    test "change_contact/1 returns a contact changeset" do
      contact = contact_fixture()
      assert %Ecto.Changeset{} = Contacts.change_contact(contact)
    end
  end

  describe "contact_roles" do
    alias SnippetSaver.Contacts.ContactRole

    import SnippetSaver.ContactsFixtures

    @invalid_attrs %{contact_id: nil, contact_role_type_id: nil}

    test "list_contact_roles/0 returns all contact_roles" do
      contact_role = contact_role_fixture()
      assert Contacts.list_contact_roles() == [contact_role]
    end

    test "get_contact_role!/1 returns the contact_role with given id" do
      contact_role = contact_role_fixture()
      assert Contacts.get_contact_role!(contact_role.id) == contact_role
    end

    test "create_contact_role/1 with valid data creates a contact_role" do
      contact = contact_fixture()
      role_type = contact_role_type_fixture()
      valid_attrs = %{contact_id: contact.id, contact_role_type_id: role_type.id}

      assert {:ok, %ContactRole{} = contact_role} = Contacts.create_contact_role(valid_attrs)
      assert contact_role.contact_id == contact.id
      assert contact_role.contact_role_type_id == role_type.id
    end

    test "create_contact_role/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contacts.create_contact_role(@invalid_attrs)
    end

    test "update_contact_role/2 with valid data updates the contact_role" do
      contact_role = contact_role_fixture()
      other_role_type = contact_role_type_fixture()
      update_attrs = %{contact_role_type_id: other_role_type.id}

      assert {:ok, %ContactRole{} = contact_role} =
               Contacts.update_contact_role(contact_role, update_attrs)

      assert contact_role.contact_role_type_id == other_role_type.id
    end

    test "update_contact_role/2 with invalid data returns error changeset" do
      contact_role = contact_role_fixture()
      assert {:error, %Ecto.Changeset{}} = Contacts.update_contact_role(contact_role, @invalid_attrs)
      assert contact_role == Contacts.get_contact_role!(contact_role.id)
    end

    test "delete_contact_role/1 deletes the contact_role" do
      contact_role = contact_role_fixture()
      assert {:ok, %ContactRole{}} = Contacts.delete_contact_role(contact_role)
      assert_raise Ecto.NoResultsError, fn -> Contacts.get_contact_role!(contact_role.id) end
    end

    test "change_contact_role/1 returns a contact_role changeset" do
      contact_role = contact_role_fixture()
      assert %Ecto.Changeset{} = Contacts.change_contact_role(contact_role)
    end
  end

  describe "contact_methods" do
    alias SnippetSaver.Contacts.ContactMethod

    import SnippetSaver.ContactsFixtures

    @invalid_attrs %{type: nil, value: nil, is_primary: nil, allow_sms: nil, allow_email: nil}

    test "list_contact_methods/0 returns all contact_methods" do
      contact_method = contact_method_fixture()
      assert Contacts.list_contact_methods() == [contact_method]
    end

    test "get_contact_method!/1 returns the contact_method with given id" do
      contact_method = contact_method_fixture()
      assert Contacts.get_contact_method!(contact_method.id) == contact_method
    end

    test "create_contact_method/1 with valid data creates a contact_method" do
      valid_attrs = %{type: "some type", value: "some value", is_primary: true, allow_sms: true, allow_email: true}

      assert {:ok, %ContactMethod{} = contact_method} = Contacts.create_contact_method(valid_attrs)
      assert contact_method.type == "some type"
      assert contact_method.value == "some value"
      assert contact_method.is_primary == true
      assert contact_method.allow_sms == true
      assert contact_method.allow_email == true
    end

    test "create_contact_method/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contacts.create_contact_method(@invalid_attrs)
    end

    test "update_contact_method/2 with valid data updates the contact_method" do
      contact_method = contact_method_fixture()
      update_attrs = %{type: "some updated type", value: "some updated value", is_primary: false, allow_sms: false, allow_email: false}

      assert {:ok, %ContactMethod{} = contact_method} = Contacts.update_contact_method(contact_method, update_attrs)
      assert contact_method.type == "some updated type"
      assert contact_method.value == "some updated value"
      assert contact_method.is_primary == false
      assert contact_method.allow_sms == false
      assert contact_method.allow_email == false
    end

    test "update_contact_method/2 with invalid data returns error changeset" do
      contact_method = contact_method_fixture()
      assert {:error, %Ecto.Changeset{}} = Contacts.update_contact_method(contact_method, @invalid_attrs)
      assert contact_method == Contacts.get_contact_method!(contact_method.id)
    end

    test "delete_contact_method/1 deletes the contact_method" do
      contact_method = contact_method_fixture()
      assert {:ok, %ContactMethod{}} = Contacts.delete_contact_method(contact_method)
      assert_raise Ecto.NoResultsError, fn -> Contacts.get_contact_method!(contact_method.id) end
    end

    test "change_contact_method/1 returns a contact_method changeset" do
      contact_method = contact_method_fixture()
      assert %Ecto.Changeset{} = Contacts.change_contact_method(contact_method)
    end
  end

  describe "addresses" do
    alias SnippetSaver.Contacts.Address

    import SnippetSaver.ContactsFixtures

    @invalid_attrs %{type: nil, street_address: nil, suburb: nil, postcode: nil, city: nil, country: nil, longitude: nil, latitude: nil, address_name: nil}

    test "list_addresses/0 returns all addresses" do
      address = address_fixture()
      assert Contacts.list_addresses() == [address]
    end

    test "get_address!/1 returns the address with given id" do
      address = address_fixture()
      assert Contacts.get_address!(address.id) == address
    end

    test "create_address/1 with valid data creates a address" do
      valid_attrs = %{type: "some type", street_address: "some street_address", suburb: "some suburb", postcode: "some postcode", city: "some city", country: "some country", longitude: "120.5", latitude: "120.5", address_name: "some address_name"}

      assert {:ok, %Address{} = address} = Contacts.create_address(valid_attrs)
      assert address.type == "some type"
      assert address.street_address == "some street_address"
      assert address.suburb == "some suburb"
      assert address.postcode == "some postcode"
      assert address.city == "some city"
      assert address.country == "some country"
      assert address.longitude == Decimal.new("120.5")
      assert address.latitude == Decimal.new("120.5")
      assert address.address_name == "some address_name"
    end

    test "create_address/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contacts.create_address(@invalid_attrs)
    end

    test "update_address/2 with valid data updates the address" do
      address = address_fixture()
      update_attrs = %{type: "some updated type", street_address: "some updated street_address", suburb: "some updated suburb", postcode: "some updated postcode", city: "some updated city", country: "some updated country", longitude: "456.7", latitude: "456.7", address_name: "some updated address_name"}

      assert {:ok, %Address{} = address} = Contacts.update_address(address, update_attrs)
      assert address.type == "some updated type"
      assert address.street_address == "some updated street_address"
      assert address.suburb == "some updated suburb"
      assert address.postcode == "some updated postcode"
      assert address.city == "some updated city"
      assert address.country == "some updated country"
      assert address.longitude == Decimal.new("456.7")
      assert address.latitude == Decimal.new("456.7")
      assert address.address_name == "some updated address_name"
    end

    test "update_address/2 with invalid data returns error changeset" do
      address = address_fixture()
      assert {:error, %Ecto.Changeset{}} = Contacts.update_address(address, @invalid_attrs)
      assert address == Contacts.get_address!(address.id)
    end

    test "delete_address/1 deletes the address" do
      address = address_fixture()
      assert {:ok, %Address{}} = Contacts.delete_address(address)
      assert_raise Ecto.NoResultsError, fn -> Contacts.get_address!(address.id) end
    end

    test "change_address/1 returns a address changeset" do
      address = address_fixture()
      assert %Ecto.Changeset{} = Contacts.change_address(address)
    end
  end

  describe "contact_general_info" do
    alias SnippetSaver.Contacts.GeneralInfo

    import SnippetSaver.ContactsFixtures

    # Omit booleans: DB columns are NOT NULL; setting them to nil causes DB errors instead of changeset errors.
    @invalid_attrs %{
      contact_id: nil,
      hospital: nil,
      website: nil,
      pet_insurance_supplier: nil,
      date_of_birth: nil,
      driver_license_number: nil,
      driver_license_issuer: nil,
      driver_license_expiry: nil,
      national_id_number: nil,
      passport_number: nil,
      credit_limit_name: nil
    }

    test "list_contact_general_info/0 returns all contact_general_info" do
      general_info = general_info_fixture()
      assert Contacts.list_contact_general_info() == [general_info]
    end

    test "get_general_info!/1 returns the general_info with given id" do
      general_info = general_info_fixture()
      assert Contacts.get_general_info!(general_info.id) == general_info
    end

    test "create_general_info/1 with valid data creates a general_info" do
      contact = contact_fixture()

      valid_attrs = %{
        contact_id: contact.id,
        hospital: "some hospital",
        website: "some website",
        pet_insurance_supplier: "some pet_insurance_supplier",
        date_of_birth: ~D[2026-03-25],
        driver_license_number: "some driver_license_number",
        driver_license_issuer: "some driver_license_issuer",
        driver_license_expiry: ~D[2026-03-25],
        national_id_number: "some national_id_number",
        passport_number: "some passport_number",
        credit_limit_name: "some credit_limit_name",
        contact_details_confirmed: true,
        consolidate_invoices: true
      }

      assert {:ok, %GeneralInfo{} = general_info} = Contacts.create_general_info(valid_attrs)
      assert general_info.hospital == "some hospital"
      assert general_info.website == "some website"
      assert general_info.pet_insurance_supplier == "some pet_insurance_supplier"
      assert general_info.date_of_birth == ~D[2026-03-25]
      assert general_info.driver_license_number == "some driver_license_number"
      assert general_info.driver_license_issuer == "some driver_license_issuer"
      assert general_info.driver_license_expiry == ~D[2026-03-25]
      assert general_info.national_id_number == "some national_id_number"
      assert general_info.passport_number == "some passport_number"
      assert general_info.credit_limit_name == "some credit_limit_name"
      assert general_info.contact_details_confirmed == true
      assert general_info.consolidate_invoices == true
    end

    test "create_general_info/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contacts.create_general_info(@invalid_attrs)
    end

    test "update_general_info/2 with valid data updates the general_info" do
      general_info = general_info_fixture()
      update_attrs = %{hospital: "some updated hospital", website: "some updated website", pet_insurance_supplier: "some updated pet_insurance_supplier", date_of_birth: ~D[2026-03-26], driver_license_number: "some updated driver_license_number", driver_license_issuer: "some updated driver_license_issuer", driver_license_expiry: ~D[2026-03-26], national_id_number: "some updated national_id_number", passport_number: "some updated passport_number", credit_limit_name: "some updated credit_limit_name", contact_details_confirmed: false, consolidate_invoices: false}

      assert {:ok, %GeneralInfo{} = general_info} = Contacts.update_general_info(general_info, update_attrs)
      assert general_info.hospital == "some updated hospital"
      assert general_info.website == "some updated website"
      assert general_info.pet_insurance_supplier == "some updated pet_insurance_supplier"
      assert general_info.date_of_birth == ~D[2026-03-26]
      assert general_info.driver_license_number == "some updated driver_license_number"
      assert general_info.driver_license_issuer == "some updated driver_license_issuer"
      assert general_info.driver_license_expiry == ~D[2026-03-26]
      assert general_info.national_id_number == "some updated national_id_number"
      assert general_info.passport_number == "some updated passport_number"
      assert general_info.credit_limit_name == "some updated credit_limit_name"
      assert general_info.contact_details_confirmed == false
      assert general_info.consolidate_invoices == false
    end

    test "update_general_info/2 with invalid data returns error changeset" do
      general_info = general_info_fixture()
      assert {:error, %Ecto.Changeset{}} = Contacts.update_general_info(general_info, @invalid_attrs)
      assert general_info == Contacts.get_general_info!(general_info.id)
    end

    test "delete_general_info/1 deletes the general_info" do
      general_info = general_info_fixture()
      assert {:ok, %GeneralInfo{}} = Contacts.delete_general_info(general_info)
      assert_raise Ecto.NoResultsError, fn -> Contacts.get_general_info!(general_info.id) end
    end

    test "change_general_info/1 returns a general_info changeset" do
      general_info = general_info_fixture()
      assert %Ecto.Changeset{} = Contacts.change_general_info(general_info)
    end
  end

  describe "contact_role_types" do
    alias SnippetSaver.Contacts.ContactRoleType

    import SnippetSaver.ContactsFixtures

    @invalid_attrs %{name: nil}

    test "list_contact_role_types/0 returns all contact_role_types" do
      contact_role_type = contact_role_type_fixture()
      assert Contacts.list_contact_role_types() == [contact_role_type]
    end

    test "get_contact_role_type!/1 returns the contact_role_type with given id" do
      contact_role_type = contact_role_type_fixture()
      assert Contacts.get_contact_role_type!(contact_role_type.id) == contact_role_type
    end

    test "create_contact_role_type/1 with valid data creates a contact_role_type" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %ContactRoleType{} = contact_role_type} = Contacts.create_contact_role_type(valid_attrs)
      assert contact_role_type.name == "some name"
    end

    test "create_contact_role_type/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contacts.create_contact_role_type(@invalid_attrs)
    end

    test "update_contact_role_type/2 with valid data updates the contact_role_type" do
      contact_role_type = contact_role_type_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %ContactRoleType{} = contact_role_type} = Contacts.update_contact_role_type(contact_role_type, update_attrs)
      assert contact_role_type.name == "some updated name"
    end

    test "update_contact_role_type/2 with invalid data returns error changeset" do
      contact_role_type = contact_role_type_fixture()
      assert {:error, %Ecto.Changeset{}} = Contacts.update_contact_role_type(contact_role_type, @invalid_attrs)
      assert contact_role_type == Contacts.get_contact_role_type!(contact_role_type.id)
    end

    test "delete_contact_role_type/1 deletes the contact_role_type" do
      contact_role_type = contact_role_type_fixture()
      assert {:ok, %ContactRoleType{}} = Contacts.delete_contact_role_type(contact_role_type)
      assert_raise Ecto.NoResultsError, fn -> Contacts.get_contact_role_type!(contact_role_type.id) end
    end

    test "change_contact_role_type/1 returns a contact_role_type changeset" do
      contact_role_type = contact_role_type_fixture()
      assert %Ecto.Changeset{} = Contacts.change_contact_role_type(contact_role_type)
    end
  end
end
