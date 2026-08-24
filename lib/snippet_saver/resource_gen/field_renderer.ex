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
    target_table = bt.module.__schema__(:source)
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
end
