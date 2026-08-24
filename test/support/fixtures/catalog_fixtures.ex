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

  # GEN_RESOURCE_INSERT_POINT
end
