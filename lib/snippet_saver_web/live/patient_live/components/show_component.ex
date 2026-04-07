defmodule SnippetSaverWeb.PatientLive.Components.ShowComponent do
  use SnippetSaverWeb, :live_component

  alias SnippetSaver.Contacts
  alias SnippetSaver.Settings

  attr :patient, :any, required: true
  attr :patch_back, :any, required: true

  def render(assigns) do
    assigns =
      assigns
      |> assign(:owner_name, contact_name(assigns.patient.owner_contact_id))
      |> assign(:species_name, settings_name(:species, assigns.patient.species_id))
      |> assign(:breed_name, settings_name(:breed, assigns.patient.breed_id))
      |> assign(:colour_name, settings_name(:colour, assigns.patient.colour_id))

    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="flex justify-between items-start mb-6">
        <.header>
          <%= @patient.patient_name || "Patient ##{@patient.id}" %>
          <:subtitle>Code: <%= @patient.code || "—" %></:subtitle>
        </.header>

        <.button
          variant="outline"
          size="sm"
          phx-click="go-to-edit"
          phx-value-id={@patient.id}
          phx-target={@myself}
        >
          <.icon name="hero-pencil" class="h-4 w-4 mr-1" />
          Edit
        </.button>
      </div>

      <.card>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
          <div><span class="text-gray-500">Microchip:</span> <%= @patient.microchip_number || "—" %></div>
          <div><span class="text-gray-500">Sex:</span> <%= @patient.sex || "—" %></div>
          <div><span class="text-gray-500">Age:</span> <%= @patient.age || "—" %></div>
          <div><span class="text-gray-500">Weight:</span> <%= @patient.weight || "—" %> <%= @patient.weight_unit || "" %></div>
          <div><span class="text-gray-500">Owner:</span> <%= @owner_name %></div>
          <div><span class="text-gray-500">Species:</span> <%= @species_name %></div>
          <div><span class="text-gray-500">Breed:</span> <%= @breed_name %></div>
          <div><span class="text-gray-500">Colour:</span> <%= @colour_name %></div>
          <div><span class="text-gray-500">Insurance #:</span> <%= @patient.insurance_number || "—" %></div>
        </div>
      </.card>
    </div>
    """
  end

  def handle_event("go-to-edit", %{"id" => id}, socket) do
    send(self(), {:go_to_edit, id})
    {:noreply, socket}
  end

  defp contact_name(nil), do: "—"

  defp contact_name(id) do
    contact = Contacts.get_contact!(id)
    [contact.first_name, contact.last_name] |> Enum.reject(&is_nil/1) |> Enum.join(" ")
  rescue
    _ -> "—"
  end

  defp settings_name(_type, nil), do: "—"
  defp settings_name(:species, id), do: safe_name(fn -> Settings.get_species!(id).name end)
  defp settings_name(:breed, id), do: safe_name(fn -> Settings.get_breed!(id).name end)
  defp settings_name(:colour, id), do: safe_name(fn -> Settings.get_colour!(id).name end)

  defp safe_name(fun) do
    fun.()
  rescue
    _ -> "—"
  end
end
