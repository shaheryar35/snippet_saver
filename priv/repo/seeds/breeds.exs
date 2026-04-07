import Ecto.Query, only: [from: 2]

alias SnippetSaver.Repo
alias SnippetSaver.Settings
alias SnippetSaver.Settings.Breed
alias SnippetSaver.Settings.Species

breeds_file = Path.join([__DIR__, "data", "breeds.txt"])

breed_names =
  if File.exists?(breeds_file) do
    breeds_file
    |> File.read!()
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> Enum.uniq()
  else
    IO.puts("Breeds seed skipped: file not found at #{breeds_file}")
    []
  end

ensure_species = fn species_name ->
  case Repo.get_by(Species, name: species_name) do
    nil ->
      case Settings.create_species(%{name: species_name, archived: false}) do
        {:ok, species} ->
          species

        {:error, changeset} ->
          raise "Failed to create species #{inspect(species_name)}: #{inspect(changeset.errors)}"
      end

    %Species{archived: true} = species ->
      case Settings.update_species(species, %{archived: false}) do
        {:ok, updated_species} ->
          updated_species

        {:error, changeset} ->
          raise "Failed to restore species #{inspect(species_name)}: #{inspect(changeset.errors)}"
      end

    %Species{} = species ->
      species
  end
end

infer_species_name = fn breed_name ->
  down = String.downcase(breed_name)

  cond do
    String.contains?(down, ["cat", "feline", "kitten"]) -> "Feline (Cat)"
    String.contains?(down, ["dog", "terrier", "retriever", "spaniel", "mastiff", "bulldog", "hound", "shepherd", "collie", "poodle", "husky", "spitz", "pinscher", "rottweiler", "doberman", "chihuahua", "pug", "beagle", "samoyed", "wolfhound"]) -> "Canine (Dog)"
    String.contains?(down, ["horse", "pony", "equine", "mustang", "saddlebred", "warmblood", "draft", "thoroughbred", "standardbred", "appaloosa", "arabian", "cob", "clydesdale", "friesian", "haflinger", "quarter", "trotter", "trakehner", "lippizzaner", "andalusian"]) -> "Equine (Horse)"
    String.contains?(down, ["bird", "parrot", "parakeet", "finch", "cockatiel", "cockatoo", "budgie", "pigeon", "dove", "robin", "woodpecker", "sparrow", "goose", "duck", "hawk", "rooster", "turkey", "hen", "gull"]) -> "Avian (Bird)"
    String.contains?(down, ["fish", "wrasse", "goby", "tang", "tetra", "goldfish", "guppy", "platies", "mollies", "anthias", "clownfish", "blennies", "damselfish", "suckerfish", "surgeonfish"]) -> "Piscine (Fish)"
    String.contains?(down, ["cow", "bovine", "angus", "hereford", "holstein", "wagyu", "zebu", "charolais", "beef", "shorthorn", "galloway", "dexter", "braford", "brangus", "limousin"]) -> "Bovine (Cow)"
    String.contains?(down, ["goat", "caprine", "caprus"]) -> "Caprus (Goat)"
    String.contains?(down, ["sheep", "ovine"]) -> "Ovine (Sheep)"
    String.contains?(down, ["rabbit", "bunny", "hare", "lagomorph"]) -> "Lagomorph (Rabbit)"
    String.contains?(down, ["guinea pig", "cavia porcellus"]) -> "Cavia porcellus (Guinea Pig)"
    String.contains?(down, ["ferret", "mustelid"]) -> "Mustelid"
    String.contains?(down, ["raccoon", "procyon"]) -> "Procyon lotor"
    String.contains?(down, ["camel", "llama", "alpaca", "camelid"]) -> "Camelid"
    String.contains?(down, ["reptile", "tortoise", "terrapene", "lizard", "snake"]) -> "Reptile"
    String.contains?(down, ["amphib", "axolotl"]) -> "Amphibian"
    String.contains?(down, ["rodent", "hamster", "rat", "mouse"]) -> "Rodent"
    true -> "Unmapped"
  end
end

required_species_names = [
  "Amphibian",
  "Avian (Bird)",
  "Bovine (Cow)",
  "Camelid",
  "Canine (Dog)",
  "Caprus (Goat)",
  "Cavia porcellus (Guinea Pig)",
  "Equine (Horse)",
  "Feline (Cat)",
  "Lagomorph (Rabbit)",
  "Mustelid",
  "Ovine (Sheep)",
  "Piscine (Fish)",
  "Procyon lotor",
  "Reptile",
  "Rodent",
  "Unmapped"
]

species_by_name =
  Enum.reduce(required_species_names, %{}, fn species_name, acc ->
    Map.put(acc, species_name, ensure_species.(species_name))
  end)

{created, restored, skipped} =
  Enum.reduce(breed_names, {0, 0, 0}, fn name, {c, r, s} ->
    species_name = infer_species_name.(name)
    species = Map.fetch!(species_by_name, species_name)

    existing =
      from(b in Breed, where: b.name == ^name and b.species_id == ^species.id)
      |> Repo.one()

    case existing do
      nil ->
        case Settings.create_breed(%{
               name: name,
               species_id: species.id,
               archived: false
             }) do
          {:ok, _} ->
            {c + 1, r, s}

          {:error, changeset} ->
            IO.puts("Failed to create breed '#{name}': #{inspect(changeset.errors)}")
            {c, r, s}
        end

      %Breed{archived: true} = breed ->
        case Settings.update_breed(breed, %{archived: false}) do
          {:ok, _} ->
            {c, r + 1, s}

          {:error, changeset} ->
            IO.puts("Failed to restore breed '#{name}': #{inspect(changeset.errors)}")
            {c, r, s}
        end

      %Breed{} ->
        {c, r, s + 1}
    end
  end)

IO.puts("Breed seed complete: created=#{created}, restored=#{restored}, skipped=#{skipped}")
