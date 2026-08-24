defmodule Mix.Tasks.Gen.Resource do
  @moduledoc """
  Generates a resource (schema, migration, context CRUD, LiveView, form, table, JS tab hook,
  fixtures, tests) from a declarative spec file.

      mix gen.resource priv/resource_specs/hear_about_option.exs
      mix gen.resource priv/resource_specs/hear_about_option.exs --dry-run

  See `resource-generator-design.md` for the full design, and
  `SnippetSaver.ResourceGen.Spec` for the spec DSL itself.

  Phase 1 scope: `routing :top_level` resources built from field types 1/2/3/4/5 only
  (`:nested_collection` fields, quick-create, and `routing :embedded_only` are not implemented —
  the spec parser raises a clear error if you try to use them).

  Router and JS hook registration are never edited automatically — the snippets to hand-paste
  into `router.ex` and `assets/js/app.js` are printed after a successful (non-dry-run) generation.
  """
  use Mix.Task

  alias SnippetSaver.ResourceGen.{Loader, Planner, Printer, Writer}

  @shortdoc "Generates a resource (schema, context, LiveView) from a spec file"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start", [])

    {opts, positional, _invalid} = OptionParser.parse(args, strict: [dry_run: :boolean])

    spec_path =
      case positional do
        [path] ->
          path

        _ ->
          Mix.raise("usage: mix gen.resource path/to/spec.exs [--dry-run]")
      end

    spec = Loader.load!(spec_path)
    plan = Planner.build_plan(spec)

    if opts[:dry_run] do
      Printer.print_plan(plan)
      print_manual_paste_snippets(spec)
    else
      {written, skipped} = Writer.write_plan!(plan)
      Writer.format!(written)

      Mix.shell().info("\nGenerated/updated #{length(written)} file(s) for #{inspect(spec.name)}.")

      if skipped != [] do
        Mix.shell().info(
          "\n#{length(skipped)} fragment(s) were NOT written automatically (existing file with no " <>
            "# GEN_RESOURCE_INSERT_POINT marker, or you declined the insert prompt) — paste these by hand:\n"
        )

        Enum.each(skipped, fn entry ->
          Mix.shell().info("--- #{entry.path} (#{entry.kind}) ---")
          Mix.shell().info(entry.content)
          Mix.shell().info("")
        end)
      end

      print_manual_paste_snippets(spec)

      Mix.shell().info("""

      Remember to:
        1) paste the router snippet above into lib/snippet_saver_web/router.ex
        2) paste the app.js hook import/registration snippet above into assets/js/app.js
        3) run `mix ecto.migrate`
        4) if any searchable_select fields are present, review the generated handle_event clauses
        5) run `mix compile --warnings-as-errors` and `mix test`
      """)
    end
  end

  defp print_manual_paste_snippets(spec) do
    Mix.shell().info("\n--- router.ex snippet (paste inside the :app live_session) ---")
    Mix.shell().info(Planner.router_snippet(spec))
    Mix.shell().info("\n--- assets/js/app.js snippet ---")
    Mix.shell().info(Planner.hooks_js_snippet(spec))
  end
end
