defmodule MedcampWeb.RequestLabComponent do
  use MedcampWeb, :live_component
  alias Medcamp.LabResults
  alias Medcamp.LabTests
  alias Medcamp.LabTests.LabTest
  alias Medcamp.Mpesas
  alias Medcamp.Pay
  alias Medcamp.Mpesas.Mpesa

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Request Lab Work for {[@patient.first_name, @patient.middle_name, @patient.last_name]
        |> Enum.filter(&(&1 != nil))
        |> Enum.join(" ")}
      </.header>

      <.simple_form
        :if={@page == :request_lab}
        for={@form}
        id="lab_result-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="flex flex-col gap-0">
          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700 mb-1">Lab payment</label>
            <select
              name="lab_payment_type"
              phx-change="change_lab_payment_type"
              phx-target={@myself}
              class="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 focus:border-[#6667ab] focus:ring-[#6667ab]"
            >
              <option value="full" selected={@lab_payment_type == "full"}>Full payment</option>
              <option value="subsidized" selected={@lab_payment_type == "subsidized"}>
                Subsidized for students (30% off)
              </option>
            </select>
          </div>
          <.input
            field={@form[:query]}
            value={@searched_query}
            phx-change="search_lab_test"
            type="text"
            label="Search Lab Test"
          />
          <div :if={@selected_tests != []} class="flex flex-wrap my-4 gap-3">
            <%= for test <- @selected_tests do %>
              <div class="flex flex-row gap-2 rounded-md bg-gray-100 flex justify-center items-center p-2  rounded-md">
                {test.name} - KES {LabTest.price_for_payment_type(test, @lab_payment_type)} /=
                <p phx-click={"remove_lab_test-#{test.id}"} phx-target={@myself}>
                  <Heroicons.icon
                    name="x-mark"
                    type="outline"
                    class="h-4 w-4 cursor-pointer text-darkblue"
                  />
                </p>
              </div>
            <% end %>
          </div>
          <div :if={@searched_lab_tests != []} class="bg-gray-100 gap-2 p-2 h-[150px] overflow-y-auto">
            <%= for option <- @searched_lab_tests do %>
              <div
                phx-click="select_lab_test"
                phx-target={@myself}
                phx-value-id={option.id}
                class="p-2 cursor-pointer border-b-[1px] hover:bg-gray-200"
              >
                {option.name} - KES {LabTest.price_for_payment_type(option, @lab_payment_type)} /=
              </div>
            <% end %>
          </div>
        </div>
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input
          field={@form[:urgency]}
          type="select"
          prompt="Select urgency"
          options={[
            {"High (Red)", "High"},
            {"Medium (Amber)", "Medium"},
            {"Low (Green)", "Low"}
          ]}
        />
        <.input
          field={@form[:payment_type]}
          type="select"
          prompt="Select payment type"
          options={["Mpesa", "Insurance"]}
          label="Payment Type"
        />

        <%= if @payment_type == "Insurance" do %>
          <.input
            field={@form[:insurance_name]}
            type="select"
            prompt="Select insurer"
            options={insurance_providers()}
            label="Insurance Provider"
            required={true}
          />
        <% end %>

        <:actions>
          <.button phx-disable-with="Saving...">Request Lab Work</.button>
        </:actions>
      </.simple_form>

      <div :if={@page == :trigger_payment}>
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
          for={@mpesa_form}
          id="patient_visit-form"
          phx-target={@myself}
          phx-change="validate_mpesa"
          phx-submit="save_mpesa"
        >
          <.phone_number_input
            field={@mpesa_form[:formatted_phone_number]}
            type="number"
            class="w-[100%]"
            required={true}
            value={@formatted_patient_number}
          />

          <.input
            field={@mpesa_form[:amount]}
            value={
              Enum.sum(
                for test <- @selected_tests,
                    do: LabTest.price_for_payment_type(test, @lab_payment_type)
              )
            }
            type="number"
            readonly
            label="Amount"
          />

          <:actions>
            <%= if @mpesa_form.source.valid? == false do %>
              <.button class="cursor-not-allowed" disabled>Trigger Payment</.button>
            <% else %>
              <.button phx-disable-with="Saving...">
                Trigger Payment
              </.button>
            <% end %>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{lab_result: lab_result} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:searched_query, "")
     |> assign(:searched_lab_tests, [])
     |> assign(:page, :request_lab)
     |> assign(:lab_payment_type, assigns[:lab_payment_type] || "full")
     |> assign(:payment_type, assigns[:payment_type] || lab_result.payment_type || "")
     |> assign(:lab_result_params, %{})
     |> assign(:selected_tests, [])
     |> assign(:payment_error, nil)
     |> assign(:mpesa, %Mpesa{})
     |> assign(
       :formatted_patient_number,
       assigns.patient.phone_number |> String.slice(1..-1//-1)
     )
     |> assign_new(:mpesa_form, fn ->
       to_form(Mpesas.change_trigger_mpesa(%Mpesa{}))
     end)
     |> assign_new(:form, fn ->
       to_form(LabResults.change_lab_result(lab_result))
     end)}
  end

  @impl true
  def handle_event("change_lab_payment_type", %{"lab_payment_type" => type}, socket) do
    {:noreply, assign(socket, :lab_payment_type, type)}
  end

  def handle_event("search_lab_test", %{"lab_result" => %{"query" => query}}, socket) do
    searched_lab_tests =
      LabTests.search_lab_tests(query)
      |> Enum.filter(fn test ->
        test.id not in Enum.map(socket.assigns.selected_tests, & &1.id)
      end)

    {:noreply,
     socket
     |> assign(searched_query: query)
     |> assign(searched_lab_tests: searched_lab_tests)}
  end

  def handle_event("select_lab_test", %{"id" => id}, socket) do
    lab_test = LabTests.get_lab_test!(id)

    selected_tests =
      [lab_test | socket.assigns.selected_tests]
      |> Enum.uniq_by(& &1.id)

    searched_lab_tests =
      LabTests.search_lab_tests(socket.assigns.searched_query)
      |> Enum.filter(fn test ->
        test.id not in Enum.map(selected_tests, & &1.id)
      end)

    {:noreply,
     socket
     |> assign(searched_lab_tests: searched_lab_tests)
     |> assign(selected_tests: selected_tests)}
  end

  def handle_event("remove_lab_test-" <> id, _, socket) do
    selected_tests =
      socket.assigns.selected_tests |> Enum.reject(&(&1.id == String.to_integer(id)))

    searched_lab_tests =
      LabTests.search_lab_tests(socket.assigns.searched_query)
      |> Enum.filter(fn test ->
        test.id not in Enum.map(selected_tests, & &1.id)
      end)

    {:noreply,
     socket
     |> assign(searched_lab_tests: searched_lab_tests)
     |> assign(selected_tests: selected_tests)}
  end

  def handle_event("validate", %{"lab_result" => lab_result_params}, socket) do
    payment_type = lab_result_params["payment_type"] || socket.assigns.payment_type

    lab_payment_type =
      if payment_type == "Insurance", do: "subsidized", else: socket.assigns.lab_payment_type

    changeset = LabResults.change_lab_result(socket.assigns.lab_result, lab_result_params)

    {:noreply,
     socket
     |> assign(:payment_type, payment_type)
     |> assign(:lab_payment_type, lab_payment_type)
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"lab_result" => lab_result_params}, socket) do
    payment_type = lab_result_params["payment_type"] || socket.assigns.payment_type

    lab_payment_type =
      if payment_type == "Insurance",
        do: "subsidized",
        else: socket.assigns.lab_payment_type || "full"

    tests =
      socket.assigns.selected_tests
      |> Enum.map(fn test ->
        price = LabTest.price_for_payment_type(test, lab_payment_type)

        %{
          name: test.name,
          price: price
        }
      end)

    lab_result_params =
      lab_result_params
      |> Map.put("patient_id", socket.assigns.patient.id)
      |> Map.put("doctor_id", socket.assigns.current_user.id)
      |> Map.put("doctor_note_id", socket.assigns.doctor_note.id)
      |> Map.put("tests", tests)

    if lab_result_params["payment_type"] == "Insurance" do
      save_lab_result(socket, socket.assigns.action, lab_result_params)
    else
      mpesa_params = %{
        "formatted_phone_number" =>
          socket.assigns.patient.phone_number |> String.slice(1..-1//-1),
        "amount" => Enum.sum(for test <- tests, do: test[:price])
      }

      changeset =
        Mpesas.change_trigger_mpesa(socket.assigns.mpesa, mpesa_params)

      {:noreply,
       socket
       |> assign(:lab_result_params, lab_result_params)
       |> assign(mpesa_form: to_form(changeset, action: :validate))
       |> assign(:page, :trigger_payment)}
    end
  end

  def handle_event("validate_mpesa", %{"mpesa" => mpesa_params}, socket) do
    changeset =
      Mpesas.change_trigger_mpesa(socket.assigns.mpesa, mpesa_params)

    {:noreply,
     socket
     |> assign(:payment_error, nil)
     |> assign(mpesa_form: to_form(changeset, action: :validate))}
  end

  def handle_event("clear_payment_error", _, socket) do
    {:noreply, assign(socket, payment_error: nil)}
  end

  def handle_event("save_mpesa", %{"mpesa" => mpesa_params}, socket) do
    phone_number = "254" <> mpesa_params["formatted_phone_number"]

    case Pay.make_request(mpesa_params["amount"], phone_number) do
      {:ok, params, 200} ->
        {:ok, lab_result} = LabResults.create_lab_result(socket.assigns.lab_result_params)

        Mpesas.create_mpesa(%{
          "phone" => phone_number,
          "amount" => mpesa_params["amount"],
          "checkout_request_id" => params["CheckoutRequestID"],
          "merchant_request_id" => params["MerchantRequestID"],
          "actionable_id" => lab_result.id,
          "actionable_type" => "create_lab_result",
          "prompter_id" => socket.assigns.current_user.id,
          "patient_id" => socket.assigns.patient.id
        })

        {:noreply,
         socket
         |> put_flash(:info, "Payment triggered successfully")
         |> push_navigate(
           to:
             "/confirm?checkout_request_id=#{params["CheckoutRequestID"]}&return_url=#{socket.assigns.return_url}&action=create_lab_result"
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

  defp save_lab_result(socket, :request_lab, lab_result_params) do
    total =
      (lab_result_params["tests"] || [])
      |> Enum.reduce(0, fn t, acc -> acc + (t[:price] || t["price"] || 0) end)

    lab_result_params =
      lab_result_params
      |> Map.put("has_paid", true)
      |> Map.put("total_amount_paid", total)

    case LabResults.create_lab_result(lab_result_params) do
      {:ok, _lab_result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Lab result created successfully and sent to the lab")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp insurance_providers do
    [
      "Human Development Fund ( HDF )",
      "GHCE",
      "Altiora School"
    ]
  end
end
