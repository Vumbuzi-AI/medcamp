defmodule MedcampWeb.LabPagesLabResultLive.PrintPreviewComponent do
  use MedcampWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div>
        <div class="col-span-full">
          <p></p>
          <hr class="bg-black h-[2px]" />
        </div>
        <div class="flex">
          <div class="w-[100%]   flex justify-center items-center">
            <div class=" p-4 w-[100%]  flex gap-1 flex-col items-start" id={"print-file-#{@uuid}"}>
              <div class=" text-xs  flex justify-between max-w-[450px] text-sm">
                <div class="flex flex-col gap-0">
                  <div class="flex gap-0 items-center" style="font-size: 10px;">
                    GS1 <span style="font-size: 10px;">&#174; </span>
                  </div>
                  <svg
                    id={"8018" <> (@patient.gsrn) <> "21" <> @uuid}
                    phx-hook="datamatrix"
                    class="datamatrix"
                    style="width: 70px; height: 70px; "
                  >
                  </svg>
                </div>
                <div class="flex w-[60%]  flex-col gap-0" style="font-size: 10px;">
                  <p>
                    {[
                      @patient.first_name,
                      @patient.middle_name,
                      @patient.last_name
                    ]
                    |> Enum.filter(&(&1 != nil))
                    |> Enum.join(" ")}
                  </p>

                  <p>
                    {@patient.age} | {@patient.gender}
                  </p>
                  <div class="flex text-xs flex-col gap-1">
                    <p class="font-bold" style="font-size: 10px;">
                      (8018) {@patient.gsrn}
                    </p>
                    <p style="font-size: 10px;">
                      (21) {@uuid}
                    </p>
                  </div>
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

            <.button phx-target={@myself} phx-click="print" phx-value-id={"print-file-#{@uuid}"}>
              Print
            </.button>
          </div>
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
