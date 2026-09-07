defmodule MedcampWeb.ReferralLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Referrals

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="referral-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:date]} type="date" label="Date" />
        <.input field={@form[:time]} type="time" label="Time" />
        <.input field={@form[:referral_note]} type="textarea" label="Referral note" />
        <.input field={@form[:hospital]} type="text" label="Hospital" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Referral</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{referral: referral} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Referrals.change_referral(referral))
     end)}
  end

  @impl true
  def handle_event("validate", %{"referral" => referral_params}, socket) do
    changeset = Referrals.change_referral(socket.assigns.referral, referral_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"referral" => referral_params}, socket) do
    referral_params =
      referral_params
      |> Map.put("doctor_id", socket.assigns.current_user.id)
      |> Map.put("patient_id", socket.assigns.patient.id)
      |> Map.put("doctor_note_id", socket.assigns.doctor_note.id)

    save_referral(socket, socket.assigns.action, referral_params)
  end

  defp save_referral(socket, :edit, referral_params) do
    case Referrals.update_referral(socket.assigns.referral, referral_params) do
      {:ok, referral} ->
        notify_parent({:saved, referral})

        {:noreply,
         socket
         |> put_flash(:info, "Referral updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_referral(socket, :refer_patient, referral_params) do
    case Referrals.create_referral(referral_params) do
      {:ok, referral} ->
        notify_parent({:saved, referral})

        {:noreply,
         socket
         |> put_flash(:info, "Referral created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
