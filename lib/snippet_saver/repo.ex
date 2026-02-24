defmodule SnippetSaver.Repo do
  use Ecto.Repo,
    otp_app: :snippet_saver,
    adapter: Ecto.Adapters.Postgres
end
