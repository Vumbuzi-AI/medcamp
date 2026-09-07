defmodule MedcampWeb.ReceptionsPagePatientLive.TriggerPayment do
  use MedcampWeb, :live_component

  alias Medcamp.Mpesas
  alias Medcamp.Mpesas.Mpesa
  alias Medcamp.Pay
  alias Medcamp.Costings

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Add Patient Details and Prompt Payment
      </.header>

      <p
        :if={@payment_error}
        class="bg-red-200 text-red-500 flex justify-between items-center rounded-md p-2 w-[100%]"
      >
        <span class="w-[90%]">
          {@payment_error}
        </span>
        <span
          phx-click="clear_payment_error"
          phx-target={@myself}
          class="w-[10%] cursor-pointer flex justify-end items-center"
        >
          <Heroicons.icon name="x-mark" type="outline" class="h-4 w-4 text-darkblue" />
        </span>
      </p>
      <.simple_form
        for={@form}
        id="patient_visit-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:reason]} type="textarea" class="w-[100%]" label="Reason" />
        <.phone_number_input
          field={@form[:formatted_phone_number]}
          type="number"
          class="w-[100%]"
          required={true}
          value={@formatted_patient_number}
        />

        <.input :if={@initial_price == nil} field={@form[:amount]} type="number" label="Amount" />
        <.input
          :if={@initial_price != nil}
          field={@form[:amount]}
          type="number"
          label="Amount"
          value={@initial_price}
          readonly={true}
        />

        <:actions>
          <%= if @form.source.valid? == false do %>
            <.button class="cursor-not-allowed" disabled>Trigger Payment</.button>
          <% else %>
            <.button phx-disable-with="Saving...">
              Trigger Payment
            </.button>
          <% end %>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    initial_price =
      get_initial_price(assigns.action_to_perform, assigns.actionable_type)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:initial_price, initial_price)
     |> assign(:payment_error, nil)
     |> assign(:mpesa, %Mpesa{})
     |> assign(
       :formatted_patient_number,
       assigns.patient.phone_number |> String.slice(1..-1//-1)
     )
     |> assign_new(:form, fn ->
       to_form(
         Mpesas.change_trigger_mpesa(%Mpesa{}, %{
           "amount" => initial_price,
           "formatted_phone_number" => assigns.patient.phone_number |> String.slice(1..-1//-1)
         })
       )
     end)}
  end

  defp get_initial_price(action_to_perform, actionable_type) do
    case action_to_perform do
      "create_nurse_procedure" ->
        actionable_type.procedure.price

      "create_doctor_procedure" ->
        actionable_type.procedure.price

      "create_patient_visit" ->
        Costings.get_costings_by_type("Consultation").price

      "create_patient_visit_for_triage" ->
        Costings.get_costings_by_type("Triage Only").price

      _ ->
        nil
    end
  end

  @impl true
  def handle_event("validate", %{"mpesa" => mpesa_params}, socket) do
    changeset =
      Mpesas.change_trigger_mpesa(socket.assigns.mpesa, mpesa_params)

    {:noreply,
     socket
     |> assign(:payment_error, nil)
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("clear_payment_error", _, socket) do
    {:noreply, assign(socket, payment_error: nil)}
  end

  def handle_event("save", %{"mpesa" => mpesa_params}, socket) do
    phone_number = "254" <> mpesa_params["formatted_phone_number"]

    case create_wallet_deposit(mpesa_params, socket.assigns.patient_id) do
      {:ok, wallet_deposit} ->
        case Pay.make_request(mpesa_params["amount"], phone_number) do
          {:ok, params, 200} ->
            Mpesas.create_mpesa(%{
              "phone" => phone_number,
              "amount" => mpesa_params["amount"],
              "checkout_request_id" => params["CheckoutRequestID"],
              "merchant_request_id" => params["MerchantRequestID"],
              "actionable_id" => wallet_deposit.id,
              "actionable_type" => socket.assigns.action_to_perform,
              "prompter_id" => socket.assigns.current_user.id,
              "patient_id" => socket.assigns.patient_id
            })

            {:noreply,
             socket
             |> put_flash(:info, "Payment triggered successfully")
             |> push_navigate(
               to:
                 "/confirm?checkout_request_id=#{params["CheckoutRequestID"]}&return_url=#{socket.assigns.return_url}&action=#{socket.assigns.action_to_perform}"
             )}

          {:ok, params, _} ->
            {:noreply,
             socket
             |> assign(
               :payment_error,
               "An error occured while processing the payment, #{params["errorMessage"]} , please try again"
             )}

          {:error, "Request Timed Out"} ->
            {:noreply,
             socket
             |> assign(
               :payment_error,
               "An error occured while processing the payment, please try again"
             )}
        end

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(
           :payment_error,
           "An error occured while creating wallet deposit, please try again"
         )}
    end
  end

  defp create_wallet_deposit(mpesa_params, patient_id) do
    Medcamp.WalletDeposits.create_wallet_deposit(%{
      "phone_number" => "254" <> mpesa_params["formatted_phone_number"],
      "amount" => mpesa_params["amount"],
      "reason" => mpesa_params["reason"],
      "patient_id" => patient_id,
      "has_been_paid" => false
    })
  end
end
