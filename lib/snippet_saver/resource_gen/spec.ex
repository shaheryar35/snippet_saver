defmodule SnippetSaver.ResourceGen.Spec do
  @moduledoc """
  Declarative DSL for `mix gen.resource` spec files.

  Spec files are plain `.exs` scripts evaluated with `Code.eval_file/1`:

      import SnippetSaver.ResourceGen.Spec

      resource "hear_about_option" do
        table :hear_about_options
        context SnippetSaver.Catalog
        audit true
        soft_delete true
        routing :top_level

        field :name, :text, required: true
        field :is_active, :boolean, required: true, default: true

        list_fields [
          name: [sortable: true, filterable: true],
          is_active: [sortable: true, filterable: false]
        ]

        subtabs [:details]
      end

  The `resource/2` block accumulates state in the process dictionary while it runs (plain
  function calls, not macros — this keeps field opts as ordinary Elixir terms: regexes, tuples,
  keyword lists, module aliases, all work exactly as written) and returns the built `%Spec{}` as
  the file's evaluated value, which is what `Loader.load!/1` reads back out.
  """

  defstruct [
    :name,
    :table,
    :context_module,
    :audit,
    :soft_delete,
    :routing,
    fields: [],
    belongs_tos: [],
    list_fields: [],
    subtabs: [],
    nested_collections: []
  ]

  @type field :: %{
          name: atom,
          type: :text | :number | :date | :textarea | :boolean | :select,
          required: boolean,
          default: term,
          options: list | nil,
          validations: list
        }

  @type belongs_to :: %{
          name: atom,
          module: module,
          searchable: boolean,
          options_from: {module, atom} | nil,
          quick_create: boolean,
          display_fn: {module, atom} | nil,
          dropdown: boolean,
          required: boolean,
          table: atom | nil
        }

  @type nested_collection :: %{
          name: atom,
          mode: :buffered | :immediate,
          child_schema: module,
          row_fields: [atom],
          sync_fn: {module, atom} | nil,
          create_fn: {module, atom} | nil,
          update_fn: {module, atom} | nil,
          delete_fn: {module, atom} | nil
        }

  @type t :: %__MODULE__{}

  @pdict_key :__resource_gen_spec__

  # -- resource/2 -------------------------------------------------------

  defmacro resource(name, do: block) do
    quote do
      SnippetSaver.ResourceGen.Spec.__start__(unquote(name))
      unquote(block)
      SnippetSaver.ResourceGen.Spec.__finish__()
    end
  end

  @doc false
  def __start__(name) do
    Process.put(@pdict_key, %__MODULE__{name: name})
  end

  @doc false
  def __finish__ do
    spec = Process.get(@pdict_key)
    Process.delete(@pdict_key)
    validate!(spec)
    spec
  end

  defp update_spec!(fun) do
    spec = Process.get(@pdict_key)

    if is_nil(spec) do
      Mix.raise(
        "SnippetSaver.ResourceGen.Spec: DSL calls (table/context/field/...) must appear inside a `resource \"name\" do ... end` block"
      )
    end

    Process.put(@pdict_key, fun.(spec))
  end

  # -- scalar declarations ------------------------------------------------

  def table(name) when is_atom(name), do: update_spec!(&%{&1 | table: name})

  def context(module) when is_atom(module), do: update_spec!(&%{&1 | context_module: module})

  def audit(bool) when is_boolean(bool), do: update_spec!(&%{&1 | audit: bool})

  def soft_delete(bool) when is_boolean(bool), do: update_spec!(&%{&1 | soft_delete: bool})

  def routing(mode) when mode in [:top_level, :embedded_only], do: update_spec!(&%{&1 | routing: mode})

  def routing(other) do
    Mix.raise("resource routing: must be :top_level or :embedded_only, got: #{inspect(other)}")
  end

  def list_fields(fields) when is_list(fields), do: update_spec!(&%{&1 | list_fields: fields})

  def subtabs(tabs) when is_list(tabs), do: update_spec!(&%{&1 | subtabs: tabs})

  # -- field/3 -------------------------------------------------------

  @simple_types [:text, :number, :date, :textarea, :boolean, :select]

  def field(name, type, opts \\ []) when is_atom(name) and type in @simple_types do
    unless is_list(opts) do
      Mix.raise("field #{inspect(name)}: opts must be a keyword list, got #{inspect(opts)}")
    end

    if type == :select and not Keyword.has_key?(opts, :options) do
      Mix.raise(
        "field #{inspect(name)}, :select requires `options:` (a list of {label, value} tuples) — " <>
          "for options sourced from a context function, use `belongs_to/3` with `options_from:` instead"
      )
    end

    entry = %{
      name: name,
      type: type,
      required: Keyword.get(opts, :required, false),
      default: Keyword.get(opts, :default),
      options: Keyword.get(opts, :options),
      validations: Keyword.get(opts, :validations, [])
    }

    update_spec!(&%{&1 | fields: &1.fields ++ [entry]})
  end

  # -- belongs_to/3 -------------------------------------------------------

  def belongs_to(name, module, opts \\ []) when is_atom(name) and is_atom(module) do
    unless is_list(opts) do
      Mix.raise("belongs_to #{inspect(name)}: opts must be a keyword list, got #{inspect(opts)}")
    end

    searchable = Keyword.get(opts, :searchable, false)
    options_from = Keyword.get(opts, :options_from)
    quick_create = Keyword.get(opts, :quick_create, false)
    display_fn = Keyword.get(opts, :display_fn)
    required = Keyword.get(opts, :required, false)

    # `dropdown: false` is for a plain internal FK column with no form field at all — the
    # nested-collection child's link back to its parent (design doc §5/§9.4), which is never
    # rendered as a user-facing select (an `:embedded_only` resource has no generated form to put
    # it on in the first place). Mirrors the codebase's own convention for this exact case: a bare
    # `field :parent_id, :id` on the child schema (see `patient_master_problem.ex`/`patient_note.ex`)
    # — `belongs_to` is reused here only because it already derives the FK/migration/index shape.
    dropdown = Keyword.get(opts, :dropdown, true)

    # Optional, explicit escape hatch from needing `module` already compiled at generation time
    # (Phase 1's `bt_migration_line`/`bt_index_line` normally call `module.__schema__(:source)` to
    # get the FK target table name — fine when `module` is an already-hand-built catalog, but a
    # nested-collection child's own parent-link (`dropdown: false`) is generated *before* the
    # parent it points at exists, per design doc §9.4's own generation order. Passing `table:`
    # here supplies the target table name directly, breaking that circular dependency.
    table = Keyword.get(opts, :table)

    if quick_create do
      Mix.raise(
        "belongs_to #{inspect(name)}: quick_create: true is not implemented in Phase 1 " <>
          "(see resource-generator-design.md §4 — planned for a later phase). Remove it, or set quick_create: false."
      )
    end

    if dropdown and searchable and is_nil(options_from) do
      Mix.raise(
        "belongs_to #{inspect(name)}, searchable: true requires `options_from: {Module, :function}` " <>
          "so the generator knows which catalog to search against (mirrors the breed/colour combobox pattern)"
      )
    end

    if dropdown and !searchable and is_nil(options_from) do
      Mix.raise(
        "belongs_to #{inspect(name)}: requires `options_from: {Module, :function}` in Phase 1 " <>
          "(plain unconstrained belongs_to selects with no option source are not supported yet) — " <>
          "or pass `dropdown: false` if this is an internal FK with no form field (e.g. a nested-collection child's link to its parent)"
      )
    end

    entry = %{
      name: name,
      module: module,
      searchable: searchable,
      options_from: options_from,
      quick_create: quick_create,
      display_fn: display_fn,
      dropdown: dropdown,
      required: required,
      table: table
    }

    update_spec!(&%{&1 | belongs_tos: &1.belongs_tos ++ [entry]})
  end

  # -- nested_collection/2 (Phase 2, design doc §5) ------------------------

  def nested_collection(name, opts) when is_atom(name) and is_list(opts) do
    mode = Keyword.get(opts, :mode)

    unless mode in [:buffered, :immediate] do
      Mix.raise(
        "nested_collection #{inspect(name)}: `mode: :buffered` or `mode: :immediate` is required — " <>
          "no default (see resource-generator-design.md §5, this is deliberate: silently defaulting " <>
          "risks the wrong save-timing behavior going unnoticed). Got: #{inspect(mode)}"
      )
    end

    child_schema =
      Keyword.get(opts, :child_schema) ||
        Mix.raise("nested_collection #{inspect(name)}: `child_schema: Module` is required")

    row_fields =
      Keyword.get(opts, :row_fields) ||
        Mix.raise("nested_collection #{inspect(name)}: `row_fields: [:field, ...]` is required")

    case mode do
      :buffered ->
        unless Keyword.has_key?(opts, :sync_fn) do
          Mix.raise(
            "nested_collection #{inspect(name)}: mode: :buffered requires sync_fn: {Context, :function_name}"
          )
        end

      :immediate ->
        unless Keyword.has_key?(opts, :create_fn) and Keyword.has_key?(opts, :update_fn) do
          Mix.raise(
            "nested_collection #{inspect(name)}: mode: :immediate requires both create_fn: {Context, :fn} and update_fn: {Context, :fn}"
          )
        end
    end

    entry = %{
      name: name,
      mode: mode,
      child_schema: child_schema,
      row_fields: row_fields,
      sync_fn: Keyword.get(opts, :sync_fn),
      create_fn: Keyword.get(opts, :create_fn),
      update_fn: Keyword.get(opts, :update_fn),
      delete_fn: Keyword.get(opts, :delete_fn)
    }

    update_spec!(&%{&1 | nested_collections: &1.nested_collections ++ [entry]})
  end

  # -- validation -------------------------------------------------------

  @doc false
  def validate!(%__MODULE__{} = spec) do
    if is_nil(spec.table), do: Mix.raise("resource #{inspect(spec.name)}: `table :atom` is required")

    if is_nil(spec.context_module),
      do: Mix.raise("resource #{inspect(spec.name)}: `context Module` is required")

    if not is_boolean(spec.audit) do
      Mix.raise(
        "resource #{inspect(spec.name)}: `audit true` or `audit false` is required — no default " <>
          "(see resource-generator-design.md §9.3, this is deliberate: silently defaulting risks the wrong " <>
          "audit-trail behavior going unnoticed)"
      )
    end

    if not is_boolean(spec.soft_delete) do
      Mix.raise(
        "resource #{inspect(spec.name)}: `soft_delete true` or `soft_delete false` is required — no default " <>
          "(see resource-generator-design.md §9.3)"
      )
    end

    case spec.routing do
      :top_level ->
        :ok

      :embedded_only ->
        if spec.nested_collections != [] do
          Mix.raise(
            "resource #{inspect(spec.name)}: routing :embedded_only cannot itself declare nested_collections " <>
              "(design doc §4 scopes quick-create/nesting to one level deep — an embedded-only resource is " <>
              "always the child, never the parent, of a nested collection)"
          )
        end

        if spec.subtabs != [] do
          Mix.raise(
            "resource #{inspect(spec.name)}: routing :embedded_only generates no web/routing layer, " <>
              "so `subtabs` (a top-level-only concept) must be [] or omitted"
          )
        end

      nil ->
        Mix.raise("resource #{inspect(spec.name)}: `routing :top_level` or `routing :embedded_only` is required")
    end

    if spec.routing == :top_level and spec.subtabs not in [[], [:details]] do
      Mix.raise(
        "resource #{inspect(spec.name)}: subtabs #{inspect(spec.subtabs)} is not supported " <>
          "(only [:details] is generated automatically — nested_collection fields render inline on the " <>
          "same form, they don't add their own subtab in Phase 2)"
      )
    end

    if spec.fields == [] and spec.belongs_tos == [] do
      Mix.raise("resource #{inspect(spec.name)}: at least one field or belongs_to is required")
    end

    :ok
  end
end
