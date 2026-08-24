defmodule SnippetSaver.ResourceGen.PlannerIdempotencyTest do
  @moduledoc """
  Regression test for the `:insert` mode not being idempotent — see bug report "mix gen.resource
  duplicates code on re-run". Runs the append-mode file kinds (context/fixtures/test) through
  `Planner.build_plan/1` + `Writer.write_plan!/1` twice against an unchanged spec and asserts the
  second run is a no-op rather than a duplicate splice.

  Deliberately scoped to a throwaway resource/context name (not `hear_about_option`/`Catalog`) so
  this test doesn't collide with real generated files, and cleans up everything it writes.
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
end
