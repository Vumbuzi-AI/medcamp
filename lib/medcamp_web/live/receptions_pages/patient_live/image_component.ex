defmodule MedcampWeb.ReceptionsPagePatientLive.ImageComponent do
  use MedcampWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- Data Matrix Section --%>
      <div class="col-span-full">
        <h3>GS1 GSRN</h3>
        <p>
          Print Data Matrix below for {[@patient.first_name, @patient.middle_name, @patient.last_name]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")}
        </p>
        <hr class="bg-black h-[2px]" />
      </div>
      <div class="flex flex-col mt-5 md:flex-row">
        <div class="w-full md:w-4/5 flex justify-center items-center">
          <div class="p-4 flex gap-2 flex-col items-start" id={"print-file#{@patient.gsrn}"}>
            <div class="flex gap-2 items-start">
              <div class="flex flex-col gap-0">
                <svg
                  id={"https://glocalhealthcentre.org/8018/#{@patient.gsrn}"}
                  phx-hook="datamatrix"
                  class="datamatrix"
                  style="width: 70px; height: 70px; "
                >
                </svg>
              </div>
              <div class="flex w-[50%] text-sm flex-col gap-0">
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
                  {@patient.date_of_birth}
                </p>
                <p>
                  {@patient.age} | {@patient.gender}
                </p>
              </div>
            </div>
            <p class="border-black mt-3 border-b-[2px] w-full" />

            <p class="text-xs font-bold">
              (8018) {@patient.gsrn}
            </p>
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

          <.button phx-target={@myself} phx-click="print" phx-value-id={"print-file#{@patient.gsrn}"}>
            Print
          </.button>
        </div>
      </div>

      <%!-- Medical Camp QR Code Section
      <div class="mt-6">
        <div class="col-span-full">
          <h3>Medical Camp QR Code</h3>
          <p>
            Print QR Code below for {[@patient.first_name, @patient.middle_name, @patient.last_name]
            |> Enum.filter(&(&1 != nil))
            |> Enum.join(" ")}
          </p>
          <hr class="bg-black h-[2px]" />
        </div>
        <div class="flex flex-col md:flex-row">
          <div class="w-full md:w-4/5 flex justify-center items-center">
            <div class="p-4 flex gap-2 flex-col items-start" id={"print-qr-camp-#{@patient.gsrn}"}>
              <div class="flex gap-2 items-start">
                <div class="flex flex-col gap-0">
                  <div class="flex text-xs gap-0 items-center">
                    GS1 <span class="text-sm">&#174; </span>
                  </div>
                  <div
                    id={"medical-camp-qr-#{@patient.gsrn}"}
                    phx-hook="MedicalCampQrCode"
                    data-url={"https://glocalhealthcentre.org/8018/#{@patient.gsrn}/medical-camp"}
                    style="width: 70px; height: 70px;"
                  >
                  </div>
                </div>
                <div class="flex text-sm flex-col gap-0">
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
                    {@patient.date_of_birth}
                  </p>
                  <p>
                    {@patient.age} | {@patient.gender}
                  </p>
                </div>
              </div>
              <p class="border-black mt-3 border-b-[2px] w-full" />

              <p class="text-xs font-bold">
                (8018) {@patient.gsrn}
              </p>
            </div>
          </div>
          <div class="w-full md:w-2/5 mt-4 md:mt-0">
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
              phx-value-id={"print-qr-camp-#{@patient.gsrn}"}
            >
              Print
            </.button>
          </div>
        </div>
      </div> --%>
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
