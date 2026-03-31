defmodule SnippetSaverWeb.ContactLive.Components.ShowComponent do
  use SnippetSaverWeb, :live_component

  alias SnippetSaver.Contacts

  def update(assigns, socket) do
    contact = Contacts.get_contact_with_assocs!(assigns.contact.id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:contact, contact)}
  end

  def render(assigns) do
    ~H"""
    <div class="h-full min-h-0 flex flex-col overflow-hidden text-xs">
      <div class="flex justify-between items-center gap-2 mb-2 shrink-0">
        <div class="min-w-0">
          <h1 class="text-base font-semibold text-gray-900 truncate"><%= display_name(@contact) %></h1>
          <p class="text-gray-500 truncate leading-tight"><%= @contact.title || "No title" %></p>
        </div>
        <.button
          variant="outline"
          size="sm"
          class="shrink-0"
          phx-click="go-to-edit"
          phx-value-id={@contact.id}
          phx-target={@myself}
        >
          <.icon name="hero-pencil" class="h-3.5 w-3.5 mr-1" />
          Edit
        </.button>
      </div>

      <div class="space-y-2 overflow-y-auto min-h-0 pr-0.5 pb-4">
        <.show_section title="Contact Information">
          <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 gap-x-3 gap-y-1.5">
            <.show_field label="Individual" value={if @contact.is_individual, do: "Yes", else: "No"} />
            <.show_field label="Title" value={@contact.title} />
            <.show_field label="First name" value={@contact.first_name} />
            <.show_field label="Last name" value={@contact.last_name} />
            <.show_field label="Business code" value={@contact.business_code} />
            <div class="min-w-0">
              <p class="text-gray-500 leading-tight">Important notes</p>
              <.badge variant={if @contact.notes_important, do: "warning", else: "info"} class="mt-0.5">
                <%= if @contact.notes_important, do: "Yes", else: "No" %>
              </.badge>
            </div>
            <.show_field label="Pref. method ID" value={id_or_dash(@contact.preferred_contact_method_id)} />
            <.show_field label="Hear about ID" value={id_or_dash(@contact.hear_about_option_id)} />
            <.show_field label="Discount grp ID" value={id_or_dash(@contact.discount_group_id)} />
            <.show_field label="Financial grp ID" value={id_or_dash(@contact.financial_group_id)} />
            <div class="col-span-2 sm:col-span-3 lg:col-span-4 xl:col-span-6 min-w-0">
              <p class="text-gray-500 leading-tight">Notes</p>
              <p class="font-medium text-gray-900 whitespace-pre-wrap leading-snug max-h-20 overflow-y-auto">
                <%= @contact.notes || "—" %>
              </p>
            </div>
          </div>
        </.show_section>

        <div class="grid grid-cols-1 xl:grid-cols-2 gap-2">
          <.show_section title="Roles">
            <div class="overflow-x-auto -mx-0.5">
              <table class="min-w-full">
                <thead class="text-gray-500 border-b border-gray-100">
                  <tr>
                    <th class="text-left font-medium py-1 px-1.5">Role</th>
                    <th class="text-left font-medium py-1 px-1.5 w-24">Added</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :if={Enum.empty?(@contact.contact_roles || [])}>
                    <td colspan="2" class="py-1.5 px-1.5 text-gray-400">None</td>
                  </tr>
                  <tr :for={role <- @contact.contact_roles || []} class="border-b border-gray-50 last:border-0">
                    <td class="py-1 px-1.5 font-medium text-gray-900">
                      <%= role.contact_role_type && role.contact_role_type.name || "—" %>
                    </td>
                    <td class="py-1 px-1.5 text-gray-600 whitespace-nowrap"><%= format_datetime(role.inserted_at) %></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </.show_section>

          <.show_section title="Contact methods">
            <div class="overflow-x-auto -mx-0.5">
              <table class="min-w-full">
                <thead class="text-gray-500 border-b border-gray-100">
                  <tr>
                    <th class="text-left font-medium py-1 px-1.5">Type</th>
                    <th class="text-left font-medium py-1 px-1.5">Value</th>
                    <th class="text-center font-medium py-1 px-0.5 w-6" title="Primary">P</th>
                    <th class="text-center font-medium py-1 px-0.5 w-6" title="SMS">S</th>
                    <th class="text-center font-medium py-1 px-0.5 w-6" title="Email">E</th>
                    <th class="text-left font-medium py-1 px-1.5 w-20">Added</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :if={Enum.empty?(@contact.contact_methods || [])}>
                    <td colspan="6" class="py-1.5 px-1.5 text-gray-400">None</td>
                  </tr>
                  <tr :for={m <- @contact.contact_methods || []} class="border-b border-gray-50 last:border-0">
                    <td class="py-1 px-1.5 text-gray-900"><%= m.type %></td>
                    <td class="py-1 px-1.5 text-gray-900 truncate max-w-[140px]" title={m.value}><%= m.value %></td>
                    <td class="py-1 px-0.5 text-center text-gray-700"><%= boolean_short(m.is_primary) %></td>
                    <td class="py-1 px-0.5 text-center text-gray-700"><%= boolean_short(m.allow_sms) %></td>
                    <td class="py-1 px-0.5 text-center text-gray-700"><%= boolean_short(m.allow_email) %></td>
                    <td class="py-1 px-1.5 text-gray-600 whitespace-nowrap"><%= format_datetime(m.inserted_at) %></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </.show_section>
        </div>

        <.show_section title="Addresses">
          <div class="overflow-x-auto -mx-0.5">
            <table class="min-w-full">
              <thead class="text-gray-500 border-b border-gray-100">
                <tr>
                  <th class="text-left font-medium py-1 px-1.5">Name</th>
                  <th class="text-left font-medium py-1 px-1.5">Type</th>
                  <th class="text-left font-medium py-1 px-1.5">Street</th>
                  <th class="text-left font-medium py-1 px-1.5">City</th>
                  <th class="text-left font-medium py-1 px-1.5 w-14">Post</th>
                  <th class="text-left font-medium py-1 px-1.5">Country</th>
                </tr>
              </thead>
              <tbody>
                <tr :if={Enum.empty?(@contact.addresses || [])}>
                  <td colspan="6" class="py-1.5 px-1.5 text-gray-400">None</td>
                </tr>
                <tr :for={a <- @contact.addresses || []} class="border-b border-gray-50 last:border-0">
                  <td class="py-1 px-1.5 text-gray-900"><%= a.address_name || "—" %></td>
                  <td class="py-1 px-1.5 text-gray-700"><%= a.type || "—" %></td>
                  <td class="py-1 px-1.5 text-gray-700 max-w-[160px] truncate" title={a.street_address}><%= a.street_address || "—" %></td>
                  <td class="py-1 px-1.5 text-gray-700"><%= a.city || "—" %></td>
                  <td class="py-1 px-1.5 text-gray-700"><%= a.postcode || "—" %></td>
                  <td class="py-1 px-1.5 text-gray-700"><%= a.country || "—" %></td>
                </tr>
              </tbody>
            </table>
          </div>
        </.show_section>

        <.show_section title="General info">
          <div :if={is_nil(@contact.general_info)} class="text-gray-400 py-0.5">None on file.</div>
          <div :if={@contact.general_info} class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-x-3 gap-y-1.5">
            <% gi = @contact.general_info %>
            <.show_field label="Hospital" value={gi.hospital} />
            <.show_field label="Website" value={gi.website} />
            <.show_field label="Pet insurance" value={gi.pet_insurance_supplier} />
            <.show_field label="DOB" value={format_date(gi.date_of_birth)} />
            <.show_field label="License #" value={gi.driver_license_number} />
            <.show_field label="License issuer" value={gi.driver_license_issuer} />
            <.show_field label="License expiry" value={format_date(gi.driver_license_expiry)} />
            <.show_field label="National ID" value={gi.national_id_number} />
            <.show_field label="Passport" value={gi.passport_number} />
            <.show_field label="Credit limit" value={gi.credit_limit_name} />
            <.show_field label="Details OK" value={boolean_label(gi.contact_details_confirmed)} />
            <.show_field label="Consolidate inv." value={boolean_label(gi.consolidate_invoices)} />
          </div>
        </.show_section>
      </div>
    </div>
    """
  end

  attr :title, :string, required: true
  slot :inner_block, required: true

  defp show_section(assigns) do
    ~H"""
    <section class="rounded border border-gray-200 bg-white shadow-sm overflow-hidden">
      <h2 class="px-2 py-1 border-b border-gray-100 bg-gray-50 text-[11px] font-semibold uppercase tracking-wide text-gray-600">
        <%= @title %>
      </h2>
      <div class="px-2 py-1.5">
        <%= render_slot(@inner_block) %>
      </div>
    </section>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true

  defp show_field(assigns) do
    value = assigns.value
    display = if value in [nil, ""], do: "—", else: to_string(value)
    assigns = assign(assigns, :display, display)

    ~H"""
    <div class="min-w-0">
      <p class="text-gray-500 leading-tight truncate" title={@label}><%= @label %></p>
      <p class="font-medium text-gray-900 leading-tight truncate" title={@display}><%= @display %></p>
    </div>
    """
  end

  def handle_event("go-to-edit", %{"id" => id}, socket) do
    send(self(), {:go_to_edit, id})
    {:noreply, socket}
  end

  defp display_name(contact) do
    [contact.first_name, contact.last_name]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
    |> case do
      "" -> "Contact ##{contact.id}"
      name -> name
    end
  end

  defp id_or_dash(nil), do: "—"
  defp id_or_dash(id), do: to_string(id)

  defp boolean_label(true), do: "Yes"
  defp boolean_label(_), do: "No"

  defp boolean_short(true), do: "Y"
  defp boolean_short(_), do: "·"

  defp format_datetime(nil), do: "—"

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y")
  end

  defp format_date(nil), do: "—"
  defp format_date(%Date{} = d), do: Calendar.strftime(d, "%Y-%m-%d")
  defp format_date(_), do: "—"
end
