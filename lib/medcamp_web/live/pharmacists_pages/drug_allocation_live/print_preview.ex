defmodule MedcampWeb.DrugAllocationLive.PrintPreviewComponent do
  use MedcampWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="col-span-full">
        <p>
          Print Prescription for {@complete_info.generic_name} ({@complete_info.brand_name})
        </p>
        <hr class="bg-black h-[2px]" />
      </div>
      <div class="flex">
        <div class="w-[80%]   flex justify-center items-center">
          <div class=" p-4  flex gap-2 flex-col items-start" id={"print-file-#{@complete_info.id}"}>
            <div class="border text-xs border-black w-full max-w-[350px] p-3 text-sm">
              {[
                @patient.first_name,
                @patient.middle_name,
                @patient.last_name
              ]
              |> Enum.filter(&(&1 != nil))
              |> Enum.join(" ")}
              <p class="border-black border-b-[1px] w-full mt-1 mb-1"></p>
              <div class="  mb-2">
                {@complete_info.brand_name} ({@complete_info.generic_name})
              </div>

              <div class="flex flex-col gap-1 mb-2">
                <p>Qty: {@complete_info.quantity} {@complete_info.unit_of_measurement}</p>
                <p>{@complete_info.frequency} for {@complete_info.duration_in_days} days</p>
                <p>Route: {@complete_info.route_of_administration}</p>
                <p>{@complete_info.prescription_note || ""}</p>
                <p>{@complete_info.pharmacist_note || ""}</p>
              </div>

              <p class="border-black border-b-[1px] w-full mt-1 mb-1"></p>
              <div class="text-xs">
                <p>Date: {Calendar.strftime(@complete_info.inserted_at, "%d/%m/%Y")}</p>
              </div>
            </div>
          </div>
        </div>
        <div class="w-[40%]">
          <a
            href="#"
            class="fa fa-download bg-green-500 hover:bg-green-400 text-white font-bold py-2 px-4 border-b-4 border-blue-700 hover:border-blue-500 rounded"
            style="font-size: 15px;"
            download
          >
          </a>

          <.button
            phx-target={@myself}
            phx-click="print"
            phx-value-id={"print-file-#{@complete_info.id}"}
          >
            Print
          </.button>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def handle_event("print", %{"id" => id, "value" => _value}, socket) do
    {:noreply, push_event(socket, "printDiv", %{id: id})}
  end
end
