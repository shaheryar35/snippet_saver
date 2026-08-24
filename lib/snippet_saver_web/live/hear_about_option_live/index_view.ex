defmodule SnippetSaverWeb.HearAboutOptionLive.IndexView do
  use SnippetSaverWeb, :html

  def render("index.html", assigns) do
    show_record? =
      assigns[:hear_about_option_page] in [:show, :edit] and
        is_map_key(assigns, :hear_about_option)

    is_new_page? = assigns[:hear_about_option_page] == :new

    assigns =
      assigns
      |> assign(:show_record?, show_record?)
      |> assign(
        :data_hear_about_option_id,
        if(show_record?, do: assigns.hear_about_option.id, else: nil)
      )
      |> assign(:data_page_new, is_new_page?)

    ~H"""
    <div
      id="hear_about_option-tab-system"
      class="container mx-auto px-4 py-4 h-[calc(100dvh-4rem)] min-h-0 flex flex-col overflow-hidden"
      phx-hook="HearAboutOptionTabs"
      data-hear-about-option-id={@data_hear_about_option_id}
      data-page-new={@data_page_new}
    >
      <.header>
        Hear About Options
        <:actions>
          <.link patch={~p"/hear_about_options/new"} class="add-hear_about_option-link">
            <.button variant="primary">Add Hear About Option</.button>
          </.link>
        </:actions>
      </.header>

      <div id="hear_about_option-tabs" phx-update="ignore" class="shrink-0 sticky top-0 z-20 bg-white">
      </div>

      <div class="content flex-1 min-h-0 border border-t-0 border-gray-200 bg-white rounded-b-lg shadow-sm overflow-hidden">
        <%= case @hear_about_option_page do %>
          <% :index -> %>
            <div class="p-4 h-full overflow-auto">
              {@table_content.(assigns)}
            </div>
          <% :show -> %>
            <div class="p-4 h-full overflow-auto">
              <.header>
                Hear About Option {@hear_about_option.id}
                <:actions>
                  <.button
                    variant="outline"
                    size="sm"
                    phx-click="go-to-edit"
                    phx-value-id={@hear_about_option.id}
                  >
                    <.icon name="hero-pencil" class="h-4 w-4 mr-1" /> Edit
                  </.button>
                </:actions>
              </.header>

              <.card>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                  <div><span class="text-gray-500">Name:</span> {@hear_about_option.name || "—"}</div>
                  <div>
                    <span class="text-gray-500">Is Active:</span> {if(@hear_about_option.is_active,
                      do: "Yes",
                      else: "No"
                    )}
                  </div>
                  <div>
                    <span class="text-gray-500">Category:</span> {@hear_about_option.category || "—"}
                  </div>
                </div>
              </.card>
            </div>
          <% :edit -> %>
            <div class="p-4 h-full min-h-0 overflow-hidden">
              <.live_component
                module={SnippetSaverWeb.HearAboutOptionLive.Components.FormComponent}
                id={"hear_about_option-form-#{@hear_about_option.id}"}
                action={:edit}
                hear_about_option={@hear_about_option}
                patch_back={~p"/hear_about_options"}
                parent_pid={@parent_pid}
              />
            </div>
          <% :new -> %>
            <div class="p-4 h-full overflow-auto">
              <.live_component
                module={SnippetSaverWeb.HearAboutOptionLive.Components.FormComponent}
                id="hear_about_option-form-new"
                action={:new}
                hear_about_option={@hear_about_option}
                patch_back={~p"/hear_about_options"}
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
