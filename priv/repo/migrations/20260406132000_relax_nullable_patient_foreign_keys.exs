defmodule SnippetSaver.Repo.Migrations.RelaxNullablePatientForeignKeys do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE patients ALTER COLUMN owner_contact_id DROP NOT NULL")
    execute("ALTER TABLE patients ALTER COLUMN species_id DROP NOT NULL")
    execute("ALTER TABLE patients ALTER COLUMN breed_id DROP NOT NULL")
    execute("ALTER TABLE patients ALTER COLUMN colour_id DROP NOT NULL")
    execute("ALTER TABLE patients ALTER COLUMN preferred_doctor_contact_id DROP NOT NULL")
    execute("ALTER TABLE patients ALTER COLUMN second_preferred_doctor_contact_id DROP NOT NULL")
  end

  def down do
    execute("ALTER TABLE patients ALTER COLUMN owner_contact_id SET NOT NULL")
    execute("ALTER TABLE patients ALTER COLUMN species_id SET NOT NULL")
    execute("ALTER TABLE patients ALTER COLUMN breed_id SET NOT NULL")
    execute("ALTER TABLE patients ALTER COLUMN colour_id SET NOT NULL")
    execute("ALTER TABLE patients ALTER COLUMN preferred_doctor_contact_id SET NOT NULL")
    execute("ALTER TABLE patients ALTER COLUMN second_preferred_doctor_contact_id SET NOT NULL")
  end
end
