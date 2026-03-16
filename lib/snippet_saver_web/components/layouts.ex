defmodule SnippetSaverWeb.Layouts do
  use SnippetSaverWeb, :html

  embed_templates "layouts/*"

  def main_nav do
    [
      %{name: "Dashboard", path: ~p"/dashboard", icon: "hero-home", key: "dashboard"},
      %{name: "Employees", path: ~p"/employees", icon: "hero-users", key: "employees"},
      %{name: "Tasks", path: ~p"/tasks", icon: "hero-check-circle", key: "tasks"}
    ]
  end
end
