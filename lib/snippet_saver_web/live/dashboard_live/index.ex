defmodule SnippetSaverWeb.DashboardLive.Index do
  use SnippetSaverWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       active_page: "dashboard",
       selected_module: "appointment",
       modules: module_tabs(),
       swimlanes: module_swimlanes()
     )}
  end

  def handle_event("set_module", %{"module" => module}, socket) do
    {:noreply, assign(socket, selected_module: module)}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="rounded-xl border border-zinc-200 bg-white p-2 shadow-sm">
        <div class="flex flex-wrap gap-2">
          <button
            :for={module <- @modules}
            type="button"
            phx-click="set_module"
            phx-value-module={module.id}
            class={[
              "rounded-lg px-4 py-2 text-sm font-medium transition",
              if(@selected_module == module.id,
                do: "bg-indigo-600 text-white shadow",
                else: "bg-zinc-100 text-zinc-700 hover:bg-zinc-200"
              )
            ]}
          >
            <%= module.label %>
          </button>
        </div>
      </div>

      <div class="mt-4 rounded-xl border border-zinc-200 bg-white p-4 shadow-sm">
        <div class="flex flex-wrap items-center justify-between gap-3 text-sm text-zinc-600">
          <div class="flex flex-wrap items-center gap-2">
            <button type="button" class="rounded-md border border-zinc-300 px-3 py-1.5 hover:bg-zinc-100">
              {Date.utc_today()}
            </button>
            <button type="button" class="rounded-md border border-zinc-300 px-3 py-1.5 hover:bg-zinc-100">
              All Doctors
            </button>
            <button type="button" class="rounded-md border border-zinc-300 px-3 py-1.5 hover:bg-zinc-100">
              All Statuses
            </button>
          </div>
          <button type="button" class="rounded-md border border-zinc-300 px-3 py-1.5 hover:bg-zinc-100">
            Refresh
          </button>
        </div>

        <div class="mt-4 min-h-20 rounded-lg border border-dashed border-zinc-300 bg-zinc-50 p-3 text-xs text-zinc-500">
          Filter area reserved for advanced filters (doctor, date range, status, appointment type, search).
        </div>
      </div>

      <div class="mt-6 grid grid-cols-1 gap-4 lg:grid-cols-2 xl:grid-cols-4">
        <div
          :for={lane <- Map.get(@swimlanes, @selected_module, [])}
          class="rounded-xl border border-zinc-200 bg-zinc-50 p-4"
        >
          <div class="mb-3">
            <h3 class="text-sm font-semibold uppercase tracking-wide text-zinc-700">{lane.title}</h3>
            <p class="mt-1 text-xs text-zinc-500">{lane.subtitle}</p>
          </div>

          <div class="space-y-3">
            <div :for={card <- lane.cards} class="rounded-lg border border-zinc-200 bg-white p-3 shadow-sm">
              <div class="text-sm font-semibold text-zinc-900">{card.title}</div>
              <div class="mt-1 text-xs text-zinc-600">{card.time}</div>
              <div class="mt-1 text-xs text-zinc-600">{card.detail}</div>
              <div class="mt-2">
                <span class="rounded-full bg-indigo-50 px-2 py-1 text-[11px] font-medium text-indigo-700">
                  {card.status}
                </span>
              </div>
            </div>

            <div :if={lane.cards == []} class="rounded-lg border border-dashed border-zinc-300 bg-white p-4 text-xs text-zinc-500">
              No cards yet. We will plug real data here next.
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp module_tabs do
    [
      %{id: "appointment", label: "Appointment"},
      %{id: "patient", label: "Patient"},
      %{id: "contact", label: "Contact"}
    ]
  end

  defp module_swimlanes do
    %{
      "appointment" => appointment_swimlanes(),
      "patient" => [
        %{title: "NEW", subtitle: "Recently added patients", cards: []},
        %{title: "FOLLOW UP", subtitle: "Needs callback or revisit", cards: []},
        %{title: "IN TREATMENT", subtitle: "Active care plans", cards: []},
        %{title: "ARCHIVED", subtitle: "Inactive records", cards: []}
      ],
      "contact" => [
        %{title: "NEW LEADS", subtitle: "Recently created contacts", cards: []},
        %{title: "IN CONVERSATION", subtitle: "Active outreach", cards: []},
        %{title: "PENDING ACTION", subtitle: "Awaiting response", cards: []},
        %{title: "CLOSED", subtitle: "Resolved or completed", cards: []}
      ]
    }
  end

  defp appointment_swimlanes do
    cards_by_lane = SnippetSaver.Appointments.appointment_swimlane_cards()

    [
      %{
        title: "UPCOMING",
        subtitle: "Next 48 hours",
        cards: Map.get(cards_by_lane, "UPCOMING", [])
      },
      %{
        title: "TODAY",
        subtitle: "Appointments for today",
        cards: Map.get(cards_by_lane, "TODAY", [])
      },
      %{
        title: "NEEDS RESCHEDULE",
        subtitle: "Passed appointments with unchanged status",
        cards: Map.get(cards_by_lane, "NEEDS RESCHEDULE", [])
      },
      %{
        title: "READY FOR BILLING",
        subtitle: "Completed and awaiting invoice",
        cards: Map.get(cards_by_lane, "READY FOR BILLING", [])
      }
    ]
  end
end
