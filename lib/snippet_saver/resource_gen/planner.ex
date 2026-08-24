defmodule SnippetSaver.ResourceGen.Planner do
  @moduledoc """
  Turns a `%Spec{}` into an ordered list of file-plan entries:

      %{path: String.t(), content: String.t(), mode: :create | :insert | :already_present | :print_instruct, kind: atom}

  `:create` — file does not exist yet, `Writer` uses `Mix.Generator.create_file/2` (which itself
  prompts on conflict — see design doc §9.1).

  `:insert` — target file exists, already contains a `# GEN_RESOURCE_INSERT_POINT` marker
  (added by an earlier `mix gen.resource` run against the same context), and does not yet contain
  this resource's own generated code. `content` is spliced above that marker.

  `:already_present` — target file exists and already contains this resource's own generated code
  (detected via a per-file-kind signature — see `already_contains_resource?/3`). This makes
  re-running an unchanged spec idempotent: nothing is written, and `Writer`/the Mix task report it
  as a no-op rather than re-splicing a duplicate copy.

  `:print_instruct` — target file exists but has no marker (e.g. a hand-written context like
  `Settings`). Nothing is written; `Mix.Tasks.Gen.Resource` prints `content` for manual pasting.
  This is the only path that can touch an already-hand-built module, and it never writes to it.
  """

  alias SnippetSaver.ResourceGen.{Naming, Renderer, Spec}

  @marker "# GEN_RESOURCE_INSERT_POINT"

  @type plan_entry :: %{path: String.t(), content: String.t(), mode: atom, kind: atom}

  @spec build_plan(Spec.t()) :: [plan_entry]
  def build_plan(%Spec{} = spec) do
    naming = Naming.build(spec)

    [
      file_entry(:schema, "lib/#{schema_path(naming)}.ex", Renderer.schema(spec, naming)),
      file_entry(
        :migration,
        "priv/repo/migrations/#{naming.migration_file_name}",
        Renderer.migration(spec, naming)
      ),
      context_entry(spec, naming),
      file_entry(
        :index,
        "lib/snippet_saver_web/live/#{naming.singular}_live/index.ex",
        Renderer.live_index(spec, naming)
      ),
      file_entry(
        :index_view,
        "lib/snippet_saver_web/live/#{naming.singular}_live/index_view.ex",
        Renderer.index_view(spec, naming)
      ),
      file_entry(
        :form_component,
        "lib/snippet_saver_web/live/#{naming.singular}_live/components/form_component.ex",
        Renderer.form_component(spec, naming)
      ),
      file_entry(
        :table,
        "lib/snippet_saver_web/live/#{naming.singular}_live/table.ex",
        Renderer.table(spec, naming)
      ),
      file_entry(
        :tabs_hook_js,
        "assets/js/hooks/#{naming.singular}_tabs.js",
        Renderer.tabs_hook_js(spec, naming)
      ),
      fixtures_entry(spec, naming),
      resource_test_entry(spec, naming)
    ]
  end

  @spec router_snippet(Spec.t()) :: String.t()
  def router_snippet(%Spec{} = spec) do
    naming = Naming.build(spec)
    live_ns = "#{naming.schema_alias}Live"

    """
    live "/#{naming.route_segment}", #{live_ns}.Index, :index
    live "/#{naming.route_segment}/new", #{live_ns}.Index, :new
    live "/#{naming.route_segment}/:id", #{live_ns}.Index, :show
    live "/#{naming.route_segment}/:id/edit", #{live_ns}.Index, :edit
    """
    |> String.trim_trailing()
  end

  @spec hooks_js_snippet(Spec.t()) :: String.t()
  def hooks_js_snippet(%Spec{} = spec) do
    naming = Naming.build(spec)
    hook = naming.web_tabs_hook_module_js

    """
    import #{hook} from "./hooks/#{naming.singular}_tabs.js";
    // ...and add `#{hook},` to the `hooks` object passed to `new LiveSocket(...)`
    """
    |> String.trim_trailing()
  end

  # ---------------------------------------------------------------------

  defp schema_path(naming) do
    naming.context_module
    |> Module.split()
    |> Enum.map(&Macro.underscore/1)
    |> Kernel.++([naming.singular])
    |> Enum.join("/")
  end

  defp file_entry(kind, path, content) do
    %{path: path, content: content, mode: :create, kind: kind}
  end

  defp context_entry(spec, naming) do
    inner = Renderer.context_functions(spec, naming)
    path = naming.context_file_path
    signal = "def create_#{naming.singular}("

    case append_mode(path, signal) do
      :create ->
        content = """
        defmodule #{inspect(naming.context_module)} do
          @moduledoc \"\"\"
          The #{naming.context_alias} context.
          \"\"\"

          import Ecto.Query, warn: false
          alias SnippetSaver.Repo

          #{inner}

          #{@marker}
        end
        """

        %{path: path, content: content, mode: :create, kind: :context}

      :insert ->
        %{path: path, content: inner, mode: :insert, kind: :context}

      :already_present ->
        %{path: path, content: inner, mode: :already_present, kind: :context}

      :print_instruct ->
        %{path: path, content: inner, mode: :print_instruct, kind: :context}
    end
  end

  defp fixtures_entry(spec, naming) do
    inner = Renderer.fixtures(spec, naming)
    path = naming.fixtures_file_path
    module_name = "SnippetSaver.#{naming.context_alias}Fixtures"
    signal = "def #{naming.fixture_fn}("

    case append_mode(path, signal) do
      :create ->
        content = """
        defmodule #{module_name} do
          @moduledoc \"\"\"
          This module defines test helpers for creating
          entities via the `#{inspect(naming.context_module)}` context.
          \"\"\"

          #{inner}

          #{@marker}
        end
        """

        %{path: path, content: content, mode: :create, kind: :fixtures}

      :insert ->
        %{path: path, content: inner, mode: :insert, kind: :fixtures}

      :already_present ->
        %{path: path, content: inner, mode: :already_present, kind: :fixtures}

      :print_instruct ->
        %{path: path, content: inner, mode: :print_instruct, kind: :fixtures}
    end
  end

  defp resource_test_entry(spec, naming) do
    inner = Renderer.resource_test(spec, naming)
    path = naming.context_test_file_path
    module_name = "SnippetSaver.#{naming.context_alias}Test"
    signal = "describe #{inspect(naming.plural)} do"

    case append_mode(path, signal) do
      :create ->
        content = """
        defmodule #{module_name} do
          use SnippetSaver.DataCase

          alias #{inspect(naming.context_module)}

          #{inner}

          #{@marker}
        end
        """

        %{path: path, content: content, mode: :create, kind: :test}

      :insert ->
        %{path: path, content: inner, mode: :insert, kind: :test}

      :already_present ->
        %{path: path, content: inner, mode: :already_present, kind: :test}

      :print_instruct ->
        %{path: path, content: inner, mode: :print_instruct, kind: :test}
    end
  end

  # `presence_signal` is a snippet unique to *this resource's* generated code within the file —
  # different per file kind (a `def` name for context/fixtures, a `describe` block for tests) since
  # none of those three file kinds share a single reliable marker string. Checking for it before
  # offering `:insert` is what makes re-running an unchanged spec idempotent instead of always
  # double-splicing on the second run.
  defp append_mode(path, presence_signal) do
    if File.exists?(path) do
      content = File.read!(path)

      cond do
        String.contains?(content, presence_signal) -> :already_present
        String.contains?(content, @marker) -> :insert
        true -> :print_instruct
      end
    else
      :create
    end
  end
end
