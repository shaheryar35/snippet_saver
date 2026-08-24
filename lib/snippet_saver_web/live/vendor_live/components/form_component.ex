defmodule SnippetSaverWeb.VendorLive.Components.FormComponent do
  use SnippetSaverWeb, :live_component

  alias SnippetSaver.Catalog
  alias SnippetSaver.Catalog.Vendor

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:parent_pid, assigns[:parent_pid])
     |> assign_form()
     |> assign_new(:vendor_contacts_modal_mode, fn -> nil end)
     |> assign_new(:vendor_contacts_modal_index, fn -> nil end)
     |> assign_new(:vendor_contacts_form, fn -> nil end)
     |> assign_vendor_contacts_rows()}
  end

  def handle_event("validate", %{"vendor" => params}, socket) do
    changeset =
      socket.assigns.vendor
      |> Vendor.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"vendor" => params}, socket) do
    save_vendor(socket, socket.assigns.action, params)
  end

  def handle_event("open-vendor_contacts-modal", %{"mode" => "new"}, socket) do
    {:noreply,
     socket
     |> assign(:vendor_contacts_modal_mode, :new)
     |> assign(:vendor_contacts_modal_index, nil)
     |> assign(
       :vendor_contacts_form,
       to_form(%{"name" => "", "role" => ""}, as: :vendor_contacts_row)
     )}
  end

  def handle_event("close-vendor_contacts-modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:vendor_contacts_modal_mode, nil)
     |> assign(:vendor_contacts_modal_index, nil)
     |> assign(:vendor_contacts_form, nil)}
  end

  def handle_event("delete-vendor_contacts-row", %{"index" => index}, socket) do
    idx = String.to_integer(index)
    rows = List.delete_at(socket.assigns.vendor_contacts_rows, idx)
    {:noreply, assign(socket, :vendor_contacts_rows, rows)}
  end

  def handle_event("edit-vendor_contacts-modal", %{"index" => index}, socket) do
    idx = if is_integer(index), do: index, else: String.to_integer(index)
    row = Enum.at(socket.assigns.vendor_contacts_rows, idx, %{"name" => "", "role" => ""})

    {:noreply,
     socket
     |> assign(:vendor_contacts_modal_mode, :edit)
     |> assign(:vendor_contacts_modal_index, idx)
     |> assign(:vendor_contacts_form, to_form(row, as: :vendor_contacts_row))}
  end

  def handle_event("save-vendor_contacts-modal", %{"vendor_contacts_row" => params}, socket) do
    row = %{"name" => Map.get(params, "name", ""), "role" => Map.get(params, "role", "")}

    rows =
      case socket.assigns.vendor_contacts_modal_mode do
        :edit when is_integer(socket.assigns.vendor_contacts_modal_index) ->
          List.replace_at(
            socket.assigns.vendor_contacts_rows,
            socket.assigns.vendor_contacts_modal_index,
            row
          )

        _ ->
          socket.assigns.vendor_contacts_rows ++ [row]
      end

    {:noreply,
     socket
     |> assign(:vendor_contacts_rows, rows)
     |> assign(:vendor_contacts_modal_mode, nil)
     |> assign(:vendor_contacts_modal_index, nil)
     |> assign(:vendor_contacts_form, nil)}
  end

  defp save_vendor(socket, :new, params) do
    with {:ok, record} <- Catalog.create_vendor(params),
         {:ok, :ok} <-
           SnippetSaver.Catalog.replace_vendor_contacts(
             record.id,
             socket.assigns.vendor_contacts_rows
           ) do
      notify_and_close(socket, record, "Vendor created successfully")
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}

      {:error, _reason} ->
        {:noreply,
         put_flash(socket, :error, "Could not save related records. Please review and try again.")}
    end
  end

  defp save_vendor(socket, :edit, params) do
    with {:ok, record} <- Catalog.update_vendor(socket.assigns.vendor, params),
         {:ok, :ok} <-
           SnippetSaver.Catalog.replace_vendor_contacts(
             record.id,
             socket.assigns.vendor_contacts_rows
           ) do
      notify_and_close(socket, record, "Vendor updated successfully")
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}

      {:error, _reason} ->
        {:noreply,
         put_flash(socket, :error, "Could not save related records. Please review and try again.")}
    end
  end

  defp notify_and_close(socket, record, message) do
    if pid = socket.assigns[:parent_pid] do
      send(pid, {:vendor_saved, record, message})
      {:noreply, socket}
    else
      {:noreply,
       socket
       |> put_flash(:info, message)
       |> push_navigate(to: ~p"/vendors/#{record}")}
    end
  end

  defp assign_form(socket) do
    changeset = Vendor.changeset(socket.assigns.vendor, %{})
    assign(socket, form: to_form(changeset))
  end

  defp assign_vendor_contacts_rows(socket) do
    rows =
      case socket.assigns[:vendor] do
        %Vendor{id: nil} ->
          []

        %Vendor{id: vendor_id} ->
          Catalog.list_vendor_contacts_for_vendor(vendor_id)
          |> Enum.map(fn record ->
            %{"name" => to_string(record.name || ""), "role" => to_string(record.role || "")}
          end)

        _ ->
          []
      end

    assign(socket, :vendor_contacts_rows, rows)
  end

  def render(assigns) do
    ~H"""
    <div id={"vendor-form-#{@id}"}>
      <.form_container>
        <.simple_form for={@form} phx-target={@myself} phx-change="validate" phx-submit="save">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <.input type="text" field={@form[:company_name]} label="Company Name" />
          </div>

          <:actions>
            <.button type="submit" variant="primary" size="lg">
              {if @action == :new, do: "Create Vendor", else: "Update Vendor"}
            </.button>
            <.link patch={@patch_back}>
              <.button type="button" variant="outline" size="lg">Cancel</.button>
            </.link>
          </:actions>
        </.simple_form>

        <div class="mt-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900">Vendor Contacts</h3>

            <.button
              type="button"
              variant="primary"
              size="sm"
              phx-target={@myself}
              phx-click={
                JS.push("open-vendor_contacts-modal", value: %{mode: "new"}, target: @myself)
              }
            >
              + Add Vendor Contact
            </.button>
          </div>

          <div class="overflow-x-auto border rounded-lg">
            <table class="min-w-full text-sm">
              <thead class="bg-gray-50 text-gray-600">
                <tr>
                  <th class="text-left px-4 py-3 font-semibold">Name</th>
                  <th class="text-left px-4 py-3 font-semibold">Role</th>
                  <th class="text-left px-4 py-3 font-semibold">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y">
                <tr :if={@vendor_contacts_rows == []}>
                  <td colspan="3" class="px-4 py-4 text-gray-500">No vendor contacts added yet.</td>
                </tr>
                <tr :for={{row, idx} <- Enum.with_index(@vendor_contacts_rows)}>
                  <td class="px-4 py-3">{row["name"] || "—"}</td>
                  <td class="px-4 py-3">{row["role"] || "—"}</td>
                  <td class="px-4 py-3">
                    <div class="flex items-center gap-2">
                      <.button
                        type="button"
                        size="sm"
                        variant="outline"
                        phx-target={@myself}
                        phx-click={
                          JS.push("edit-vendor_contacts-modal", value: %{index: idx}, target: @myself)
                        }
                      >
                        Edit
                      </.button>
                      <.button
                        type="button"
                        size="sm"
                        variant="danger"
                        phx-target={@myself}
                        phx-click="delete-vendor_contacts-row"
                        phx-value-index={idx}
                      >
                        Delete
                      </.button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <.modal
          :if={@vendor_contacts_modal_mode}
          id={"vendor-contacts-modal-#{@id}"}
          show
          on_cancel={JS.push("close-vendor_contacts-modal", target: @myself)}
        >
          <div class="space-y-4">
            <h3 class="text-lg font-semibold">
              {if @vendor_contacts_modal_mode == :edit,
                do: "Edit Vendor Contact",
                else: "Add Vendor Contact"}
            </h3>
            <.simple_form
              for={@vendor_contacts_form}
              phx-target={@myself}
              phx-submit="save-vendor_contacts-modal"
            >
              <div class="grid grid-cols-1 gap-4">
                <.input type="text" field={@vendor_contacts_form[:name]} label="Name" />
                <.input type="text" field={@vendor_contacts_form[:role]} label="Role" />
              </div>
              <:actions>
                <.button type="submit" variant="primary">
                  {if @vendor_contacts_modal_mode == :edit, do: "Update", else: "Add"}
                </.button>
                <.button
                  type="button"
                  variant="outline"
                  phx-target={@myself}
                  phx-click="close-vendor_contacts-modal"
                >
                  Cancel
                </.button>
              </:actions>
            </.simple_form>
          </div>
        </.modal>
      </.form_container>
    </div>
    """
  end
end
