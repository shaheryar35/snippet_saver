defmodule SnippetSaverWeb.VendorLive.IndexView do
  use SnippetSaverWeb, :html

  def render("index.html", assigns) do
    show_record? = assigns[:vendor_page] in [:show, :edit] and is_map_key(assigns, :vendor)
    is_new_page? = assigns[:vendor_page] == :new

    assigns =
      assigns
      |> assign(:show_record?, show_record?)
      |> assign(:data_vendor_id, if(show_record?, do: assigns.vendor.id, else: nil))
      |> assign(:data_page_new, is_new_page?)

    ~H"""
    <div
      id="vendor-tab-system"
      class="container mx-auto px-4 py-4 h-[calc(100dvh-4rem)] min-h-0 flex flex-col overflow-hidden"
      phx-hook="VendorTabs"
      data-vendor-id={@data_vendor_id}
      data-page-new={@data_page_new}
    >
      <.header>
        Vendors
        <:actions>
          <.link patch={~p"/vendors/new"} class="add-vendor-link">
            <.button variant="primary">Add Vendor</.button>
          </.link>
        </:actions>
      </.header>

      <div id="vendor-tabs" phx-update="ignore" class="shrink-0 sticky top-0 z-20 bg-white"></div>

      <div class="content flex-1 min-h-0 border border-t-0 border-gray-200 bg-white rounded-b-lg shadow-sm overflow-hidden">
        <%= case @vendor_page do %>
          <% :index -> %>
            <div class="p-4 h-full overflow-auto">
              {@table_content.(assigns)}
            </div>
          <% :show -> %>
            <div class="p-4 h-full overflow-auto">
              <.header>
                Vendor {@vendor.id}
                <:actions>
                  <.button
                    variant="outline"
                    size="sm"
                    phx-click="go-to-edit"
                    phx-value-id={@vendor.id}
                  >
                    <.icon name="hero-pencil" class="h-4 w-4 mr-1" /> Edit
                  </.button>
                </:actions>
              </.header>

              <.card>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                  <div>
                    <span class="text-gray-500">Company Name:</span> {@vendor.company_name || "—"}
                  </div>
                </div>
              </.card>
            </div>
          <% :edit -> %>
            <div class="p-4 h-full min-h-0 overflow-hidden">
              <.live_component
                module={SnippetSaverWeb.VendorLive.Components.FormComponent}
                id={"vendor-form-#{@vendor.id}"}
                action={:edit}
                vendor={@vendor}
                patch_back={~p"/vendors"}
                parent_pid={@parent_pid}
              />
            </div>
          <% :new -> %>
            <div class="p-4 h-full overflow-auto">
              <.live_component
                module={SnippetSaverWeb.VendorLive.Components.FormComponent}
                id="vendor-form-new"
                action={:new}
                vendor={@vendor}
                patch_back={~p"/vendors"}
                parent_pid={@parent_pid}
              />
            </div>
          <% _ -> %>
            <div class="p-4 h-full overflow-auto">
              {@table_content.(assigns)}
            </div>
        <% end %>
      </div>
    </div>
    """
  end
end
