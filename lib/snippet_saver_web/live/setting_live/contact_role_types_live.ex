defmodule SnippetSaverWeb.SettingLive.ContactRoleTypesLive do
  use SnippetSaverWeb, :live_view

  use LiveTable.ExportHelpers, schema: SnippetSaver.Contacts.ContactRoleType
  use LiveTable.FilterToggleHelpers
  use LiveTable.FilterHelpers

  use LiveTable.TableComponent,
    table_options:
      LiveTable.TableConfig.get_table_options(
        SnippetSaverWeb.SettingLive.ContactRoleTypeTable.table_options()
      )

  import Ecto.Query
  import LiveTable.Filter
  import LiveTable.Join
  import LiveTable.Paginate
  import LiveTable.Sorting
  import LiveTable.SortHelpers
  import Debug, only: [debug_pipeline: 2]

  alias SnippetSaver.Contacts
  alias SnippetSaver.Contacts.ContactRoleType
  alias SnippetSaver.Repo
  alias SnippetSaverWeb.SettingLive.ContactRoleTypeTable

  @repo Application.compile_env(:live_table, :repo)

  def fields, do: ContactRoleTypeTable.fields()
  def filters, do: ContactRoleTypeTable.filters()

  def list_resources(fields, options, schema \\ ContactRoleType) do
    {regular_filters, transformers, debug_mode} = prepare_query_context(options)

    schema
    |> from(as: :resource)
    |> join_associations(regular_filters)
    |> select_columns(fields)
    |> apply_filters(regular_filters, fields)
    |> maybe_sort(fields, options["sort"]["sort_params"], options["sort"]["sortable?"])
    |> apply_transformers(transformers)
    |> maybe_paginate(options["pagination"], options["pagination"]["paginate?"])
    |> debug_pipeline(debug_mode)
  end

  def stream_resources(
        fields,
        %{"pagination" => %{"paginate?" => true}} = options,
        data_source
      ) do
    per_page = options["pagination"]["per_page"] |> String.to_integer()
    data_source = data_source || ContactRoleType

    list_resources(fields, options, data_source)
    |> @repo.all()
    |> Enum.split(per_page)
  end

  def stream_resources(
        fields,
        %{"pagination" => %{"paginate?" => false}} = options,
        data_source
      ) do
    data_source = data_source || ContactRoleType
    list_resources(fields, options, data_source) |> @repo.all()
  end

  def get_merged_table_options do
    LiveTable.TableConfig.get_table_options(ContactRoleTypeTable.table_options())
  end

  defp prepare_query_context(options) do
    debug_mode =
      Map.get(LiveTable.TableConfig.get_table_options(ContactRoleTypeTable.table_options()), :debug, :off)

    {regular_filters, transformers} =
      Map.get(options, "filters", nil)
      |> separate_filters_and_transformers()

    {regular_filters, transformers, debug_mode}
  end

  defp separate_filters_and_transformers(filters) when is_map(filters) do
    {transformers, regular_filters} =
      filters
      |> Enum.split_with(fn {_, filter} ->
        match?(%LiveTable.Transformer{}, filter)
      end)

    {Map.new(regular_filters), Map.new(transformers)}
  end

  defp separate_filters_and_transformers(nil), do: {%{}, %{}}

  defp apply_transformers(query, transformers) do
    Enum.reduce(transformers, query, fn {_key, transformer}, acc ->
      LiveTable.Transformer.apply(acc, transformer)
    end)
  end

  @new_modal_id "new-contact-role-type-modal"

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Role types")
     |> assign(:active_page, "settings_contacts")
     |> assign(:editing_id, nil)
     |> assign(:edit_form, nil)
     |> assign(:form, to_form(Contacts.change_contact_role_type(%ContactRoleType{})))
     |> assign(:table_query_string, "")}
  end

  @impl true
  def handle_params(params, uri, socket) do
    apply_table_params(socket, params, uri)
  end

  defp apply_table_params(socket, params, uri) do
    current_path =
      uri
      |> URI.parse()
      |> Map.get(:path, "")
      |> String.trim_leading("/")

    qs = uri |> URI.parse() |> Map.get(:query)
    table_query_string = if is_binary(qs), do: qs, else: ""

    opts = get_merged_table_options()
    default_sort = get_in(opts, [:sorting, :default_sort]) || [id: :asc]

    sort_params =
      case params["sort_params"] do
        nil -> default_sort
        %{} = m when map_size(m) == 0 -> default_sort
        other -> other
      end
      |> Enum.map(fn
        {k, v} when is_atom(k) and is_atom(v) -> {k, v}
        {k, v} -> {String.to_existing_atom(k), String.to_existing_atom(v)}
      end)

    filters =
      (params["filters"] || %{})
      |> Map.put("search", params["search"] || "")
      |> Enum.reduce(%{}, fn
        {"search", search_term}, acc ->
          Map.put(acc, "search", search_term)

        {k, _}, acc ->
          Map.put(acc, String.to_existing_atom(k), get_filter(k))
      end)

    options = %{
      "sort" => %{
        "sortable?" => get_in(opts, [:sorting, :enabled]),
        "sort_params" => sort_params
      },
      "pagination" => %{
        "paginate?" => get_in(opts, [:pagination, :enabled]),
        "page" => params["page"] || "1",
        "per_page" =>
          params["per_page"] || to_string(get_in(opts, [:pagination, :default_size]) || 10)
      },
      "filters" => filters
    }

    {resources, updated_options} =
      case stream_resources(fields(), options, ContactRoleType) do
        {resources, overflow} ->
          options = put_in(options["pagination"][:has_next_page], length(overflow) > 0)
          {resources, options}

        resources when is_list(resources) ->
          {resources, options}
      end

    socket =
      socket
      |> assign(:resources, resources)
      |> assign(:options, updated_options)
      |> assign(:current_path, current_path)
      |> assign(:table_query_string, table_query_string)

    {:noreply, socket}
  end

  defp role_types_index_path(%{table_query_string: ""}), do: ~p"/setting/contact/role_types"

  defp role_types_index_path(%{table_query_string: qs}),
    do: "/setting/contact/role_types?" <> qs

  @impl true
  def handle_event("sort", %{"clear_filters" => "true"}, socket) do
    current_path = socket.assigns.current_path

    options =
      socket.assigns.options
      |> Enum.reduce(%{}, fn
        {"filters", _v}, acc ->
          Map.put(acc, "filters", %{})

        {_, v}, acc when is_map(v) ->
          Map.merge(acc, v)
      end)
      |> Map.take(~w(page per_page sort_params))
      |> Map.reject(fn {_, v} -> v == "" || is_nil(v) end)

    {:noreply, push_patch(socket, to: "/#{current_path}?#{Plug.Conn.Query.encode(options)}")}
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
  def handle_event("validate", %{"contact_role_type" => params}, socket) do
    changeset =
      %ContactRoleType{}
      |> Contacts.change_contact_role_type(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("create", %{"contact_role_type" => params}, socket) do
    case Contacts.create_contact_role_type(params, socket.assigns.current_user.id) do
      {:ok, _} ->
        to = role_types_index_path(socket.assigns)

        {:noreply,
         socket
         |> put_flash(:info, "Role type created.")
         |> assign(:form, to_form(Contacts.change_contact_role_type(%ContactRoleType{})))
         |> push_patch(to: to)}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, :form, to_form(cs))}
    end
  end

  def handle_event("edit", %{"id" => id}, socket) do
    id = String.to_integer(id)

    rt =
      Contacts.get_contact_role_type!(id)
      |> Repo.preload([:inserted_by, :updated_by])

    cs = Contacts.change_contact_role_type(rt)

    {:noreply,
     socket
     |> assign(:editing_id, id)
     |> assign(:edit_form, to_form(cs))}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_id, nil)
     |> assign(:edit_form, nil)}
  end

  def handle_event("validate_edit", %{"contact_role_type" => params}, socket) do
    rt = Contacts.get_contact_role_type!(socket.assigns.editing_id)

    changeset =
      rt
      |> Contacts.change_contact_role_type(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :edit_form, to_form(changeset))}
  end

  def handle_event("update", %{"contact_role_type" => params}, socket) do
    rt = Contacts.get_contact_role_type!(socket.assigns.editing_id)

    case Contacts.update_contact_role_type(rt, params, socket.assigns.current_user.id) do
      {:ok, _} ->
        to = role_types_index_path(socket.assigns)

        {:noreply,
         socket
         |> put_flash(:info, "Role type updated.")
         |> assign(:editing_id, nil)
         |> assign(:edit_form, nil)
         |> push_patch(to: to)}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, :edit_form, to_form(cs))}
    end
  end

  def handle_event("archive", %{"id" => id}, socket) do
    id = String.to_integer(id)
    rt = Contacts.get_contact_role_type!(id)

    case Contacts.archive_contact_role_type(rt, socket.assigns.current_user.id) do
      {:ok, _} ->
        to = role_types_index_path(socket.assigns)

        socket =
          socket
          |> put_flash(:info, "Role type archived (soft delete).")

        socket =
          if socket.assigns.editing_id == id do
            assign(socket, editing_id: nil, edit_form: nil)
          else
            socket
          end

        {:noreply, push_patch(socket, to: to)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not archive this role type.")}
    end
  end

  def handle_event("restore", %{"id" => id}, socket) do
    id = String.to_integer(id)
    rt = Contacts.get_contact_role_type!(id)

    case Contacts.restore_contact_role_type(rt, socket.assigns.current_user.id) do
      {:ok, _} ->
        to = role_types_index_path(socket.assigns)
        {:noreply, socket |> put_flash(:info, "Role type restored.") |> push_patch(to: to)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not restore this role type.")}
    end
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :new_modal_id, @new_modal_id)

    ~H"""
    <div class="container mx-auto px-4 py-8">
      <.link patch={~p"/setting/contact"}>
        <.button variant="ghost" class="mb-4">
          <.icon name="hero-arrow-left" class="h-4 w-4 mr-1" /> Back to contact settings
        </.button>
      </.link>

      <.header>
        Role types
        <:subtitle>Manage contact role types (archived items are hidden from pickers)</:subtitle>
        <:actions>
          <.button type="button" variant="primary" phx-click={show_modal(@new_modal_id)}>
            Add new Role
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

      <div :if={@edit_form} class="mt-6">
        <.card title="Edit role type">
          <.simple_form for={@edit_form} phx-change="validate_edit" phx-submit="update">
            <div class="grid grid-cols-1 gap-4">
              <.input field={@edit_form[:name]} type="text" label="Name" required />
            </div>
            <:actions>
              <.button type="submit" variant="primary">Save</.button>
              <.button type="button" variant="outline" phx-click="cancel_edit">Cancel</.button>
            </:actions>
          </.simple_form>
        </.card>
      </div>

      <.modal id={@new_modal_id} on_cancel={hide_modal(@new_modal_id)}>
        <div class="space-y-4">
          <h3 id={"#{@new_modal_id}-title"} class="text-lg font-semibold text-gray-900">
            New role type
          </h3>
          <p id={"#{@new_modal_id}-description"} class="text-sm text-gray-600">
            Add a name for this role type. You can archive it later if it is no longer needed.
          </p>
          <.simple_form for={@form} class="space-y-4" phx-change="validate" phx-submit="create">
            <div class="grid grid-cols-1 gap-4">
              <.input field={@form[:name]} type="text" label="Name" required />
            </div>
            <:actions>
              <.button type="submit" variant="primary">Create</.button>
              <.button type="button" variant="outline" phx-click={hide_modal(@new_modal_id)}>
                Cancel
              </.button>
            </:actions>
          </.simple_form>
        </div>
      </.modal>
    </div>
    """
  end
end
