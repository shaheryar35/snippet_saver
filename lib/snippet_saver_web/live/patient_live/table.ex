defmodule SnippetSaverWeb.PatientLive.Table do
  use SnippetSaverWeb, :html
  import Ecto.Query

  def fields do
    [
      patient_name: %{
        label: "Patient Name",
        sortable: true,
        searchable: true,
        renderer: fn name, assigns ->
          patient = assigns.actions
          label = name || "Patient ##{patient.id}"
          clickable_cell(patient, label)
        end
      },
      code: %{
        label: "Code",
        sortable: true,
        searchable: true,
        renderer: fn code, assigns ->
          patient = assigns.actions
          clickable_cell(patient, code || "—")
        end
      },
      microchip_number: %{
        label: "Microchip",
        sortable: true,
        searchable: true,
        renderer: fn value, assigns ->
          patient = assigns.actions
          clickable_cell(patient, value || "—")
        end
      },
      sex: %{
        label: "Sex",
        sortable: true,
        searchable: true,
        renderer: fn value, assigns ->
          patient = assigns.actions
          clickable_cell(patient, value || "—")
        end
      },
      age: %{
        label: "Age",
        sortable: true,
        searchable: false,
        renderer: fn value, assigns ->
          patient = assigns.actions
          clickable_cell(patient, value || "—")
        end
      },
      actions: %{
        label: "Actions",
        sortable: false,
        computed: dynamic([resource: r], r),
        renderer: fn patient ->
          assigns = %{id: patient.id}

          ~H"""
          <div class="flex gap-2">
            <.button type="button" phx-click="go-to-edit" phx-value-id={@id} variant="outline" size="xs">
              <.icon name="hero-pencil" class="h-3 w-3" />
            </.button>
            <.button phx-click="delete" phx-value-id={@id} variant="danger" size="xs" data-confirm="Are you sure?">
              <.icon name="hero-trash" class="h-3 w-3" />
            </.button>
          </div>
          """
        end
      }
    ]
  end

  def filters, do: []

  def table_options do
    %{
      use_streams: false,
      pagination: %{
        enabled: true,
        sizes: [10, 25, 50, 100],
        default_size: 10
      }
    }
  end

  defp clickable_cell(patient, label) do
    assigns = %{patient: patient, label: label}

    ~H"""
    <button
      type="button"
      class="patient-name-link text-left hover:text-primary-600 focus:outline-none w-full block"
      data-patient-id={@patient.id}
      data-patient-name={@patient.patient_name || "Patient ##{@patient.id}"}
    >
      <%= @label %>
    </button>
    """
  end
end
