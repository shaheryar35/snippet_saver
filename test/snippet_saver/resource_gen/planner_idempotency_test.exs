defmodule SnippetSaver.ResourceGen.PlannerIdempotencyTest do
  @moduledoc """
  Regression tests for `mix gen.resource` re-run idempotency:

    1. "mix gen.resource duplicates code on re-run" — the `:insert` mode wasn't idempotent for the
       append-mode file kinds (context/fixtures/test).
    2. "mix gen.resource creates a duplicate migration file on every re-run" — migration filenames
       always embed a fresh timestamp, so path-based conflict detection can never catch a repeat
       run; needs its own content-based check (`Planner.migration_entry/2`).

  Both run the same throwaway spec through `Planner.build_plan/1` + `Writer.write_plan!/1` twice
  and assert the second run is a no-op rather than a duplicate write.

  Deliberately scoped to a throwaway resource/context name (not `hear_about_option`/`Catalog`) so
  this test doesn't collide with real generated files, and cleans up everything it writes —
  including the real `priv/repo/migrations/` entry the migration test creates.
  """

  use ExUnit.Case, async: false

  import SnippetSaver.ResourceGen.Spec

  alias SnippetSaver.ResourceGen.{Naming, Planner, Writer}

  setup do
    spec =
      resource "resource_gen_regression_widget" do
        table :resource_gen_regression_widgets
        context SnippetSaver.ResourceGenRegressionCtx
        audit false
        soft_delete false
        routing :top_level

        field :name, :text, required: true

        list_fields(name: [sortable: true, filterable: true])

        subtabs([])
      end

    naming = Naming.build(spec)

    paths = [naming.context_file_path, naming.context_test_file_path, naming.fixtures_file_path]

    # Clear out any leftovers from a previous failed run before we start.
    Enum.each(paths, &File.rm/1)
    on_exit(fn -> Enum.each(paths, &File.rm/1) end)

    %{spec: spec, naming: naming, paths: paths}
  end

  test "re-running the same spec does not duplicate generated context/fixtures/test code", %{
    spec: spec,
    naming: naming
  } do
    append_mode_kinds = [:context, :fixtures, :test]

    plan1 = Planner.build_plan(spec) |> Enum.filter(&(&1.kind in append_mode_kinds))
    {written1, skipped1} = Writer.write_plan!(plan1)

    assert length(written1) == 3
    assert skipped1 == []

    plan2 = Planner.build_plan(spec) |> Enum.filter(&(&1.kind in append_mode_kinds))
    {written2, skipped2} = Writer.write_plan!(plan2)

    assert written2 == []
    assert length(skipped2) == 3
    assert Enum.all?(skipped2, &(&1.mode == :already_present))

    context_content = File.read!(naming.context_file_path)
    fixtures_content = File.read!(naming.fixtures_file_path)
    test_content = File.read!(naming.context_test_file_path)

    assert context_content
           |> String.split("def create_#{naming.singular}(")
           |> length() == 2

    assert fixtures_content
           |> String.split("def #{naming.fixture_fn}(")
           |> length() == 2

    assert test_content
           |> String.split("describe #{inspect(naming.plural)} do")
           |> length() == 2

    assert {:ok, _} = Code.string_to_quoted(context_content)
    assert {:ok, _} = Code.string_to_quoted(fixtures_content)
    assert {:ok, _} = Code.string_to_quoted(test_content)
  end

  test "re-running the same spec does not create a duplicate migration file", %{spec: spec} do
    glob = "priv/repo/migrations/*_create_resource_gen_regression_widgets.exs"

    assert Path.wildcard(glob) == []

    plan1 = Planner.build_plan(spec) |> Enum.filter(&(&1.kind == :migration))
    [migration_entry1] = plan1
    assert migration_entry1.mode == :create

    {written1, skipped1} = Writer.write_plan!(plan1)
    on_exit(fn -> File.rm(migration_entry1.path) end)

    assert written1 == [migration_entry1.path]
    assert skipped1 == []
    assert Path.wildcard(glob) == [migration_entry1.path]

    plan2 = Planner.build_plan(spec) |> Enum.filter(&(&1.kind == :migration))
    [migration_entry2] = plan2

    # Found the *existing* file by content, not generated a fresh timestamped path.
    assert migration_entry2.mode == :already_present
    assert migration_entry2.path == migration_entry1.path

    {written2, skipped2} = Writer.write_plan!(plan2)

    assert written2 == []
    assert [%{mode: :already_present, path: skipped_path}] = skipped2
    assert skipped_path == migration_entry1.path

    # Exactly one migration file for this table exists on disk after two runs.
    assert Path.wildcard(glob) == [migration_entry1.path]
  end
end
