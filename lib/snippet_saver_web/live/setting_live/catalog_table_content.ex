defmodule SnippetSaverWeb.SettingLive.CatalogTableContent do
  @moduledoc """
  Table body matching LiveTable layout, with row `phx-click` to open detail drawer.
  Action column renderers should wrap controls in `onclick="event.stopPropagation()"`.
  """
  use SnippetSaverWeb, :html

  import LiveTable.SortHelpers

  def table_section(assigns) do
    ~H"""
    <div class="mt-8 flow-root">
      <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
        <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
          <div class="overflow-hidden shadow sm:rounded-lg">
            <table class="min-w-full divide-y divide-gray-300 dark:divide-gray-700">
              <thead class="bg-gray-50 dark:bg-gray-800">
                <tr>
                  <th
                    :for={{key, field} <- @fields}
                    scope="col"
                    class="px-3 py-3.5 text-start text-sm font-semibold text-gray-900 dark:text-gray-100"
                  >
                    <.sort_link
                      key={key}
                      label={field.label}
                      sort_params={@options["sort"]["sort_params"]}
                      sortable={field.sortable}
                    />
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200 bg-white dark:divide-gray-700 dark:bg-gray-900">
                <tr id="empty-placeholder" class="only:table-row hidden">
                  <td colspan={length(@fields)} class="py-10 text-center">
                    <h3 class="text-sm font-semibold text-gray-900 dark:text-gray-100">No data</h3>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                      Get started by creating a new record.
                    </p>
                  </td>
                </tr>
                <tr
                  :for={resource <- @streams}
                  id={"catalog-row-#{resource.id}"}
                  phx-click="open_detail"
                  phx-value-id={resource.id}
                  class="cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800 text-gray-800 dark:text-neutral-200"
                >
                  <td
                    :for={{key, field} <- @fields}
                    class="whitespace-nowrap px-3 py-4 text-sm text-gray-900 dark:text-gray-100"
                  >
                    {render_cell(Map.get(resource, key), field, resource)}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_cell(value, field, record) do
    empty_text = Map.get(field, :empty_text)
    renderer = Map.get(field, :renderer)
    component = Map.get(field, :component)

    cond do
      is_nil(value) && not is_nil(empty_text) ->
        empty_text

      is_function(renderer, 2) ->
        renderer.(value, record)

      is_function(renderer, 1) ->
        renderer.(value)

      is_function(component, 1) ->
        component.(%{value: value, record: record})

      is_function(component, 2) ->
        component.(value, record)

      value == true ->
        "Yes"

      value == false ->
        "No"

      true ->
        Phoenix.HTML.Safe.to_iodata(value)
    end
  end
end
