defmodule SnippetSaver.Repo.Migrations.AddTimestampsToSettingsCatalogTables do
  use Ecto.Migration

  @doc """
  Backfills `inserted_at` / `updated_at` when tables were created outside migrations
  (e.g. existing relation skipped by `create_if_not_exists` without these columns).
  """
  def change do
    for table <- [:species, :breeds, :colours, :master_problem_templates] do
      alter table(table) do
        add_if_not_exists :inserted_at, :utc_datetime,
          default: fragment("(timezone('UTC', now()))"),
          null: false

        add_if_not_exists :updated_at, :utc_datetime,
          default: fragment("(timezone('UTC', now()))"),
          null: false
      end
    end
  end
end
