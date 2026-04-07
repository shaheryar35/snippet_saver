defmodule SnippetSaverWeb.SettingLive.AppointmentTypesTable do
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
          t = Map.get(row, :actions)
          archived? = t && t.archived == true
          assigns = %{name: name, archived?: archived?}

          ~H"""
          <span class={[@archived? && "font-normal text-gray-500", !@archived? && "font-semibold text-gray-900"]}>
            {@name}
          </span>
          """
        end
      },
      duration_minutes: %{
        label: "Duration (min)",
        sortable: true,
        searchable: false,
        renderer: fn n -> to_string(n) end
      },
      color: %{
        label: "Color",
        sortable: false,
        searchable: false,
        renderer: fn color ->
          c = color || ""
          assigns = %{color: c}

          ~H"""
          <span class="inline-flex items-center gap-2">
            <span class="h-5 w-5 rounded border border-gray-200 shrink-0" style={"background-color: #{@color}"} />
            <span class="text-gray-700 font-mono text-xs">{@color}</span>
          </span>
          """
        end
      },
      is_active: %{
        label: "Active",
        sortable: true,
        searchable: false,
        renderer: fn active? ->
          assigns = %{active?: active? == true}

          ~H"""
          <%= if @active? do %>
            <.badge variant="success">Yes</.badge>
          <% else %>
            <.badge variant="warning">No</.badge>
          <% end %>
          """
        end
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
        renderer: fn t ->
          id = if is_struct(t), do: t.id, else: t[:id] || get_in(t, [:actions, :id])
          archived? = if is_struct(t), do: t.archived, else: Map.get(t, :archived, false)

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
              data-confirm="Archive this appointment type? It will be hidden from scheduling pickers."
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
