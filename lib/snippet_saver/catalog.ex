defmodule SnippetSaver.Catalog do
  @moduledoc """
  The Catalog context.
  """

  import Ecto.Query, warn: false
  alias SnippetSaver.Repo

  alias SnippetSaver.Catalog.HearAboutOption

  @doc """
  Active hear about options only (`archived: false`), for dropdowns and associations.
  """
  def list_hear_about_options do
    from(x in HearAboutOption, where: x.archived == false, order_by: [asc: x.id])
    |> Repo.all()
  end

  @doc """
  All hear about options (including archived), for admin views.
  """
  def list_hear_about_options_for_admin do
    from(x in HearAboutOption, order_by: [asc: x.id])
    |> preload([:inserted_by, :updated_by])
    |> Repo.all()
  end

  def get_hear_about_option!(id), do: Repo.get!(HearAboutOption, id)

  @doc """
  Creates a hear_about_option. Pass `user_id` to record audit columns.
  """
  def create_hear_about_option(attrs, user_id \\ nil) do
    # AUTHZ_HOOK: :catalog, :create_hear_about_option — no-op until RBAC module exists
    %HearAboutOption{}
    |> HearAboutOption.changeset(attrs)
    |> apply_hear_about_option_insert_audit(user_id)
    |> Repo.insert()
  end

  @doc """
  Updates a hear_about_option. Pass `user_id` to set `updated_by_id`.
  """
  def update_hear_about_option(%HearAboutOption{} = hear_about_option, attrs, user_id \\ nil) do
    # AUTHZ_HOOK: :catalog, :update_hear_about_option — no-op until RBAC module exists
    hear_about_option
    |> HearAboutOption.changeset(attrs)
    |> apply_hear_about_option_update_audit(user_id)
    |> Repo.update()
  end

  @doc """
  Soft-deletes a hear_about_option (`archived: true`).
  """
  def archive_hear_about_option(%HearAboutOption{} = hear_about_option, user_id \\ nil) do
    # AUTHZ_HOOK: :catalog, :archive_hear_about_option — no-op until RBAC module exists
    update_hear_about_option(hear_about_option, %{archived: true}, user_id)
  end

  @doc """
  Restores an archived hear_about_option.
  """
  def restore_hear_about_option(%HearAboutOption{} = hear_about_option, user_id \\ nil) do
    update_hear_about_option(hear_about_option, %{archived: false}, user_id)
  end

  @doc """
  Soft-deletes a hear_about_option. Prefer `archive_hear_about_option/2`.
  """
  def delete_hear_about_option(%HearAboutOption{} = hear_about_option) do
    archive_hear_about_option(hear_about_option, nil)
  end

  def change_hear_about_option(%HearAboutOption{} = hear_about_option, attrs \\ %{}) do
    HearAboutOption.changeset(hear_about_option, attrs)
  end

  defp apply_hear_about_option_insert_audit(changeset, nil), do: changeset

  defp apply_hear_about_option_insert_audit(changeset, user_id) do
    changeset
    |> Ecto.Changeset.put_change(:inserted_by_id, user_id)
    |> Ecto.Changeset.put_change(:updated_by_id, user_id)
  end

  defp apply_hear_about_option_update_audit(changeset, nil), do: changeset

  defp apply_hear_about_option_update_audit(changeset, user_id) do
    Ecto.Changeset.put_change(changeset, :updated_by_id, user_id)
  end

  # GEN_RESOURCE_INSERT_POINT
end
