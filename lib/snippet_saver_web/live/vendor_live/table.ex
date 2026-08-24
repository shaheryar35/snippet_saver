defmodule SnippetSaverWeb.VendorLive.Table do
  @moduledoc """
  LiveTable configuration for the Vendors index: fields, filters, and table options.
  """
  use SnippetSaverWeb, :html
  import Ecto.Query

  def fields do
    [
      company_name: %{
        label: "Company Name",
        sortable: true,
        filter: true
      },
      actions: %{
        label: "Actions",
        sortable: false,
        computed: dynamic([resource: r], r),
        renderer: fn vendor ->
          id =
            if is_struct(vendor),
              do: vendor.id,
              else: vendor[:id] || get_in(vendor, [:actions, :id])

          assigns = %{id: id}

          ~H"""
          <div class="flex gap-2">
            <.button type="button" phx-click="go-to-edit" phx-value-id={@id} variant="outline" size="xs">
              <.icon name="hero-pencil" class="h-3 w-3" />
            </.button>
            <.button type="button" phx-click="go-to-show" phx-value-id={@id} variant="outline" size="xs">
              <.icon name="hero-eye" class="h-3 w-3" />
            </.button>
            <.button
              phx-click="delete"
              phx-value-id={@id}
              variant="danger"
              size="xs"
              data-confirm="Are you sure?"
            >
              <.icon name="hero-trash" class="h-3 w-3" />
            </.button>
          </div>
          """
        end
      }
    ]
  end

  def filters, do: []

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
