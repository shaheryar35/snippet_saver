defmodule SnippetSaverWeb.HearAboutOptionLive.Components.FormComponent do
  use SnippetSaverWeb, :live_component

  alias SnippetSaver.Catalog
  alias SnippetSaver.Catalog.HearAboutOption

  def mount(socket) do
    {:ok,
     assign(socket,
       category_options: [{"Referral", "referral"}, {"Online", "online"}, {"Other", "other"}]
     )}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:parent_pid, assigns[:parent_pid])
     |> assign_form()}
  end

  def handle_event("validate", %{"hear_about_option" => params}, socket) do
    changeset =
      socket.assigns.hear_about_option
      |> HearAboutOption.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"hear_about_option" => params}, socket) do
    save_hear_about_option(socket, socket.assigns.action, params)
  end

  defp save_hear_about_option(socket, :new, params) do
    case Catalog.create_hear_about_option(params) do
      {:ok, record} ->
        notify_and_close(socket, record, "Hear About Option created successfully")

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_hear_about_option(socket, :edit, params) do
    case Catalog.update_hear_about_option(socket.assigns.hear_about_option, params) do
      {:ok, record} ->
        notify_and_close(socket, record, "Hear About Option updated successfully")

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp notify_and_close(socket, record, message) do
    if pid = socket.assigns[:parent_pid] do
      send(pid, {:hear_about_option_saved, record, message})
      {:noreply, socket}
    else
      {:noreply,
       socket
       |> put_flash(:info, message)
       |> push_navigate(to: ~p"/hear_about_options/#{record}")}
    end
  end

  defp assign_form(socket) do
    changeset = HearAboutOption.changeset(socket.assigns.hear_about_option, %{})
    assign(socket, form: to_form(changeset))
  end

  def render(assigns) do
    ~H"""
    <div id={"hear_about_option-form-#{@id}"}>
      <.form_container>
        <.simple_form for={@form} phx-target={@myself} phx-change="validate" phx-submit="save">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <.input type="text" field={@form[:name]} label="Name" />
            <.yes_no
              name="hear_about_option[is_active]"
              label="Is Active"
              value={Phoenix.HTML.Form.input_value(@form, :is_active)}
            />
            <.input
              type="select"
              field={@form[:category]}
              label="Category"
              options={@category_options}
              prompt="Select category"
            />
          </div>

          <:actions>
            <.button type="submit" variant="primary" size="lg">
              {if @action == :new, do: "Create Hear About Option", else: "Update Hear About Option"}
            </.button>
            <.link patch={@patch_back}>
              <.button type="button" variant="outline" size="lg">Cancel</.button>
            </.link>
          </:actions>
        </.simple_form>
      </.form_container>
    </div>
    """
  end
end
