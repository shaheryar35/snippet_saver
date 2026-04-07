alias SnippetSaver.Repo
alias SnippetSaver.Settings
alias SnippetSaver.Settings.Species

species_names = [
  "Amphibian",
  "Avian (Bird)",
  "Bovine (Cow)",
  "Camelid",
  "Canine (Dog)",
  "Caprus (Goat)",
  "Cavia porcellus (Guinea Pig)",
  "Equine (Horse)",
  "Feline (Cat)",
  "Genus Procyon",
  "Goat",
  "Lagomorph (Rabbit)",
  "Mustelid",
  "Ovine (Sheep)",
  "Piscine (Fish)",
  "Porcine (Pig)",
  "Procyon lotor",
  "Reptile",
  "Rodent"
]

{created, restored, skipped} =
  Enum.reduce(species_names, {0, 0, 0}, fn name, {c, r, s} ->
    case Repo.get_by(Species, name: name) do
      nil ->
        case Settings.create_species(%{name: name, archived: false}) do
          {:ok, _} ->
            {c + 1, r, s}

          {:error, changeset} ->
            IO.puts("Failed to create species '#{name}': #{inspect(changeset.errors)}")
            {c, r, s}
        end

      %Species{archived: true} = species ->
        case Settings.update_species(species, %{archived: false}) do
          {:ok, _} ->
            {c, r + 1, s}

          {:error, changeset} ->
            IO.puts("Failed to restore species '#{name}': #{inspect(changeset.errors)}")
            {c, r, s}
        end

      %Species{} ->
        {c, r, s + 1}
    end
  end)

IO.puts("Species seed complete: created=#{created}, restored=#{restored}, skipped=#{skipped}")
