defmodule MedcampWeb.RequestRadiologyComponent do
  use MedcampWeb, :live_component
  alias Medcamp.RadiologyResults
  alias Medcamp.RadiologyTests
  alias Medcamp.Mpesas
  alias Medcamp.Pay
  alias Medcamp.Mpesas.Mpesa

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Request Radiology Tests for {[@patient.first_name, @patient.middle_name, @patient.last_name]
        |> Enum.filter(&(&1 != nil))
        |> Enum.join(" ")}
      </.header>

      <.simple_form
        :if={@page == :request_radiology_test}
        for={@form}
        id="radiology_result-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="flex flex-col gap-0">
          <.input
            field={@form[:query]}
            value={@searched_query}
            phx-change="search_radiology_test"
            type="text"
            label="Search Radiology Test"
          />
          <div :if={@selected_tests != []} class="flex flex-wrap my-4 gap-3">
            <%= for test <- @selected_tests do %>
              <div class="flex flex-row gap-2 rounded-md bg-gray-100 flex justify-center items-center p-2  rounded-md">
                {test.name} - KES {test.price} /=
                <p phx-click={"remove_radiology_test-#{test.id}"} phx-target={@myself}>
                  <Heroicons.icon
                    name="x-mark"
                    type="outline"
                    class="h-4 w-4 cursor-pointer text-darkblue"
                  />
                </p>
              </div>
            <% end %>
          </div>
          <div
            :if={@searched_radiology_tests != []}
            class="bg-gray-100 gap-2 p-2 h-[150px] overflow-y-auto"
          >
            <%= for option <- @searched_radiology_tests do %>
              <div
                phx-click="select_radiology_test"
                phx-target={@myself}
                phx-value-id={option.id}
                class="p-2 cursor-pointer border-b-[1px] hover:bg-gray-200"
              >
                {option.name} - KES {option.price} /=
              </div>
            <% end %>
          </div>
        </div>
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input
          field={@form[:urgency]}
          type="select"
          prompt="Select urgency"
          options={["Low", "Medium", "High"]}
        />
        <.input
          field={@form[:payment_type]}
          type="select"
          prompt="Select payment type"
          options={["Mpesa", "Insurance"]}
          label="Payment Type"
        />

        <:actions>
          <.button phx-disable-with="Saving...">Request Radiology Work</.button>
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
            value={Enum.sum(for test <- @selected_tests, do: test.price)}
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
  def update(%{radiology_result: radiology_result} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:searched_query, "")
     |> assign(:searched_radiology_tests, [])
     |> assign(:page, :request_radiology_test)
     |> assign(:radiology_result_params, %{})
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
       to_form(RadiologyResults.change_radiology_result(radiology_result))
     end)}
  end

  @impl true
  def handle_event("search_radiology_test", %{"radiology_result" => %{"query" => query}}, socket) do
    searched_radiology_tests =
      RadiologyTests.search_radiology_tests(query)
      |> Enum.filter(fn test ->
        test.id not in Enum.map(socket.assigns.selected_tests, & &1.id)
      end)

    {:noreply,
     socket
     |> assign(searched_query: query)
     |> assign(searched_radiology_tests: searched_radiology_tests)}
  end

  def handle_event("select_radiology_test", %{"id" => id}, socket) do
    radiology_test = RadiologyTests.get_radiology_test!(id)

    selected_tests =
      [radiology_test | socket.assigns.selected_tests]
      |> Enum.uniq_by(& &1.id)

    searched_radiology_tests =
      RadiologyTests.search_radiology_tests(socket.assigns.searched_query)
      |> Enum.filter(fn test ->
        test.id not in Enum.map(socket.assigns.selected_tests, & &1.id)
      end)

    {:noreply,
     socket
     |> assign(searched_radiology_tests: searched_radiology_tests)
     |> assign(selected_tests: selected_tests)}
  end

  def handle_event("remove_radiology_test-" <> id, _, socket) do
    selected_tests =
      socket.assigns.selected_tests |> Enum.reject(&(&1.id == String.to_integer(id)))

    searched_radiology_tests =
      RadiologyTests.search_radiology_tests(socket.assigns.searched_query)
      |> Enum.filter(fn test ->
        test.id not in Enum.map(socket.assigns.selected_tests, & &1.id)
      end)

    {:noreply,
     socket
     |> assign(searched_radiology_tests: searched_radiology_tests)
     |> assign(selected_tests: selected_tests)}
  end

  def handle_event("validate", %{"radiology_result" => radiology_result_params}, socket) do
    changeset =
      RadiologyResults.change_radiology_result(
        socket.assigns.radiology_result,
        radiology_result_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"radiology_result" => radiology_result_params}, socket) do
    tests =
      socket.assigns.selected_tests
      |> Enum.map(fn test ->
        %{
          name: test.name,
          price: test.price
        }
      end)

    radiology_result_params =
      radiology_result_params
      |> Map.put("patient_id", socket.assigns.patient.id)
      |> Map.put("doctor_id", socket.assigns.current_user.id)
      |> Map.put("doctor_note_id", socket.assigns.doctor_note.id)
      |> Map.put("scans", tests)

    if radiology_result_params["payment_type"] == "Insurance" do
      save_radiology_result(socket, socket.assigns.action, radiology_result_params)
    else
      mpesa_params = %{
        "formatted_phone_number" =>
          socket.assigns.patient.phone_number |> String.slice(1..-1//-1),
        "amount" => Enum.sum(for test <- tests, do: test.price)
      }

      changeset =
        Mpesas.change_trigger_mpesa(socket.assigns.mpesa, mpesa_params)

      {:noreply,
       socket
       |> assign(:radiology_result_params, radiology_result_params)
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
        {:ok, radiology_result} =
          RadiologyResults.create_radiology_result(socket.assigns.radiology_result_params)

        Mpesas.create_mpesa(%{
          "phone" => phone_number,
          "amount" => mpesa_params["amount"],
          "checkout_request_id" => params["CheckoutRequestID"],
          "merchant_request_id" => params["MerchantRequestID"],
          "actionable_id" => radiology_result.id,
          "actionable_type" => "create_radiology_result",
          "prompter_id" => socket.assigns.current_user.id,
          "patient_id" => socket.assigns.patient.id
        })

        {:noreply,
         socket
         |> put_flash(:info, "Payment triggered successfully")
         |> push_navigate(
           to:
             "/confirm?checkout_request_id=#{params["CheckoutRequestID"]}&return_url=#{socket.assigns.return_url}&action=create_radiology_result"
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

  defp save_radiology_result(socket, :request_radiology_test, radiology_result_params) do
    radiology_result_params =
      radiology_result_params
      |> Map.put("has_paid", true)

    case RadiologyResults.create_radiology_result(radiology_result_params) do
      {:ok, _radiology_result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Lab result created successfully and sent to the lab")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
