defmodule SnippetSaverWeb.PatientLive.Components.ImagesComponent do
  use SnippetSaverWeb, :live_component

  attr :patient, :any, required: true
  attr :patch_back, :any, required: true

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <.header>
        Images for <%= @patient.patient_name || "Patient ##{@patient.id}" %>
      </.header>

      <.card>
        <p class="text-sm text-gray-500 mb-2">Images</p>
        <p class="text-sm text-gray-400">
          Image upload is not implemented yet. This tab is a placeholder for
          future patient image management.
        </p>
      </.card>
    </div>
    """
  end
end
