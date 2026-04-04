import Config

Code.eval_file(Path.join(__DIR__, "load_dotenv.exs"))

pg_port =
  case System.get_env("PGPORT") do
    nil -> 5432
    p -> String.to_integer(p)
  end

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :snippet_saver, SnippetSaver.Repo,
  username: System.get_env("PGUSER") || System.get_env("USER") || "postgres",
  password: System.get_env("PGPASSWORD") || "",
  hostname: System.get_env("PGHOST") || "localhost",
  port: pg_port,
  database:
    (System.get_env("PGDATABASE") || "snippet_saver_test") <>
      "#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :snippet_saver, SnippetSaverWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "PEi70+cIptJIzGFkHeSj+z4WRssOSzFoIlIXCYfilqhuWB/vFc+GlDgKxr03UuJv",
  server: false

# In test we don't send emails.
config :snippet_saver, SnippetSaver.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
