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
    subtabs: []
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
          display_fn: {module, atom} | nil
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

  def routing(mode) when is_atom(mode), do: update_spec!(&%{&1 | routing: mode})

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

    if quick_create do
      Mix.raise(
        "belongs_to #{inspect(name)}: quick_create: true is not implemented in Phase 1 " <>
          "(see resource-generator-design.md §4 — planned for a later phase). Remove it, or set quick_create: false."
      )
    end

    if searchable and is_nil(options_from) do
      Mix.raise(
        "belongs_to #{inspect(name)}, searchable: true requires `options_from: {Module, :function}` " <>
          "so the generator knows which catalog to search against (mirrors the breed/colour combobox pattern)"
      )
    end

    if !searchable and is_nil(options_from) do
      Mix.raise(
        "belongs_to #{inspect(name)}: requires `options_from: {Module, :function}` in Phase 1 " <>
          "(plain unconstrained belongs_to selects with no option source are not supported yet)"
      )
    end

    entry = %{
      name: name,
      module: module,
      searchable: searchable,
      options_from: options_from,
      quick_create: quick_create,
      display_fn: display_fn
    }

    update_spec!(&%{&1 | belongs_tos: &1.belongs_tos ++ [entry]})
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

      nil ->
        Mix.raise("resource #{inspect(spec.name)}: `routing :top_level` is required")

      other ->
        Mix.raise(
          "resource #{inspect(spec.name)}: routing #{inspect(other)} is not implemented in Phase 1 " <>
            "(only :top_level is supported — see resource-generator-design.md §9.4 for :embedded_only, planned later)"
        )
    end

    if spec.subtabs not in [[], [:details]] do
      Mix.raise(
        "resource #{inspect(spec.name)}: subtabs #{inspect(spec.subtabs)} is not supported in Phase 1 " <>
          "(only [:details] — additional subtabs require :nested_collection fields, see design doc §5, " <>
          "planned for a later phase)"
      )
    end

    if spec.fields == [] and spec.belongs_tos == [] do
      Mix.raise("resource #{inspect(spec.name)}: at least one field or belongs_to is required")
    end

    :ok
  end
end
