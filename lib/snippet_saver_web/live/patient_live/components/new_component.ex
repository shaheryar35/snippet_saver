defmodule SnippetSaverWeb.PatientLive.Components.NewComponent do
  use SnippetSaverWeb, :live_component

  attr :patient, :any, required: true
  attr :patch_back, :any, required: true
  attr :parent_pid, :any, required: true

  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={SnippetSaverWeb.PatientLive.Components.FormComponent}
        id="new-patient-form"
        title="Patient Information"
        action={:new}
        patient={@patient}
        parent_pid={@parent_pid}
      />
    </div>
    """
  end
end
