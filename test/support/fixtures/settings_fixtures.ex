defmodule SnippetSaver.SettingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SnippetSaver.Settings` context.
  """

  @doc """
  Generate a species.
  """
  def species_fixture(attrs \\ %{}) do
    {:ok, species} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> SnippetSaver.Settings.create_species()

    species
  end

  @doc """
  Generate a breed.
  """
  def breed_fixture(attrs \\ %{}) do
    merged =
      %{name: "some name"}
      |> Map.merge(if Map.has_key?(attrs, :species_id), do: %{}, else: %{species_id: species_fixture().id})
      |> Map.merge(attrs)

    {:ok, breed} = SnippetSaver.Settings.create_breed(merged)
    breed
  end

  @doc """
  Generate a colour.
  """
  def colour_fixture(attrs \\ %{}) do
    {:ok, colour} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> SnippetSaver.Settings.create_colour()

    colour
  end

  @doc """
  Generate a master_problem_template.
  """
  def master_problem_template_fixture(attrs \\ %{}) do
    {:ok, master_problem_template} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> SnippetSaver.Settings.create_master_problem_template()

    master_problem_template
  end
end
