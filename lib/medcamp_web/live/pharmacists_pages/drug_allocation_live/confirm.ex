defmodule MedcampWeb.DrugAllocationLive.ConfirmComponent do
  alias Medcamp.Mpesas
  alias Medcamp.Mpesas.Mpesa
  alias Medcamp.Pay
  alias Medcamp.DrugAllocations
  use MedcampWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Confirm And Prompt User for Payment
      </.header>
      <div class="flex flex-col gap-2">
        <p class="mb-4 font-semibold text-darkblue">
          Drugs To be Given to Patient
        </p>

        <%= for drug_given <- @drugs_given do %>
          <div class="flex flex-col gap-3 p-4 rounded-lg shadow-md bg-white border border-gray-200 mb-4">
            <div class="border-b border-gray-200 pb-2">
              <h3 class="font-semibold text-lg text-gray-800">Drug Information</h3>
            </div>

            <div class="grid grid-cols-2 gap-2">
              <div class="flex flex-col">
                <span class="text-sm text-gray-500">Brand Name</span>
                <span class="font-medium text-gray-900">{drug_given.complete_info.brand_name}</span>
              </div>

              <div class="flex flex-col">
                <span class="text-sm text-gray-500">Generic Name</span>
                <span class="font-medium text-gray-900">{drug_given.complete_info.generic_name}</span>
              </div>

              <div class="flex flex-col">
                <span class="text-sm text-gray-500">Quantity</span>
                <span class="font-medium text-gray-900">{drug_given.complete_info.quantity}</span>
              </div>

              <div class="flex flex-col">
                <span class="text-sm text-gray-500">Price</span>
                <span class="font-medium text-gray-900">KES {drug_given.complete_info.price} /=</span>
              </div>
            </div>
          </div>
        <% end %>

        <p>
          Total Price is KES {Enum.sum(for drug <- @drugs_given, do: drug.complete_info.price)} /=
        </p>

        <%= if @drug_allocation.payment_type == "Insurance" do %>
          <div class="mt-4 rounded-lg border border-blue-200 bg-blue-50 p-4">
            <div class="flex items-center gap-2 mb-3">
              <Heroicons.icon name="shield-check" type="outline" class="h-5 w-5 text-blue-600" />
              <p class="font-semibold text-blue-800">Insurance Payment</p>
            </div>
            <%= if @drug_allocation.insurance_name do %>
              <p class="text-sm text-blue-700 mb-3">
                Insurer: <span class="font-semibold">{@drug_allocation.insurance_name}</span>
              </p>
            <% end %>
            <p class="text-sm text-blue-600 mb-4">
              This allocation is covered by insurance. Click below to mark as paid and dispense the drugs.
            </p>
            <button
              phx-click="mark_insurance_paid"
              phx-target={@myself}
              phx-disable-with="Processing..."
              class="w-full rounded-md bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            >
              Mark as Paid by Insurance & Dispense
            </button>
          </div>
        <% else %>
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
            id="drug-allocation-form"
            phx-target={@myself}
            phx-change="validate"
            phx-submit="save"
          >
            <.phone_number_input
              field={@form[:formatted_phone_number]}
              type="number"
              class="w-[100%]"
              value={@formatted_patient_number}
              required={true}
            />
            <.input
              field={@form[:amount]}
              value={Enum.sum(for drug <- @drugs_given, do: drug.complete_info.price)}
              type="number"
              readonly
              label="Amount"
            />

            <:actions>
              <%= if @form.source.valid? == false do %>
                <.button class="cursor-not-allowed" disabled>Confirm And Prompt Patient</.button>
              <% else %>
                <.button phx-disable-with="Saving...">
                  Confirm And Prompt Patient
                </.button>
              <% end %>
            </:actions>
          </.simple_form>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    mpesa_params = %{
      "formatted_phone_number" => assigns.patient.phone_number |> String.slice(1..-1//-1),
      "amount" => Enum.sum(for drug <- assigns.drugs_given, do: drug.complete_info.price)
    }

    changeset =
      Mpesas.change_trigger_mpesa(%Mpesa{}, mpesa_params)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:payment_error, nil)
     |> assign(
       :formatted_patient_number,
       assigns.patient.phone_number |> String.slice(1..-1//-1)
     )
     |> assign(:mpesa, %Mpesa{})
     |> assign(:form, to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("mark_insurance_paid", _params, socket) do
    drug_allocation = socket.assigns.drug_allocation
    total = Enum.sum(for drug <- socket.assigns.drugs_given, do: drug.complete_info.price)

    case DrugAllocations.update_drug_allocation(drug_allocation, %{
           "has_paid" => true,
           "has_been_assigned" => true,
           "total_amount_paid" => total
         }) do
      {:ok, _updated} ->
        {:noreply,
         socket
         |> put_flash(:info, "Insurance payment confirmed. Drugs dispensed successfully.")
         |> push_navigate(to: "/pharmacist/drug_allocations/#{drug_allocation.id}")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(:payment_error, "Failed to confirm insurance payment. Please try again.")}
    end
  end

  @impl true
  def handle_event("clear_payment_error", _, socket) do
    {:noreply, assign(socket, :payment_error, nil)}
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

  def handle_event("save", %{"mpesa" => mpesa_params}, socket) do
    phone_number = "254" <> mpesa_params["formatted_phone_number"]

    case Pay.make_request(mpesa_params["amount"], phone_number) do
      {:ok, params, 200} ->
        Mpesas.create_mpesa(%{
          "phone" => phone_number,
          "amount" => mpesa_params["amount"],
          "checkout_request_id" => params["CheckoutRequestID"],
          "merchant_request_id" => params["MerchantRequestID"],
          "actionable_id" => socket.assigns.drug_allocation.id,
          "actionable_type" => "create_drug_allocation",
          "prompter_id" => socket.assigns.current_user.id,
          "patient_id" => socket.assigns.drug_allocation.patient_id
        })

        {:noreply,
         socket
         |> put_flash(:info, "Payment triggered successfully")
         |> push_navigate(
           to:
             "/confirm?checkout_request_id=#{params["CheckoutRequestID"]}&return_url=#{"/pharmacist/drug_allocations/#{socket.assigns.drug_allocation.id}"}&action=create_drug_allocation"
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
  end
end
