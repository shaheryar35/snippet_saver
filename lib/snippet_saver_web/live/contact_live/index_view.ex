defmodule SnippetSaverWeb.ContactLive.IndexView do
  use SnippetSaverWeb, :html

  def render("index.html", assigns) do
    show_contact? = assigns[:contact_page] in [:show, :edit] and is_map_key(assigns, :contact)
    is_new_page? = assigns[:contact_page] == :new
    active_subtab = Map.get(assigns, :active_subtab, :details)

    assigns =
      assigns
      |> assign(:show_contact?, show_contact?)
      |> assign(:data_contact_id, if(show_contact?, do: assigns.contact.id, else: nil))
      |> assign(
        :data_contact_name,
        if(show_contact?, do: contact_display_name(assigns.contact), else: nil)
      )
      |> assign(:data_page_new, is_new_page?)
      |> assign(:active_subtab, active_subtab)

    ~H"""
    <div
      id="contact-tab-system"
      class="container mx-auto px-4 py-4 h-[calc(100dvh-4rem)] min-h-0 flex flex-col overflow-hidden"
      phx-hook="ContactTabs"
      data-contact-id={@data_contact_id}
      data-contact-name={@data_contact_name}
      data-page-new={@data_page_new}
      data-contact-subtab={if @contact_page == :show, do: @active_subtab, else: nil}
    >
      <.header>
        Contacts
        <:subtitle>Manage your contacts</:subtitle>
        <:actions>
          <.link patch={~p"/contacts/new"} class="add-contact-link">
            <.button variant="primary">Add Contact</.button>
          </.link>
        </:actions>
      </.header>

      <div id="contact-tabs" phx-update="ignore" class="shrink-0 sticky top-0 z-20 bg-white"></div>

      <div class="content flex-1 min-h-0 border border-t-0 border-gray-200 bg-white rounded-b-lg shadow-sm overflow-hidden">
        <%= case @contact_page do %>
          <% :index -> %>
            <div class="p-4 h-full overflow-auto">
              <%= @table_content.(assigns) %>
            </div>

          <% :show -> %>
            <div class="p-4 h-full overflow-auto">
              <%= case @active_subtab do %>
                <% :details -> %>
                  <.live_component
                    module={SnippetSaverWeb.ContactLive.Components.ShowComponent}
                    id={"contact-show-#{@contact.id}"}
                    contact={@contact}
                    patch_back={~p"/contacts"}
                  />
              <% end %>
            </div>

          <% :edit -> %>
            <div class="p-4 h-full min-h-0 overflow-hidden">
              <.live_component
                module={SnippetSaverWeb.ContactLive.Components.EditComponent}
                id={"contact-edit-#{@contact.id}"}
                contact={@contact}
                patch_back={~p"/contacts"}
                parent_pid={@parent_pid}
              />
            </div>

          <% :new -> %>
            <div class="p-4 h-full overflow-auto">
              <.live_component
                module={SnippetSaverWeb.ContactLive.Components.NewComponent}
                id="contact-new"
                contact={@contact}
                patch_back={~p"/contacts"}
                parent_pid={@parent_pid}
              />
            </div>

          <% _ -> %>
            <div class="p-4 h-full overflow-auto">
              <%= @table_content.(assigns) %>
            </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp contact_display_name(contact) do
    [contact.first_name, contact.last_name]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
    |> case do
      "" -> "Contact ##{contact.id}"
      name -> name
    end
  end
end
