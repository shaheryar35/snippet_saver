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
        <:subtitle>Add clinic-related configuration cards here as you grow this section</:subtitle>
      </.header>

      <div class="mt-8 rounded-lg border border-dashed border-gray-300 bg-white p-8 text-center text-sm text-gray-500">
        No clinic setting modules yet — this hub is ready for cards (same pattern as Contact settings).
      </div>
    </div>
    """
  end
end
