defmodule SnippetSaverWeb.ContactLive.Components.PermissionsComponent do
  use SnippetSaverWeb, :live_component

  attr :contact, :any, required: true
  attr :patch_back, :any, required: true

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="flex justify-between items-start mb-6">
        <.header>
          Permissions for <%= display_name(@contact) %>
          <:subtitle><%= @contact.title || "No title" %></:subtitle>
        </.header>
      </div>

      <.card>
        <p class="text-sm text-gray-500 mb-2">Permissions</p>
        <p class="text-sm text-gray-400">
          No permission management UI is implemented yet. This tab is a placeholder for future contact permissions.
        </p>
      </.card>
    </div>
    """
  end

  defp display_name(contact) do
    [contact.first_name, contact.last_name]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
    |> case do
      "" -> "Contact ##{contact.id}"
      name -> name
    end
  end
end
