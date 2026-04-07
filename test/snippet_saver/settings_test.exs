defmodule SnippetSaver.SettingsTest do
  use SnippetSaver.DataCase

  alias SnippetSaver.Settings
  alias SnippetSaver.Settings.{Breed, Colour, MasterProblemTemplate, Species}

  setup do
    # Catalog list tests assume no pre-existing rows (sandbox still sees committed data from other envs).
    Repo.delete_all(Breed)
    Repo.delete_all(Species)
    Repo.delete_all(Colour)
    Repo.delete_all(MasterProblemTemplate)

    :ok
  end

  describe "species" do
    alias SnippetSaver.Settings.Species

    import SnippetSaver.SettingsFixtures

    @invalid_attrs %{name: nil}

    test "list_species/0 returns active species only" do
      species = species_fixture()
      assert Settings.list_species() == [species]
    end

    test "list_species/0 excludes archived species" do
      species = species_fixture()
      assert {:ok, _} = Settings.archive_species(species, nil)
      assert Settings.list_species() == []
    end

    test "get_species!/1 returns the species with given id" do
      species = species_fixture()
      assert Settings.get_species!(species.id) == species
    end

    test "create_species/1 with valid data creates a species" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Species{} = species} = Settings.create_species(valid_attrs)
      assert species.name == "some name"
    end

    test "create_species/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Settings.create_species(@invalid_attrs)
    end

    test "update_species/2 with valid data updates the species" do
      species = species_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Species{} = species} = Settings.update_species(species, update_attrs)
      assert species.name == "some updated name"
    end

    test "update_species/2 with invalid data returns error changeset" do
      species = species_fixture()
      assert {:error, %Ecto.Changeset{}} = Settings.update_species(species, @invalid_attrs)
      assert species == Settings.get_species!(species.id)
    end

    test "delete_species/1 archives the species" do
      species = species_fixture()
      assert {:ok, %Species{archived: true}} = Settings.delete_species(species)
      assert Settings.list_species() == []
      assert %Species{archived: true} = Settings.get_species!(species.id)
    end

    test "change_species/1 returns a species changeset" do
      species = species_fixture()
      assert %Ecto.Changeset{} = Settings.change_species(species)
    end
  end

  describe "breeds" do
    alias SnippetSaver.Settings.Breed

    import SnippetSaver.SettingsFixtures

    @invalid_attrs %{name: nil}

    test "list_breeds/0 returns active breeds only" do
      breed = breed_fixture()
      assert Settings.list_breeds() == [breed]
    end

    test "list_breeds/0 excludes archived breeds" do
      breed = breed_fixture()
      assert {:ok, _} = Settings.archive_breed(breed, nil)
      assert Settings.list_breeds() == []
    end

    test "get_breed!/1 returns the breed with given id" do
      breed = breed_fixture()
      assert Settings.get_breed!(breed.id) == breed
    end

    test "create_breed/1 with valid data creates a breed" do
      species = species_fixture()
      valid_attrs = %{name: "some name", species_id: species.id}

      assert {:ok, %Breed{} = breed} = Settings.create_breed(valid_attrs)
      assert breed.name == "some name"
    end

    test "create_breed/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Settings.create_breed(@invalid_attrs)
    end

    test "update_breed/2 with valid data updates the breed" do
      breed = breed_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Breed{} = breed} = Settings.update_breed(breed, update_attrs)
      assert breed.name == "some updated name"
    end

    test "update_breed/2 with invalid data returns error changeset" do
      breed = breed_fixture()
      assert {:error, %Ecto.Changeset{}} = Settings.update_breed(breed, @invalid_attrs)
      assert breed == Settings.get_breed!(breed.id)
    end

    test "delete_breed/1 archives the breed" do
      breed = breed_fixture()
      assert {:ok, %Breed{archived: true}} = Settings.delete_breed(breed)
      assert Settings.list_breeds() == []
      assert %Breed{archived: true} = Settings.get_breed!(breed.id)
    end

    test "change_breed/1 returns a breed changeset" do
      breed = breed_fixture()
      assert %Ecto.Changeset{} = Settings.change_breed(breed)
    end
  end

  describe "colours" do
    alias SnippetSaver.Settings.Colour

    import SnippetSaver.SettingsFixtures

    @invalid_attrs %{name: nil}

    test "list_colours/0 returns active colours only" do
      colour = colour_fixture()
      assert Settings.list_colours() == [colour]
    end

    test "list_colours/0 excludes archived colours" do
      colour = colour_fixture()
      assert {:ok, _} = Settings.archive_colour(colour, nil)
      assert Settings.list_colours() == []
    end

    test "get_colour!/1 returns the colour with given id" do
      colour = colour_fixture()
      assert Settings.get_colour!(colour.id) == colour
    end

    test "create_colour/1 with valid data creates a colour" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Colour{} = colour} = Settings.create_colour(valid_attrs)
      assert colour.name == "some name"
    end

    test "create_colour/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Settings.create_colour(@invalid_attrs)
    end

    test "update_colour/2 with valid data updates the colour" do
      colour = colour_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Colour{} = colour} = Settings.update_colour(colour, update_attrs)
      assert colour.name == "some updated name"
    end

    test "update_colour/2 with invalid data returns error changeset" do
      colour = colour_fixture()
      assert {:error, %Ecto.Changeset{}} = Settings.update_colour(colour, @invalid_attrs)
      assert colour == Settings.get_colour!(colour.id)
    end

    test "delete_colour/1 archives the colour" do
      colour = colour_fixture()
      assert {:ok, %Colour{archived: true}} = Settings.delete_colour(colour)
      assert Settings.list_colours() == []
      assert %Colour{archived: true} = Settings.get_colour!(colour.id)
    end

    test "change_colour/1 returns a colour changeset" do
      colour = colour_fixture()
      assert %Ecto.Changeset{} = Settings.change_colour(colour)
    end
  end

  describe "master_problem_templates" do
    alias SnippetSaver.Settings.MasterProblemTemplate

    import SnippetSaver.SettingsFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_master_problem_templates/0 returns active templates only" do
      master_problem_template = master_problem_template_fixture()
      assert Settings.list_master_problem_templates() == [master_problem_template]
    end

    test "list_master_problem_templates/0 excludes archived templates" do
      master_problem_template = master_problem_template_fixture()
      assert {:ok, _} = Settings.archive_master_problem_template(master_problem_template, nil)
      assert Settings.list_master_problem_templates() == []
    end

    test "get_master_problem_template!/1 returns the master_problem_template with given id" do
      master_problem_template = master_problem_template_fixture()
      assert Settings.get_master_problem_template!(master_problem_template.id) == master_problem_template
    end

    test "create_master_problem_template/1 with valid data creates a master_problem_template" do
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %MasterProblemTemplate{} = master_problem_template} = Settings.create_master_problem_template(valid_attrs)
      assert master_problem_template.name == "some name"
      assert master_problem_template.description == "some description"
    end

    test "create_master_problem_template/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Settings.create_master_problem_template(@invalid_attrs)
    end

    test "update_master_problem_template/2 with valid data updates the master_problem_template" do
      master_problem_template = master_problem_template_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %MasterProblemTemplate{} = master_problem_template} = Settings.update_master_problem_template(master_problem_template, update_attrs)
      assert master_problem_template.name == "some updated name"
      assert master_problem_template.description == "some updated description"
    end

    test "update_master_problem_template/2 with invalid data returns error changeset" do
      master_problem_template = master_problem_template_fixture()
      assert {:error, %Ecto.Changeset{}} = Settings.update_master_problem_template(master_problem_template, @invalid_attrs)
      assert master_problem_template == Settings.get_master_problem_template!(master_problem_template.id)
    end

    test "delete_master_problem_template/1 archives the master_problem_template" do
      master_problem_template = master_problem_template_fixture()
      assert {:ok, %MasterProblemTemplate{archived: true}} =
               Settings.delete_master_problem_template(master_problem_template)

      assert Settings.list_master_problem_templates() == []

      assert %MasterProblemTemplate{archived: true} =
               Settings.get_master_problem_template!(master_problem_template.id)
    end

    test "change_master_problem_template/1 returns a master_problem_template changeset" do
      master_problem_template = master_problem_template_fixture()
      assert %Ecto.Changeset{} = Settings.change_master_problem_template(master_problem_template)
    end
  end
end
