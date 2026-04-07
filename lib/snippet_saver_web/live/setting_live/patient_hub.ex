defmodule SnippetSaverWeb.SettingLive.PatientHub do
  use SnippetSaverWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Settings · Patient")
     |> assign(:active_page, "settings_patient")
     |> assign(:current_path, "setting/patient")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <.header>
        Patient settings
        <:subtitle>Choose a category to manage reference data for patients</:subtitle>
      </.header>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mt-8">
        <.link patch={~p"/setting/patient/species"} class="group block">
          <.card class="h-full transition-shadow group-hover:shadow-md cursor-pointer">
            <div class="flex items-start gap-3">
              <div class="p-2 rounded-lg bg-primary-50">
                <.icon name="hero-squares-2x2" class="h-6 w-6 text-primary-600" />
              </div>
              <div>
                <h3 class="font-semibold text-gray-900">Species</h3>
                <p class="text-sm text-gray-600 mt-1">
                  Manage species used on patient records (with audit and soft archive).
                </p>
              </div>
            </div>
          </.card>
        </.link>

        <.link patch={~p"/setting/patient/breeds"} class="group block">
          <.card class="h-full transition-shadow group-hover:shadow-md cursor-pointer">
            <div class="flex items-start gap-3">
              <div class="p-2 rounded-lg bg-primary-50">
                <.icon name="hero-queue-list" class="h-6 w-6 text-primary-600" />
              </div>
              <div>
                <h3 class="font-semibold text-gray-900">Breeds</h3>
                <p class="text-sm text-gray-600 mt-1">
                  Manage breeds linked to species (with audit and soft archive).
                </p>
              </div>
            </div>
          </.card>
        </.link>

        <.link patch={~p"/setting/patient/colours"} class="group block">
          <.card class="h-full transition-shadow group-hover:shadow-md cursor-pointer">
            <div class="flex items-start gap-3">
              <div class="p-2 rounded-lg bg-primary-50">
                <.icon name="hero-swatch" class="h-6 w-6 text-primary-600" />
              </div>
              <div>
                <h3 class="font-semibold text-gray-900">Colours</h3>
                <p class="text-sm text-gray-600 mt-1">
                  Manage coat / colour options for patients (with audit and soft archive).
                </p>
              </div>
            </div>
          </.card>
        </.link>

        <.link patch={~p"/setting/patient/problem_templates"} class="group block">
          <.card class="h-full transition-shadow group-hover:shadow-md cursor-pointer">
            <div class="flex items-start gap-3">
              <div class="p-2 rounded-lg bg-primary-50">
                <.icon name="hero-clipboard-document-list" class="h-6 w-6 text-primary-600" />
              </div>
              <div>
                <h3 class="font-semibold text-gray-900">Master problem templates</h3>
                <p class="text-sm text-gray-600 mt-1">
                  Reusable problem templates for patient master problems (with audit and soft archive).
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
