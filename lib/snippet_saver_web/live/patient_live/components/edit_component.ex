defmodule SnippetSaverWeb.PatientLive.Components.EditComponent do
  use SnippetSaverWeb, :live_component

  attr :patient, :any, required: true
  attr :patch_back, :any, required: true
  attr :parent_pid, :any, required: true

  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={SnippetSaverWeb.PatientLive.Components.FormComponent}
        id={"edit-patient-form-#{@patient.id}"}
        title="Patient Information"
        action={:edit}
        patient={@patient}
        parent_pid={@parent_pid}
      />
    </div>
    """
  end
end
