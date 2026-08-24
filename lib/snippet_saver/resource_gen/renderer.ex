defmodule SnippetSaver.ResourceGen.Renderer do
  @moduledoc """
  Builds the source text for each generated file. One `render_*/2` function per template in
  `lib/mix/tasks/gen/resource/templates/` — each returns the binding map that template's
  `<%= @body %>` (or field-level interpolations, for `schema.ex.eex`/`migration.exs.eex`) needs.

  Conditional logic (audit x soft_delete x field types) lives here as plain Elixir functions
  rather than nested `<%= if %>` blocks in the `.eex` files themselves, per the spec's guidance.
  Output does not need to be perfectly indented — `Writer` runs `mix format` on every generated
  `.ex`/`.exs` file after writing.
  """

  alias SnippetSaver.ResourceGen.{FieldRenderer, Naming, Spec}

  @templates_dir Path.join([__DIR__, "..", "..", "mix", "tasks", "gen", "resource", "templates"])
                 |> Path.expand()

  def template_path(name), do: Path.join(@templates_dir, name)

  defp render(template_name, bindings) do
    EEx.eval_file(template_path(template_name), assigns: bindings, trim: true)
  end

  # ---------------------------------------------------------------------
  # schema.ex
  # ---------------------------------------------------------------------

  def schema(%Spec{} = spec, %Naming{} = naming) do
    field_lines = Enum.map_join(spec.fields, "\n", &("    " <> FieldRenderer.schema_line(&1)))
    bt_lines = Enum.map_join(spec.belongs_tos, "\n", &("    " <> FieldRenderer.bt_schema_line(&1)))
    soft_delete_line = if spec.soft_delete, do: "    field :archived, :boolean, default: false", else: ""

    audit_lines =
      if spec.audit do
        """
            belongs_to :inserted_by, SnippetSaver.Accounts.User, foreign_key: :inserted_by_id
            belongs_to :updated_by, SnippetSaver.Accounts.User, foreign_key: :updated_by_id
        """
        |> String.trim_trailing("\n")
      else
        ""
      end

    cast_names =
      Enum.map(spec.fields, & &1.name) ++
        Enum.map(spec.belongs_tos, &FieldRenderer.fk_name/1) ++
        if(spec.soft_delete, do: [:archived], else: [])

    validate_lines =
      FieldRenderer.validate_lines(spec.fields, spec.belongs_tos)
      |> Enum.map_join("\n", &("    " <> &1))

    bindings = %{
      module: inspect(naming.schema_module),
      table: naming.plural,
      field_lines: field_lines,
      bt_lines: bt_lines,
      soft_delete_line: soft_delete_line,
      audit_lines: audit_lines,
      var: naming.singular,
      cast_list: inspect(cast_names),
      validate_lines: validate_lines
    }

    render("schema.ex.eex", bindings)
  end

  # ---------------------------------------------------------------------
  # migration.exs
  # ---------------------------------------------------------------------

  def migration(%Spec{} = spec, %Naming{} = naming) do
    column_lines = Enum.map_join(spec.fields, "\n", &("      " <> FieldRenderer.migration_line(&1)))

    bt_column_lines =
      Enum.map_join(spec.belongs_tos, "\n", &("      " <> FieldRenderer.bt_migration_line(&1)))

    soft_delete_line =
      if spec.soft_delete,
        do: "\n      add :archived, :boolean, default: false, null: false",
        else: ""

    audit_lines =
      if spec.audit do
        "\n      add :inserted_by_id, references(:users, on_delete: :nilify_all)" <>
          "\n      add :updated_by_id, references(:users, on_delete: :nilify_all)"
      else
        ""
      end

    column_block =
      [column_lines, bt_column_lines]
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n")
      |> Kernel.<>(soft_delete_line)
      |> Kernel.<>(audit_lines)

    index_lines =
      spec.belongs_tos
      |> Enum.map_join("\n", &("    " <> FieldRenderer.bt_index_line(&1, naming.plural)))

    bindings = %{
      module: inspect(naming.migration_module),
      table: naming.plural,
      column_lines: column_block,
      index_lines: index_lines
    }

    render("migration.exs.eex", bindings)
  end

  # ---------------------------------------------------------------------
  # context functions (inner body — wrapped in defmodule by Planner for :create,
  # spliced as-is for :insert)
  # ---------------------------------------------------------------------

  def context_functions(%Spec{} = spec, %Naming{} = naming) do
    s = naming.singular
    schema_ref = naming.schema_alias
    user_id_param = if spec.audit, do: ", user_id \\\\ nil", else: ""

    list_fn =
      if spec.soft_delete do
        """
        @doc \"\"\"
        Active #{humanize_plural(naming.plural)} only (`archived: false`), for dropdowns and associations.
        \"\"\"
        def list_#{naming.plural} do
          from(x in #{schema_ref}, where: x.archived == false, order_by: [asc: x.id])
          |> Repo.all()
        end

        @doc \"\"\"
        All #{humanize_plural(naming.plural)} (including archived), for admin views.
        \"\"\"
        def list_#{naming.plural}_for_admin do
          from(x in #{schema_ref}, order_by: [asc: x.id])
          #{if spec.audit, do: "|> preload([:inserted_by, :updated_by])", else: ""}
          |> Repo.all()
        end
        """
      else
        """
        def list_#{naming.plural} do
          Repo.all(#{schema_ref})
        end
        """
      end

    get_fn = """
    def get_#{s}!(id), do: Repo.get!(#{schema_ref}, id)
    """

    create_fn = """
    @doc \"\"\"
    Creates a #{s}.#{if spec.audit, do: " Pass `user_id` to record audit columns.", else: ""}
    \"\"\"
    def create_#{s}(attrs#{user_id_param}) do
      # AUTHZ_HOOK: :#{naming.context_alias |> Naming.underscore()}, :create_#{s} — no-op until RBAC module exists
      %#{schema_ref}{}
      |> #{schema_ref}.changeset(attrs)
      #{if spec.audit, do: "|> apply_#{s}_insert_audit(user_id)", else: ""}
      |> Repo.insert()
    end
    """

    update_fn = """
    @doc \"\"\"
    Updates a #{s}.#{if spec.audit, do: " Pass `user_id` to set `updated_by_id`.", else: ""}
    \"\"\"
    def update_#{s}(%#{schema_ref}{} = #{s}, attrs#{user_id_param}) do
      # AUTHZ_HOOK: :#{naming.context_alias |> Naming.underscore()}, :update_#{s} — no-op until RBAC module exists
      #{s}
      |> #{schema_ref}.changeset(attrs)
      #{if spec.audit, do: "|> apply_#{s}_update_audit(user_id)", else: ""}
      |> Repo.update()
    end
    """

    delete_fn =
      if spec.soft_delete do
        """
        @doc \"\"\"
        Soft-deletes a #{s} (`archived: true`).
        \"\"\"
        def archive_#{s}(%#{schema_ref}{} = #{s}, user_id \\\\ nil) do
          # AUTHZ_HOOK: :#{naming.context_alias |> Naming.underscore()}, :archive_#{s} — no-op until RBAC module exists
          update_#{s}(#{s}, %{archived: true}#{if spec.audit, do: ", user_id", else: ""})
        end

        @doc \"\"\"
        Restores an archived #{s}.
        \"\"\"
        def restore_#{s}(%#{schema_ref}{} = #{s}, user_id \\\\ nil) do
          update_#{s}(#{s}, %{archived: false}#{if spec.audit, do: ", user_id", else: ""})
        end

        @doc \"\"\"
        Soft-deletes a #{s}. Prefer `archive_#{s}/2`.
        \"\"\"
        def delete_#{s}(%#{schema_ref}{} = #{s}) do
          archive_#{s}(#{s}, nil)
        end
        """
      else
        """
        def delete_#{s}(%#{schema_ref}{} = #{s}) do
          # AUTHZ_HOOK: :#{naming.context_alias |> Naming.underscore()}, :delete_#{s} — no-op until RBAC module exists
          Repo.delete(#{s})
        end
        """
      end

    change_fn = """
    def change_#{s}(%#{schema_ref}{} = #{s}, attrs \\\\ %{}) do
      #{schema_ref}.changeset(#{s}, attrs)
    end
    """

    audit_helpers =
      if spec.audit do
        """

        defp apply_#{s}_insert_audit(changeset, nil), do: changeset

        defp apply_#{s}_insert_audit(changeset, user_id) do
          changeset
          |> Ecto.Changeset.put_change(:inserted_by_id, user_id)
          |> Ecto.Changeset.put_change(:updated_by_id, user_id)
        end

        defp apply_#{s}_update_audit(changeset, nil), do: changeset

        defp apply_#{s}_update_audit(changeset, user_id) do
          Ecto.Changeset.put_change(changeset, :updated_by_id, user_id)
        end
        """
      else
        ""
      end

    [
      "alias #{inspect(naming.schema_module)}",
      "",
      list_fn,
      get_fn,
      create_fn,
      update_fn,
      delete_fn,
      change_fn
    ]
    |> Enum.join("\n")
    |> Kernel.<>(audit_helpers)
    |> then(&render("context_functions.ex.eex", %{body: &1}))
  end

  defp humanize_plural(singular), do: singular |> String.replace("_", " ")

  defp enum_options_helper do
    """
    defp enum_options(items) do
      Enum.map(items, fn item -> {item.name, item.id} end)
    rescue
      _ -> []
    end
    """
  end

  defp fk_helpers do
    """
    defp normalize_fk(""), do: nil
    defp normalize_fk(nil), do: nil
    defp normalize_fk(id), do: id

    defp filter_name_tuples(catalog, query, limit) do
      q = String.downcase(query || "")

      catalog
      |> Enum.filter(fn {label, _id} -> String.contains?(String.downcase(label), q) end)
      |> Enum.take(limit)
    end
    """
  end

  # ---------------------------------------------------------------------
  # index.ex
  # ---------------------------------------------------------------------

  def live_index(%Spec{} = spec, %Naming{} = naming) do
    s = naming.singular
    ctx = inspect(naming.context_module)
    schema_ref = "#{ctx}.#{naming.schema_alias}"
    delete_fn_name = if spec.soft_delete, do: "archive_#{s}", else: "delete_#{s}"

    list_data_source =
      if spec.soft_delete,
        do: "from(x in Schema, where: x.archived == false)",
        else: "Schema"

    mount_data_provider_line =
      if spec.soft_delete do
        # `use LiveTable.LiveResource`'s injected `handle_params/3` clause always matches before any
        # custom one defined later in this module (a framework quirk, not specific to this resource —
        # see the identical pre-existing pattern in PatientLive.Index/EmployeeLive.Index), so archived
        # filtering can't happen there. LiveTable does honor `socket.assigns[:data_provider]` at
        # runtime, which is the reliable way to keep archived records out of the default list —
        # but it must be an actual query (not an `{module, function, args}` tuple): the MFA form
        # skips `select_columns/2`, which breaks per-column values for every table renderer
        # (including the actions column's row-id lookup).
        "|> assign(:data_provider, from(x in Schema, where: x.archived == false))"
      else
        ""
      end

    body = """
    defmodule #{inspect(naming.web_index_module)} do
      use SnippetSaverWeb, :live_view
      use LiveTable.LiveResource, schema: #{schema_ref}

      alias #{ctx}
      alias #{schema_ref}, as: Schema
      alias #{inspect(naming.web_table_module)}, as: Table
      alias #{inspect(naming.web_index_view_module)}, as: IndexView

      def fields, do: Table.fields()
      def filters, do: Table.filters()
      def table_options, do: Table.table_options()

      @impl true
      def mount(params, _session, socket) do
        socket =
          socket
          |> assign_#{s}_page(params)
          #{mount_data_provider_line}

        {:ok, socket}
      end

      defp assign_#{s}_page(socket, params) do
        id = Map.get(params || %{}, "id")

        case socket.assigns[:live_action] do
          :new ->
            socket
            |> assign(:#{s}_page, :new)
            |> assign(:#{s}, %Schema{})
            |> assign(:page_title, "New #{Naming.humanize(s)}")
            |> assign(:active_page, "#{naming.plural}")

          :show when is_binary(id) and id != "" ->
            record = #{naming.context_alias}.get_#{s}!(id)

            socket
            |> assign(:#{s}_page, :show)
            |> assign(:#{s}, record)
            |> assign(:page_title, "#{Naming.humanize(s)} ##{"\#{record.id}"}")
            |> assign(:active_page, "#{naming.plural}")

          :edit when is_binary(id) and id != "" ->
            record = #{naming.context_alias}.get_#{s}!(id)

            socket
            |> assign(:#{s}_page, :edit)
            |> assign(:#{s}, record)
            |> assign(:page_title, "Edit #{Naming.humanize(s)}")
            |> assign(:active_page, "#{naming.plural}")

          _ ->
            assign(socket, :#{s}_page, :index)
        end
      end

      @impl true
      def handle_params(params, uri, socket) do
        path_segments =
          uri |> URI.parse() |> Map.get(:path, "") |> String.trim_leading("/") |> String.split("/")

        if path_segments == ["#{naming.plural}"] do
          apply_table_params(socket, params, path_segments)
        else
          socket = assign_#{s}_page(socket, params)

          if socket.assigns[:#{s}_page] == :index do
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
            "per_page" => params["per_page"] || to_string(get_in(opts, [:pagination, :default_size]) || 10)
          },
          "filters" => filters
        }

        {resources, updated_options} =
          case stream_resources(fields(), options, #{list_data_source}) do
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
          |> assign(:#{s}_page, :index)
          |> assign(:page_title, "#{Naming.humanize(naming.plural)}")
          |> assign(:active_page, "#{naming.plural}")

        {:noreply, socket}
      end

      # Tab-bar navigation (see assets/js/hooks/#{s}_tabs.js) pushes this event instead of using
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

            {:noreply, socket} = apply_table_params(socket, list_params, ["#{naming.plural}"])
            {:noreply, push_patch(socket, to: ~p"/#{naming.route_segment}?page=1&per_page=10&sort_params[id]=asc")}

          "new" ->
            {:noreply,
             socket
             |> assign(:#{s}_page, :new)
             |> assign(:#{s}, %Schema{})
             |> assign(:page_title, "New #{Naming.humanize(s)}")
             |> assign(:active_page, "#{naming.plural}")
             |> push_patch(to: ~p"/#{naming.route_segment}/new")}

          _ ->
            record = #{naming.context_alias}.get_#{s}!(id)

            {:noreply,
             socket
             |> assign(:#{s}_page, :show)
             |> assign(:#{s}, record)
             |> assign(:page_title, "#{Naming.humanize(s)} ##{"\#{record.id}"}")
             |> assign(:active_page, "#{naming.plural}")
             |> push_patch(to: ~p"/#{naming.route_segment}/\#{id}")}
        end
      end

      def handle_event("go-to-edit", %{"id" => id}, socket) do
        record = #{naming.context_alias}.get_#{s}!(id)

        {:noreply,
         socket
         |> assign(:#{s}_page, :edit)
         |> assign(:#{s}, record)
         |> assign(:page_title, "Edit #{Naming.humanize(s)}")
         |> assign(:active_page, "#{naming.plural}")
         |> push_patch(to: ~p"/#{naming.route_segment}/\#{id}/edit")}
      end

      def handle_event("go-to-show", %{"id" => id}, socket) do
        {:noreply, push_patch(socket, to: ~p"/#{naming.route_segment}/\#{id}")}
      end

      def handle_event("delete", %{"id" => id}, socket) do
        record = #{naming.context_alias}.get_#{s}!(id)

        case #{naming.context_alias}.#{delete_fn_name}(record) do
          {:ok, _record} ->
            {:noreply,
             socket
             |> put_flash(:info, "#{Naming.humanize(s)} deleted")
             |> push_patch(to: ~p"/#{naming.route_segment}")}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Failed to delete #{s}")}
        end
      end

      @impl true
      def handle_info({:#{s}_saved, record, message}, socket) do
        {:noreply,
         socket
         |> put_flash(:info, message)
         |> assign(:#{s}_page, :show)
         |> assign(:#{s}, record)
         |> assign(:page_title, "#{Naming.humanize(s)} ##{"\#{record.id}"}")
         |> push_patch(to: ~p"/#{naming.route_segment}/\#{record.id}")}
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
        case Map.get(assigns, :#{s}_page) do
          :new -> assign(assigns, :parent_pid, self())
          :edit -> assign(assigns, :parent_pid, self())
          _ -> assigns
        end
      end

      def render_table(assigns) do
        ~H\"\"\"
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
        \"\"\"
      end
    end
    """

    render("index.ex.eex", %{body: body})
  end

  # ---------------------------------------------------------------------
  # index_view.ex — includes an inline "show" details grid (no separate
  # ShowComponent template — Phase 1 keeps the file list to what's in spec §Part 2)
  # ---------------------------------------------------------------------

  def index_view(%Spec{} = spec, %Naming{} = naming) do
    s = naming.singular

    show_rows =
      spec.fields
      |> Enum.map(fn f ->
        value_expr =
          if f.type == :boolean do
            ~s|if(@#{s}.#{f.name}, do: "Yes", else: "No")|
          else
            ~s(@#{s}.#{f.name} || "—")
          end

        ~s(<div><span class="text-gray-500">#{FieldRenderer.label(f.name)}:</span> <%= #{value_expr} %></div>)
      end)
      |> Enum.concat(
        Enum.map(spec.belongs_tos, fn bt ->
          fk = FieldRenderer.fk_name(bt)
          ~s(<div><span class="text-gray-500">#{FieldRenderer.label(bt.name)}:</span> <%= @#{s}.#{fk} || "—" %></div>)
        end)
      )
      |> Enum.map_join("\n            ", & &1)

    body = """
    defmodule #{inspect(naming.web_index_view_module)} do
      use SnippetSaverWeb, :html

      def render("index.html", assigns) do
        show_record? = assigns[:#{s}_page] in [:show, :edit] and is_map_key(assigns, :#{s})
        is_new_page? = assigns[:#{s}_page] == :new

        assigns =
          assigns
          |> assign(:show_record?, show_record?)
          |> assign(:data_#{s}_id, if(show_record?, do: assigns.#{s}.id, else: nil))
          |> assign(:data_page_new, is_new_page?)

        ~H\"\"\"
        <div
          id="#{s}-tab-system"
          class="container mx-auto px-4 py-4 h-[calc(100dvh-4rem)] min-h-0 flex flex-col overflow-hidden"
          phx-hook="#{naming.web_tabs_hook_module_js}"
          data-#{Naming.underscore(s) |> String.replace("_", "-")}-id={@data_#{s}_id}
          data-page-new={@data_page_new}
        >
          <.header>
            #{Naming.humanize(naming.plural)}
            <:actions>
              <.link patch={~p"/#{naming.route_segment}/new"} class="add-#{s}-link">
                <.button variant="primary">Add #{Naming.humanize(s)}</.button>
              </.link>
            </:actions>
          </.header>

          <div id="#{s}-tabs" phx-update="ignore" class="shrink-0 sticky top-0 z-20 bg-white"></div>

          <div class="content flex-1 min-h-0 border border-t-0 border-gray-200 bg-white rounded-b-lg shadow-sm overflow-hidden">
            <%= case @#{s}_page do %>
              <% :index -> %>
                <div class="p-4 h-full overflow-auto">
                  <%= @table_content.(assigns) %>
                </div>

              <% :show -> %>
                <div class="p-4 h-full overflow-auto">
                  <.header>
                    #{Naming.humanize(s)} #{"<%= @" <> s <> ".id %>"}
                    <:actions>
                      <.button variant="outline" size="sm" phx-click="go-to-edit" phx-value-id={@#{s}.id}>
                        <.icon name="hero-pencil" class="h-4 w-4 mr-1" /> Edit
                      </.button>
                    </:actions>
                  </.header>

                  <.card>
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                      #{show_rows}
                    </div>
                  </.card>
                </div>

              <% :edit -> %>
                <div class="p-4 h-full min-h-0 overflow-hidden">
                  <.live_component
                    module={#{inspect(naming.web_form_component_module)}}
                    id={"#{s}-form-\#{@#{s}.id}"}
                    action={:edit}
                    #{s}={@#{s}}
                    patch_back={~p"/#{naming.route_segment}"}
                    parent_pid={@parent_pid}
                  />
                </div>

              <% :new -> %>
                <div class="p-4 h-full overflow-auto">
                  <.live_component
                    module={#{inspect(naming.web_form_component_module)}}
                    id="#{s}-form-new"
                    action={:new}
                    #{s}={@#{s}}
                    patch_back={~p"/#{naming.route_segment}"}
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
        \"\"\"
      end
    end
    """

    render("index_view.ex.eex", %{body: body})
  end

  # ---------------------------------------------------------------------
  # form_component.ex
  # ---------------------------------------------------------------------

  def form_component(%Spec{} = spec, %Naming{} = naming) do
    s = naming.singular
    ctx = naming.context_alias

    simple_field_heex =
      Enum.map_join(spec.fields, "\n            ", &FieldRenderer.form_field_heex(&1, s))

    bt_field_heex =
      Enum.map_join(spec.belongs_tos, "\n            ", &FieldRenderer.bt_form_field_heex/1)

    static_select_assigns =
      spec.fields
      |> Enum.filter(&(&1.type == :select))
      |> Enum.map_join(",\n       ", fn f ->
        "#{FieldRenderer.options_assign_name(f)}: #{inspect(f.options)}"
      end)

    context_select_assigns =
      spec.belongs_tos
      |> Enum.reject(& &1.searchable)
      |> Enum.map_join(",\n       ", fn bt ->
        {mod, fun} = bt.options_from
        "#{FieldRenderer.options_assign_name(bt)}: enum_options(#{inspect(mod)}.#{fun}())"
      end)

    searchable_bts = Enum.filter(spec.belongs_tos, & &1.searchable)

    searchable_mount_assigns =
      searchable_bts
      |> Enum.flat_map(&FieldRenderer.searchable_select_mount_assigns/1)
      |> Enum.map_join(",\n       ", & &1)

    searchable_catalog_assigns =
      searchable_bts
      |> Enum.map_join(",\n       ", fn bt ->
        {mod, fun} = bt.options_from
        "#{bt.name}_catalog: enum_options(#{inspect(mod)}.#{fun}())"
      end)

    searchable_handlers =
      searchable_bts
      |> Enum.map_join("\n\n  ", &FieldRenderer.searchable_select_handle_events/1)

    mount_assign_lines =
      [static_select_assigns, searchable_mount_assigns]
      |> Enum.reject(&(&1 == ""))
      |> Enum.join(",\n       ")

    update_assign_lines =
      [context_select_assigns, searchable_catalog_assigns]
      |> Enum.reject(&(&1 == ""))
      |> Enum.join(",\n       ")

    save_fn_name = "save_#{s}"

    body = """
    defmodule #{inspect(naming.web_form_component_module)} do
      use SnippetSaverWeb, :live_component

      alias #{inspect(naming.context_module)}
      alias #{inspect(naming.schema_module)}

      def mount(socket) do
        {:ok,
         assign(socket#{if mount_assign_lines == "", do: "", else: ",\n       " <> mount_assign_lines})}
      end

      def update(assigns, socket) do
        {:ok,
         socket
         |> assign(assigns)
         |> assign(:parent_pid, assigns[:parent_pid])
         #{if update_assign_lines == "", do: "", else: "|> assign(" <> update_assign_lines <> ")"}
         |> assign_form()}
      end

      def handle_event("validate", %{"#{s}" => params}, socket) do
        changeset =
          socket.assigns.#{s}
          |> #{naming.schema_alias}.changeset(params)
          |> Map.put(:action, :validate)

        {:noreply, assign(socket, :form, to_form(changeset))}
      end

      def handle_event("save", %{"#{s}" => params}, socket) do
        #{save_fn_name}(socket, socket.assigns.action, params)
      end

    #{searchable_handlers}

      defp #{save_fn_name}(socket, :new, params) do
        case #{ctx}.create_#{s}(params) do
          {:ok, record} ->
            notify_and_close(socket, record, "#{Naming.humanize(s)} created successfully")

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end
      end

      defp #{save_fn_name}(socket, :edit, params) do
        case #{ctx}.update_#{s}(socket.assigns.#{s}, params) do
          {:ok, record} ->
            notify_and_close(socket, record, "#{Naming.humanize(s)} updated successfully")

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end
      end

      defp notify_and_close(socket, record, message) do
        if pid = socket.assigns[:parent_pid] do
          send(pid, {:#{s}_saved, record, message})
          {:noreply, socket}
        else
          {:noreply,
           socket
           |> put_flash(:info, message)
           |> push_navigate(to: ~p"/#{naming.route_segment}/\#{record}")}
        end
      end

      defp assign_form(socket) do
        changeset = #{naming.schema_alias}.changeset(socket.assigns.#{s}, %{})
        assign(socket, form: to_form(changeset))
      end

    #{if spec.belongs_tos != [], do: enum_options_helper(), else: ""}
    #{if searchable_bts != [], do: fk_helpers(), else: ""}

      def render(assigns) do
        ~H\"\"\"
        <div id={"#{s}-form-#{"\#{@id}"}"}>
          <.form_container>
            <.simple_form for={@form} phx-target={@myself} phx-change="validate" phx-submit="save">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                #{simple_field_heex}
                #{bt_field_heex}
              </div>

              <:actions>
                <.button type="submit" variant="primary" size="lg">
                  <%= if @action == :new, do: "Create #{Naming.humanize(s)}", else: "Update #{Naming.humanize(s)}" %>
                </.button>
                <.link patch={@patch_back}>
                  <.button type="button" variant="outline" size="lg">Cancel</.button>
                </.link>
              </:actions>
            </.simple_form>
          </.form_container>
        </div>
        \"\"\"
      end
    end
    """

    render("form_component.ex.eex", %{body: body})
  end

  # ---------------------------------------------------------------------
  # table.ex
  # ---------------------------------------------------------------------

  def table(%Spec{} = spec, %Naming{} = naming) do
    fields_body = FieldRenderer.table_fields_body(naming, spec.list_fields)

    body = """
    defmodule #{inspect(naming.web_table_module)} do
      @moduledoc \"\"\"
      LiveTable configuration for the #{Naming.humanize(naming.plural)} index: fields, filters, and table options.
      \"\"\"
      use SnippetSaverWeb, :html
      import Ecto.Query

      def fields do
        [
          #{fields_body}
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
    end
    """

    render("table.ex.eex", %{body: body})
  end

  # ---------------------------------------------------------------------
  # JS tabs hook — Phase 1 has only a single `:details` subtab, so this is
  # the parent-tab-bar-only shape (no child row), ready to extend once
  # :nested_collection subtabs land in a later phase.
  # ---------------------------------------------------------------------

  def tabs_hook_js(%Spec{} = _spec, %Naming{} = naming) do
    s = naming.singular
    hook = naming.web_tabs_hook_module_js
    kebab = String.replace(s, "_", "-")

    body = """
    const #{hook} = {
      mounted() {
        this.tabs = [];
        this.activeId = null;
        this.userChoseList = false;

        this.syncFromDOM();
        this.renderTabs();

        this.handleEvent("open_#{s}_tab", ({ #{s} }) => {
          this.openTab(#{s}, { navigate: false });
        });

        this.el.addEventListener("click", (e) => {
          const addLink = e.target.closest(".add-#{s}-link");
          if (addLink) {
            e.preventDefault();
            this.openTab({ id: "new", name: "New #{Naming.humanize(s)}" }, { navigate: true });
            return;
          }

          const link = e.target.closest(".#{kebab}-name-link");
          if (!link) return;
          e.preventDefault();
          e.stopPropagation();
          const id = link.getAttribute("data-#{kebab}-id");
          const name = link.getAttribute("data-#{kebab}-name") || "";
          if (!id) return;
          this.openTab({ id, name }, { navigate: true });
        });
      },

      updated() {
        if (this.userChoseList) {
          this.userChoseList = false;
          this.activeId = null;
          this.renderTabs();
          return;
        }

        setTimeout(() => {
          this.syncFromDOM();
          this.renderTabs();
        }, 0);
      },

      syncFromDOM() {
        const pageNew = this.el.getAttribute("data-page-new");
        const isNewPage = pageNew === "true" || pageNew === "1" || pageNew === true;
        if (isNewPage) {
          this.ensureTab({ id: "new", name: "New #{Naming.humanize(s)}" });
          this.activeId = "new";
          this.renderTabs();
          return;
        }

        const id = this.el.getAttribute("data-#{kebab}-id");
        if (id != null && id !== "") {
          const tab = this.ensureTab({ id: id.trim(), name: "#" + id.trim() });
          this.activeId = tab.id;
          this.renderTabs();
        } else {
          this.activeId = null;
        }
      },

      ensureTab(#{s}) {
        const isNew = #{s}.id === "new" || String(#{s}.id) === "new";
        const id = isNew ? "new" : Number(#{s}.id);
        let tab = this.tabs.find((t) => t.id === id);
        if (!tab) {
          tab = { id, name: #{s}.name || "New #{Naming.humanize(s)}" };
          this.tabs.push(tab);
        }
        return tab;
      },

      openTab(#{s}, opts) {
        const tab = this.ensureTab(#{s});
        this.activeId = tab.id;
        this.renderTabs();

        if (opts && opts.navigate) {
          if (tab.id === "new") {
            this.pushEvent("navigate_to", { id: "new" });
          } else {
            this.pushEvent("navigate_to", { id: String(tab.id) });
          }
        }
      },

      closeTab(id, e) {
        if (e) e.stopPropagation();
        this.tabs = this.tabs.filter((t) => t.id !== id);

        if (this.activeId === id) {
          if (this.tabs.length > 0) {
            const next = this.tabs[0];
            this.activeId = next.id;
            this.pushEvent("navigate_to", { id: String(next.id) });
          } else {
            this.activeId = null;
            this.pushEvent("navigate_to", { id: "list" });
          }
        }

        this.renderTabs();
      },

      switchToList() {
        this.activeId = null;
        this.userChoseList = true;
        this.renderTabs();
        this.pushEvent("navigate_to", { id: "list" });
      },

      switchTab(id) {
        this.activeId = id;
        this.renderTabs();
        this.pushEvent("navigate_to", { id: String(id) });
      },

      renderTabs() {
        const container = this.el.querySelector("##{s}-tabs");
        if (!container) return;

        const isListActive = this.activeId == null;
        const listClasses = isListActive
          ? "border-primary-600 text-primary-600 bg-white"
          : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300";

        const listBtn = `
          <button type="button" class="#{kebab}-tab flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 whitespace-nowrap transition-colors #{"$"}{listClasses}" data-list="true">
            <span>#{Naming.humanize(naming.plural)} List</span>
          </button>
        `;

        const tabs = this.tabs
          .map((tab) => {
            const isActive = this.activeId === tab.id;
            const classes = isActive
              ? "border-primary-600 text-primary-600 bg-white"
              : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300";
            const name = (tab.name || "").slice(0, 20);

            return `
              <button type="button" class="#{kebab}-tab #{kebab}-parent-tab group flex items-center gap-2 pl-4 pr-2 py-2.5 text-sm font-medium border-b-2 whitespace-nowrap transition-colors #{"$"}{classes}" data-tab-id="#{"$"}{tab.id}">
                <span class="max-w-[120px] truncate">#{"$"}{name}</span>
                <span class="close-tab ml-1 rounded p-0.5 text-gray-400 hover:bg-gray-200 hover:text-gray-600" data-tab-id="#{"$"}{tab.id}" aria-label="Close tab">
                  <svg class="h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
                </span>
              </button>
            `;
          })
          .join("");

        container.innerHTML = `
          <div class="mt-4 #{kebab}-tabs-root bg-white border-b border-gray-200">
            <div class="#{kebab}-tabs-parent-row flex items-end overflow-x-auto" role="tablist">
              #{"$"}{listBtn}#{"$"}{tabs}
            </div>
          </div>
        `;

        const listButton = container.querySelector('[data-list="true"]');
        if (listButton) listButton.addEventListener("click", () => this.switchToList());

        container.querySelectorAll(".#{kebab}-parent-tab").forEach((btn) => {
          const idRaw = btn.getAttribute("data-tab-id");
          const id = idRaw === "new" ? "new" : Number(idRaw);
          btn.addEventListener("click", (e) => {
            if (e.target.closest(".close-tab")) return;
            this.switchTab(id);
          });
        });

        container.querySelectorAll(".close-tab").forEach((el) => {
          const idRaw = el.getAttribute("data-tab-id");
          const id = idRaw === "new" ? "new" : Number(idRaw);
          el.addEventListener("click", (e) => this.closeTab(id, e));
        });
      },
    };

    export default #{hook};
    """

    render("tabs_hook.js.eex", %{body: body})
  end

  # ---------------------------------------------------------------------
  # fixtures (inner body)
  # ---------------------------------------------------------------------

  def fixtures(%Spec{} = spec, %Naming{} = naming) do
    s = naming.singular

    attrs =
      spec.fields
      |> Enum.map(fn f -> "#{f.name}: #{inspect(default_value(f))}" end)
      |> Enum.join(",\n        ")

    bt_setup =
      spec.belongs_tos
      |> Enum.map(&fixture_bt_line/1)
      |> Enum.join("\n    ")

    bt_merge =
      spec.belongs_tos
      |> Enum.map_join(",\n        ", fn bt -> "#{FieldRenderer.fk_name(bt)}: #{bt.name}.id" end)

    merge_line =
      [attrs, bt_merge] |> Enum.reject(&(&1 in ["", nil])) |> Enum.join(",\n        ")

    body = """
    @doc \"\"\"
    Generate a #{s}.
    \"\"\"
    def #{naming.fixture_fn}(attrs \\\\ %{}) do
      #{bt_setup}

      {:ok, #{s}} =
        attrs
        |> Enum.into(%{
          #{merge_line}
        })
        |> #{inspect(naming.context_module)}.create_#{s}()

      #{s}
    end
    """

    render("fixtures.ex.eex", %{body: body})
  end

  defp fixture_bt_line(bt) do
    {mod, fun} = bt.options_from
    "#{bt.name} = #{inspect(mod)}.#{fun}() |> List.first()"
  end

  defp default_value(%{type: :text}), do: "some #{"value"}"
  defp default_value(%{type: :textarea}), do: "some notes"
  defp default_value(%{type: :number}), do: 42
  defp default_value(%{type: :date}), do: Date.utc_today()
  defp default_value(%{type: :boolean, default: nil}), do: true
  defp default_value(%{type: :boolean, default: d}), do: d
  defp default_value(%{type: :select, options: [{_label, value} | _]}), do: value
  defp default_value(%{type: :select}), do: nil

  # ---------------------------------------------------------------------
  # resource_test.exs (inner describe block)
  # ---------------------------------------------------------------------

  def resource_test(%Spec{} = spec, %Naming{} = naming) do
    s = naming.singular
    ctx = naming.context_alias
    ctx_mod = inspect(naming.context_module)
    schema_ref = "#{ctx_mod}.#{naming.schema_alias}"

    update_field = List.first(spec.fields) || %{name: :id}
    valid_attrs = Enum.map(spec.fields, fn f -> "#{f.name}: #{inspect(default_value(f))}" end)

    invalid_attrs =
      spec.fields |> Enum.filter(& &1.required) |> Enum.map(fn f -> "#{f.name}: nil" end)

    list_line = "assert #{ctx}.list_#{naming.plural}() == [#{s}]"

    archive_test =
      if spec.soft_delete do
        """

          test "list_#{naming.plural}/0 excludes archived #{humanize_plural(s)}" do
            #{s} = #{naming.fixture_fn}()
            assert {:ok, _} = #{ctx}.archive_#{s}(#{s})
            assert #{ctx}.list_#{naming.plural}() == []
          end
        """
      else
        ""
      end

    delete_call = if spec.soft_delete, do: "archive_#{s}", else: "delete_#{s}"

    body = """
    describe #{inspect(naming.plural)} do
      alias #{schema_ref}

      import SnippetSaver.#{Naming.camelize(ctx)}Fixtures

      @invalid_attrs %{#{Enum.join(invalid_attrs, ", ")}}

      test "list_#{naming.plural}/0 returns all #{humanize_plural(s)}" do
        #{s} = #{naming.fixture_fn}()
        #{list_line}
      end
    #{archive_test}
      test "get_#{s}!/1 returns the #{s} with given id" do
        #{s} = #{naming.fixture_fn}()
        assert #{ctx}.get_#{s}!(#{s}.id) == #{s}
      end

      test "create_#{s}/1 with valid data creates a #{s}" do
        valid_attrs = %{#{Enum.join(valid_attrs, ", ")}}
        assert {:ok, %#{naming.schema_alias}{}} = #{ctx}.create_#{s}(valid_attrs)
      end

      test "create_#{s}/1 with invalid data returns error changeset" do
        assert {:error, %Ecto.Changeset{}} = #{ctx}.create_#{s}(@invalid_attrs)
      end

      test "update_#{s}/2 with valid data updates the #{s}" do
        #{s} = #{naming.fixture_fn}()
        assert {:ok, %#{naming.schema_alias}{}} = #{ctx}.update_#{s}(#{s}, %{#{update_field.name}: #{inspect(default_value(update_field))}})
      end

      test "update_#{s}/2 with invalid data returns error changeset" do
        #{s} = #{naming.fixture_fn}()
        assert {:error, %Ecto.Changeset{}} = #{ctx}.update_#{s}(#{s}, @invalid_attrs)
        assert #{s} == #{ctx}.get_#{s}!(#{s}.id)
      end

      test "#{delete_call}/1 removes the #{s} from the active list" do
        #{s} = #{naming.fixture_fn}()
        assert {:ok, _} = #{ctx}.#{delete_call}(#{s})
      end

      test "change_#{s}/1 returns a #{s} changeset" do
        #{s} = #{naming.fixture_fn}()
        assert %Ecto.Changeset{} = #{ctx}.change_#{s}(#{s})
      end
    end
    """

    render("resource_test.exs.eex", %{body: body})
  end
end
