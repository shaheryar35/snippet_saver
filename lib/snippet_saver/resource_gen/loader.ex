defmodule SnippetSaver.ResourceGen.Loader do
  @moduledoc """
  Loads a `mix gen.resource` spec file and returns the `%SnippetSaver.ResourceGen.Spec{}` it
  evaluates to.
  """

  alias SnippetSaver.ResourceGen.Spec

  @spec load!(Path.t()) :: Spec.t()
  def load!(path) do
    unless File.exists?(path) do
      Mix.raise("Resource spec file not found: #{path}")
    end

    case Code.eval_file(path) do
      {%Spec{} = spec, _bindings} ->
        spec

      {other, _bindings} ->
        Mix.raise(
          "Resource spec file #{path} did not evaluate to a %SnippetSaver.ResourceGen.Spec{} " <>
            "(the file's last expression must be the `resource \"...\" do ... end` block) — got: #{inspect(other)}"
        )
    end
  end
end
