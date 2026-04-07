defmodule SnippetSaverWeb.SettingLive.BreedTable do
  @moduledoc false
  use SnippetSaverWeb, :html
  import Ecto.Query

  def fields do
    [
      id: %{
        label: "ID",
        sortable: true,
        searchable: false,
        renderer: fn id -> to_string(id) end
      },
      name: %{
        label: "Name",
        sortable: true,
        searchable: true,
        renderer: fn name, row ->
          b = Map.get(row, :actions)
          archived? = b && b.archived == true
          assigns = %{name: name, archived?: archived?}

          ~H"""
          <span class={[@archived? && "font-normal text-gray-500", !@archived? && "font-semibold text-gray-900"]}>
            {@name}
          </span>
          """
        end
      },
      species_name: %{
        label: "Species",
        sortable: false,
        searchable: false,
        computed: dynamic(
          [resource: r],
          fragment(
            "(SELECT s.name FROM species AS s WHERE s.id = ? LIMIT 1)",
            r.species_id
          )
        ),
        renderer: fn name -> name || "—" end
      },
      archived: %{
        label: "Archived",
        sortable: true,
        searchable: false,
        renderer: fn archived? ->
          assigns = %{archived?: archived? == true}

          ~H"""
          <%= if @archived? do %>
            <.badge variant="warning">Yes</.badge>
          <% else %>
            <.badge variant="success">No</.badge>
          <% end %>
          """
        end
      },
      inserted_by_email: %{
        label: "Inserted by",
        sortable: false,
        searchable: false,
        computed: dynamic(
          [resource: r],
          fragment(
            "(SELECT u.email FROM users AS u WHERE u.id = ? LIMIT 1)",
            r.inserted_by_id
          )
        ),
        renderer: fn email -> email || "—" end
      },
      updated_by_email: %{
        label: "Updated by",
        sortable: false,
        searchable: false,
        computed: dynamic(
          [resource: r],
          fragment(
            "(SELECT u.email FROM users AS u WHERE u.id = ? LIMIT 1)",
            r.updated_by_id
          )
        ),
        renderer: fn email -> email || "—" end
      },
      actions: %{
        label: "Actions",
        sortable: false,
        computed: dynamic([resource: r], r),
        renderer: fn b ->
          id = if is_struct(b), do: b.id, else: b[:id] || get_in(b, [:actions, :id])
          archived? = if is_struct(b), do: b.archived, else: Map.get(b, :archived, false)

          assigns = %{id: id, archived?: archived? == true}

          ~H"""
          <div
            class="flex flex-wrap items-center justify-end gap-2"
            onclick="event.stopPropagation()"
            role="presentation"
          >
            <.button
              :if={not @archived?}
              type="button"
              variant="outline"
              size="xs"
              phx-click="edit"
              phx-value-id={@id}
            >
              <.icon name="hero-pencil" class="h-3.5 w-3.5" />
            </.button>
            <.button
              :if={not @archived?}
              type="button"
              variant="danger"
              size="xs"
              phx-click="archive"
              phx-value-id={@id}
              data-confirm="Archive this breed? It will be hidden from patient pickers."
            >
              <.icon name="hero-trash" class="h-3.5 w-3.5" />
            </.button>
            <.button
              :if={@archived?}
              type="button"
              variant="outline"
              size="xs"
              phx-click="restore"
              phx-value-id={@id}
            >
              Restore
            </.button>
          </div>
          """
        end
      }
    ]
  end

  def filters do
    [
      archived:
        LiveTable.Boolean.new(:archived, "archived", %{
          label: "Archived only",
          condition: dynamic([resource: r], r.archived == true)
        })
    ]
  end

  def table_options do
    %{
      use_streams: false,
      custom_content: {SnippetSaverWeb.SettingLive.CatalogTableContent, :table_section},
      pagination: %{
        enabled: true,
        sizes: [10, 25, 50, 100],
        default_size: 10
      }
    }
  end
end
