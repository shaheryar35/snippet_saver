defmodule SnippetSaver.Settings do
  @moduledoc """
  The Settings context.
  """

  import Ecto.Query, warn: false
  alias SnippetSaver.Repo

  alias SnippetSaver.Settings.Species

  @doc """
  Active species only (`archived: false`), for dropdowns and associations.
  """
  def list_species do
    from(s in Species,
      where: s.archived == false,
      order_by: [asc: s.name]
    )
    |> Repo.all()
  end

  @doc """
  All species (including archived), for admin settings UI.
  """
  def list_species_for_admin do
    from(s in Species, order_by: [asc: s.name])
    |> preload([:inserted_by, :updated_by])
    |> Repo.all()
  end

  @doc """
  Gets a single species.

  Raises `Ecto.NoResultsError` if the Species does not exist.

  ## Examples

      iex> get_species!(123)
      %Species{}

      iex> get_species!(456)
      ** (Ecto.NoResultsError)

  """
  def get_species!(id), do: Repo.get!(Species, id)

  @doc """
  Creates a species. Pass `user_id` to record audit columns.
  """
  def create_species(attrs, user_id \\ nil) do
    %Species{}
    |> Species.changeset(attrs)
    |> apply_settings_insert_audit(user_id)
    |> Repo.insert()
  end

  @doc """
  Updates a species. Pass `user_id` to set `updated_by_id`.
  """
  def update_species(%Species{} = species, attrs, user_id \\ nil) do
    species
    |> Species.changeset(attrs)
    |> apply_settings_update_audit(user_id)
    |> Repo.update()
  end

  @doc """
  Soft-deletes a species (`archived: true`).
  """
  def archive_species(%Species{} = species, user_id \\ nil) do
    update_species(species, %{archived: true}, user_id)
  end

  @doc """
  Restores an archived species.
  """
  def restore_species(%Species{} = species, user_id \\ nil) do
    update_species(species, %{archived: false}, user_id)
  end

  @doc """
  Soft-deletes a species. Prefer `archive_species/2`.
  """
  def delete_species(%Species{} = species) do
    archive_species(species, nil)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking species changes.

  ## Examples

      iex> change_species(species)
      %Ecto.Changeset{data: %Species{}}

  """
  def change_species(%Species{} = species, attrs \\ %{}) do
    Species.changeset(species, attrs)
  end

  alias SnippetSaver.Settings.Breed

  @doc """
  Active breeds only (`archived: false`).
  """
  def list_breeds do
    from(b in Breed,
      where: b.archived == false,
      order_by: [asc: b.name]
    )
    |> Repo.all()
  end

  @doc """
  All breeds (including archived), for admin settings UI.
  """
  def list_breeds_for_admin do
    from(b in Breed, order_by: [asc: b.name])
    |> preload([:inserted_by, :updated_by, :species])
    |> Repo.all()
  end

  @doc """
  Gets a single breed.

  Raises `Ecto.NoResultsError` if the Breed does not exist.

  ## Examples

      iex> get_breed!(123)
      %Breed{}

      iex> get_breed!(456)
      ** (Ecto.NoResultsError)

  """
  def get_breed!(id), do: Repo.get!(Breed, id)

  @doc """
  Creates a breed. Pass `user_id` to record audit columns.
  """
  def create_breed(attrs, user_id \\ nil) do
    %Breed{}
    |> Breed.changeset(attrs)
    |> apply_settings_insert_audit(user_id)
    |> Repo.insert()
  end

  @doc """
  Updates a breed. Pass `user_id` to set `updated_by_id`.
  """
  def update_breed(%Breed{} = breed, attrs, user_id \\ nil) do
    breed
    |> Breed.changeset(attrs)
    |> apply_settings_update_audit(user_id)
    |> Repo.update()
  end

  @doc """
  Soft-deletes a breed (`archived: true`).
  """
  def archive_breed(%Breed{} = breed, user_id \\ nil) do
    update_breed(breed, %{archived: true}, user_id)
  end

  @doc """
  Restores an archived breed.
  """
  def restore_breed(%Breed{} = breed, user_id \\ nil) do
    update_breed(breed, %{archived: false}, user_id)
  end

  @doc """
  Soft-deletes a breed. Prefer `archive_breed/2`.
  """
  def delete_breed(%Breed{} = breed) do
    archive_breed(breed, nil)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking breed changes.

  ## Examples

      iex> change_breed(breed)
      %Ecto.Changeset{data: %Breed{}}

  """
  def change_breed(%Breed{} = breed, attrs \\ %{}) do
    Breed.changeset(breed, attrs)
  end

  alias SnippetSaver.Settings.Colour

  @doc """
  Active colours only (`archived: false`).
  """
  def list_colours do
    from(c in Colour,
      where: c.archived == false,
      order_by: [asc: c.name]
    )
    |> Repo.all()
  end

  @doc """
  All colours (including archived), for admin settings UI.
  """
  def list_colours_for_admin do
    from(c in Colour, order_by: [asc: c.name])
    |> preload([:inserted_by, :updated_by])
    |> Repo.all()
  end

  @doc """
  Gets a single colour.

  Raises `Ecto.NoResultsError` if the Colour does not exist.

  ## Examples

      iex> get_colour!(123)
      %Colour{}

      iex> get_colour!(456)
      ** (Ecto.NoResultsError)

  """
  def get_colour!(id), do: Repo.get!(Colour, id)

  @doc """
  Creates a colour. Pass `user_id` to record audit columns.
  """
  def create_colour(attrs, user_id \\ nil) do
    %Colour{}
    |> Colour.changeset(attrs)
    |> apply_settings_insert_audit(user_id)
    |> Repo.insert()
  end

  @doc """
  Updates a colour. Pass `user_id` to set `updated_by_id`.
  """
  def update_colour(%Colour{} = colour, attrs, user_id \\ nil) do
    colour
    |> Colour.changeset(attrs)
    |> apply_settings_update_audit(user_id)
    |> Repo.update()
  end

  @doc """
  Soft-deletes a colour (`archived: true`).
  """
  def archive_colour(%Colour{} = colour, user_id \\ nil) do
    update_colour(colour, %{archived: true}, user_id)
  end

  @doc """
  Restores an archived colour.
  """
  def restore_colour(%Colour{} = colour, user_id \\ nil) do
    update_colour(colour, %{archived: false}, user_id)
  end

  @doc """
  Soft-deletes a colour. Prefer `archive_colour/2`.
  """
  def delete_colour(%Colour{} = colour) do
    archive_colour(colour, nil)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking colour changes.

  ## Examples

      iex> change_colour(colour)
      %Ecto.Changeset{data: %Colour{}}

  """
  def change_colour(%Colour{} = colour, attrs \\ %{}) do
    Colour.changeset(colour, attrs)
  end

  alias SnippetSaver.Settings.MasterProblemTemplate

  @doc """
  Active master problem templates only (`archived: false`).
  """
  def list_master_problem_templates do
    from(m in MasterProblemTemplate,
      where: m.archived == false,
      order_by: [asc: m.name]
    )
    |> Repo.all()
  end

  @doc """
  All master problem templates (including archived), for admin settings UI.
  """
  def list_master_problem_templates_for_admin do
    from(m in MasterProblemTemplate, order_by: [asc: m.name])
    |> preload([:inserted_by, :updated_by])
    |> Repo.all()
  end

  @doc """
  Gets a single master_problem_template.

  Raises `Ecto.NoResultsError` if the Master problem template does not exist.

  ## Examples

      iex> get_master_problem_template!(123)
      %MasterProblemTemplate{}

      iex> get_master_problem_template!(456)
      ** (Ecto.NoResultsError)

  """
  def get_master_problem_template!(id), do: Repo.get!(MasterProblemTemplate, id)

  @doc """
  Creates a master_problem_template. Pass `user_id` to record audit columns.
  """
  def create_master_problem_template(attrs, user_id \\ nil) do
    %MasterProblemTemplate{}
    |> MasterProblemTemplate.changeset(attrs)
    |> apply_settings_insert_audit(user_id)
    |> Repo.insert()
  end

  @doc """
  Updates a master_problem_template. Pass `user_id` to set `updated_by_id`.
  """
  def update_master_problem_template(
        %MasterProblemTemplate{} = master_problem_template,
        attrs,
        user_id \\ nil
      ) do
    master_problem_template
    |> MasterProblemTemplate.changeset(attrs)
    |> apply_settings_update_audit(user_id)
    |> Repo.update()
  end

  @doc """
  Soft-deletes a master_problem_template (`archived: true`).
  """
  def archive_master_problem_template(
        %MasterProblemTemplate{} = master_problem_template,
        user_id \\ nil
      ) do
    update_master_problem_template(master_problem_template, %{archived: true}, user_id)
  end

  @doc """
  Restores an archived master_problem_template.
  """
  def restore_master_problem_template(
        %MasterProblemTemplate{} = master_problem_template,
        user_id \\ nil
      ) do
    update_master_problem_template(master_problem_template, %{archived: false}, user_id)
  end

  @doc """
  Soft-deletes a master_problem_template. Prefer `archive_master_problem_template/2`.
  """
  def delete_master_problem_template(%MasterProblemTemplate{} = master_problem_template) do
    archive_master_problem_template(master_problem_template, nil)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking master_problem_template changes.

  ## Examples

      iex> change_master_problem_template(master_problem_template)
      %Ecto.Changeset{data: %MasterProblemTemplate{}}

  """
  def change_master_problem_template(%MasterProblemTemplate{} = master_problem_template, attrs \\ %{}) do
    MasterProblemTemplate.changeset(master_problem_template, attrs)
  end

  defp apply_settings_insert_audit(changeset, nil), do: changeset

  defp apply_settings_insert_audit(changeset, user_id) do
    changeset
    |> Ecto.Changeset.put_change(:inserted_by_id, user_id)
    |> Ecto.Changeset.put_change(:updated_by_id, user_id)
  end

  defp apply_settings_update_audit(changeset, nil), do: changeset

  defp apply_settings_update_audit(changeset, user_id) do
    Ecto.Changeset.put_change(changeset, :updated_by_id, user_id)
  end
end
