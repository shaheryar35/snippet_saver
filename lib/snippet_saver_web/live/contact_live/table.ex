defmodule SnippetSaverWeb.ContactLive.Table do
  use SnippetSaverWeb, :html
  import Ecto.Query

  def fields do
    [
      full_name: %{
        label: "Name",
        sortable: false,
        searchable: false,
        computed: dynamic([resource: r], fragment("concat(coalesce(?, ''), ' ', coalesce(?, ''))", r.first_name, r.last_name)),
        renderer: fn full_name, assigns ->
          contact = assigns.actions
          assigns = %{full_name: String.trim(full_name || ""), contact: contact}

          ~H"""
          <a
            href={~p"/contacts/#{@contact.id}"}
            class="contact-name-link text-left hover:text-primary-600 focus:outline-none w-full block"
            data-contact-id={@contact.id}
            data-contact-name={if @full_name == "", do: "Contact ##{@contact.id}", else: @full_name}
          >
            <%= if @full_name == "", do: "Contact ##{@contact.id}", else: @full_name %>
          </a>
          """
        end
      },
      title: %{
        label: "Title",
        sortable: true,
        searchable: true,
        renderer: fn title -> title || "—" end
      },
      business_code: %{
        label: "Business Code",
        sortable: true,
        searchable: true,
        renderer: fn code -> code || "—" end
      },
      is_individual: %{
        label: "Type",
        sortable: true,
        filter: true,
        renderer: fn is_individual ->
          if is_individual, do: "Individual", else: "Organization"
        end
      },
      notes_important: %{
        label: "Important Notes",
        sortable: true,
        renderer: fn notes_important ->
          assigns = %{notes_important: notes_important}

          ~H"""
          <%= if @notes_important do %>
            <.badge variant="warning">Yes</.badge>
          <% else %>
            <.badge variant="info">No</.badge>
          <% end %>
          """
        end
      },
      actions: %{
        label: "Actions",
        sortable: false,
        computed: dynamic([resource: r], r),
        renderer: fn contact ->
          id =
            if is_struct(contact), do: contact.id, else: contact[:id] || get_in(contact, [:actions, :id])

          assigns = %{id: id}

          ~H"""
          <div class="flex gap-2">
            <.button type="button" phx-click="go-to-edit" phx-value-id={@id} variant="outline" size="xs">
              <.icon name="hero-pencil" class="h-3 w-3" />
            </.button>
            <.button type="button" phx-click="go-to-show" phx-value-id={@id} variant="outline" size="xs">
              <.icon name="hero-eye" class="h-3 w-3" />
            </.button>
            <.button phx-click="delete" phx-value-id={@id} variant="danger" size="xs" data-confirm="Are you sure?">
              <.icon name="hero-trash" class="h-3 w-3" />
            </.button>
          </div>
          """
        end
      }
    ]
  end

  def filters do
    [
      is_individual:
        LiveTable.Boolean.new(:is_individual, "is_individual", %{
          label: "Individuals Only",
          condition: dynamic([c], c.is_individual == true)
        })
    ]
  end

  def table_options do
    %{
      use_streams: false,
      pagination: %{
        enabled: true,
        sizes: [10, 25, 50, 100],
        default_size: 10
      }
    }
  end
end
