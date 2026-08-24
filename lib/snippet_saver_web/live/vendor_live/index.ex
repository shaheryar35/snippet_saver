defmodule SnippetSaverWeb.VendorLive.Index do
  use SnippetSaverWeb, :live_view
  use LiveTable.LiveResource, schema: SnippetSaver.Catalog.Vendor

  alias SnippetSaver.Catalog
  alias SnippetSaver.Catalog.Vendor, as: Schema
  alias SnippetSaverWeb.VendorLive.Table, as: Table
  alias SnippetSaverWeb.VendorLive.IndexView, as: IndexView

  def fields, do: Table.fields()
  def filters, do: Table.filters()
  def table_options, do: Table.table_options()

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_vendor_page(params)
      |> assign(:data_provider, from(x in Schema, where: x.archived == false))

    {:ok, socket}
  end

  defp assign_vendor_page(socket, params) do
    id = Map.get(params || %{}, "id")

    case socket.assigns[:live_action] do
      :new ->
        socket
        |> assign(:vendor_page, :new)
        |> assign(:vendor, %Schema{})
        |> assign(:page_title, "New Vendor")
        |> assign(:active_page, "vendors")

      :show when is_binary(id) and id != "" ->
        record = Catalog.get_vendor!(id)

        socket
        |> assign(:vendor_page, :show)
        |> assign(:vendor, record)
        |> assign(:page_title, "Vendor ##{record.id}")
        |> assign(:active_page, "vendors")

      :edit when is_binary(id) and id != "" ->
        record = Catalog.get_vendor!(id)

        socket
        |> assign(:vendor_page, :edit)
        |> assign(:vendor, record)
        |> assign(:page_title, "Edit Vendor")
        |> assign(:active_page, "vendors")

      _ ->
        assign(socket, :vendor_page, :index)
    end
  end

  @impl true
  def handle_params(params, uri, socket) do
    path_segments =
      uri |> URI.parse() |> Map.get(:path, "") |> String.trim_leading("/") |> String.split("/")

    if path_segments == ["vendors"] do
      apply_table_params(socket, params, path_segments)
    else
      socket = assign_vendor_page(socket, params)

      if socket.assigns[:vendor_page] == :index do
        apply_table_params(socket, params, path_segments)
      else
        {:noreply, socket}
      end
    end
  end

  defp apply_table_params(socket, params, path_segments) do
    current_path = Enum.join(path_segments, "/")
    opts = get_merged_table_options()
    default_sort = get_in(opts, [:sorting, :default_sort]) || [id: :asc]

    sort_params =
      (params["sort_params"] || default_sort)
      |> Enum.map(fn
        {k, v} when is_atom(k) and is_atom(v) -> {k, v}
        {k, v} -> {String.to_existing_atom(k), String.to_existing_atom(v)}
      end)

    filters =
      (params["filters"] || %{})
      |> Map.put("search", params["search"] || "")
      |> Enum.reduce(%{}, fn
        {"search", search_term}, acc -> Map.put(acc, "search", search_term)
        {k, _}, acc -> Map.put(acc, String.to_existing_atom(k), get_filter(k))
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
      case stream_resources(fields(), options, from(x in Schema, where: x.archived == false)) do
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
      |> assign(:vendor_page, :index)
      |> assign(:page_title, "Vendors")
      |> assign(:active_page, "vendors")

    {:noreply, socket}
  end

  # Tab-bar navigation (see assets/js/hooks/vendor_tabs.js) pushes this event instead of using
  # plain patch links, so the JS hook can manage which tab looks active — this clause is what
  # actually performs the navigation server-side.
  def handle_event("navigate_to", %{"id" => id}, socket) do
    case id do
      "list" ->
        list_params = %{
          "page" => "1",
          "per_page" => "10",
          "sort_params" => %{"id" => "asc"},
          "filters" => %{},
          "search" => ""
        }

        {:noreply, socket} = apply_table_params(socket, list_params, ["vendors"])
        {:noreply, push_patch(socket, to: ~p"/vendors?page=1&per_page=10&sort_params[id]=asc")}

      "new" ->
        {:noreply,
         socket
         |> assign(:vendor_page, :new)
         |> assign(:vendor, %Schema{})
         |> assign(:page_title, "New Vendor")
         |> assign(:active_page, "vendors")
         |> push_patch(to: ~p"/vendors/new")}

      _ ->
        record = Catalog.get_vendor!(id)

        {:noreply,
         socket
         |> assign(:vendor_page, :show)
         |> assign(:vendor, record)
         |> assign(:page_title, "Vendor ##{record.id}")
         |> assign(:active_page, "vendors")
         |> push_patch(to: ~p"/vendors/#{id}")}
    end
  end

  def handle_event("go-to-edit", %{"id" => id}, socket) do
    record = Catalog.get_vendor!(id)

    {:noreply,
     socket
     |> assign(:vendor_page, :edit)
     |> assign(:vendor, record)
     |> assign(:page_title, "Edit Vendor")
     |> assign(:active_page, "vendors")
     |> push_patch(to: ~p"/vendors/#{id}/edit")}
  end

  def handle_event("go-to-show", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/vendors/#{id}")}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    record = Catalog.get_vendor!(id)

    case Catalog.archive_vendor(record) do
      {:ok, _record} ->
        {:noreply,
         socket
         |> put_flash(:info, "Vendor deleted")
         |> push_patch(to: ~p"/vendors")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete vendor")}
    end
  end

  @impl true
  def handle_info({:vendor_saved, record, message}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:vendor_page, :show)
     |> assign(:vendor, record)
     |> assign(:page_title, "Vendor ##{record.id}")
     |> push_patch(to: ~p"/vendors/#{record.id}")}
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:table_content, &__MODULE__.render_table/1)
      |> maybe_assign_parent_pid()

    IndexView.render("index.html", assigns)
  end

  defp maybe_assign_parent_pid(assigns) do
    case Map.get(assigns, :vendor_page) do
      :new -> assign(assigns, :parent_pid, self())
      :edit -> assign(assigns, :parent_pid, self())
      _ -> assigns
    end
  end

  def render_table(assigns) do
    ~H"""
    <.live_table
      fields={fields()}
      filters={filters()}
      options={Map.get(assigns, :options, %{})}
      streams={Map.get(assigns, :streams, Map.get(assigns, :resources, []))}
      per_page={[10, 25, 50, 100]}
      default_per_page={10}
      show_search={true}
      show_columns_toggle={true}
      show_export={true}
    />
    """
  end
end
