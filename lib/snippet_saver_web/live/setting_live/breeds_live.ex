defmodule SnippetSaverWeb.SettingLive.BreedsLive do
  use SnippetSaverWeb, :live_view

  use LiveTable.ExportHelpers, schema: SnippetSaver.Settings.Breed
  use LiveTable.FilterToggleHelpers
  use LiveTable.FilterHelpers

  use LiveTable.TableComponent,
    table_options:
      LiveTable.TableConfig.get_table_options(
        SnippetSaverWeb.SettingLive.BreedTable.table_options()
      )

  import LiveTable.SortHelpers

  alias SnippetSaver.Repo
  alias SnippetSaver.Settings
  alias SnippetSaver.Settings.Breed
  alias SnippetSaverWeb.SettingLive.{BreedTable, CatalogTableSupport}

  def fields, do: BreedTable.fields()
  def filters, do: BreedTable.filters()

  def list_resources(fields, options, schema \\ Breed) do
    CatalogTableSupport.list_resources(fields, options, schema, BreedTable.table_options())
  end

  def stream_resources(fields, options, schema \\ Breed) do
    CatalogTableSupport.stream_resources(fields, options, schema, BreedTable.table_options())
  end

  def get_merged_table_options do
    CatalogTableSupport.get_merged_table_options(BreedTable.table_options())
  end

  @new_drawer_id "new-breed-drawer"
  @view_drawer_id "view-breed-drawer"

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Breeds")
     |> assign(:active_page, "settings_patient")
     |> assign(:detail_form, nil)
     |> assign(:detail_mode, nil)
     |> assign(:detail_record, nil)
     |> assign(:species_options, species_options())
     |> assign(:form, to_form(Settings.change_breed(%Breed{})))
     |> assign(:table_query_string, "")}
  end

  defp species_options do
    Settings.list_species_for_admin()
    |> Enum.map(&{&1.name, &1.id})
  end

  @impl true
  def handle_params(params, uri, socket) do
    socket =
      CatalogTableSupport.apply_table_params(
        socket,
        params,
        uri,
        Breed,
        BreedTable,
        &get_filter/1
      )

    {:noreply, socket}
  end

  defp index_path(%{table_query_string: ""}), do: ~p"/setting/patient/breeds"
  defp index_path(%{table_query_string: qs}), do: "/setting/patient/breeds?" <> qs

  defp load_breed_detail(id) do
    Settings.get_breed!(id) |> Repo.preload([:inserted_by, :updated_by, :species])
  end

  @impl true
  def handle_event("sort", %{"clear_filters" => "true"}, socket) do
    CatalogTableSupport.handle_sort_clear(socket)
  end

  def handle_event("sort", params, socket) do
    shift_key = Map.get(params, "shift_key", false)
    sort_params = Map.get(params, "sort", nil)
    filter_params = Map.get(params, "filters", nil)
    current_path = socket.assigns.current_path

    options =
      socket.assigns.options
      |> Enum.reduce(%{}, fn
        {"filters", %{"search" => search_term} = v}, acc ->
          filters = encode_filters(v)
          Map.put(acc, "filters", filters) |> Map.put("search", search_term)

        {_, v}, acc when is_map(v) ->
          Map.merge(acc, v)
      end)
      |> Map.merge(params, fn
        "filters", v1, v2 when is_map(v1) and is_map(v2) -> v1
        _, _, v -> v
      end)
      |> update_sort_params(sort_params, shift_key)
      |> update_filter_params(filter_params)
      |> Map.take(~w(page per_page search sort_params filters))
      |> Map.reject(fn {_, v} -> v == "" || is_nil(v) end)
      |> remove_unused_keys()

    {:noreply, push_patch(socket, to: "/#{current_path}?#{Plug.Conn.Query.encode(options)}")}
  end

  defp remove_unused_keys(map) when is_map(map) do
    map
    |> Map.reject(fn {key, _value} ->
      key_string = to_string(key)
      String.starts_with?(key_string, "_unused")
    end)
    |> Enum.map(fn {key, value} ->
      {key, remove_unused_keys(value)}
    end)
    |> Enum.into(%{})
  end

  defp remove_unused_keys(value), do: value

  @impl true
  def handle_event("open_detail", %{"id" => id}, socket) do
    id = String.to_integer(id)
    b = load_breed_detail(id)
    cs = Settings.change_breed(b)

    {:noreply,
     socket
     |> assign(:species_options, species_options())
     |> assign(:detail_record, b)
     |> assign(:detail_mode, :view)
     |> assign(:detail_form, to_form(cs))}
  end

  def handle_event("detail_close", _params, socket) do
    {:noreply,
     socket
     |> assign(:detail_form, nil)
     |> assign(:detail_mode, nil)
     |> assign(:detail_record, nil)}
  end

  def handle_event("detail_begin_edit", _params, socket) do
    {:noreply, assign(socket, :detail_mode, :edit)}
  end

  def handle_event("detail_cancel_edit", _params, socket) do
    id = socket.assigns.detail_record.id
    b = load_breed_detail(id)
    cs = Settings.change_breed(b)

    {:noreply,
     socket
     |> assign(:detail_record, b)
     |> assign(:detail_mode, :view)
     |> assign(:detail_form, to_form(cs))}
  end

  def handle_event("validate", %{"breed" => params}, socket) do
    changeset =
      %Breed{}
      |> Settings.change_breed(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("create", %{"breed" => params}, socket) do
    case Settings.create_breed(params, socket.assigns.current_user.id) do
      {:ok, _} ->
        to = index_path(socket.assigns)

        {:noreply,
         socket
         |> put_flash(:info, "Breed created.")
         |> assign(:form, to_form(Settings.change_breed(%Breed{})))
         |> push_patch(to: to)}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, :form, to_form(cs))}
    end
  end

  def handle_event("edit", %{"id" => id}, socket) do
    id = String.to_integer(id)
    b = load_breed_detail(id)
    cs = Settings.change_breed(b)

    {:noreply,
     socket
     |> assign(:species_options, species_options())
     |> assign(:detail_record, b)
     |> assign(:detail_mode, :edit)
     |> assign(:detail_form, to_form(cs))}
  end

  def handle_event("validate_detail", %{"breed" => params}, socket) do
    if socket.assigns.detail_mode != :edit do
      {:noreply, socket}
    else
      b = socket.assigns.detail_record

      changeset =
        b
        |> Settings.change_breed(params)
        |> Map.put(:action, :validate)

      {:noreply, assign(socket, :detail_form, to_form(changeset))}
    end
  end

  def handle_event("update_detail", %{"breed" => params}, socket) do
    if socket.assigns.detail_mode != :edit do
      {:noreply, socket}
    else
      b = socket.assigns.detail_record

      case Settings.update_breed(b, params, socket.assigns.current_user.id) do
        {:ok, _} ->
          to = index_path(socket.assigns)

          {:noreply,
           socket
           |> put_flash(:info, "Breed updated.")
           |> assign(:detail_form, nil)
           |> assign(:detail_mode, nil)
           |> assign(:detail_record, nil)
           |> push_patch(to: to)}

        {:error, %Ecto.Changeset{} = cs} ->
          {:noreply, assign(socket, :detail_form, to_form(cs))}
      end
    end
  end

  def handle_event("archive", %{"id" => id}, socket) do
    id = String.to_integer(id)
    b = Settings.get_breed!(id)

    case Settings.archive_breed(b, socket.assigns.current_user.id) do
      {:ok, _} ->
        to = index_path(socket.assigns)

        socket =
          socket
          |> put_flash(:info, "Breed archived.")

        socket =
          if match?(%Breed{}, socket.assigns.detail_record) &&
               socket.assigns.detail_record.id == id do
            assign(socket, detail_form: nil, detail_mode: nil, detail_record: nil)
          else
            socket
          end

        {:noreply, push_patch(socket, to: to)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not archive this breed.")}
    end
  end

  def handle_event("restore", %{"id" => id}, socket) do
    id = String.to_integer(id)
    b = Settings.get_breed!(id)

    case Settings.restore_breed(b, socket.assigns.current_user.id) do
      {:ok, _} ->
        to = index_path(socket.assigns)
        {:noreply, socket |> put_flash(:info, "Breed restored.") |> push_patch(to: to)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not restore this breed.")}
    end
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:new_drawer_id, @new_drawer_id)
      |> assign(:view_drawer_id, @view_drawer_id)

    ~H"""
    <div class="container mx-auto px-4 py-8">
      <.link patch={~p"/setting/patient"}>
        <.button variant="ghost" class="mb-4">
          <.icon name="hero-arrow-left" class="h-4 w-4 mr-1" /> Back to patient settings
        </.button>
      </.link>

      <.header>
        Breeds
        <:subtitle>Manage breeds (archived items are hidden from patient pickers)</:subtitle>
        <:actions>
          <.button type="button" variant="primary" phx-click={show_drawer(@new_drawer_id)}>
            Add new breed
          </.button>
        </:actions>
      </.header>

      <div class="content border border-gray-200 bg-white rounded-lg shadow-sm min-h-[320px] mt-6">
        <div class="p-4">
          <.live_table
            fields={fields()}
            filters={filters()}
            options={@options}
            streams={@resources}
            per_page={[10, 25, 50, 100]}
            default_per_page={10}
            show_search={true}
            show_columns_toggle={true}
            show_export={true}
          />
        </div>
      </div>

      <.drawer
        :if={@detail_form}
        id={@view_drawer_id}
        show={true}
        on_cancel={JS.push("detail_close")}
      >
        <div class="space-y-4">
          <div class="flex flex-wrap items-start justify-between gap-3 border-b border-gray-200 pb-4">
            <div>
              <h3 id={"#{@view_drawer_id}-title"} class="text-lg font-semibold text-gray-900">
                <%= if @detail_mode == :edit do %>
                  Edit breed
                <% else %>
                  Breed details
                <% end %>
              </h3>
              <p id={"#{@view_drawer_id}-description"} class="text-sm text-gray-600">
                <%= if @detail_mode == :view do %>
                  View details. Use Edit to make changes.
                <% else %>
                  Update fields, then save.
                <% end %>
              </p>
            </div>
            <div class="flex flex-wrap items-center gap-2 shrink-0">
              <%= if @detail_mode == :view && @detail_record && @detail_record.archived == false do %>
                <.button type="button" variant="primary" phx-click="detail_begin_edit">
                  Edit
                </.button>
              <% end %>
              <%= if @detail_mode == :edit do %>
                <.button type="button" variant="outline" phx-click="detail_cancel_edit">
                  Cancel edit
                </.button>
              <% end %>
            </div>
          </div>

          <.simple_form
            for={@detail_form}
            phx-change="validate_detail"
            phx-submit="update_detail"
            class="space-y-4"
          >
            <div class="grid grid-cols-1 gap-4">
              <.input
                field={@detail_form[:name]}
                type="text"
                label="Name"
                required={@detail_mode == :edit}
                readonly={@detail_mode == :view}
              />
              <.input
                field={@detail_form[:species_id]}
                type="select"
                label="Species"
                options={@species_options}
                prompt="Select species"
                required={@detail_mode == :edit}
                disabled={@detail_mode == :view}
              />
            </div>
            <:actions :if={@detail_mode == :edit}>
              <.button type="submit" variant="primary">Save</.button>
            </:actions>
          </.simple_form>
        </div>
      </.drawer>

      <.drawer id={@new_drawer_id} on_cancel={hide_drawer(@new_drawer_id)}>
        <div class="space-y-4">
          <h3 id={"#{@new_drawer_id}-title"} class="text-lg font-semibold text-gray-900">
            New breed
          </h3>
          <p id={"#{@new_drawer_id}-description"} class="text-sm text-gray-600">
            Choose a species and name for this breed. You can archive it later if it is no longer needed.
          </p>
          <.simple_form for={@form} class="space-y-4" phx-change="validate" phx-submit="create">
            <div class="grid grid-cols-1 gap-4">
              <.input field={@form[:name]} type="text" label="Name" required />
              <.input
                field={@form[:species_id]}
                type="select"
                label="Species"
                options={@species_options}
                prompt="Select species"
                required
              />
            </div>
            <:actions>
              <.button type="submit" variant="primary">Create</.button>
              <.button type="button" variant="outline" phx-click={hide_drawer(@new_drawer_id)}>
                Cancel
              </.button>
            </:actions>
          </.simple_form>
        </div>
      </.drawer>
    </div>
    """
  end
end
