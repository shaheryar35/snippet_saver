# Loads project-root `.env` into the process environment before Repo config runs.
# Required from `dev.exs` and `test.exs` only (not production).

path = Path.expand("../.env", __DIR__)

if File.exists?(path) do
  path
  |> File.read!()
  |> String.split("\n")
  |> Enum.each(fn raw_line ->
    line = String.trim(raw_line)

    cond do
      line == "" ->
        :ok

      String.starts_with?(line, "#") ->
        :ok

      true ->
        line = String.replace_prefix(line, "export ", "")

        case String.split(line, "=", parts: 2) do
          [key, value] ->
            key = String.trim(key)
            value = String.trim(value)

            value =
              cond do
                String.starts_with?(value, "\"") and String.ends_with?(value, "\"") ->
                  value |> String.slice(1..-2//1) |> String.replace("\\\"", "\"")

                String.starts_with?(value, "'") and String.ends_with?(value, "'") ->
                  String.slice(value, 1..-2//1)

                true ->
                  value
              end

            System.put_env(key, value)

          _ ->
            :ok
        end
    end
  end)
end
