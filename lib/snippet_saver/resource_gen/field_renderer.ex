defmodule SnippetSaver.ResourceGen.FieldRenderer do
  @moduledoc """
  Per-field-type source generation, dispatched by field type (design doc §3, types 1/2/3/4/5).

  Each function here returns plain text (Elixir or HEEx source) that templates splice in
  verbatim — kept as small dispatching functions rather than nested `<%= if %>` conditionals in
  the `.eex` templates themselves, per the spec's Part 2 guidance.

  Reference conventions mirrored exactly (do not invent new component APIs):
    - `lib/snippet_saver/patients/patient.ex` — plain `field :x_id, :id` for relationships,
      not a real `Ecto.Schema.belongs_to/3`
    - `lib/snippet_saver_web/live/patient_live/components/form_component.ex` — `<.input>`,
      `<.yes_no>`, `<.searchable_select>` call shapes, `enum_options/1`, the breed-combobox
      `handle_event` quintet (focus/search/close/pick/clear)
    - `priv/repo/migrations/20260405145101_create_patients.exs` — `references(table, on_delete:
      :nothing)` + a companion `create_if_not_exists index(...)` for every FK column
  """

  alias SnippetSaver.ResourceGen.Naming

  # ---------------------------------------------------------------------
  # Simple fields (types 1/2/3): schema/migration/changeset
  # ---------------------------------------------------------------------

  @spec ecto_type(map) :: atom
  def ecto_type(%{type: :text}), do: :string
  def ecto_type(%{type: :number}), do: :integer
  def ecto_type(%{type: :date}), do: :date
  def ecto_type(%{type: :textarea}), do: :string
  def ecto_type(%{type: :boolean}), do: :boolean
  def ecto_type(%{type: :select}), do: :string

  @spec schema_line(map) :: String.t()
  def schema_line(%{type: :boolean, default: default} = f) do
    default = if is_nil(default), do: false, else: default
    "field :#{f.name}, :boolean, default: #{inspect(default)}"
  end

  def schema_line(%{default: nil} = f), do: "field :#{f.name}, :#{ecto_type(f)}"
  def schema_line(f), do: "field :#{f.name}, :#{ecto_type(f)}, default: #{inspect(f.default)}"

  @spec migration_line(map) :: String.t()
  def migration_line(%{type: :boolean} = f) do
    default = if is_nil(f.default), do: false, else: f.default
    "add :#{f.name}, :boolean, default: #{inspect(default)}, null: false"
  end

  def migration_line(%{default: nil} = f), do: "add :#{f.name}, :#{ecto_type(f)}"
  def migration_line(f), do: "add :#{f.name}, :#{ecto_type(f)}, default: #{inspect(f.default)}"

  @spec label(atom) :: String.t()
  def label(name) do
    name
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  @spec validate_lines([map], [map]) :: [String.t()]
  def validate_lines(fields, belongs_tos) do
    required_names =
      (Enum.filter(fields, & &1.required) |> Enum.map(& &1.name)) ++
        (Enum.filter(belongs_tos, & &1[:required]) |> Enum.map(&:"#{&1.name}_id"))

    required_line =
      if required_names == [],
        do: [],
        else: ["|> validate_required(#{inspect(required_names)})"]

    boolean_inclusion_lines =
      fields
      |> Enum.filter(&(&1.type == :boolean))
      |> Enum.map(&"|> validate_inclusion(:#{&1.name}, [true, false])")

    field_validation_lines =
      fields
      |> Enum.flat_map(fn f -> Enum.map(f.validations, &render_validation(f.name, &1)) end)

    required_line ++ field_validation_lines ++ boolean_inclusion_lines
  end

  defp render_validation(name, {:number, opts}) do
    "|> validate_number(:#{name}, #{inspect(opts)})"
  end

  defp render_validation(name, {:format, regex, opts}) do
    opts_str = if opts == [], do: "", else: ", #{inspect(opts)}"
    "|> validate_format(:#{name}, #{inspect(regex)}#{opts_str})"
  end

  defp render_validation(name, {:length, opts}) do
    "|> validate_length(:#{name}, #{inspect(opts)})"
  end

  defp render_validation(name, {:inclusion, values}) do
    "|> validate_inclusion(:#{name}, #{inspect(values)})"
  end

  # ---------------------------------------------------------------------
  # belongs_to fields (types 4/5)
  # ---------------------------------------------------------------------

  @spec fk_name(map) :: atom
  def fk_name(bt), do: :"#{bt.name}_id"

  @spec bt_schema_line(map) :: String.t()
  def bt_schema_line(bt), do: "field :#{fk_name(bt)}, :id"

  @spec bt_migration_line(map) :: String.t()
  def bt_migration_line(bt) do
    target_table = bt[:table] || bt.module.__schema__(:source)
    "add :#{fk_name(bt)}, references(:#{target_table}, on_delete: :nothing)"
  end

  @spec bt_index_line(map, atom) :: String.t()
  def bt_index_line(bt, table) do
    "create_if_not_exists index(:#{table}, [:#{fk_name(bt)}])"
  end

  @spec options_assign_name(map) :: String.t()
  def options_assign_name(%{name: name}), do: "#{name}_options"

  # ---------------------------------------------------------------------
  # Form field HEEx
  # ---------------------------------------------------------------------

  @spec form_field_heex(map, String.t()) :: String.t()
  def form_field_heex(%{type: type} = f, _resource_name) when type in [:text, :date] do
    tag = if type == :date, do: "date", else: "text"
    ~s|<.input type="#{tag}" field={@form[:#{f.name}]} label="#{label(f.name)}" />|
  end

  def form_field_heex(%{type: :number} = f, _resource_name) do
    ~s|<.input type="number" field={@form[:#{f.name}]} label="#{label(f.name)}" />|
  end

  def form_field_heex(%{type: :textarea} = f, _resource_name) do
    ~s|<.input type="textarea" field={@form[:#{f.name}]} label="#{label(f.name)}" rows="4" />|
  end

  def form_field_heex(%{type: :boolean} = f, resource_name) do
    ~s|<.yes_no name="#{resource_name}[#{f.name}]" label="#{label(f.name)}" value={Phoenix.HTML.Form.input_value(@form, :#{f.name})} />|
  end

  def form_field_heex(%{type: :select} = f, _resource_name) do
    ~s|<.input type="select" field={@form[:#{f.name}]} label="#{label(f.name)}" options={@#{options_assign_name(f)}} prompt="Select #{String.downcase(label(f.name))}" />|
  end

  @spec bt_form_field_heex(map) :: String.t()
  def bt_form_field_heex(%{searchable: false} = bt) do
    ~s|<.input type="select" field={@form[:#{fk_name(bt)}]} label="#{label(bt.name)}" options={@#{options_assign_name(bt)}} prompt="Select #{String.downcase(label(bt.name))}" />|
  end

  def bt_form_field_heex(%{searchable: true} = bt) do
    prefix = "#{bt.name}"

    """
    <.searchable_select
      field={@form[:#{fk_name(bt)}]}
      label="#{label(bt.name)}"
      placeholder="Search #{String.downcase(label(bt.name))}s..."
      display={@#{prefix}_combobox_display}
      open={@#{prefix}_combobox_open}
      suggestions={@#{prefix}_combobox_suggestions}
      search_name="#{prefix}_combobox_q"
      search_event="#{prefix}-combobox-search"
      focus_event="#{prefix}-combobox-focus"
      close_event="#{prefix}-combobox-close"
      pick_event="#{prefix}-combobox-pick"
      clear_event="#{prefix}-combobox-clear"
      phx_target={@myself}
    />
    """
    |> String.trim_trailing()
  end

  # ---------------------------------------------------------------------
  # searchable_select (type 5): handle_event quintet + catalog assign
  # ---------------------------------------------------------------------

  @spec searchable_select_handle_events(map) :: String.t()
  def searchable_select_handle_events(bt) do
    prefix = bt.name
    fk = fk_name(bt)
    catalog_assign = "#{prefix}_catalog"

    """
    def handle_event("#{prefix}-combobox-focus", _params, socket) do
      q = socket.assigns.#{prefix}_combobox_display || ""
      suggestions = filter_name_tuples(socket.assigns.#{catalog_assign}, q, 50)

      {:noreply,
       assign(socket,
         #{prefix}_combobox_open: true,
         #{prefix}_combobox_suggestions: suggestions
       )}
    end

    def handle_event("#{prefix}-combobox-search", params, socket) do
      q = Map.get(params, "#{prefix}_combobox_q", "") || ""
      suggestions = filter_name_tuples(socket.assigns.#{catalog_assign}, q, 50)

      {:noreply,
       assign(socket,
         #{prefix}_combobox_display: q,
         #{prefix}_combobox_open: true,
         #{prefix}_combobox_suggestions: suggestions
       )}
    end

    def handle_event("#{prefix}-combobox-close", _params, socket) do
      {:noreply, assign(socket, #{prefix}_combobox_open: false)}
    end

    def handle_event("#{prefix}-combobox-pick", %{"id" => id, "label" => label}, socket) do
      fk = normalize_fk(id)
      cs = socket.assigns.form.source |> Ecto.Changeset.put_change(:#{fk}, fk)

      {:noreply,
       socket
       |> assign(:form, to_form(cs))
       |> assign(:#{prefix}_combobox_display, label)
       |> assign(:#{prefix}_combobox_open, false)
       |> assign(:#{prefix}_combobox_suggestions, [])}
    end

    def handle_event("#{prefix}-combobox-clear", _params, socket) do
      cs = socket.assigns.form.source |> Ecto.Changeset.put_change(:#{fk}, nil)

      {:noreply,
       socket
       |> assign(:form, to_form(cs))
       |> assign(:#{prefix}_combobox_display, "")
       |> assign(:#{prefix}_combobox_open, false)
       |> assign(:#{prefix}_combobox_suggestions, [])}
    end
    """
    |> String.trim_trailing()
  end

  @spec searchable_select_mount_assigns(map) :: [String.t()]
  def searchable_select_mount_assigns(bt) do
    prefix = bt.name

    [
      "#{prefix}_combobox_display: \"\"",
      "#{prefix}_combobox_open: false",
      "#{prefix}_combobox_suggestions: []"
    ]
  end

  # ---------------------------------------------------------------------
  # LiveTable field entry (table.ex)
  # ---------------------------------------------------------------------

  @spec table_field_entry({atom, keyword}) :: String.t()
  def table_field_entry({name, opts}) do
    label = label(name)
    sortable = Keyword.get(opts, :sortable, false)
    filterable = Keyword.get(opts, :filterable, false)
    computed = Keyword.get(opts, :computed, false)

    lines = [
      "label: #{inspect(label)}",
      "sortable: #{inspect(sortable)}"
    ]

    lines = if filterable, do: lines ++ ["filter: true"], else: lines

    lines =
      if computed do
        lines ++ ["computed: dynamic([resource: r], field(r, ^:#{name}))"]
      else
        lines
      end

    body = Enum.map_join(lines, ",\n        ", & &1)

    "#{name}: %{\n        #{body}\n      }"
  end

  @doc "Renders the `list_fields` opts into a `fields/0` map body for `table.ex.eex`."
  @spec table_fields_body(Naming.t(), [{atom, keyword}]) :: String.t()
  def table_fields_body(naming, list_fields) do
    entries = Enum.map(list_fields, &table_field_entry/1)

    actions_entry = """
    actions: %{
        label: "Actions",
        sortable: false,
        computed: dynamic([resource: r], r),
        renderer: fn #{naming.singular} ->
          id =
            if is_struct(#{naming.singular}), do: #{naming.singular}.id,
            else: #{naming.singular}[:id] || get_in(#{naming.singular}, [:actions, :id])

          assigns = %{id: id}

          ~H\"\"\"
          <div class="flex gap-2">
            <.button type="button" phx-click="go-to-edit" phx-value-id={@id} variant="outline" size="xs">
              <.icon name="hero-pencil" class="h-3 w-3" />
            </.button>
            <.button type="button" phx-click="go-to-show" phx-value-id={@id} variant="outline" size="xs">
              <.icon name="hero-eye" class="h-3 w-3" />
            </.button>
            <.button phx-click="delete" phx-value-id={@id} variant="danger" size="xs" data-confirm="Are you sure?">
              <.icon name="hero-trash" class="h-3 w-3" />
            </.button>
          </div>
          \"\"\"
        end
      }
    """
    |> String.trim_trailing()

    Enum.map_join(entries ++ [actions_entry], ",\n\n      ", & &1)
  end

  # ---------------------------------------------------------------------
  # :nested_collection (Phase 2, design doc §5) — both `mode: :buffered` and `mode: :immediate`.
  #
  # Reference conventions mirrored exactly here too:
  #   - `lib/snippet_saver_web/live/patient_live/components/form_component.ex` — the buffered
  #     shape: `@master_problem_rows` (plain string-keyed maps), index-based edit/delete,
  #     `replace_patient_master_problems/2` called only from the parent's own save function.
  #   - `lib/snippet_saver_web/live/patient_live/components/notes_component.ex` — the immediate
  #     shape: `@notes` (real structs), id-based edit/delete, each mutation hits the DB directly.
  #
  # Per design doc §5's own "generated vs manual" table, the row-form's *field layout* is
  # domain-specific and explicitly left manual for hand-composition from types 1-5 — `row_fields`
  # here carries no type info (see Naming's moduledoc note on child specs not being re-parsed), so
  # every row field renders as a generic text input. That's a deliberate, documented starting
  # point (matches the design doc's "70-95% generated, hand-finish the bespoke parts" framing),
  # not an oversight — swap individual `<.input type="text" .../>` lines for the real field type
  # by hand once generated, same as any other hand-finishing step in this pipeline.
  # ---------------------------------------------------------------------

  @spec nc_row_fields_str([atom]) :: [String.t()]
  defp nc_row_fields_str(row_fields), do: Enum.map(row_fields, &Atom.to_string/1)

  @spec nc_blank_row_map(map) :: String.t()
  def nc_blank_row_map(nc) do
    body = nc.row_fields |> nc_row_fields_str() |> Enum.map_join(", ", &~s[#{inspect(&1)} => ""])
    "%{#{body}}"
  end

  @spec nc_row_extract_from_params(map) :: String.t()
  def nc_row_extract_from_params(nc) do
    body =
      nc.row_fields
      |> nc_row_fields_str()
      |> Enum.map_join(", ", &~s[#{inspect(&1)} => Map.get(params, #{inspect(&1)}, "")])

    "%{#{body}}"
  end

  @spec nc_row_to_map_from_struct(map, String.t()) :: String.t()
  def nc_row_to_map_from_struct(nc, record_var) do
    body =
      nc.row_fields
      |> nc_row_fields_str()
      |> Enum.map_join(", ", &~s[#{inspect(&1)} => to_string(#{record_var}.#{&1} || "")])

    "%{#{body}}"
  end

  @spec nc_row_field_inputs_heex(map) :: String.t()
  def nc_row_field_inputs_heex(nc) do
    nc.row_fields
    |> Enum.map_join("\n            ", fn f ->
      ~s|<.input type="text" field={@#{nc.name}_form[:#{f}]} label="#{label(f)}" />|
    end)
  end

  @spec nc_table_headers_heex([atom]) :: String.t()
  def nc_table_headers_heex(row_fields) do
    row_fields
    |> Enum.map_join(
      "\n                  ",
      &~s|<th class="text-left px-4 py-3 font-semibold">#{label(&1)}</th>|
    )
  end

  @spec nc_table_cells_heex(map, :buffered | :immediate) :: String.t()
  def nc_table_cells_heex(nc, :buffered) do
    nc.row_fields
    |> Enum.map_join(
      "\n                    ",
      &"<td class=\"px-4 py-3\"><%= row[\"#{&1}\"] || \"—\" %></td>"
    )
  end

  def nc_table_cells_heex(nc, :immediate) do
    nc.row_fields
    |> Enum.map_join(
      "\n                    ",
      &"<td class=\"px-4 py-3\"><%= row.#{&1} || \"—\" %></td>"
    )
  end

  @doc "The extra context functions a nested_collection needs beyond what its child's own gen run already produced: a parent-scoped list (both modes) and, for :buffered, the sync_fn body."
  @spec nc_context_functions(map, Naming.t()) :: String.t()
  def nc_context_functions(nc, naming) do
    # Fully-qualified (never a bare alias) — this body may be spliced into a *different* context
    # module than the child's own (design doc §5 doesn't require the two to match), and fully
    # qualified calls work correctly either way, with or without an `alias` in scope.
    child_ctx = inspect(Naming.nc_child_context_module(nc.child_schema))
    child_schema_ref = inspect(nc.child_schema)
    child_singular = Naming.nc_child_singular(nc.child_schema)
    scoped_list_fn = Naming.nc_scoped_list_fn(nc.child_schema, naming.singular)
    parent_fk = "#{naming.singular}_id"

    list_fn = """
    @doc \"\"\"
    #{label(nc.name)} belonging to the given #{naming.singular}.
    \"\"\"
    def #{scoped_list_fn}(#{naming.singular}_id) do
      from(x in #{child_schema_ref}, where: field(x, :#{parent_fk}) == ^#{naming.singular}_id, order_by: [asc: x.id])
      |> Repo.all()
    end
    """

    sync_fn =
      if nc.mode == :buffered do
        {_mod, fun} = nc.sync_fn

        """

        @doc \"\"\"
        Replaces all #{label(nc.name)} for the given #{naming.singular} with `rows` in one transaction —
        deletes existing rows, then reinserts `rows`. Buffered nested-collection sync (design doc §5):
        nothing is persisted until the parent record itself is saved.
        \"\"\"
        def #{fun}(#{naming.singular}_id, rows) when is_list(rows) do
          Repo.transaction(fn ->
            from(x in #{child_schema_ref}, where: field(x, :#{parent_fk}) == ^#{naming.singular}_id) |> Repo.delete_all()

            Enum.reduce_while(rows, :ok, fn row, _acc ->
              attrs =
                Map.merge(
                  %{"#{parent_fk}" => #{naming.singular}_id},
                  Map.new(#{inspect(nc_row_fields_str(nc.row_fields))}, fn key -> {key, row[key] || row[String.to_existing_atom(key)]} end)
                )

              case #{child_ctx}.create_#{child_singular}(attrs) do
                {:ok, _record} -> {:cont, :ok}
                {:error, changeset} -> {:halt, Repo.rollback(changeset)}
              end
            end)
          end)
        end
        """
      else
        ""
      end

    list_fn <> sync_fn
  end

  @doc "The LiveComponent state assign_new/1 lines added to `update/2`'s pipe for one nested_collection (mode-agnostic — both need modal open/close/index state)."
  @spec nc_update_pipe_lines(map) :: [String.t()]
  def nc_update_pipe_lines(nc) do
    [
      "|> assign_new(:#{nc.name}_modal_mode, fn -> nil end)",
      "|> assign_new(:#{nc.name}_modal_index, fn -> nil end)",
      "|> assign_new(:#{nc.name}_form, fn -> nil end)",
      "|> assign_#{nc.name}_rows()"
    ]
  end

  @doc "The `defp assign_<name>_rows/1` loader — mode-specific: buffered maps DB structs down to plain row maps (so the buffered save-modal handler, which only ever deals in plain maps, doesn't need a struct-vs-map branch); immediate keeps real structs since edit/delete key off `.id`."
  @spec nc_assign_rows_fn(map, Naming.t()) :: String.t()
  def nc_assign_rows_fn(nc, naming) do
    scoped_list_fn = Naming.nc_scoped_list_fn(nc.child_schema, naming.singular)
    schema_alias = naming.schema_alias
    ctx = naming.context_alias

    load_expr = "#{ctx}.#{scoped_list_fn}(#{naming.singular}_id)"

    load_expr =
      if nc.mode == :buffered do
        "#{load_expr} |> Enum.map(fn record -> #{nc_row_to_map_from_struct(nc, "record")} end)"
      else
        load_expr
      end

    """
    defp assign_#{nc.name}_rows(socket) do
      rows =
        case socket.assigns[:#{naming.singular}] do
          %#{schema_alias}{id: nil} -> []
          %#{schema_alias}{id: #{naming.singular}_id} -> #{load_expr}
          _ -> []
        end

      assign(socket, :#{nc.name}_rows, rows)
    end
    """
  end

  @doc "The `handle_event` clauses for one nested_collection's modal open/edit/close/save/delete."
  @spec nc_handle_events(map, Naming.t()) :: String.t()
  def nc_handle_events(nc, naming) do
    child_singular = Naming.nc_child_singular(nc.child_schema)
    # Fully-qualified, not a bare alias — `form_component.ex` only ever aliases the *parent's*
    # own context module, so a bare child-context reference would fail to compile whenever the
    # child lives in a different context than the parent.
    child_ctx = inspect(Naming.nc_child_context_module(nc.child_schema))
    label = label(nc.name)
    name = nc.name

    open_close = """
    def handle_event("open-#{name}-modal", %{"mode" => "new"}, socket) do
      {:noreply,
       socket
       |> assign(:#{name}_modal_mode, :new)
       |> assign(:#{name}_modal_index, nil)
       |> assign(:#{name}_form, #{nc_new_row_form_expr(nc, child_singular, child_ctx)})}
    end

    def handle_event("close-#{name}-modal", _params, socket) do
      {:noreply,
       socket
       |> assign(:#{name}_modal_mode, nil)
       |> assign(:#{name}_modal_index, nil)
       |> assign(:#{name}_form, nil)}
    end

    def handle_event("delete-#{name}-row", #{if nc.mode == :buffered, do: ~s(%{"index" => index}), else: ~s(%{"id" => id})}, socket) do
    #{nc_delete_row_body(nc, naming, child_ctx)}
    end
    """

    edit_and_save =
      if nc.mode == :buffered do
        """
        def handle_event("edit-#{name}-modal", %{"index" => index}, socket) do
          idx = if is_integer(index), do: index, else: String.to_integer(index)
          row = Enum.at(socket.assigns.#{name}_rows, idx, #{nc_blank_row_map(nc)})

          {:noreply,
           socket
           |> assign(:#{name}_modal_mode, :edit)
           |> assign(:#{name}_modal_index, idx)
           |> assign(:#{name}_form, to_form(row, as: :#{name}_row))}
        end

        def handle_event("save-#{name}-modal", %{"#{name}_row" => params}, socket) do
          row = #{nc_row_extract_from_params(nc)}

          rows =
            case socket.assigns.#{name}_modal_mode do
              :edit when is_integer(socket.assigns.#{name}_modal_index) ->
                List.replace_at(socket.assigns.#{name}_rows, socket.assigns.#{name}_modal_index, row)

              _ ->
                socket.assigns.#{name}_rows ++ [row]
            end

          {:noreply,
           socket
           |> assign(:#{name}_rows, rows)
           |> assign(:#{name}_modal_mode, nil)
           |> assign(:#{name}_modal_index, nil)
           |> assign(:#{name}_form, nil)}
        end
        """
      else
        """
        def handle_event("edit-#{name}-modal", %{"id" => id}, socket) do
          record = Enum.find(socket.assigns.#{name}_rows, &(to_string(&1.id) == to_string(id)))

          if record do
            changeset = #{child_ctx}.change_#{child_singular}(record, %{})

            {:noreply,
             socket
             |> assign(:#{name}_modal_mode, :edit)
             |> assign(:#{name}_modal_index, record.id)
             |> assign(:#{name}_form, to_form(changeset))}
          else
            {:noreply, socket}
          end
        end

        def handle_event("save-#{name}-modal", %{"#{child_singular}" => params}, socket) do
          save_#{name}_row(socket, socket.assigns.#{name}_modal_mode, params)
        end
        """
      end

    [open_close, edit_and_save]
    |> Enum.join("\n")
    |> Kernel.<>(if nc.mode == :immediate, do: "\n" <> nc_immediate_save_helpers(nc, naming, child_singular, child_ctx, label), else: "")
  end

  defp nc_new_row_form_expr(%{mode: :buffered} = nc, _child_singular, _child_ctx) do
    "to_form(#{nc_blank_row_map(nc)}, as: :#{nc.name}_row)"
  end

  defp nc_new_row_form_expr(%{mode: :immediate} = nc, child_singular, child_ctx) do
    "to_form(#{child_ctx}.change_#{child_singular}(struct(#{inspect(nc.child_schema)}), %{}))"
  end

  defp nc_delete_row_body(%{mode: :buffered} = nc, _naming, _child_ctx) do
    """
      idx = String.to_integer(index)
      rows = List.delete_at(socket.assigns.#{nc.name}_rows, idx)
      {:noreply, assign(socket, :#{nc.name}_rows, rows)}
    """
  end

  defp nc_delete_row_body(%{mode: :immediate} = nc, _naming, child_ctx) do
    child_singular = Naming.nc_child_singular(nc.child_schema)
    delete_call = nc_delete_call(nc, child_ctx, child_singular)

    """
      record = Enum.find(socket.assigns.#{nc.name}_rows, &(to_string(&1.id) == to_string(id)))

      case record && #{delete_call}(record) do
        {:ok, _deleted} ->
          {:noreply,
           socket
           |> put_flash(:info, "#{label(nc.name)} deleted")
           |> assign_#{nc.name}_rows()}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Failed to delete")}

        nil ->
          {:noreply, socket}
      end
    """
  end

  defp nc_delete_call(%{delete_fn: {mod, fun}}, _child_ctx, _child_singular), do: "#{inspect(mod)}.#{fun}"

  defp nc_delete_call(%{delete_fn: nil, child_schema: child_schema}, child_ctx, child_singular) do
    if Naming.nc_child_soft_delete?(child_schema) do
      "#{child_ctx}.archive_#{child_singular}"
    else
      "#{child_ctx}.delete_#{child_singular}"
    end
  end

  defp nc_immediate_save_helpers(nc, naming, child_singular, child_ctx, label) do
    """
    defp save_#{nc.name}_row(socket, :edit, params) do
      record = Enum.find(socket.assigns.#{nc.name}_rows, &(&1.id == socket.assigns.#{nc.name}_modal_index))

      case #{child_ctx}.update_#{child_singular}(record, params) do
        {:ok, _record} ->
          {:noreply,
           socket
           |> put_flash(:info, "#{label} updated")
           |> assign(:#{nc.name}_modal_mode, nil)
           |> assign(:#{nc.name}_modal_index, nil)
           |> assign(:#{nc.name}_form, nil)
           |> assign_#{nc.name}_rows()}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :#{nc.name}_form, to_form(changeset))}
      end
    end

    defp save_#{nc.name}_row(socket, _mode, params) do
      params = Map.put(params, "#{naming.singular}_id", socket.assigns.#{naming.singular}.id)

      case #{child_ctx}.create_#{child_singular}(params) do
        {:ok, _record} ->
          {:noreply,
           socket
           |> put_flash(:info, "#{label} added")
           |> assign(:#{nc.name}_modal_mode, nil)
           |> assign(:#{nc.name}_modal_index, nil)
           |> assign(:#{nc.name}_form, nil)
           |> assign_#{nc.name}_rows()}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :#{nc.name}_form, to_form(changeset))}
      end
    end
    """
  end

  @doc "The table + add-button + modal HEEx block for one nested_collection, spliced into the parent form's render/1."
  @spec nc_heex(map, Naming.t()) :: String.t()
  def nc_heex(nc, naming) do
    row_var = if nc.mode == :buffered, do: "{row, idx}", else: "row"
    rows_expr = if nc.mode == :buffered, do: "Enum.with_index(@#{nc.name}_rows)", else: "@#{nc.name}_rows"
    child_singular = Naming.nc_child_singular(nc.child_schema)
    colspan = length(nc.row_fields) + 1

    add_button_wrapper_open =
      if nc.mode == :immediate, do: ~s(<div :if={@#{naming.singular}.id}>), else: ""

    add_button_wrapper_close = if nc.mode == :immediate, do: "</div>", else: ""

    edit_click =
      if nc.mode == :buffered do
        ~s|phx-click={JS.push("edit-#{nc.name}-modal", value: %{index: idx}, target: @myself)}|
      else
        ~s|phx-click={JS.push("edit-#{nc.name}-modal", value: %{id: row.id}, target: @myself)}|
      end

    delete_click =
      if nc.mode == :buffered do
        ~s|phx-click="delete-#{nc.name}-row" phx-value-index={idx}|
      else
        ~s|phx-click="delete-#{nc.name}-row" phx-value-id={row.id} data-confirm="Are you sure?"|
      end

    """
    <div class="mt-6">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-gray-900">#{label(nc.name)}</h3>
        #{add_button_wrapper_open}
        <.button type="button" variant="primary" size="sm" phx-target={@myself} phx-click={JS.push("open-#{nc.name}-modal", value: %{mode: "new"}, target: @myself)}>
          + Add #{label(String.to_atom(child_singular))}
        </.button>
        #{add_button_wrapper_close}
      </div>

      <div class="overflow-x-auto border rounded-lg">
        <table class="min-w-full text-sm">
          <thead class="bg-gray-50 text-gray-600">
            <tr>
              #{nc_table_headers_heex(nc.row_fields)}
              <th class="text-left px-4 py-3 font-semibold">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y">
            <tr :if={@#{nc.name}_rows == []}>
              <td colspan="#{colspan}" class="px-4 py-4 text-gray-500">No #{String.downcase(label(nc.name))} added yet.</td>
            </tr>
            <tr :for={#{row_var} <- #{rows_expr}}>
              #{nc_table_cells_heex(nc, nc.mode)}
              <td class="px-4 py-3">
                <div class="flex items-center gap-2">
                  <.button type="button" size="sm" variant="outline" phx-target={@myself} #{edit_click}>
                    Edit
                  </.button>
                  <.button type="button" size="sm" variant="danger" phx-target={@myself} #{delete_click}>
                    Delete
                  </.button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <.modal
      :if={@#{nc.name}_modal_mode}
      id={"#{String.replace(to_string(nc.name), "_", "-")}-modal-\#{@id}"}
      show
      on_cancel={JS.push("close-#{nc.name}-modal", target: @myself)}
    >
      <div class="space-y-4">
        <h3 class="text-lg font-semibold">
          <%= if @#{nc.name}_modal_mode == :edit, do: "Edit #{label(String.to_atom(child_singular))}", else: "Add #{label(String.to_atom(child_singular))}" %>
        </h3>
        <.simple_form for={@#{nc.name}_form} phx-target={@myself} phx-submit="save-#{nc.name}-modal">
          <div class="grid grid-cols-1 gap-4">
            #{nc_row_field_inputs_heex(nc)}
          </div>
          <:actions>
            <.button type="submit" variant="primary">
              <%= if @#{nc.name}_modal_mode == :edit, do: "Update", else: "Add" %>
            </.button>
            <.button type="button" variant="outline" phx-target={@myself} phx-click="close-#{nc.name}-modal">
              Cancel
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  @doc "For :buffered collections only — the sync_fn call(s) wired into the parent's own save function, after the parent record itself is created/updated (design doc §5's own \"Parent save wiring\" example)."
  @spec nc_sync_calls([map]) :: [String.t()]
  def nc_sync_calls(nested_collections) do
    nested_collections
    |> Enum.filter(&(&1.mode == :buffered))
    |> Enum.map(fn nc ->
      {mod, fun} = nc.sync_fn
      "{:ok, :ok} <- #{inspect(mod)}.#{fun}(record.id, socket.assigns.#{nc.name}_rows)"
    end)
  end
end
