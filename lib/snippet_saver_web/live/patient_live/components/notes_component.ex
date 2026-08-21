defmodule SnippetSaverWeb.PatientLive.Components.NotesComponent do
  use SnippetSaverWeb, :live_component

  alias SnippetSaver.Patients
  alias SnippetSaver.Patients.PatientNote

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:modal_mode, fn -> nil end)
     |> assign_new(:editing_note, fn -> nil end)
     |> assign_new(:form, fn -> nil end)
     |> assign_notes()}
  end

  attr :patient, :any, required: true
  attr :patch_back, :any, required: true

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="flex justify-between items-start mb-6">
        <.header>
          Notes for <%= @patient.patient_name || "Patient ##{@patient.id}" %>
        </.header>

        <.button
          type="button"
          variant="primary"
          size="sm"
          phx-target={@myself}
          phx-click="open-note-modal"
          phx-value-mode="new"
        >
          + Add Note
        </.button>
      </div>

      <div :if={@notes == []} class="text-sm text-gray-400">
        No notes yet.
      </div>

      <div class="space-y-3">
        <.card :for={note <- @notes}>
          <div class="flex justify-between items-start gap-4">
            <div class="min-w-0">
              <div class="flex items-center gap-2 mb-1">
                <span :if={note.notes_important} class="rounded-full bg-red-50 px-2 py-0.5 text-[11px] font-medium text-red-700">
                  Important
                </span>
                <span class="text-xs text-gray-400">
                  <%= Calendar.strftime(note.inserted_at, "%Y-%m-%d %H:%M") %>
                </span>
              </div>
              <p class="text-sm text-gray-800 whitespace-pre-wrap"><%= note.notes %></p>
            </div>

            <div class="flex items-center gap-2 shrink-0">
              <.button
                type="button"
                size="sm"
                variant="outline"
                phx-target={@myself}
                phx-click="open-note-modal"
                phx-value-mode="edit"
                phx-value-id={note.id}
              >
                Edit
              </.button>
              <.button
                type="button"
                size="sm"
                variant="danger"
                phx-target={@myself}
                phx-click="delete-note"
                phx-value-id={note.id}
                data-confirm="Are you sure you want to delete this note?"
              >
                Delete
              </.button>
            </div>
          </div>
        </.card>
      </div>

      <.modal
        :if={@modal_mode}
        id={"patient-note-modal-#{@id}"}
        show
        on_cancel={JS.push("close-note-modal", target: @myself)}
      >
        <div class="space-y-4">
          <h3 class="text-lg font-semibold">
            <%= if @modal_mode == :edit, do: "Edit Note", else: "Add Note" %>
          </h3>

          <.simple_form for={@form} phx-target={@myself} phx-change="validate-note" phx-submit="save-note">
            <.input type="textarea" field={@form[:notes]} label="Notes" rows="4" />
            <.input type="checkbox" field={@form[:notes_important]} label="Mark as important" />

            <:actions>
              <.button type="submit" variant="primary">
                <%= if @modal_mode == :edit, do: "Update", else: "Create" %>
              </.button>
              <.button type="button" variant="outline" phx-target={@myself} phx-click="close-note-modal">
                Cancel
              </.button>
            </:actions>
          </.simple_form>
        </div>
      </.modal>
    </div>
    """
  end

  @impl true
  def handle_event("open-note-modal", %{"mode" => "new"}, socket) do
    changeset = Patients.change_patient_note(%PatientNote{}, %{})

    {:noreply,
     socket
     |> assign(:modal_mode, :new)
     |> assign(:editing_note, nil)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("open-note-modal", %{"mode" => "edit", "id" => id}, socket) do
    note = Enum.find(socket.assigns.notes, &(to_string(&1.id) == to_string(id)))

    if note do
      changeset = Patients.change_patient_note(note, %{})

      {:noreply,
       socket
       |> assign(:modal_mode, :edit)
       |> assign(:editing_note, note)
       |> assign(:form, to_form(changeset))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("close-note-modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:modal_mode, nil)
     |> assign(:editing_note, nil)
     |> assign(:form, nil)}
  end

  def handle_event("validate-note", %{"patient_note" => params}, socket) do
    changeset =
      (socket.assigns.editing_note || %PatientNote{})
      |> Patients.change_patient_note(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save-note", %{"patient_note" => params}, socket) do
    save_note(socket, socket.assigns.modal_mode, params)
  end

  def handle_event("delete-note", %{"id" => id}, socket) do
    note = Enum.find(socket.assigns.notes, &(to_string(&1.id) == to_string(id)))

    case note && Patients.delete_patient_note(note) do
      {:ok, _deleted} ->
        {:noreply,
         socket
         |> put_flash(:info, "Note deleted")
         |> assign_notes()}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete note")}

      nil ->
        {:noreply, socket}
    end
  end

  defp save_note(socket, :new, params) do
    params = Map.put(params, "patient_id", socket.assigns.patient.id)

    case Patients.create_patient_note(params) do
      {:ok, _note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Note added")
         |> assign(:modal_mode, nil)
         |> assign(:editing_note, nil)
         |> assign(:form, nil)
         |> assign_notes()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_note(socket, :edit, params) do
    case Patients.update_patient_note(socket.assigns.editing_note, params) do
      {:ok, _note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Note updated")
         |> assign(:modal_mode, nil)
         |> assign(:editing_note, nil)
         |> assign(:form, nil)
         |> assign_notes()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp assign_notes(socket) do
    assign(socket, :notes, Patients.list_patient_notes_for_patient(socket.assigns.patient.id))
  end
end
