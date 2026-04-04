defmodule SnippetSaverWeb.ContactLive.Components.EditComponent do
  use SnippetSaverWeb, :live_component

  alias Phoenix.LiveView.JS
  alias SnippetSaver.Contacts
  alias SnippetSaver.Contacts.{Address, ContactMethod, ContactRole, GeneralInfo}

  def update(assigns, socket) do
    contact = Contacts.get_contact_with_assocs!(assigns.contact.id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:contact, contact)
     |> assign(:sections, sections())
     |> assign(:role_type_options, role_type_options())
     |> assign(:contact_roles, Contacts.list_contact_roles_for_contact(contact.id))
     |> assign(:contact_methods, Contacts.list_contact_methods_for_contact(contact.id))
     |> assign(:addresses, Contacts.list_addresses_for_contact(contact.id))
     |> assign(:general_info, Contacts.get_general_info_for_contact(contact.id))
     |> assign(:role_modal_mode, nil)
     |> assign(:selected_role, nil)
     |> assign(:method_modal_mode, nil)
     |> assign(:selected_method, nil)
     |> assign(:address_modal_mode, nil)
     |> assign(:selected_address, nil)
     |> assign(:general_info_modal_mode, nil)
     |> assign_forms(contact)}
  end

  def handle_event("open-role-modal", %{"mode" => mode, "id" => id}, socket)
      when mode in ["view", "edit"] do
    role = get_selected_role(socket, mode, id)
    {:noreply, assign_role_modal(socket, mode, role)}
  end

  def handle_event("open-role-modal", %{"mode" => mode}, socket)
      when mode in ["new", "view", "edit"] do
    role = get_selected_role(socket, mode, nil)
    {:noreply, assign_role_modal(socket, mode, role)}
  end

  def handle_event("close-role-modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:role_modal_mode, nil)
     |> assign(:selected_role, nil)
     |> assign(:role_form, blank_role_form(socket.assigns.contact.id))}
  end

  def handle_event("save-role-modal", %{"contact_role" => params}, socket) do
    attrs = Map.put(params, "contact_id", socket.assigns.contact.id)

    result =
      case socket.assigns.role_modal_mode do
        :edit when not is_nil(socket.assigns.selected_role) ->
          Contacts.update_contact_role(socket.assigns.selected_role, attrs)

        _ ->
          Contacts.create_contact_role(attrs)
      end

    case result do
      {:ok, _contact_role} ->
        {:noreply,
         socket
         |> refresh_assoc_data("Role saved successfully")
         |> assign(:role_modal_mode, nil)
         |> assign(:selected_role, nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :role_form, to_form(changeset))}
    end
  end

  def handle_event("delete-role", %{"id" => id}, socket) do
    role = Contacts.get_contact_role!(id)

    case Contacts.delete_contact_role(role) do
      {:ok, _deleted} ->
        {:noreply, refresh_assoc_data(socket, "Role deleted successfully")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete role")}
    end
  end

  def handle_event("open-method-modal", %{"mode" => mode, "id" => id}, socket)
      when mode in ["view", "edit"] do
    method = get_selected_method(socket, mode, id)
    {:noreply, assign_method_modal(socket, mode, method)}
  end

  def handle_event("open-method-modal", %{"mode" => mode}, socket)
      when mode in ["new", "view", "edit"] do
    method = get_selected_method(socket, mode, nil)
    {:noreply, assign_method_modal(socket, mode, method)}
  end

  def handle_event("close-method-modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:method_modal_mode, nil)
     |> assign(:selected_method, nil)
     |> assign(:method_form, blank_method_form(socket.assigns.contact.id))}
  end

  def handle_event("save-method-modal", %{"contact_method" => params}, socket) do
    attrs = Map.put(params, "contact_id", socket.assigns.contact.id)

    result =
      case socket.assigns.method_modal_mode do
        :edit when not is_nil(socket.assigns.selected_method) ->
          Contacts.update_contact_method(socket.assigns.selected_method, attrs)

        _ ->
          Contacts.create_contact_method(attrs)
      end

    case result do
      {:ok, _contact_method} ->
        {:noreply,
         socket
         |> refresh_assoc_data("Contact method saved successfully")
         |> assign(:method_modal_mode, nil)
         |> assign(:selected_method, nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :method_form, to_form(changeset))}
    end
  end

  def handle_event("delete-method", %{"id" => id}, socket) do
    method = Contacts.get_contact_method!(id)

    case Contacts.delete_contact_method(method) do
      {:ok, _deleted} ->
        {:noreply, refresh_assoc_data(socket, "Contact method deleted successfully")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete contact method")}
    end
  end

  def handle_event("open-address-modal", %{"mode" => mode, "id" => id}, socket)
      when mode in ["view", "edit"] do
    address = get_selected_address(socket, mode, id)
    {:noreply, assign_address_modal(socket, mode, address)}
  end

  def handle_event("open-address-modal", %{"mode" => mode}, socket)
      when mode in ["new", "view", "edit"] do
    address = get_selected_address(socket, mode, nil)
    {:noreply, assign_address_modal(socket, mode, address)}
  end

  def handle_event("close-address-modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:address_modal_mode, nil)
     |> assign(:selected_address, nil)
     |> assign(:address_form, blank_address_form(socket.assigns.contact.id))}
  end

  def handle_event("save-address-modal", %{"address" => params}, socket) do
    attrs = Map.put(params, "contact_id", socket.assigns.contact.id)

    result =
      case socket.assigns.address_modal_mode do
        :edit when not is_nil(socket.assigns.selected_address) ->
          Contacts.update_address(socket.assigns.selected_address, attrs)

        _ ->
          Contacts.create_address(attrs)
      end

    case result do
      {:ok, _address} ->
        {:noreply,
         socket
         |> refresh_assoc_data("Address saved successfully")
         |> assign(:address_modal_mode, nil)
         |> assign(:selected_address, nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :address_form, to_form(changeset))}
    end
  end

  def handle_event("delete-address", %{"id" => id}, socket) do
    address = Contacts.get_address!(id)

    case Contacts.delete_address(address) do
      {:ok, _deleted} ->
        {:noreply, refresh_assoc_data(socket, "Address deleted successfully")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete address")}
    end
  end

  def handle_event("open-general-info-modal", %{"mode" => mode}, socket)
      when mode in ["new", "view", "edit"] do
    {:noreply, assign_general_info_modal(socket, mode)}
  end

  def handle_event("close-general-info-modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:general_info_modal_mode, nil)
     |> assign(:general_info_form, blank_general_info_form(socket))}
  end

  def handle_event("save-general-info-modal", %{"general_info" => params}, socket) do
    attrs = Map.put(params, "contact_id", socket.assigns.contact.id)

    result =
      case socket.assigns.general_info do
        nil -> Contacts.create_general_info(attrs)
        general_info -> Contacts.update_general_info(general_info, attrs)
      end

    case result do
      {:ok, _general_info} ->
        {:noreply,
         socket
         |> refresh_assoc_data("General info saved successfully")
         |> assign(:general_info_modal_mode, nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :general_info_form, to_form(changeset))}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="h-full min-h-0 flex flex-col scroll-smooth overflow-hidden">
      <.header>
        Edit Contact
        <:subtitle>Update contact information and related records</:subtitle>
      </.header>

      <div
        id={"edit-sections-layout-#{@contact.id}"}
        class="grid grid-cols-1 lg:grid-cols-4 gap-6 flex-1 min-h-0 overflow-hidden"
        phx-hook="SectionScrollSpy"
      >
        <aside class="lg:col-span-1 h-full min-h-0 overflow-hidden">
          <div class="h-full lg:sticky lg:top-4 rounded-lg border border-gray-200 p-4 bg-gray-50">
            <p class="text-xs font-semibold uppercase tracking-wide text-gray-500 mb-3">Sections</p>
            <nav class="space-y-2" data-sections-nav>
              <a
                :for={section <- @sections}
                href={"##{section.id}"}
                data-section-link={section.id}
                class="section-nav-link block rounded-md px-3 py-2 text-sm font-medium text-gray-700 hover:bg-primary-50 hover:text-primary-700 transition-colors"
              >
                <%= section.name %>
              </a>
            </nav>
          </div>
        </aside>

        <div class="lg:col-span-3 h-full min-h-0 space-y-6 overflow-y-auto pr-1 pb-6" data-sections-scroll>
          <section id="contact-information" data-section-id="contact-information" class="scroll-mt-24">
            <.live_component
              module={SnippetSaverWeb.ContactLive.Components.FormComponent}
              id={"edit-contact-form-#{@contact.id}"}
              title=" "
              section_name="Contact Information"
              show_section_nav={false}
              action={:edit}
              contact={@contact}
              parent_pid={@parent_pid}
            />
          </section>

          <section id="roles" data-section-id="roles" class="scroll-mt-24">
            <.card title="Roles">
              <div class="space-y-4">
                <div class="overflow-x-auto border rounded-lg">
                  <table class="min-w-full text-sm">
                    <thead class="bg-gray-50 text-gray-600">
                      <tr>
                        <th class="text-left px-4 py-3 font-semibold">Role Type</th>
                        <th class="text-left px-4 py-3 font-semibold">Date Added</th>
                        <th class="text-left px-4 py-3 font-semibold">Actions</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y">
                      <tr :if={Enum.empty?(@contact_roles)}>
                        <td colspan="3" class="px-4 py-4 text-gray-500">No roles added yet.</td>
                      </tr>
                      <tr :for={role <- @contact_roles}>
                        <td class="px-4 py-3"><%= role.contact_role_type && role.contact_role_type.name || "Unknown Role" %></td>
                        <td class="px-4 py-3"><%= format_datetime(role.inserted_at) %></td>
                        <td class="px-4 py-3">
                          <div class="flex items-center gap-2">
                            <.button
                              type="button"
                              size="sm"
                              variant="outline"
                              phx-click={JS.push("open-role-modal", value: %{mode: "view", id: role.id}, target: @myself)}
                            >
                              View
                            </.button>
                            <.button
                              type="button"
                              size="sm"
                              variant="outline"
                              phx-click={JS.push("open-role-modal", value: %{mode: "edit", id: role.id}, target: @myself)}
                            >
                              Edit
                            </.button>
                            <.button
                              type="button"
                              size="sm"
                              variant="danger"
                              phx-click="delete-role"
                              phx-target={@myself}
                              phx-value-id={role.id}
                            >
                              Delete
                            </.button>
                          </div>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>

                <div>
                  <.button
                    type="button"
                    variant="primary"
                    phx-click={JS.push("open-role-modal", value: %{mode: "new"}, target: @myself)}
                  >
                    + Add Role
                  </.button>
                </div>
              </div>

              <.modal
                :if={@role_modal_mode}
                id={"role-modal-#{@contact.id}"}
                show
                on_cancel={JS.push("close-role-modal", target: @myself)}
              >
                <%= if @role_modal_mode == :view do %>
                  <div class="space-y-3">
                    <h3 class="text-lg font-semibold">Role Details</h3>
                    <div class="grid grid-cols-1 gap-3 text-sm">
                      <div>
                        <p class="text-gray-500">Role Type</p>
                        <p class="font-medium">
                          <%= @selected_role && @selected_role.contact_role_type && @selected_role.contact_role_type.name || "Unknown Role" %>
                        </p>
                      </div>
                      <div>
                        <p class="text-gray-500">Date Added</p>
                        <p class="font-medium">
                          <%= @selected_role && format_datetime(@selected_role.inserted_at) || "—" %>
                        </p>
                      </div>
                    </div>
                    <div class="pt-3">
                      <.button
                        type="button"
                        variant="outline"
                        phx-click="close-role-modal"
                        phx-target={@myself}
                      >
                        Close
                      </.button>
                    </div>
                  </div>
                <% else %>
                  <div class="space-y-4">
                    <h3 class="text-lg font-semibold">
                      <%= if @role_modal_mode == :edit, do: "Edit Role", else: "Add Role" %>
                    </h3>
                    <.simple_form for={@role_form} phx-target={@myself} phx-submit="save-role-modal">
                      <div class="grid grid-cols-1 gap-4">
                        <.input
                          type="select"
                          field={@role_form[:contact_role_type_id]}
                          label="Role Type"
                          prompt="Select role type"
                          options={@role_type_options}
                        />
                      </div>
                      <:actions>
                        <.button type="submit" variant="primary">
                          <%= if @role_modal_mode == :edit, do: "Update Role", else: "Create Role" %>
                        </.button>
                        <.button
                          type="button"
                          variant="outline"
                          phx-click="close-role-modal"
                          phx-target={@myself}
                        >
                          Cancel
                        </.button>
                      </:actions>
                    </.simple_form>
                  </div>
                <% end %>
              </.modal>
            </.card>
          </section>

          <section id="contact-methods" data-section-id="contact-methods" class="scroll-mt-24">
            <.card title="Contact Methods">
              <div class="space-y-4">
                <div class="overflow-x-auto border rounded-lg">
                  <table class="min-w-full text-sm">
                    <thead class="bg-gray-50 text-gray-600">
                      <tr>
                        <th class="text-left px-4 py-3 font-semibold">Type</th>
                        <th class="text-left px-4 py-3 font-semibold">Value</th>
                        <th class="text-left px-4 py-3 font-semibold">Date Added</th>
                        <th class="text-left px-4 py-3 font-semibold">Actions</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y">
                      <tr :if={Enum.empty?(@contact_methods)}>
                        <td colspan="4" class="px-4 py-4 text-gray-500">No contact methods added yet.</td>
                      </tr>
                      <tr :for={method <- @contact_methods}>
                        <td class="px-4 py-3"><%= method.type %></td>
                        <td class="px-4 py-3"><%= method.value %></td>
                        <td class="px-4 py-3"><%= format_datetime(method.inserted_at) %></td>
                        <td class="px-4 py-3">
                          <div class="flex items-center gap-2">
                            <.button
                              type="button"
                              size="sm"
                              variant="outline"
                              phx-click={JS.push("open-method-modal", value: %{mode: "view", id: method.id}, target: @myself)}
                            >
                              View
                            </.button>
                            <.button
                              type="button"
                              size="sm"
                              variant="outline"
                              phx-click={JS.push("open-method-modal", value: %{mode: "edit", id: method.id}, target: @myself)}
                            >
                              Edit
                            </.button>
                            <.button
                              type="button"
                              size="sm"
                              variant="danger"
                              phx-click="delete-method"
                              phx-target={@myself}
                              phx-value-id={method.id}
                            >
                              Delete
                            </.button>
                          </div>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>

                <div>
                  <.button
                    type="button"
                    variant="primary"
                    phx-click={JS.push("open-method-modal", value: %{mode: "new"}, target: @myself)}
                  >
                    + Add Contact Method
                  </.button>
                </div>
              </div>

              <.modal
                :if={@method_modal_mode}
                id={"method-modal-#{@contact.id}"}
                show
                on_cancel={JS.push("close-method-modal", target: @myself)}
              >
                <%= if @method_modal_mode == :view do %>
                  <div class="space-y-3">
                    <h3 class="text-lg font-semibold">Contact Method Details</h3>
                    <div class="grid grid-cols-1 gap-3 text-sm">
                      <div>
                        <p class="text-gray-500">Type</p>
                        <p class="font-medium"><%= @selected_method && @selected_method.type || "—" %></p>
                      </div>
                      <div>
                        <p class="text-gray-500">Value</p>
                        <p class="font-medium"><%= @selected_method && @selected_method.value || "—" %></p>
                      </div>
                      <div>
                        <p class="text-gray-500">Primary</p>
                        <p class="font-medium"><%= @selected_method && boolean_label(@selected_method.is_primary) || "No" %></p>
                      </div>
                      <div>
                        <p class="text-gray-500">Allow SMS</p>
                        <p class="font-medium"><%= @selected_method && boolean_label(@selected_method.allow_sms) || "No" %></p>
                      </div>
                      <div>
                        <p class="text-gray-500">Allow Email</p>
                        <p class="font-medium"><%= @selected_method && boolean_label(@selected_method.allow_email) || "No" %></p>
                      </div>
                    </div>
                    <div class="pt-3">
                      <.button
                        type="button"
                        variant="outline"
                        phx-click="close-method-modal"
                        phx-target={@myself}
                      >
                        Close
                      </.button>
                    </div>
                  </div>
                <% else %>
                  <div class="space-y-4">
                    <h3 class="text-lg font-semibold">
                      <%= if @method_modal_mode == :edit, do: "Edit Contact Method", else: "Add Contact Method" %>
                    </h3>
                    <.simple_form for={@method_form} phx-target={@myself} phx-submit="save-method-modal">
                      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <.input type="text" field={@method_form[:type]} label="Type" placeholder="email / phone" />
                        <.input type="text" field={@method_form[:value]} label="Value" placeholder="john@example.com" />
                        <.yes_no
                          name="contact_method[is_primary]"
                          label="Primary"
                          value={Phoenix.HTML.Form.input_value(@method_form, :is_primary)}
                        />
                        <.yes_no
                          name="contact_method[allow_sms]"
                          label="Allow SMS"
                          value={Phoenix.HTML.Form.input_value(@method_form, :allow_sms)}
                        />
                        <.yes_no
                          name="contact_method[allow_email]"
                          label="Allow Email"
                          value={Phoenix.HTML.Form.input_value(@method_form, :allow_email)}
                        />
                      </div>
                      <:actions>
                        <.button type="submit" variant="primary">
                          <%= if @method_modal_mode == :edit, do: "Update Contact Method", else: "Create Contact Method" %>
                        </.button>
                        <.button
                          type="button"
                          variant="outline"
                          phx-click="close-method-modal"
                          phx-target={@myself}
                        >
                          Cancel
                        </.button>
                      </:actions>
                    </.simple_form>
                  </div>
                <% end %>
              </.modal>
            </.card>
          </section>

          <section id="addresses" data-section-id="addresses" class="scroll-mt-24">
            <.card title="Addresses">
              <div class="space-y-4">
                <div class="overflow-x-auto border rounded-lg">
                  <table class="min-w-full text-sm">
                    <thead class="bg-gray-50 text-gray-600">
                      <tr>
                        <th class="text-left px-4 py-3 font-semibold">Address Name</th>
                        <th class="text-left px-4 py-3 font-semibold">Type</th>
                        <th class="text-left px-4 py-3 font-semibold">City</th>
                        <th class="text-left px-4 py-3 font-semibold">Date Added</th>
                        <th class="text-left px-4 py-3 font-semibold">Actions</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y">
                      <tr :if={Enum.empty?(@addresses)}>
                        <td colspan="5" class="px-4 py-4 text-gray-500">No addresses added yet.</td>
                      </tr>
                      <tr :for={address <- @addresses}>
                        <td class="px-4 py-3"><%= address.address_name %></td>
                        <td class="px-4 py-3"><%= address.type %></td>
                        <td class="px-4 py-3"><%= address.city %></td>
                        <td class="px-4 py-3"><%= format_datetime(address.inserted_at) %></td>
                        <td class="px-4 py-3">
                          <div class="flex items-center gap-2">
                            <.button
                              type="button"
                              size="sm"
                              variant="outline"
                              phx-click={JS.push("open-address-modal", value: %{mode: "view", id: address.id}, target: @myself)}
                            >
                              View
                            </.button>
                            <.button
                              type="button"
                              size="sm"
                              variant="outline"
                              phx-click={JS.push("open-address-modal", value: %{mode: "edit", id: address.id}, target: @myself)}
                            >
                              Edit
                            </.button>
                            <.button
                              type="button"
                              size="sm"
                              variant="danger"
                              phx-click="delete-address"
                              phx-target={@myself}
                              phx-value-id={address.id}
                            >
                              Delete
                            </.button>
                          </div>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>

                <div>
                  <.button
                    type="button"
                    variant="primary"
                    phx-click={JS.push("open-address-modal", value: %{mode: "new"}, target: @myself)}
                  >
                    + Add Address
                  </.button>
                </div>
              </div>

              <.modal
                :if={@address_modal_mode}
                id={"address-modal-#{@contact.id}"}
                show
                on_cancel={JS.push("close-address-modal", target: @myself)}
              >
                <%= if @address_modal_mode == :view do %>
                  <div class="space-y-3">
                    <h3 class="text-lg font-semibold">Address Details</h3>
                    <div class="grid grid-cols-1 gap-3 text-sm">
                      <div><p class="text-gray-500">Address Name</p><p class="font-medium"><%= @selected_address && @selected_address.address_name || "—" %></p></div>
                      <div><p class="text-gray-500">Type</p><p class="font-medium"><%= @selected_address && @selected_address.type || "—" %></p></div>
                      <div><p class="text-gray-500">Street</p><p class="font-medium"><%= @selected_address && @selected_address.street_address || "—" %></p></div>
                      <div><p class="text-gray-500">Suburb</p><p class="font-medium"><%= @selected_address && @selected_address.suburb || "—" %></p></div>
                      <div><p class="text-gray-500">City</p><p class="font-medium"><%= @selected_address && @selected_address.city || "—" %></p></div>
                      <div><p class="text-gray-500">Postcode</p><p class="font-medium"><%= @selected_address && @selected_address.postcode || "—" %></p></div>
                      <div><p class="text-gray-500">Country</p><p class="font-medium"><%= @selected_address && @selected_address.country || "—" %></p></div>
                    </div>
                    <div class="pt-3">
                      <.button type="button" variant="outline" phx-click="close-address-modal" phx-target={@myself}>Close</.button>
                    </div>
                  </div>
                <% else %>
                  <div class="space-y-4">
                    <h3 class="text-lg font-semibold">
                      <%= if @address_modal_mode == :edit, do: "Edit Address", else: "Add Address" %>
                    </h3>
                    <.simple_form for={@address_form} phx-target={@myself} phx-submit="save-address-modal">
                      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <.input type="text" field={@address_form[:type]} label="Type" placeholder="home / office" />
                        <.input type="text" field={@address_form[:address_name]} label="Address Name" placeholder="Main Branch" />
                        <.input type="text" field={@address_form[:street_address]} label="Street Address" />
                        <.input type="text" field={@address_form[:suburb]} label="Suburb" />
                        <.input type="text" field={@address_form[:city]} label="City" />
                        <.input type="text" field={@address_form[:postcode]} label="Postcode" />
                        <.input type="text" field={@address_form[:country]} label="Country" />
                        <.input type="text" field={@address_form[:longitude]} label="Longitude" />
                        <.input type="text" field={@address_form[:latitude]} label="Latitude" />
                      </div>
                      <:actions>
                        <.button type="submit" variant="primary">
                          <%= if @address_modal_mode == :edit, do: "Update Address", else: "Create Address" %>
                        </.button>
                        <.button type="button" variant="outline" phx-click="close-address-modal" phx-target={@myself}>Cancel</.button>
                      </:actions>
                    </.simple_form>
                  </div>
                <% end %>
              </.modal>
            </.card>
          </section>

          <section id="general-info" data-section-id="general-info" class="scroll-mt-24">
            <.card title="General Info">
              <div class="space-y-4">
                <div class="overflow-x-auto border rounded-lg">
                  <table class="min-w-full text-sm">
                    <thead class="bg-gray-50 text-gray-600">
                      <tr>
                        <th class="text-left px-4 py-3 font-semibold">Website</th>
                        <th class="text-left px-4 py-3 font-semibold">Hospital</th>
                        <th class="text-left px-4 py-3 font-semibold">Updated</th>
                        <th class="text-left px-4 py-3 font-semibold">Actions</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y">
                      <tr :if={is_nil(@general_info)}>
                        <td colspan="4" class="px-4 py-4 text-gray-500">No general info saved yet.</td>
                      </tr>
                      <tr :if={!is_nil(@general_info)}>
                        <td class="px-4 py-3"><%= @general_info.website || "—" %></td>
                        <td class="px-4 py-3"><%= @general_info.hospital || "—" %></td>
                        <td class="px-4 py-3"><%= format_datetime(@general_info.updated_at) %></td>
                        <td class="px-4 py-3">
                          <div class="flex items-center gap-2">
                            <.button type="button" size="sm" variant="outline" phx-click={JS.push("open-general-info-modal", value: %{mode: "view"}, target: @myself)}>View</.button>
                            <.button type="button" size="sm" variant="outline" phx-click={JS.push("open-general-info-modal", value: %{mode: "edit"}, target: @myself)}>Edit</.button>
                          </div>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>

                <div>
                  <.button
                    type="button"
                    variant="primary"
                    phx-click={JS.push("open-general-info-modal", value: %{mode: if(is_nil(@general_info), do: "new", else: "edit")}, target: @myself)}
                  >
                    <%= if is_nil(@general_info), do: "+ Add General Info", else: "Edit General Info" %>
                  </.button>
                </div>
              </div>

              <.modal
                :if={@general_info_modal_mode}
                id={"general-info-modal-#{@contact.id}"}
                show
                on_cancel={JS.push("close-general-info-modal", target: @myself)}
              >
                <%= if @general_info_modal_mode == :view do %>
                  <div class="space-y-3">
                    <h3 class="text-lg font-semibold">General Info Details</h3>
                    <div class="grid grid-cols-1 gap-3 text-sm">
                      <div><p class="text-gray-500">Hospital</p><p class="font-medium"><%= @general_info && @general_info.hospital || "—" %></p></div>
                      <div><p class="text-gray-500">Website</p><p class="font-medium"><%= @general_info && @general_info.website || "—" %></p></div>
                      <div><p class="text-gray-500">Pet Insurance Supplier</p><p class="font-medium"><%= @general_info && @general_info.pet_insurance_supplier || "—" %></p></div>
                    </div>
                    <div class="pt-3">
                      <.button type="button" variant="outline" phx-click="close-general-info-modal" phx-target={@myself}>Close</.button>
                    </div>
                  </div>
                <% else %>
                  <div class="space-y-4">
                    <h3 class="text-lg font-semibold">
                      <%= if @general_info_modal_mode == :edit, do: "Edit General Info", else: "Add General Info" %>
                    </h3>
                    <.simple_form for={@general_info_form} phx-target={@myself} phx-submit="save-general-info-modal">
                      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <.input type="text" field={@general_info_form[:hospital]} label="Hospital" />
                        <.input type="text" field={@general_info_form[:website]} label="Website" />
                        <.input type="text" field={@general_info_form[:pet_insurance_supplier]} label="Pet Insurance Supplier" />
                        <.input type="date" field={@general_info_form[:date_of_birth]} label="Date of Birth" />
                        <.input type="text" field={@general_info_form[:driver_license_number]} label="Driver License Number" />
                        <.input type="text" field={@general_info_form[:driver_license_issuer]} label="Driver License Issuer" />
                        <.input type="date" field={@general_info_form[:driver_license_expiry]} label="Driver License Expiry" />
                        <.input type="text" field={@general_info_form[:national_id_number]} label="National ID Number" />
                        <.input type="text" field={@general_info_form[:passport_number]} label="Passport Number" />
                        <.input type="text" field={@general_info_form[:credit_limit_name]} label="Credit Limit Name" />
                        <.yes_no
                          name="general_info[contact_details_confirmed]"
                          label="Contact Details Confirmed"
                          value={Phoenix.HTML.Form.input_value(@general_info_form, :contact_details_confirmed)}
                        />
                        <.yes_no
                          name="general_info[consolidate_invoices]"
                          label="Consolidate Invoices"
                          value={Phoenix.HTML.Form.input_value(@general_info_form, :consolidate_invoices)}
                        />
                      </div>
                      <:actions>
                        <.button type="submit" variant="primary">Save General Info</.button>
                        <.button type="button" variant="outline" phx-click="close-general-info-modal" phx-target={@myself}>Cancel</.button>
                      </:actions>
                    </.simple_form>
                  </div>
                <% end %>
              </.modal>
            </.card>
          </section>
        </div>
      </div>
    </div>
    """
  end

  defp sections do
    [
      %{id: "contact-information", name: "Contact Information"},
      %{id: "roles", name: "Roles"},
      %{id: "contact-methods", name: "Contact Methods"},
      %{id: "addresses", name: "Addresses"},
      %{id: "general-info", name: "General Info"}
    ]
  end

  defp role_type_options do
    Contacts.list_contact_role_types()
    |> Enum.map(&{&1.name, &1.id})
  end

  defp assign_forms(socket, contact) do
    role_changeset = Contacts.change_contact_role(%ContactRole{}, %{contact_id: contact.id})

    method_changeset =
      Contacts.change_contact_method(%ContactMethod{}, %{
        contact_id: contact.id,
        is_primary: false,
        allow_sms: false,
        allow_email: false
      })

    address_changeset = Contacts.change_address(%Address{}, %{contact_id: contact.id})

    general_info =
      socket.assigns[:general_info] ||
        %GeneralInfo{
          contact_id: contact.id,
          contact_details_confirmed: false,
          consolidate_invoices: false
        }

    general_info_changeset = Contacts.change_general_info(general_info, %{contact_id: contact.id})

    socket
    |> assign(:role_form, to_form(role_changeset))
    |> assign(:method_form, to_form(method_changeset))
    |> assign(:address_form, to_form(address_changeset))
    |> assign(:general_info_form, to_form(general_info_changeset))
  end

  defp refresh_assoc_data(socket, message) do
    contact = socket.assigns.contact
    general_info = Contacts.get_general_info_for_contact(contact.id)

    socket
    |> assign(:contact_roles, Contacts.list_contact_roles_for_contact(contact.id))
    |> assign(:contact_methods, Contacts.list_contact_methods_for_contact(contact.id))
    |> assign(:addresses, Contacts.list_addresses_for_contact(contact.id))
    |> assign(:general_info, general_info)
    |> assign_forms(contact)
    |> put_flash(:info, message)
  end

  defp get_selected_role(_socket, _mode, nil), do: nil

  defp get_selected_role(socket, _mode, id) do
    Enum.find(socket.assigns.contact_roles, fn role -> to_string(role.id) == to_string(id) end)
  end

  defp assign_role_modal(socket, mode, role) do
    role_form =
      case mode do
        "edit" ->
          case role do
            nil -> blank_role_form(socket.assigns.contact.id)
            selected -> to_form(Contacts.change_contact_role(selected, %{}))
          end

        "new" ->
          blank_role_form(socket.assigns.contact.id)

        _ ->
          socket.assigns.role_form
      end

    socket
    |> assign(:role_modal_mode, String.to_existing_atom(mode))
    |> assign(:selected_role, role)
    |> assign(:role_form, role_form)
  end

  defp blank_role_form(contact_id) do
    Contacts.change_contact_role(%ContactRole{}, %{contact_id: contact_id})
    |> to_form()
  end

  defp get_selected_method(_socket, _mode, nil), do: nil

  defp get_selected_method(socket, _mode, id) do
    Enum.find(socket.assigns.contact_methods, fn method ->
      to_string(method.id) == to_string(id)
    end)
  end

  defp assign_method_modal(socket, mode, method) do
    method_form =
      case mode do
        "edit" ->
          case method do
            nil -> blank_method_form(socket.assigns.contact.id)
            selected -> to_form(Contacts.change_contact_method(selected, %{}))
          end

        "new" ->
          blank_method_form(socket.assigns.contact.id)

        _ ->
          socket.assigns.method_form
      end

    socket
    |> assign(:method_modal_mode, String.to_existing_atom(mode))
    |> assign(:selected_method, method)
    |> assign(:method_form, method_form)
  end

  defp blank_method_form(contact_id) do
    Contacts.change_contact_method(%ContactMethod{}, %{
      contact_id: contact_id,
      is_primary: false,
      allow_sms: false,
      allow_email: false
    })
    |> to_form()
  end

  defp get_selected_address(_socket, _mode, nil), do: nil

  defp get_selected_address(socket, _mode, id) do
    Enum.find(socket.assigns.addresses, fn address -> to_string(address.id) == to_string(id) end)
  end

  defp assign_address_modal(socket, mode, address) do
    address_form =
      case mode do
        "edit" ->
          case address do
            nil -> blank_address_form(socket.assigns.contact.id)
            selected -> to_form(Contacts.change_address(selected, %{}))
          end

        "new" ->
          blank_address_form(socket.assigns.contact.id)

        _ ->
          socket.assigns.address_form
      end

    socket
    |> assign(:address_modal_mode, String.to_existing_atom(mode))
    |> assign(:selected_address, address)
    |> assign(:address_form, address_form)
  end

  defp blank_address_form(contact_id) do
    Contacts.change_address(%Address{}, %{contact_id: contact_id})
    |> to_form()
  end

  defp assign_general_info_modal(socket, mode) do
    general_info_form =
      case mode do
        "edit" ->
          to_form(
            Contacts.change_general_info(
              socket.assigns.general_info || %GeneralInfo{contact_id: socket.assigns.contact.id},
              %{}
            )
          )

        "new" ->
          blank_general_info_form(socket)

        _ ->
          socket.assigns.general_info_form
      end

    socket
    |> assign(:general_info_modal_mode, String.to_existing_atom(mode))
    |> assign(:general_info_form, general_info_form)
  end

  defp blank_general_info_form(socket) do
    general_info =
      socket.assigns[:general_info] ||
        %GeneralInfo{
          contact_id: socket.assigns.contact.id,
          contact_details_confirmed: false,
          consolidate_invoices: false
        }

    Contacts.change_general_info(general_info, %{contact_id: socket.assigns.contact.id})
    |> to_form()
  end

  defp format_datetime(nil), do: "—"

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y")
  end

  defp boolean_label(true), do: "Yes"
  defp boolean_label(_), do: "No"
end
