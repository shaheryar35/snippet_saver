defmodule SnippetSaverWeb.ContactLive.Index do
  use SnippetSaverWeb, :live_view
  use LiveTable.LiveResource, schema: SnippetSaver.Contacts.Contact

  alias SnippetSaver.Contacts
  alias SnippetSaver.Contacts.Contact
  alias SnippetSaverWeb.ContactLive.Table
  alias SnippetSaverWeb.ContactLive.ContactRouter
  alias SnippetSaverWeb.ContactLive.IndexView

  def fields, do: Table.fields()
  def filters, do: Table.filters()
  def table_options, do: Table.table_options()

  @impl true
  def mount(params, _session, socket) do
    socket = assign_contact_page_from_live_action(socket, params)
    {:ok, socket}
  end

  defp assign_contact_page_from_live_action(socket, params) do
    id = Map.get(params || %{}, "id")

    case socket.assigns[:live_action] do
      :new ->
        socket
        |> assign(:contact_page, :new)
        |> assign(:contact, %Contact{})
        |> assign(:page_title, "New Contact")
        |> assign(:active_page, "contacts")

      :show when is_binary(id) and id != "" ->
        contact = Contacts.get_contact!(id)

        socket
        |> assign(:contact_page, :show)
        |> assign(:contact, contact)
        |> assign(:active_subtab, :details)
        |> assign(:page_title, contact_display_name(contact))
        |> assign(:active_page, "contacts")

      :edit when is_binary(id) and id != "" ->
        contact = Contacts.get_contact!(id)

        socket
        |> assign(:contact_page, :edit)
        |> assign(:contact, contact)
        |> assign(:page_title, "Edit Contact")
        |> assign(:active_page, "contacts")

      _ ->
        assign(socket, :contact_page, :index)
    end
  end

  @impl true
  def handle_params(params, uri, socket) do
    path_segments =
      uri |> URI.parse() |> Map.get(:path, "") |> String.trim_leading("/") |> String.split("/")

    cond do
      path_segments == ["contacts"] ->
        apply_table_params(socket, params, path_segments)

      match?(["contacts", _, "edit"], path_segments) ->
        id = Enum.at(path_segments, 1)
        contact = Contacts.get_contact!(id)

        socket =
          socket
          |> assign(:contact_page, :edit)
          |> assign(:contact, contact)
          |> assign(:page_title, "Edit Contact")
          |> assign(:active_page, "contacts")

        {:noreply, socket}

      true ->
        case ContactRouter.handle(params, uri, socket) do
          {:index, socket, params, path} ->
            apply_table_params(socket, params, path)

          {:noreply, socket} ->
            socket =
              case socket.assigns[:contact_page] do
                :new ->
                  push_event(socket, "open_contact_tab", %{
                    contact: %{id: "new", name: "New Contact"}
                  })

                :show when is_map_key(socket.assigns, :contact) ->
                  contact = socket.assigns.contact

                  push_event(socket, "open_contact_tab", %{
                    contact: %{id: contact.id, name: contact_display_name(contact)}
                  })

                :edit when is_map_key(socket.assigns, :contact) ->
                  contact = socket.assigns.contact

                  push_event(socket, "open_contact_tab", %{
                    contact: %{id: contact.id, name: contact_display_name(contact)}
                  })

                _ ->
                  socket
              end

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
      case stream_resources(fields(), options, SnippetSaver.Contacts.Contact) do
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
      |> assign(:contact_page, :index)
      |> assign(:page_title, "Contacts")
      |> assign(:active_page, "contacts")

    {:noreply, socket}
  end

  def handle_event("open-contact-tab", %{"id" => id}, socket) do
    contact = Contacts.get_contact!(id)

    socket =
      push_event(socket, "open_contact_tab", %{
        contact: %{id: contact.id, name: contact_display_name(contact)}
      })

    {:noreply, socket}
  end

  def handle_event("navigate_to", %{"contact_id" => contact_id, "subtab" => subtab}, socket) do
    contact = Contacts.get_contact!(contact_id)
    active_subtab = if subtab == "details", do: :details, else: :details

    socket =
      socket
      |> assign(:contact_page, :show)
      |> assign(:contact, contact)
      |> assign(:active_subtab, active_subtab)
      |> assign(:page_title, contact_display_name(contact))
      |> assign(:active_page, "contacts")
      |> push_patch(to: ~p"/contacts/#{contact_id}/details")

    {:noreply, socket}
  end

  def handle_event("navigate_to", %{"contact_id" => contact_id}, socket) do
    handle_event("navigate_to", %{"contact_id" => contact_id, "subtab" => "details"}, socket)
  end

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

        {:noreply, socket} = apply_table_params(socket, list_params, ["contacts"])
        socket = push_patch(socket, to: ~p"/contacts?page=1&per_page=10&sort_params[id]=asc")
        {:noreply, socket}

      "new" ->
        socket =
          socket
          |> assign(:contact_page, :new)
          |> assign(:contact, %Contact{})
          |> assign(:page_title, "New Contact")
          |> assign(:active_page, "contacts")
          |> push_patch(to: ~p"/contacts/new")

        {:noreply, socket}

      _ ->
        contact = Contacts.get_contact!(id)

        socket =
          socket
          |> assign(:contact_page, :show)
          |> assign(:contact, contact)
          |> assign(:active_subtab, :details)
          |> assign(:page_title, contact_display_name(contact))
          |> assign(:active_page, "contacts")
          |> push_patch(to: ~p"/contacts/#{id}")

        {:noreply, socket}
    end
  end

  def handle_event("go-to-edit", %{"id" => id}, socket) do
    contact = Contacts.get_contact!(id)

    socket =
      socket
      |> assign(:contact_page, :edit)
      |> assign(:contact, contact)
      |> assign(:page_title, "Edit Contact")
      |> assign(:active_page, "contacts")
      |> push_patch(to: ~p"/contacts/#{id}/edit")

    {:noreply, socket}
  end

  def handle_event("go-to-show", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/contacts/#{id}")}
  end

  def handle_event("nav-contacts", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/contacts?page=1&per_page=10&sort_params[id]=asc")}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    contact = Contacts.get_contact!(id)

    case Contacts.delete_contact(contact) do
      {:ok, _contact} ->
        socket =
          socket
          |> put_flash(:info, "Contact deleted")
          |> push_patch(to: ~p"/contacts")

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete contact")}
    end
  end

  @impl true
  def handle_info({:go_to_edit, id}, socket) do
    contact = Contacts.get_contact!(id)

    socket =
      socket
      |> assign(:contact_page, :edit)
      |> assign(:contact, contact)
      |> assign(:page_title, "Edit Contact")
      |> assign(:active_page, "contacts")
      |> push_patch(to: ~p"/contacts/#{id}/edit")

    {:noreply, socket}
  end

  @impl true
  def handle_info({:contact_saved, contact, message}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, message)
     |> push_patch(to: ~p"/contacts/#{contact}")}
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
    case Map.get(assigns, :contact_page) do
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

  defp contact_display_name(contact) do
    [contact.first_name, contact.last_name]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
    |> case do
      "" -> "Contact ##{contact.id}"
      name -> name
    end
  end
end
