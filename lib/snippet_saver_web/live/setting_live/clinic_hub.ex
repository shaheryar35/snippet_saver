defmodule SnippetSaverWeb.SettingLive.ClinicHub do
  use SnippetSaverWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Settings · Clinic")
     |> assign(:active_page, "clinic")
     |> assign(:current_path, "setting/clinic")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <.header>
        Clinic settings
        <:subtitle>Manage reference data used for scheduling and clinic workflows</:subtitle>
      </.header>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mt-8">
        <.link patch={~p"/setting/clinic/appointment_types"} class="group block">
          <.card class="h-full transition-shadow group-hover:shadow-md cursor-pointer">
            <div class="flex items-start gap-3">
              <div class="p-2 rounded-lg bg-primary-50">
                <.icon name="hero-calendar-days" class="h-6 w-6 text-primary-600" />
              </div>
              <div>
                <h3 class="font-semibold text-gray-900">Appointment types</h3>
                <p class="text-sm text-gray-600 mt-1">
                  Durations, colors, and active flags for appointment types (with audit and soft archive).
                </p>
              </div>
            </div>
          </.card>
        </.link>

        <.link patch={~p"/setting/clinic/appointment_status"} class="group block">
          <.card class="h-full transition-shadow group-hover:shadow-md cursor-pointer">
            <div class="flex items-start gap-3">
              <div class="p-2 rounded-lg bg-primary-50">
                <.icon name="hero-flag" class="h-6 w-6 text-primary-600" />
              </div>
              <div>
                <h3 class="font-semibold text-gray-900">Appointment status</h3>
                <p class="text-sm text-gray-600 mt-1">
                  Status labels and colors for appointments (with audit and soft archive).
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
