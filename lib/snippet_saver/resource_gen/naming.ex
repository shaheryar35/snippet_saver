defmodule SnippetSaver.ResourceGen.Naming do
  @moduledoc """
  Derives every module/file/route name a template needs from a `%Spec{}`.

  Kept as one place so templates never invent their own casing rules. Plurals are read from the
  spec's `table:` atom rather than English-pluralized from `name:` — pluralization heuristics are
  a well-known source of generator bugs (`species` -> `speciess` etc.), and the spec author already
  has to state the table name anyway.
  """

  alias SnippetSaver.ResourceGen.Spec

  defstruct [
    :singular,
    :plural,
    :schema_alias,
    :schema_module,
    :context_module,
    :context_alias,
    :web_index_module,
    :web_index_view_module,
    :web_table_module,
    :web_form_component_module,
    :web_tabs_hook_module_js,
    :route_segment,
    :migration_module,
    :migration_file_name,
    :fixture_fn,
    :context_file_path,
    :context_test_file_path,
    :fixtures_file_path
  ]

  @spec build(Spec.t()) :: %__MODULE__{}
  def build(%Spec{} = spec) do
    singular = spec.name
    plural = spec.table |> Atom.to_string()
    schema_alias = camelize(singular)
    context_alias = spec.context_module |> Module.split() |> List.last()

    %__MODULE__{
      singular: singular,
      plural: plural,
      schema_alias: schema_alias,
      schema_module: Module.concat(spec.context_module, schema_alias),
      context_module: spec.context_module,
      context_alias: context_alias,
      web_index_module: Module.concat([SnippetSaverWeb, "#{schema_alias}Live", "Index"]),
      web_index_view_module: Module.concat([SnippetSaverWeb, "#{schema_alias}Live", "IndexView"]),
      web_table_module: Module.concat([SnippetSaverWeb, "#{schema_alias}Live", "Table"]),
      web_form_component_module:
        Module.concat([SnippetSaverWeb, "#{schema_alias}Live", "Components", "FormComponent"]),
      web_tabs_hook_module_js: "#{schema_alias}Tabs",
      route_segment: plural,
      migration_module: Module.concat([SnippetSaver.Repo.Migrations, "Create#{camelize(plural)}"]),
      migration_file_name: "#{timestamp()}_create_#{plural}.exs",
      fixture_fn: "#{singular}_fixture",
      context_file_path:
        "lib/snippet_saver/#{underscore(context_alias)}.ex",
      context_test_file_path:
        "test/snippet_saver/#{underscore(context_alias)}_test.exs",
      fixtures_file_path:
        "test/support/fixtures/#{underscore(context_alias)}_fixtures.ex"
    }
  end

  def camelize(str) when is_binary(str), do: Macro.camelize(str)
  def camelize(atom) when is_atom(atom), do: atom |> Atom.to_string() |> camelize()

  def underscore(str) when is_binary(str), do: Macro.underscore(str)

  @doc "Human-readable text for UI strings — \"hear_about_option\" -> \"Hear About Option\". Not for module names, use `camelize/1` for those."
  def humanize(str) when is_binary(str) do
    str
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  def humanize(atom) when is_atom(atom), do: atom |> Atom.to_string() |> humanize()

  # -- nested_collection child derivation (Phase 2, design doc §5) --------
  #
  # A `:nested_collection` only carries `child_schema` (a compiled module, e.g.
  # `SnippetSaver.Catalog.VendorContact`) — the child's own spec file isn't re-parsed (design doc
  # §5: "trust the user here, same as Phase 1 trusts options_from/display_fn"). Everything below is
  # derived either from the module name itself or by introspecting the already-compiled schema
  # (`__schema__/1` — safe because an embedded-only child must be generated *and compiled* before
  # the parent that nests it, same ordering the smoke test spec enforces).

  @spec nc_child_context_module(module) :: module
  def nc_child_context_module(child_schema), do: child_schema |> Module.split() |> Enum.drop(-1) |> Module.concat()

  @spec nc_child_context_alias(module) :: String.t()
  def nc_child_context_alias(child_schema), do: nc_child_context_module(child_schema) |> Module.split() |> List.last()

  @spec nc_child_singular(module) :: String.t()
  def nc_child_singular(child_schema), do: child_schema |> Module.split() |> List.last() |> underscore()

  @spec nc_child_plural(module) :: String.t()
  def nc_child_plural(child_schema) do
    unless Code.ensure_loaded?(child_schema) do
      Mix.raise(
        "nested_collection: child_schema #{inspect(child_schema)} is not compiled/available — generate " <>
          "and compile its `routing :embedded_only` spec first (see resource-generator-design.md §9.4)"
      )
    end

    child_schema.__schema__(:source)
  end

  @spec nc_child_soft_delete?(module) :: boolean
  def nc_child_soft_delete?(child_schema), do: :archived in (child_schema.__schema__(:fields) || [])

  @spec nc_scoped_list_fn(module, String.t()) :: String.t()
  def nc_scoped_list_fn(child_schema, parent_singular),
    do: "list_#{nc_child_plural(child_schema)}_for_#{parent_singular}"

  defp timestamp do
    {{y, mo, d}, {h, mi, s}} = :calendar.universal_time()
    "#{y}#{pad(mo)}#{pad(d)}#{pad(h)}#{pad(mi)}#{pad(s)}"
  end

  defp pad(i) when i < 10, do: "0#{i}"
  defp pad(i), do: "#{i}"
end
