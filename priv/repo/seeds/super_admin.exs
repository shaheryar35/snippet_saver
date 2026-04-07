alias SnippetSaver.Accounts
alias SnippetSaver.Accounts.User

super_admin_email = System.get_env("SUPER_ADMIN_EMAIL") || "admin@example.com"
super_admin_password = System.get_env("SUPER_ADMIN_PASSWORD") || "ChangeMe123456!"

case Accounts.get_user_by_email(super_admin_email) do
  nil ->
    case Accounts.register_user(%{
           email: super_admin_email,
           password: super_admin_password
         }) do
      {:ok, user} ->
        {:ok, _} = Accounts.update_user_role(user, "super_admin")
        IO.puts("Created super admin: #{super_admin_email}")

      {:error, changeset} ->
        IO.puts("Failed to create super admin: #{inspect(changeset.errors)}")
    end

  %User{} = user ->
    if user.role == "super_admin" do
      IO.puts("Super admin already exists: #{super_admin_email}")
    else
      {:ok, _} = Accounts.update_user_role(user, "super_admin")
      IO.puts("Promoted existing user to super admin: #{super_admin_email}")
    end
end
