defmodule MedcampWeb.VisitorBookLive.New do
  use MedcampWeb, :live_view

  alias Medcamp.Visitors
  alias Medcamp.Visitors.VisitorBookEntry

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "New Visitor Book Note")
     |> assign_form(default_entry_attrs())}
  end

  @impl true
  def handle_event("validate", %{"visitor_book_entry" => params}, socket) do
    params = build_entry_params(params, socket.assigns.current_user.id)

    form =
      %VisitorBookEntry{}
      |> Visitors.change_visitor_book_entry(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"visitor_book_entry" => params}, socket) do
    params = build_entry_params(params, socket.assigns.current_user.id)

    case Visitors.create_visitor_book_entry(params) do
      {:ok, _entry} ->
        {:noreply,
         socket
         |> put_flash(:info, "Visitor entry saved.")
         |> assign_form(default_entry_attrs())}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp assign_form(socket, attrs) do
    form =
      %VisitorBookEntry{}
      |> Visitors.change_visitor_book_entry(attrs)
      |> to_form()

    assign(socket, :form, form)
  end

  defp build_entry_params(params, user_id) do
    params
    |> Map.put("user_id", user_id)
  end

  defp default_entry_attrs do
    %{
      "visitor_name" => "",
      "phone_number" => "",
      "person_to_see" => "",
      "purpose" => "",
      "message" => ""
    }
    |> Map.merge(VisitorBookEntry.current_visit_defaults())
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-8">
      <.public_navbar />

      <div class="mx-auto py-32 w-full max-w-2xl">
        <section class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm">
          <.header class="text-[#373896]">
            New Visitor Book Note
            <:subtitle>
              Capture visitor details, what they said, and the time they arrived.
            </:subtitle>
          </.header>

          <.simple_form for={@form} phx-change="validate" phx-submit="save">
            <.input field={@form[:visitor_name]} label="Visitor name" placeholder="Full name" />
            <.input field={@form[:phone_number]} label="Phone number" placeholder="Optional" />
            <.input field={@form[:person_to_see]} label="Person to see" placeholder="Optional" />
            <.input field={@form[:purpose]} label="Purpose" placeholder="Optional" />

            <.input
              field={@form[:message]}
              type="textarea"
              label="What the visitor said"
              placeholder="Reason for visit, message left, outcome, or anything to record"
            />

            <:actions>
              <.button class="w-full bg-[#6667ab] hover:bg-[#5556a0]">Save entry</.button>
            </:actions>
          </.simple_form>
        </section>
      </div>
    </div>
    """
  end
end
