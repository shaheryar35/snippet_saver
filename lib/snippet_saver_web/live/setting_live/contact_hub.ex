defmodule SnippetSaverWeb.SettingLive.ContactHub do
  use SnippetSaverWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Settings · Contacts")
     |> assign(:active_page, "settings_contacts")
     |> assign(:current_path, "setting/contact")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <.header>
        Contact settings
        <:subtitle>Choose a category to manage reference data for contacts</:subtitle>
      </.header>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mt-8">
        <.link patch={~p"/setting/contact/role_types"} class="group block">
          <.card class="h-full transition-shadow group-hover:shadow-md cursor-pointer">
            <div class="flex items-start gap-3">
              <div class="p-2 rounded-lg bg-primary-50">
                <.icon name="hero-rectangle-group" class="h-6 w-6 text-primary-600" />
              </div>
              <div>
                <h3 class="font-semibold text-gray-900">Role types</h3>
                <p class="text-sm text-gray-600 mt-1">
                  Define role types used when assigning roles to contacts (with audit and soft archive).
                </p>
              </div>
            </div>
          </.card>
        </.link>
      </div>
    </div>
    """
  end
end
