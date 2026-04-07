defmodule SnippetSaverWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, drawers, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import SnippetSaverWeb.Gettext

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                {render_slot(@inner_block)}
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a right-side drawer (slide-over panel).

  Same lifecycle as `modal/1`: use `show_drawer/2` and `hide_drawer/2`, optional `show={true}` to open on mount,
  and `on_cancel` for close / LiveView events.

  ## Examples

      <.drawer id="item-drawer" on_cancel={hide_drawer("item-drawer")}>
        Content
      </.drawer>

      <.drawer id="detail-drawer" show={true} on_cancel={JS.push("close_detail")}>
        Details
      </.drawer>
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def drawer(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_drawer(@id)}
      phx-remove={hide_drawer(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div
        id={"#{@id}-bg"}
        class="fixed inset-0 z-40 bg-zinc-900/40 transition-opacity opacity-0"
        aria-hidden="true"
        phx-click={JS.exec("data-cancel", to: "##{@id}")}
      />
      <div
        class="fixed inset-y-0 right-0 z-50 flex w-full max-w-[40rem] mx-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <.focus_wrap
          id={"#{@id}-container"}
          phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
          phx-key="escape"
          class="h-full w-full"
        >
          <div
            id={"#{@id}-panel"}
            class="relative flex h-full w-full translate-x-full transform flex-col overflow-y-auto bg-white p-6 shadow-xl ring-1 ring-zinc-700/10 transition-transform hidden"
          >
            <div class="absolute end-3 top-3 z-10">
              <button
                phx-click={JS.exec("data-cancel", to: "##{@id}")}
                type="button"
                class="-m-2 flex-none rounded-lg p-2 text-gray-500 opacity-70 hover:bg-gray-100 hover:opacity-100"
                aria-label={gettext("close")}
              >
                <.icon name="hero-x-mark-solid" class="h-5 w-5" />
              </button>
            </div>
            <div id={"#{@id}-content"} class="min-h-0 flex-1 pt-6 pe-2">
              {render_slot(@inner_block)}
            </div>
          </div>
        </.focus_wrap>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include:
      ~w(autocomplete name rel action enctype method novalidate target multipart phx-change phx-submit),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil

  attr :variant, :string,
    default: "primary",
    doc: "button style: primary, secondary, danger, warning, outline, ghost"

  attr :size, :string, default: "md", doc: "button size: xs, sm, md, lg, xl"
  attr :rest, :global, include: ~w(disabled form name value phx-click phx-value-id)

  slot :inner_block, required: true

  def button(assigns) do
    # Assign values to assigns so they can be used with @ in template
    assigns =
      assigns
      |> assign(:variant, assigns[:variant] || "primary")
      |> assign(:size, assigns[:size] || "md")
      |> assign(:type, assigns[:type] || "button")

    ~H"""
    <button
      type={@type}
      {@rest}
      class={[
        "font-medium transition-colors duration-200 rounded-lg",
        "focus:outline-none focus:ring-2 focus:ring-offset-2",
        button_variant(@variant),
        button_size(@size)
      ]}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp button_variant(variant) do
    case variant do
      "primary" -> "bg-primary-600 text-white hover:bg-primary-700 focus:ring-primary-500"
      "secondary" -> "bg-secondary-500 text-white hover:bg-secondary-600 focus:ring-secondary-500"
      "danger" -> "bg-danger-500 text-white hover:bg-danger-600 focus:ring-danger-500"
      "warning" -> "bg-warning-500 text-white hover:bg-warning-600 focus:ring-warning-500"
      "outline" -> "border border-gray-300 text-gray-700 hover:bg-gray-50 focus:ring-primary-500"
      "ghost" -> "text-gray-700 hover:bg-gray-100 focus:ring-gray-500"
      # default
      _ -> "bg-primary-600 text-white hover:bg-primary-700 focus:ring-primary-500"
    end
  end

  defp button_size(size) do
    case size do
      "xs" -> "px-2 py-1 text-xs"
      "sm" -> "px-3 py-1.5 text-sm"
      "md" -> "px-4 py-2 text-sm"
      "lg" -> "px-6 py-3 text-base"
      "xl" -> "px-8 py-4 text-lg"
      # default
      _ -> "px-4 py-2 text-sm"
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"

  attr :multiple, :boolean,
    default: false,
    doc:
      "multi-select (native HTML is always an open list; for dropdown-style multi-select, use checkbox_group)"

  attr :size, :string, default: "md", doc: "visual size: sm, md, lg"
  attr :variant, :string, default: "default", doc: "visual variant for border/focus styling"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        {@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(assigns) do
    rest = assigns[:rest] || []
    rest = if is_list(rest), do: rest, else: Map.to_list(rest)
    rest_for_element = Keyword.drop(rest, [:size, :variant])

    assigns =
      assigns
      |> assign(:size, assigns[:size] || "md")
      |> assign(:variant, assigns[:variant] || "default")
      |> assign(:errors, assigns[:errors] || [])
      |> assign(:required, Keyword.get(rest, :required, assigns[:required] || false))
      |> assign(:type, assigns[:type] || "text")
      |> assign(:multiple, assigns[:multiple] || false)
      |> assign(:options, assigns[:options] || [])
      |> assign(:prompt, assigns[:prompt])
      |> assign(:rest, rest_for_element)

    ~H"""
    <div class="mb-4" phx-feedback-for={@name}>
      <label :if={@label} for={@id} class="block text-sm font-medium text-gray-700 mb-1">
        {@label}
        <span :if={@required} class="text-danger-500 ml-1">*</span>
      </label>
      <%= case @type do %>
        <% "textarea" -> %>
          <textarea
            id={@id}
            name={@name}
            class={[
              "w-full rounded-lg border focus:outline-none focus:ring-2 focus:ring-offset-2",
              "min-h-[6rem] phx-no-feedback:border-gray-300",
              input_size(@size),
              input_variant(@variant, @errors)
            ]}
            {@rest}
          ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
        <% "select" -> %>
          <select
            id={@id}
            name={if @multiple, do: @name |> to_string() |> ensure_bracket_suffix(), else: @name}
            multiple={@multiple}
            {if @multiple, do: [size: 4], else: []}
            class={[
              "w-full rounded-lg border focus:outline-none focus:ring-2 focus:ring-offset-2",
              input_size(@size),
              input_variant(@variant, @errors)
            ]}
            {@rest}
          >
            <%= if @options != [] do %>
              <option :if={@prompt} value="">{@prompt}</option>
              {Phoenix.HTML.Form.options_for_select(@options, @value)}
            <% else %>
              {render_slot(@inner_block)}
            <% end %>
          </select>
        <% _ -> %>
          <input
            type={@type}
            id={@id}
            name={@name}
            value={Phoenix.HTML.Form.normalize_value(@type, @value)}
            class={[
              "w-full rounded-lg border focus:outline-none focus:ring-2 focus:ring-offset-2",
              input_size(@size),
              input_variant(@variant, @errors)
            ]}
            {@rest}
          />
      <% end %>

    <!-- Error messages -->
      <div :if={length(@errors) > 0} class="mt-1">
        <p :for={msg <- @errors} class="text-sm text-danger-600">
          {msg}
        </p>
      </div>
    </div>
    """
  end

  @doc """
  Searchable single-select (combobox) for large option lists.

  Uses a hidden input for the real form value and a text input for filtering.
  Wire `phx-target` on the LiveView/LiveComponent and handle `search_event`,
  `focus_event`, `close_event`, and `pick_event` on the server.

  ## Examples

      <.searchable_select
        field={@form[:breed_id]}
        label="Breed"
        placeholder="Search breeds..."
        display={@breed_combobox_display}
        open={@breed_combobox_open}
        suggestions={@breed_combobox_suggestions}
        search_name="breed_combobox_q"
        search_event="breed-combobox-search"
        focus_event="breed-combobox-focus"
        close_event="breed-combobox-close"
        pick_event="breed-combobox-pick"
        clear_event="breed-combobox-clear"
        phx_target={@myself}
      />
  """
  attr :id, :string, default: nil
  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: nil
  attr :required, :boolean, default: false
  attr :placeholder, :string, default: "Search..."
  attr :display, :string, default: ""
  attr :open, :boolean, default: false
  attr :suggestions, :list, default: [], doc: "list of {label, id} tuples"
  attr :search_name, :string, required: true
  attr :search_event, :string, required: true
  attr :focus_event, :string, required: true
  attr :close_event, :string, required: true
  attr :pick_event, :string, required: true
  attr :clear_event, :string, default: nil
  attr :phx_target, :any, required: true

  def searchable_select(assigns) do
    field = assigns.field
    base_id = assigns[:id] || "#{field.id}-searchable"
    hidden_value = hidden_select_value(field.value)
    errors = Enum.map(field.errors, &translate_error/1)

    assigns =
      assigns
      |> assign(:base_id, base_id)
      |> assign(:hidden_value, hidden_value)
      |> assign(:errors, errors)

    ~H"""
    <div
      id={@base_id}
      class="relative mb-4"
      phx-click-away={JS.push(@close_event, target: @phx_target)}
      phx-feedback-for={@field.name}
    >
      <label
        :if={@label}
        for={"#{@base_id}-query"}
        class="block text-sm font-medium text-gray-700 mb-1"
      >
        {@label}
        <span :if={@required} class="text-danger-500 ml-1">*</span>
      </label>
      <input type="hidden" name={@field.name} id={"#{@base_id}-hidden"} value={@hidden_value} />
      <div class="relative flex gap-1">
        <input
          type="text"
          id={"#{@base_id}-query"}
          name={@search_name}
          value={@display}
          placeholder={@placeholder}
          autocomplete="off"
          class={[
            "w-full rounded-lg border focus:outline-none focus:ring-2 focus:ring-offset-2",
            "px-3 py-2 text-sm phx-no-feedback:border-gray-300",
            input_size("md"),
            input_variant("default", @errors)
          ]}
          phx-target={@phx_target}
          phx-focus={JS.push(@focus_event, target: @phx_target)}
          phx-change={@search_event}
          phx-debounce="200"
        />
        <button
          :if={@clear_event && @hidden_value != ""}
          type="button"
          class="shrink-0 rounded-lg border border-gray-300 px-2 py-2 text-xs text-gray-600 hover:bg-gray-50"
          phx-target={@phx_target}
          phx-click={JS.push(@clear_event, target: @phx_target)}
          aria-label={gettext("Clear selection")}
        >
          <.icon name="hero-x-mark" class="h-4 w-4" />
        </button>
      </div>
      <div
        :if={@open && @suggestions != []}
        class="absolute z-20 mt-1 max-h-60 w-full overflow-auto rounded-lg border border-gray-200 bg-white py-1 shadow-lg"
        role="listbox"
      >
        <button
          :for={{label, id} <- @suggestions}
          type="button"
          role="option"
          class="block w-full px-3 py-2 text-left text-sm text-gray-900 hover:bg-primary-50"
          phx-target={@phx_target}
          phx-click={JS.push(@pick_event, value: %{id: to_string(id), label: label}, target: @phx_target)}
        >
          {label}
        </button>
      </div>
      <div :if={length(@errors) > 0} class="mt-1">
        <p :for={msg <- @errors} class="text-sm text-danger-600">
          {msg}
        </p>
      </div>
    </div>
    """
  end

  defp hidden_select_value(nil), do: ""
  defp hidden_select_value(""), do: ""

  defp hidden_select_value(val) do
    val |> to_string() |> String.trim()
  end

  @doc """
  Renders a container wrapper for forms with optional title.

  ## Examples

      <.form_container title="Create New Task">
        <.form for={@changeset} phx-submit="create">
          ...
        </.form>
      </.form_container>
  """
  attr :title, :string, default: nil, doc: "optional title displayed above the form"
  slot :inner_block, required: true

  def form_container(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-md p-6 mx-auto">
      <%= if @title do %>
        <h2 class="text-xl font-semibold text-gray-800 mb-6">{@title}</h2>
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a row of form action buttons (submit, cancel, etc.).

  ## Examples

      <.form_actions>
        <.button type="submit">Save</.button>
        <.button type="button" phx-click="cancel">Cancel</.button>
      </.form_actions>
  """
  slot :inner_block, required: true

  def form_actions(assigns) do
    ~H"""
    <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-200">
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a card container for grouping content.

  ## Examples

      <.card>
        <h3>Card Title</h3>
        <p>Card content goes here.</p>
      </.card>

      <.card title="My Card" class="max-w-md">
        Content
      </.card>
  """
  attr :title, :string, default: nil
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={["rounded-lg border border-gray-200 bg-white shadow-sm", @class]}>
      <div :if={@title} class="border-b border-gray-200 px-4 py-3">
        <h3 class="text-base font-semibold text-gray-900">{@title}</h3>
      </div>
      <div class="p-4">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a badge/tag for status, labels, or counts.

  ## Examples

      <.badge>New</.badge>
      <.badge variant="success">Active</.badge>
      <.badge variant="danger">Deleted</.badge>
  """
  attr :variant, :string, default: "default", doc: "default, success, warning, danger, info"
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
      badge_variant(@variant),
      @class
    ]}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp badge_variant("success"), do: "bg-secondary-100 text-secondary-800"
  defp badge_variant("warning"), do: "bg-warning-100 text-warning-800"
  defp badge_variant("danger"), do: "bg-danger-100 text-danger-800"
  defp badge_variant("info"), do: "bg-primary-100 text-primary-800"
  defp badge_variant(_), do: "bg-gray-100 text-gray-800"

  @doc """
  Renders an inline alert (for form or page-level messages, not toast-style).

  ## Examples

      <.alert kind="info">Your changes have been saved.</.alert>
      <.alert kind="error" title="Error">Something went wrong.</.alert>
  """
  attr :kind, :atom, values: [:info, :error, :warning, :success], default: :info
  attr :title, :string, default: nil
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def alert(assigns) do
    ~H"""
    <div
      role="alert"
      class={[
        "rounded-lg p-4",
        alert_kind(@kind),
        @class
      ]}
    >
      <p :if={@title} class="font-semibold mb-1">{@title}</p>
      <div class="text-sm">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  defp alert_kind(:info), do: "bg-primary-50 text-primary-800 border border-primary-200"
  defp alert_kind(:error), do: "bg-danger-50 text-danger-800 border border-danger-200"
  defp alert_kind(:warning), do: "bg-warning-50 text-warning-800 border border-warning-200"
  defp alert_kind(:success), do: "bg-secondary-50 text-secondary-800 border border-secondary-200"

  @doc """
  Renders a loading spinner.

  ## Examples

      <.spinner />
      <.spinner class="h-8 w-8" />
  """
  attr :class, :string, default: nil

  def spinner(assigns) do
    ~H"""
    <svg
      class={["animate-spin h-5 w-5 text-primary-600", @class]}
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
      </circle>
      <path
        class="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      >
      </path>
    </svg>
    """
  end

  @doc """
  Renders an empty state when a list or table has no items.

  ## Examples

      <.empty_state :if={@tasks == []}>
        No tasks yet. Create your first one!
      </.empty_state>
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def empty_state(assigns) do
    ~H"""
    <div class={[
      "rounded-lg border-2 border-dashed border-gray-200 bg-gray-50 p-12 text-center",
      @class
    ]}>
      <p class="text-sm text-gray-700">{render_slot(@inner_block)}</p>
    </div>
    """
  end

  @doc """
  Renders a switch/toggle (checkbox styled as a switch).

  ## Examples

      <.switch name="task[active]" label="Enable notifications" checked={true} />
  """
  attr :name, :any, required: true
  attr :label, :string, default: nil
  attr :checked, :boolean, default: false
  attr :value, :string, default: "true"
  attr :errors, :list, default: []
  attr :rest, :global, include: ~w(disabled)

  def switch(assigns) do
    ~H"""
    <div class="mb-4" phx-feedback-for={@name}>
      <label class="flex items-center gap-3 cursor-pointer">
        <input type="hidden" name={@name} value="false" />
        <div class="relative w-11 h-6">
          <input
            type="checkbox"
            name={@name}
            value={@value}
            checked={@checked}
            class="sr-only peer"
            {@rest}
          />
          <div class="block w-11 h-6 bg-gray-200 rounded-full peer-checked:bg-primary-600 transition-colors">
          </div>
          <div class="absolute left-1 top-1 w-4 h-4 bg-white rounded-full shadow transition-transform peer-checked:translate-x-5 pointer-events-none">
          </div>
        </div>
        <span :if={@label} class="text-sm font-medium text-gray-700">{@label}</span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders Yes/No radio buttons.

  ## Examples

      <.yes_no name="task[confirmed]" value={true} label="Confirmed?" />
  """
  attr :name, :any, required: true
  attr :label, :string, default: nil
  attr :value, :any, doc: "true for Yes, false for No, nil for neither"
  attr :errors, :list, default: []
  attr :rest, :global, include: ~w(disabled required)

  def yes_no(assigns) do
    normalized_value = normalize_yes_no_value(assigns[:value])

    name_key =
      assigns[:name]
      |> to_string()
      |> String.replace(~r/[^a-zA-Z0-9_-]/, "_")

    assigns =
      assigns
      |> assign(:yes_checked, normalized_value == true)
      |> assign(:no_checked, normalized_value == false)
      |> assign(:yes_id, "#{name_key}_yes")
      |> assign(:no_id, "#{name_key}_no")

    ~H"""
    <div class="mb-4" phx-feedback-for={@name}>
      <label :if={@label} class="block text-sm font-medium text-gray-700 mb-2">{@label}</label>
      <div class="flex gap-6">
        <label class="flex items-center gap-2 cursor-pointer" for={@yes_id}>
          <input
            id={@yes_id}
            type="radio"
            name={@name}
            value="true"
            checked={@yes_checked}
            class="rounded-full border-gray-300 text-primary-600 focus:ring-primary-500"
            {@rest}
          />
          <span class="text-sm text-gray-700">Yes</span>
        </label>
        <label class="flex items-center gap-2 cursor-pointer" for={@no_id}>
          <input
            id={@no_id}
            type="radio"
            name={@name}
            value="false"
            checked={@no_checked}
            class="rounded-full border-gray-300 text-primary-600 focus:ring-primary-500"
            {@rest}
          />
          <span class="text-sm text-gray-700">No</span>
        </label>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  defp normalize_yes_no_value(value) when value in [true, "true", 1, "1"], do: true
  defp normalize_yes_no_value(value) when value in [false, "false", 0, "0"], do: false
  defp normalize_yes_no_value(_), do: nil

  @doc """
  Renders a group of radio buttons (single selection).

  ## Examples

      <.radio_group name="task[priority]" label="Priority" options={[{"Low", "low"}, {"Medium", "medium"}, {"High", "high"}]} value="medium" />
  """
  attr :name, :any, required: true
  attr :label, :string, default: nil
  attr :value, :any, doc: "the selected value"
  attr :options, :list, required: true, doc: "list of {label, value} tuples"
  attr :errors, :list, default: []
  attr :rest, :global, include: ~w(disabled required)

  def radio_group(assigns) do
    ~H"""
    <div class="mb-4" phx-feedback-for={@name}>
      <label :if={@label} class="block text-sm font-medium text-gray-700 mb-2">{@label}</label>
      <div class="space-y-2">
        <div :for={{label, val} <- @options} class="flex items-center gap-2">
          <label class="flex items-center gap-2 cursor-pointer">
            <input
              type="radio"
              name={@name}
              value={val}
              checked={@value == val}
              class="rounded-full border-gray-300 text-primary-600 focus:ring-primary-500"
              {@rest}
            />
            <span class="text-sm text-gray-700">{label}</span>
          </label>
        </div>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a group of checkboxes (multi-select).

  ## Examples

      <.checkbox_group name="task[tags]" label="Tags" options={[{"Work", "work"}, {"Personal", "personal"}]} value={["work"]} />
  """
  attr :name, :any, required: true
  attr :label, :string, default: nil
  attr :value, :any, doc: "list of selected values"
  attr :options, :list, required: true, doc: "list of {label, value} tuples"
  attr :errors, :list, default: []
  attr :rest, :global, include: ~w(disabled)

  def checkbox_group(assigns) do
    assigns = assign(assigns, :selected, List.wrap(assigns[:value] || []))

    ~H"""
    <div class="mb-4" phx-feedback-for={@name}>
      <label :if={@label} class="block text-sm font-medium text-gray-700 mb-2">{@label}</label>
      <div class="space-y-2">
        <div :for={{label, val} <- @options} class="flex items-center gap-2">
          <label class="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              name={"#{@name}[]"}
              value={val}
              checked={val in @selected}
              class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
              {@rest}
            />
            <span class="text-sm text-gray-700">{label}</span>
          </label>
        </div>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a dropdown-style multi-select (collapsed by default, expands on click).

  ## Examples

      <.multi_select_dropdown
        name="task[tags]"
        label="Select tags"
        options={[{"Work", "work"}, {"Personal", "personal"}, {"Urgent", "urgent"}]}
        value={["work", "urgent"]}
        placeholder="Choose tags..."
      />
  """
  attr :id, :string, default: nil
  attr :name, :any, required: true
  attr :label, :string, default: nil
  attr :options, :list, required: true, doc: "list of {label, value} tuples"
  attr :value, :any, default: [], doc: "list of selected values"
  attr :placeholder, :string, default: "Select..."
  attr :errors, :list, default: []

  def multi_select_dropdown(assigns) do
    id = assigns[:id] || "multi-select-#{unique_id(assigns[:name])}"
    dropdown_id = "#{id}-dropdown"
    selected = List.wrap(assigns[:value] || [])

    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:dropdown_id, dropdown_id)
      |> assign(:selected, selected)
      |> assign(:selected_labels, selected_labels(assigns[:options], selected))

    ~H"""
    <div
      id={@id}
      class="relative mb-4"
      phx-click-away={JS.add_class("hidden", to: "##{@dropdown_id}")}
      phx-feedback-for={@name}
    >
      <label :if={@label} class="block text-sm font-medium text-gray-700 mb-1">{@label}</label>
      <button
        type="button"
        phx-click={JS.toggle_class("hidden", to: "##{@dropdown_id}")}
        class="w-full flex items-center justify-between rounded-lg border border-gray-300 bg-white px-3 py-2 text-left text-sm shadow-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
      >
        <span class={if @selected == [], do: "text-gray-500", else: "text-gray-900"}>
          <%= if @selected == [] do %>
            {@placeholder}
          <% else %>
            {Enum.join(@selected_labels, ", ")}
          <% end %>
        </span>
        <.icon name="hero-chevron-down" class="h-5 w-5 text-gray-400" />
      </button>
      <div
        id={@dropdown_id}
        class="hidden absolute z-10 mt-1 w-full rounded-lg border border-gray-200 bg-white shadow-lg max-h-60 overflow-auto"
      >
        <div class="py-1">
          <div :for={{label, val} <- @options} class="px-3 py-2 hover:bg-gray-50">
            <label class="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                name={"#{@name}[]"}
                value={val}
                checked={val in @selected}
                class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
              />
              <span class="text-sm text-gray-700">{label}</span>
            </label>
          </div>
        </div>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  defp unique_id(name) when is_binary(name), do: String.replace(name, ~r/[\[\]]/, "-")
  defp unique_id(name), do: unique_id(to_string(name))

  defp selected_labels(options, selected) do
    for {label, val} <- options, val in selected, do: label
  end

  defp ensure_bracket_suffix(name) when is_binary(name) do
    if String.ends_with?(name, "[]"), do: name, else: name <> "[]"
  end

  defp input_size("sm"), do: "px-2 py-1 text-sm"
  defp input_size("lg"), do: "px-4 py-3 text-lg"
  defp input_size(_), do: "px-3 py-2 text-base"

  defp input_variant("error", errors) when length(errors) > 0,
    do: "border-danger-300 focus:border-danger-500 focus:ring-danger-500"

  defp input_variant(_, errors) when length(errors) > 0,
    do: "border-danger-300 focus:border-danger-500 focus:ring-danger-500"

  defp input_variant("default", _),
    do: "border-gray-300 focus:border-primary-500 focus:ring-primary-500"

  defp input_variant(_, _),
    do: "border-gray-300 focus:border-primary-500 focus:ring-primary-500"

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal">{col[:label]}</th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  {render_slot(action, @row_item.(row))}
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500">{item.title}</dt>
          <dd class="text-zinc-700">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders the main application sidebar with navigation links.

  ## Examples

      <.sidebar current_user={@current_user} active_page={@active_page}>
        <:nav_item
          name="Dashboard"
          path={~p"/dashboard"}
          icon="hero-home"
          active={@active_page == "dashboard"}
        />
        <:nav_section title="Management">
          <:nav_item
            name="Employees"
            path={~p"/employees"}
            icon="hero-users"
            active={@active_page == "employees"}
          />
          <:nav_item
            name="Tasks"
            path={~p"/tasks"}
            icon="hero-check-circle"
            active={@active_page == "tasks"}
          />
        </:nav_section>
      </.sidebar>
  """
  attr :current_user, :any, default: nil
  attr :active_page, :string, default: nil

  slot :inner_block

  slot :nav_item, doc: "individual navigation items" do
    attr :name, :string, required: true
    attr :path, :any, required: true
    attr :icon, :string, required: true
    attr :active, :boolean
  end

  slot :nav_section, doc: "group of navigation items with a title" do
    attr :title, :string, required: true
  end

  slot :bottom_nav, doc: "optional nav content pinned above auth footer"

  def sidebar(assigns) do
    ~H"""
    <!-- Mobile Header -->
    <div class="lg:hidden fixed top-0 left-0 right-0 bg-white border-b border-gray-200 z-30 p-4">
      <div class="flex items-center justify-between">
        <h1 class="text-xl font-bold text-primary-600">SnippetSaver</h1>
        <button
          type="button"
          phx-click={JS.toggle(to: "#mobile-sidebar")}
          class="p-2 rounded-lg hover:bg-gray-100"
        >
          <.icon name="hero-bars-3" class="h-6 w-6" />
        </button>
      </div>
    </div>

    <!-- Mobile Sidebar -->
    <div
      id="mobile-sidebar"
      class="lg:hidden fixed inset-0 z-40 hidden"
      phx-click-away={JS.hide(to: "#mobile-sidebar")}
    >
      <div
        class="fixed inset-0 bg-black bg-opacity-50"
        phx-click={JS.hide(to: "#mobile-sidebar")}
      >
      </div>

      <aside class="fixed left-0 top-0 bottom-0 w-64 bg-white shadow-xl flex flex-col">
        <div class="p-4 border-b border-gray-200">
          <h1 class="text-xl font-bold text-primary-600">SnippetSaver</h1>
        </div>

        <nav class="flex-1 overflow-y-auto p-4">
          <ul class="space-y-1">
            <%= for item <- @nav_item do %>
              <li>
                <.sidebar_link
                  name={item.name}
                  path={item.path}
                  icon={item.icon}
                  active={Map.get(item, :active, false)}
                />
              </li>
            <% end %>

            <%= for section <- @nav_section do %>
              <li class="mt-4 mb-2">
                <p class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3">
                  {section.title}
                </p>
              </li>

              {render_slot(section)}
            <% end %>

            {render_slot(@inner_block)}
          </ul>
        </nav>

        <div :if={@bottom_nav != []} class="px-4 pb-3">
          {render_slot(@bottom_nav)}
        </div>

        <div class="p-4 border-t border-gray-200 space-y-2">
          <%= if @current_user do %>
            <p class="text-xs text-gray-500 px-1 truncate">
              Signed in as<br />
              <span class="font-medium text-gray-900">{@current_user.email}</span>
            </p>

            <.sidebar_link
              name="Settings"
              path="/users/settings"
              icon="hero-cog"
              active={false}
            />

            <.sidebar_link
              name="Log out"
              path="/users/log_out"
              icon="hero-arrow-right-on-rectangle"
              method="delete"
              active={false}
            />
          <% else %>
            <.sidebar_link
              name="Log in"
              path="/users/log_in"
              icon="hero-arrow-right-on-rectangle"
              active={false}
            />

            <.sidebar_link
              name="Register"
              path="/users/register"
              icon="hero-user-plus"
              active={false}
            />
          <% end %>
        </div>
      </aside>
    </div>

    <!-- Desktop Sidebar -->
    <aside class="hidden lg:flex lg:w-64 bg-white border-r border-gray-200 flex-col h-screen">
      <div class="p-4 border-b border-gray-200">
        <h1 class="text-xl font-bold text-primary-600">SnippetSaver</h1>
      </div>

      <nav class="flex-1 overflow-y-auto p-4">
        <ul class="space-y-1">
          <%= for item <- @nav_item do %>
            <li>
              <.sidebar_link
                name={item.name}
                path={item.path}
                icon={item.icon}
                active={Map.get(item, :active, false)}
              />
            </li>
          <% end %>

          <%= for section <- @nav_section do %>
            <li class="mt-4 mb-2">
              <p class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3">
                {section.title}
              </p>
            </li>

            {render_slot(section)}
          <% end %>

          {render_slot(@inner_block)}
        </ul>
      </nav>

      <div :if={@bottom_nav != []} class="px-4 pb-3">
        {render_slot(@bottom_nav)}
      </div>

      <div class="p-4 border-t border-gray-200 space-y-2">
        <%= if @current_user do %>
          <p class="text-xs text-gray-500 px-1 truncate">
            Signed in as<br />
            <span class="font-medium text-gray-900">{@current_user.email}</span>
          </p>

          <.sidebar_link
            name="Settings"
            path="/users/settings"
            icon="hero-cog"
            active={false}
          />

          <.sidebar_link
            name="Log out"
            path="/users/log_out"
            icon="hero-arrow-right-on-rectangle"
            method="delete"
            active={false}
          />
        <% else %>
          <.sidebar_link
            name="Log in"
            path="/users/log_in"
            icon="hero-arrow-right-on-rectangle"
            active={false}
          />

          <.sidebar_link
            name="Register"
            path="/users/register"
            icon="hero-user-plus"
            active={false}
          />
        <% end %>
      </div>
    </aside>
    """
  end

  @doc """
  Renders a single sidebar navigation link.
  """
  attr :name, :string, required: true
  attr :path, :any, required: true
  attr :icon, :string, required: true
  attr :active, :boolean, default: false
  attr :method, :string, default: nil
  attr :rest, :global

  def sidebar_link(assigns) do
    ~H"""
    <%= if @active and is_nil(@method) do %>
      <button
        type="button"
        class={[
          "w-full text-left flex items-center gap-3 px-3 py-2 rounded-lg transition-colors duration-200 text-sm font-medium",
          "bg-primary-50 text-primary-700 cursor-default"
        ]}
        {@rest}
      >
        <.icon name={@icon} class="h-5 w-5" />
        <span>{@name}</span>
      </button>
    <% else %>
      <.link
        href={@path}
        method={@method}
        class={[
          "flex items-center gap-3 px-3 py-2 rounded-lg transition-colors duration-200 text-sm font-medium",
          if(@active,
            do: "bg-primary-50 text-primary-700",
            else: "text-gray-700 hover:bg-gray-100"
          )
        ]}
        {@rest}
      >
        <.icon name={@icon} class="h-5 w-5" />
        <span>{@name}</span>
      </.link>
    <% end %>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        {render_slot(@inner_block)}
      </.link>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  def show_drawer(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-opacity ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-panel",
      transition:
        {"transition-transform ease-out duration-300", "translate-x-full", "translate-x-0"}
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_drawer(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-opacity ease-in duration-200", "opacity-100", "opacity-0"},
      time: 200
    )
    |> JS.hide(
      to: "##{id}-panel",
      transition:
        {"transition-transform ease-in duration-200", "translate-x-0", "translate-x-full"},
      time: 200
    )
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(SnippetSaverWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(SnippetSaverWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
