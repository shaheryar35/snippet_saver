defmodule SnippetSaverWeb.PatientLive.PatientRouter do
  @moduledoc false
  import Phoenix.Component, only: [assign: 3]

  alias SnippetSaver.Patients
  alias SnippetSaver.Patients.Patient

  def handle(params, uri, socket) do
    path = URI.parse(uri).path |> String.trim_leading("/") |> String.split("/")

    case page_from_path(path) do
      :index ->
        {:index, socket, params, path}

      :new ->
        {:noreply,
         socket
         |> assign(:patient_page, :new)
         |> assign(:patient, %Patient{})
         |> assign(:page_title, "New Patient")
         |> assign(:active_page, "patients")}

      {:show, id} ->
        patient = Patients.get_patient!(id)

        {:noreply,
         socket
         |> assign(:patient_page, :show)
         |> assign(:patient, patient)
         |> assign(:page_title, patient.patient_name || "Patient ##{patient.id}")
         |> assign(:active_page, "patients")}

      {:edit, id} ->
        patient = Patients.get_patient!(id)

        {:noreply,
         socket
         |> assign(:patient_page, :edit)
         |> assign(:patient, patient)
         |> assign(:page_title, "Edit Patient")
         |> assign(:active_page, "patients")}
    end
  end

  defp page_from_path(["patients"]), do: :index

  defp page_from_path(["patients" | rest]) do
    case rest do
      [] -> :index
      ["new"] -> :new
      [id, "edit"] -> {:edit, String.to_integer(id)}
      [id] -> {:show, String.to_integer(id)}
      _ -> :index
    end
  end

  defp page_from_path(_), do: :index
end
