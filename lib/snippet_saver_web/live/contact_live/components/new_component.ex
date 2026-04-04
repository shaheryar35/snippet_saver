defmodule SnippetSaverWeb.ContactLive.Components.NewComponent do
  use SnippetSaverWeb, :live_component

  attr :contact, :any, required: true
  attr :patch_back, :any, required: true
  attr :parent_pid, :any, required: true

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">


      <.live_component
        module={SnippetSaverWeb.ContactLive.Components.FormComponent}
        id="new-contact-form"
        title="Contact Information"
        action={:new}
        contact={@contact}
        parent_pid={@parent_pid}
      />
    </div>
    """
  end
end
