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

  defp timestamp do
    {{y, mo, d}, {h, mi, s}} = :calendar.universal_time()
    "#{y}#{pad(mo)}#{pad(d)}#{pad(h)}#{pad(mi)}#{pad(s)}"
  end

  defp pad(i) when i < 10, do: "0#{i}"
  defp pad(i), do: "#{i}"
end
