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

  # GEN_RESOURCE_INSERT_POINT
end
