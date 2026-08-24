defmodule SnippetSaver.ResourceGen.Writer do
  @moduledoc """
  Writes a file plan to disk.

  `:create` entries go through `Mix.Generator.create_file/2`, which prompts
  `already exists, overwrite? [y/N]` if the path is unexpectedly already there — that prompt is
  never suppressed (design doc §9.1: no silent overwrite, ever).

  `:insert` entries modify an existing file (splicing above its `# GEN_RESOURCE_INSERT_POINT`
  marker) — confirmed with the user before writing, since it's still a change to a file the
  generator didn't create.

  `:print_instruct` entries are never written — the caller is expected to print `content` for
  manual pasting instead.

  Returns `{written_paths, print_instruct_entries}` so the Mix task can run `mix format` on what
  was written and print instructions for what wasn't.
  """

  @marker "# GEN_RESOURCE_INSERT_POINT"

  @spec write_plan!([map]) :: {[String.t()], [map]}
  def write_plan!(plan) do
    Enum.reduce(plan, {[], []}, fn entry, {written, skipped} ->
      case entry.mode do
        :create ->
          File.mkdir_p!(Path.dirname(entry.path))
          Mix.Generator.create_file(entry.path, entry.content)
          {[entry.path | written], skipped}

        :insert ->
          if Mix.shell().yes?(
               "#{entry.path} already has a # GEN_RESOURCE_INSERT_POINT marker — insert the new #{entry.kind} code above it?"
             ) do
            existing = File.read!(entry.path)
            spliced = String.replace(existing, @marker, "#{entry.content}\n\n  #{@marker}", global: false)
            File.write!(entry.path, spliced)
            {[entry.path | written], skipped}
          else
            {written, [entry | skipped]}
          end

        :print_instruct ->
          {written, [entry | skipped]}
      end
    end)
    |> then(fn {written, skipped} -> {Enum.reverse(written), Enum.reverse(skipped)} end)
  end

  @doc "Runs `mix format` on every written `.ex`/`.exs` path. Best-effort — a format failure doesn't undo the write."
  @spec format!([String.t()]) :: :ok
  def format!(paths) do
    paths
    |> Enum.filter(&(Path.extname(&1) in [".ex", ".exs"]))
    |> Enum.each(fn path ->
      case System.cmd("mix", ["format", path], stderr_to_stdout: true) do
        {_, 0} -> :ok
        {output, _} -> Mix.shell().info("(mix format skipped for #{path}: #{output})")
      end
    end)

    :ok
  end
end
