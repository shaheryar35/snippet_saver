defmodule SnippetSaverWeb.EmployeeLive.Components.ActivityComponent do
  use SnippetSaverWeb, :live_component

  attr :employee, :any, required: true
  attr :patch_back, :any, required: true

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">

      <div class="flex justify-between items-start mb-6">
        <.header>
          Activity for <%= @employee.name %>
          <:subtitle><%= @employee.email %></:subtitle>
        </.header>
      </div>

      <.card>
        <p class="text-sm text-gray-500 mb-2">Recent Activity</p>
        <p class="text-sm text-gray-400">
          No activity feed is implemented yet. This tab is a placeholder for future employee activity.
        </p>
      </.card>
    </div>
    """
  end
end
