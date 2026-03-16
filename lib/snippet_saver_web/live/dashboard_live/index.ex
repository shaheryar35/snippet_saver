defmodule SnippetSaverWeb.DashboardLive.Index do
  use SnippetSaverWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, active_page: "dashboard")}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <.header>
        Dashboard
        <:subtitle>Welcome to SnippetSaver</:subtitle>
      </.header>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mt-6">
        <.stat_card title="Total Employees" value="42" icon="hero-users" />
        <.stat_card title="Active Tasks" value="12" icon="hero-check-circle" />
        <.stat_card title="Completed" value="156" icon="hero-check-badge" />
      </div>
    </div>
    """
  end

  defp stat_card(assigns) do
    ~H"""
    <.card>
      <div class="flex items-center gap-4">
        <div class="p-3 bg-primary-50 rounded-lg">
          <.icon name={@icon} class="h-6 w-6 text-primary-600" />
        </div>
        <div>
          <p class="text-sm text-gray-500"><%= @title %></p>
          <p class="text-2xl font-bold"><%= @value %></p>
        </div>
      </div>
    </.card>
    """
  end
end
