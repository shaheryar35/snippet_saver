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

  alias SnippetSaver.Catalog.VendorContact

  def list_vendor_contacts do
    Repo.all(VendorContact)
  end

  def get_vendor_contact!(id), do: Repo.get!(VendorContact, id)

  @doc """
  Creates a vendor_contact.
  """
  def create_vendor_contact(attrs) do
    # AUTHZ_HOOK: :catalog, :create_vendor_contact — no-op until RBAC module exists
    %VendorContact{}
    |> VendorContact.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a vendor_contact.
  """
  def update_vendor_contact(%VendorContact{} = vendor_contact, attrs) do
    # AUTHZ_HOOK: :catalog, :update_vendor_contact — no-op until RBAC module exists
    vendor_contact
    |> VendorContact.changeset(attrs)
    |> Repo.update()
  end

  def delete_vendor_contact(%VendorContact{} = vendor_contact) do
    # AUTHZ_HOOK: :catalog, :delete_vendor_contact — no-op until RBAC module exists
    Repo.delete(vendor_contact)
  end

  def change_vendor_contact(%VendorContact{} = vendor_contact, attrs \\ %{}) do
    VendorContact.changeset(vendor_contact, attrs)
  end

  alias SnippetSaver.Catalog.Vendor

  @doc """
  Active vendors only (`archived: false`), for dropdowns and associations.
  """
  def list_vendors do
    from(x in Vendor, where: x.archived == false, order_by: [asc: x.id])
    |> Repo.all()
  end

  @doc """
  All vendors (including archived), for admin views.
  """
  def list_vendors_for_admin do
    from(x in Vendor, order_by: [asc: x.id])
    |> preload([:inserted_by, :updated_by])
    |> Repo.all()
  end

  def get_vendor!(id), do: Repo.get!(Vendor, id)

  @doc """
  Creates a vendor. Pass `user_id` to record audit columns.
  """
  def create_vendor(attrs, user_id \\ nil) do
    # AUTHZ_HOOK: :catalog, :create_vendor — no-op until RBAC module exists
    %Vendor{}
    |> Vendor.changeset(attrs)
    |> apply_vendor_insert_audit(user_id)
    |> Repo.insert()
  end

  @doc """
  Updates a vendor. Pass `user_id` to set `updated_by_id`.
  """
  def update_vendor(%Vendor{} = vendor, attrs, user_id \\ nil) do
    # AUTHZ_HOOK: :catalog, :update_vendor — no-op until RBAC module exists
    vendor
    |> Vendor.changeset(attrs)
    |> apply_vendor_update_audit(user_id)
    |> Repo.update()
  end

  @doc """
  Soft-deletes a vendor (`archived: true`).
  """
  def archive_vendor(%Vendor{} = vendor, user_id \\ nil) do
    # AUTHZ_HOOK: :catalog, :archive_vendor — no-op until RBAC module exists
    update_vendor(vendor, %{archived: true}, user_id)
  end

  @doc """
  Restores an archived vendor.
  """
  def restore_vendor(%Vendor{} = vendor, user_id \\ nil) do
    update_vendor(vendor, %{archived: false}, user_id)
  end

  @doc """
  Soft-deletes a vendor. Prefer `archive_vendor/2`.
  """
  def delete_vendor(%Vendor{} = vendor) do
    archive_vendor(vendor, nil)
  end

  def change_vendor(%Vendor{} = vendor, attrs \\ %{}) do
    Vendor.changeset(vendor, attrs)
  end

  defp apply_vendor_insert_audit(changeset, nil), do: changeset

  defp apply_vendor_insert_audit(changeset, user_id) do
    changeset
    |> Ecto.Changeset.put_change(:inserted_by_id, user_id)
    |> Ecto.Changeset.put_change(:updated_by_id, user_id)
  end

  defp apply_vendor_update_audit(changeset, nil), do: changeset

  defp apply_vendor_update_audit(changeset, user_id) do
    Ecto.Changeset.put_change(changeset, :updated_by_id, user_id)
  end

  @doc """
  Vendor Contacts belonging to the given vendor.
  """
  def list_vendor_contacts_for_vendor(vendor_id) do
    from(x in SnippetSaver.Catalog.VendorContact,
      where: field(x, :vendor_id) == ^vendor_id,
      order_by: [asc: x.id]
    )
    |> Repo.all()
  end

  @doc """
  Replaces all Vendor Contacts for the given vendor with `rows` in one transaction —
  deletes existing rows, then reinserts `rows`. Buffered nested-collection sync (design doc §5):
  nothing is persisted until the parent record itself is saved.
  """
  def replace_vendor_contacts(vendor_id, rows) when is_list(rows) do
    Repo.transaction(fn ->
      from(x in SnippetSaver.Catalog.VendorContact, where: field(x, :vendor_id) == ^vendor_id)
      |> Repo.delete_all()

      Enum.reduce_while(rows, :ok, fn row, _acc ->
        attrs =
          Map.merge(
            %{"vendor_id" => vendor_id},
            Map.new(["name", "role"], fn key ->
              {key, row[key] || row[String.to_existing_atom(key)]}
            end)
          )

        case SnippetSaver.Catalog.create_vendor_contact(attrs) do
          {:ok, _record} -> {:cont, :ok}
          {:error, changeset} -> {:halt, Repo.rollback(changeset)}
        end
      end)
    end)
  end

  # GEN_RESOURCE_INSERT_POINT
end
