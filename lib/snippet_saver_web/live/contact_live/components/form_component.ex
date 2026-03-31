defmodule SnippetSaverWeb.ContactLive.Components.FormComponent do
  use SnippetSaverWeb, :live_component

  alias SnippetSaver.Contacts
  alias SnippetSaver.Contacts.Contact

  @titles [
    {"Mr.", "Mr."},
    {"Mrs.", "Mrs."},
    {"Ms.", "Ms."},
    {"Dr.", "Dr."}
  ]

  def mount(socket) do
    {:ok, assign(socket, titles: @titles)}
  end

  def update(assigns, socket) do
    section_name = assigns[:section_name] || "Main"
    show_section_nav = Map.get(assigns, :show_section_nav, true)
    section = %{id: section_id(section_name), name: section_name}

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:parent_pid, assigns[:parent_pid])
     |> assign(:show_section_nav, show_section_nav)
     |> assign(:section, section)
     |> assign_form()}
  end

  def handle_event("validate", %{"contact" => contact_params}, socket) do
    changeset =
      socket.assigns.contact
      |> Contact.changeset(contact_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"contact" => contact_params}, socket) do
    save_contact(socket, socket.assigns.action, contact_params)
  end

  defp save_contact(socket, :new, contact_params) do
    case Contacts.create_contact(contact_params) do
      {:ok, contact} ->
        if pid = socket.assigns[:parent_pid] do
          send(pid, {:contact_saved, contact, "Contact created successfully"})
          {:noreply, socket}
        else
          {:noreply, socket |> put_flash(:info, "Contact created successfully") |> push_navigate(to: ~p"/contacts/#{contact}")}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_contact(socket, :edit, contact_params) do
    case Contacts.update_contact(socket.assigns.contact, contact_params) do
      {:ok, contact} ->
        if pid = socket.assigns[:parent_pid] do
          send(pid, {:contact_saved, contact, "Contact updated successfully"})
          {:noreply, socket}
        else
          {:noreply, socket |> put_flash(:info, "Contact updated successfully") |> push_navigate(to: ~p"/contacts/#{contact}")}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp assign_form(socket) do
    changeset = Contact.changeset(socket.assigns.contact, %{})
    assign(socket, form: to_form(changeset))
  end

  defp section_id(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
    |> case do
      "" -> "main"
      value -> value
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form_container title={@title}>
        <div class="grid grid-cols-1 lg:grid-cols-4 gap-6">
          <aside :if={@show_section_nav} class="lg:col-span-1">
            <div class="lg:sticky lg:top-6 rounded-lg border border-gray-200 p-4 bg-gray-50">
              <p class="text-xs font-semibold uppercase tracking-wide text-gray-500 mb-3">Sections</p>
              <nav class="space-y-2">
                <a
                  href={"##{@section.id}"}
                  class="block rounded-md px-3 py-2 text-sm font-medium text-gray-700 hover:bg-primary-50 hover:text-primary-700 transition-colors"
                >
                  <%= @section.name %>
                </a>
              </nav>
            </div>
          </aside>

          <div class={[@show_section_nav && "lg:col-span-3", !@show_section_nav && "lg:col-span-4", "scroll-smooth"]}>
            <section id={@section.id} class="scroll-mt-24">
              <h3 class="text-lg font-semibold text-gray-900 mb-4"><%= @section.name %></h3>

              <.simple_form for={@form} phx-target={@myself} phx-change="validate" phx-submit="save">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <.yes_no
                    name="contact[is_individual]"
                    label="Is Individual"
                    value={Phoenix.HTML.Form.input_value(@form, :is_individual)}
                  />

                  <.input type="select" field={@form[:title]} label="Title" prompt="Select title" options={@titles} />
                  <.input type="text" field={@form[:first_name]} label="First Name" placeholder="John" />
                  <.input type="text" field={@form[:last_name]} label="Last Name" placeholder="Doe" />
                  <.input type="text" field={@form[:business_code]} label="Business Code" placeholder="BUS-001" />

                  <.yes_no
                    name="contact[notes_important]"
                    label="Important Notes"
                    value={Phoenix.HTML.Form.input_value(@form, :notes_important)}
                  />

                  <div class="md:col-span-2">
                    <.input type="textarea" field={@form[:notes]} label="Notes" placeholder="Additional notes..." />
                  </div>
                </div>

                <:actions>
                  <.button type="submit" variant="primary" size="lg">
                    <%= if @action == :new, do: "Create Contact", else: "Update Contact" %>
                  </.button>

                  <.link patch={~p"/contacts"}>
                    <.button type="button" variant="outline" size="lg">Cancel</.button>
                  </.link>
                </:actions>
              </.simple_form>
            </section>
          </div>
        </div>
      </.form_container>
    </div>
    """
  end
end
