defmodule SnippetSaver.Repo.Migrations.AddTimestampsToPatientChildTables do
  use Ecto.Migration

  def change do
    for table <- [:patient_other_contacts, :patient_notes, :patient_master_problems, :patient_images] do
      alter table(table) do
        add_if_not_exists :inserted_at, :utc_datetime, null: false, default: fragment("NOW()")
        add_if_not_exists :updated_at, :utc_datetime, null: false, default: fragment("NOW()")
      end
    end
  end
end
