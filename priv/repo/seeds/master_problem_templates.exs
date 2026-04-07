alias SnippetSaver.Repo
alias SnippetSaver.Settings
alias SnippetSaver.Settings.MasterProblemTemplate

templates_file = Path.join([__DIR__, "data", "master_problem_templates.txt"])

template_names =
  if File.exists?(templates_file) do
    templates_file
    |> File.read!()
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> Enum.uniq()
  else
    IO.puts("Master problem templates seed skipped: file not found at #{templates_file}")
    []
  end

{created, restored, skipped} =
  Enum.reduce(template_names, {0, 0, 0}, fn name, {c, r, s} ->
    case Repo.get_by(MasterProblemTemplate, name: name) do
      nil ->
        case Settings.create_master_problem_template(%{
               name: name,
               description: name,
               archived: false
             }) do
          {:ok, _} ->
            {c + 1, r, s}

          {:error, changeset} ->
            IO.puts(
              "Failed to create master problem template '#{name}': #{inspect(changeset.errors)}"
            )

            {c, r, s}
        end

      %MasterProblemTemplate{archived: true} = template ->
        case Settings.update_master_problem_template(template, %{archived: false}) do
          {:ok, _} ->
            {c, r + 1, s}

          {:error, changeset} ->
            IO.puts(
              "Failed to restore master problem template '#{name}': #{inspect(changeset.errors)}"
            )

            {c, r, s}
        end

      %MasterProblemTemplate{} ->
        {c, r, s + 1}
    end
  end)

IO.puts(
  "Master problem templates seed complete: created=#{created}, restored=#{restored}, skipped=#{skipped}"
)
