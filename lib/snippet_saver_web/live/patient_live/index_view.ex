defmodule SnippetSaverWeb.PatientLive.IndexView do
  use SnippetSaverWeb, :html

  def render("index.html", assigns) do
    show_patient? = assigns[:patient_page] in [:show, :edit] and is_map_key(assigns, :patient)
    is_new_page? = assigns[:patient_page] == :new
    active_subtab = Map.get(assigns, :active_subtab, :details)

    assigns =
      assigns
      |> assign(:show_patient?, show_patient?)
      |> assign(:data_patient_id, if(show_patient?, do: assigns.patient.id, else: nil))
      |> assign(
        :data_patient_name,
        if(show_patient?, do: patient_display_name(assigns.patient), else: nil)
      )
      |> assign(:data_page_new, is_new_page?)
      |> assign(:active_subtab, active_subtab)

    ~H"""
    <div
      id="patient-tab-system"
      class="container mx-auto px-4 py-4 h-[calc(100dvh-4rem)] min-h-0 flex flex-col overflow-hidden"
      phx-hook="PatientTabs"
      data-patient-id={@data_patient_id}
      data-patient-name={@data_patient_name}
      data-page-new={@data_page_new}
      data-patient-subtab={if @patient_page == :show, do: @active_subtab, else: nil}
    >
      <.header>
        Patients
        <:subtitle>Manage patient records</:subtitle>
        <:actions>
          <.link patch={~p"/patients/new"} class="add-patient-link">
            <.button variant="primary">Add Patient</.button>
          </.link>
        </:actions>
      </.header>

      <div id="patient-tabs" phx-update="ignore" class="shrink-0 sticky top-0 z-20 bg-white"></div>

      <div class="content flex-1 min-h-0 border border-t-0 border-gray-200 bg-white rounded-b-lg shadow-sm overflow-hidden">
        <%= case @patient_page do %>
          <% :index -> %>
            <div class="p-4 h-full overflow-auto">
              <%= @table_content.(assigns) %>
            </div>

          <% :show -> %>
            <div class="p-4 h-full overflow-auto">
              <.live_component
                module={SnippetSaverWeb.PatientLive.Components.ShowComponent}
                id={"patient-show-#{@patient.id}"}
                patient={@patient}
                patch_back={~p"/patients"}
              />
            </div>

          <% :edit -> %>
            <div class="p-4 h-full min-h-0 overflow-hidden">
              <.live_component
                module={SnippetSaverWeb.PatientLive.Components.EditComponent}
                id={"patient-edit-#{@patient.id}"}
                patient={@patient}
                patch_back={~p"/patients"}
                parent_pid={@parent_pid}
              />
            </div>

          <% :new -> %>
            <div class="p-4 h-full overflow-auto">
              <.live_component
                module={SnippetSaverWeb.PatientLive.Components.NewComponent}
                id="patient-new"
                patient={@patient}
                patch_back={~p"/patients"}
                parent_pid={@parent_pid}
              />
            </div>

          <% _ -> %>
            <div class="p-4 h-full overflow-auto">
              <%= @table_content.(assigns) %>
            </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp patient_display_name(patient) do
    case String.trim(patient.patient_name || "") do
      "" -> "Patient ##{patient.id}"
      name -> name
    end
  end
end
