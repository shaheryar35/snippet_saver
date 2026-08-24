defmodule SnippetSaver.ResourceGen.Printer do
  @moduledoc """
  `--dry-run` output: the full file plan, with no disk writes.
  """

  @spec print_plan([map]) :: :ok
  def print_plan(plan) do
    Mix.shell().info("\nDry run — no files will be written.\n")

    Enum.each(plan, fn entry ->
      header =
        case entry.mode do
          :create -> "CREATE #{entry.path}"
          :insert -> "INSERT into #{entry.path} (above # GEN_RESOURCE_INSERT_POINT)"
          :already_present -> "ALREADY UP TO DATE — #{entry.path} already has this resource's code"
          :print_instruct -> "MANUAL PASTE needed — #{entry.path} exists with no marker"
        end

      Mix.shell().info(String.duplicate("-", min(String.length(header), 100)))
      Mix.shell().info(header)
      Mix.shell().info(String.duplicate("-", min(String.length(header), 100)))
      Mix.shell().info(entry.content)
      Mix.shell().info("")
    end)

    Mix.shell().info("#{length(plan)} file(s)/fragment(s) planned.")
    :ok
  end
end
