# Script for populating the database. You can run it as:
#
#   mix run priv/repo/seeds.exs
#
# Optional selective run:
#   SEED_ONLY=species mix run priv/repo/seeds.exs
#   SEED_ONLY=super_admin,species mix run priv/repo/seeds.exs
#   SEED_ONLY=colours mix run priv/repo/seeds.exs
#   SEED_ONLY=breeds mix run priv/repo/seeds.exs
#   SEED_ONLY=master_problem_templates mix run priv/repo/seeds.exs

seed_scripts = %{
  "super_admin" => "seeds/super_admin.exs",
  "species" => "seeds/species.exs",
  "colours" => "seeds/colours.exs",
  "breeds" => "seeds/breeds.exs",
  "master_problem_templates" => "seeds/master_problem_templates.exs"
}

seed_only =
  System.get_env("SEED_ONLY")
  |> case do
    nil -> :all
    value ->
      value
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> MapSet.new()
  end

Enum.each(seed_scripts, fn {name, relative_path} ->
  should_run? = seed_only == :all or MapSet.member?(seed_only, name)

  if should_run? do
    IO.puts("Running seed: #{name}")
    Code.require_file(relative_path, __DIR__)
  end
end)
