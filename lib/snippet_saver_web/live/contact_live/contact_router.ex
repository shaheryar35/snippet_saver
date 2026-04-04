defmodule SnippetSaverWeb.ContactLive.ContactRouter do
  import Phoenix.Component, only: [assign: 3]

  alias SnippetSaver.Contacts
  alias SnippetSaver.Contacts.Contact

  def handle(params, uri, socket) do
    path = URI.parse(uri).path |> String.trim_leading("/") |> String.split("/")
    page = page_from_path(path)

    case page do
      :index ->
        {:index, socket, params, path}

      :new ->
        {:noreply,
         socket
         |> assign(:contact_page, :new)
         |> assign(:contact, %Contact{})
         |> assign(:page_title, "New Contact")
         |> assign(:active_page, "contacts")}

      {:show, id} ->
        contact = Contacts.get_contact!(id)

        socket =
          socket
          |> assign(:contact_page, :show)
          |> assign(:contact, contact)
          |> assign(:active_subtab, :details)
          |> assign(:page_title, contact_display_name(contact))
          |> assign(:active_page, "contacts")

        {:noreply, socket}

      {:edit, id} ->
        contact = Contacts.get_contact!(id)

        socket =
          socket
          |> assign(:contact_page, :edit)
          |> assign(:contact, contact)
          |> assign(:page_title, "Edit Contact")
          |> assign(:active_page, "contacts")

        {:noreply, socket}

      {:show_subtab, id, _subtab} ->
        contact = Contacts.get_contact!(id)

        socket =
          socket
          |> assign(:contact_page, :show)
          |> assign(:contact, contact)
          |> assign(:active_subtab, :details)
          |> assign(:page_title, contact_display_name(contact))
          |> assign(:active_page, "contacts")

        {:noreply, socket}
    end
  end

  defp page_from_path(["contacts"]), do: :index

  defp page_from_path(["contacts" | rest]) do
    case rest do
      [] -> :index
      ["new"] -> :new
      [id, "edit"] -> {:edit, String.to_integer(id)}
      [id] -> {:show, String.to_integer(id)}
      [id, subtab] -> {:show_subtab, String.to_integer(id), subtab}
      _ -> :index
    end
  end

  defp page_from_path(_), do: :index

  defp contact_display_name(contact) do
    [contact.first_name, contact.last_name]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
    |> case do
      "" -> "Contact ##{contact.id}"
      name -> name
    end
  end
end
