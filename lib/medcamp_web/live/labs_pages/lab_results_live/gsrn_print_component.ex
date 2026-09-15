defmodule MedcampWeb.LabPagesLabResultLive.GsrnPrintComponent do
  use MedcampWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="col-span-full">
        <h3>GS1 GSRN - Lab Test Request</h3>
        <p>
          Print Data Matrix below for {[
            @patient.first_name,
            @patient.middle_name,
            @patient.last_name
          ]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")}
        </p>
        <hr class="bg-black h-[2px]" />
      </div>
      <div class="flex mt-5">
        <div class="w-[80%]  flex justify-center items-center">
          <div
            class="p-4 flex gap-2 flex-col items-start"
            id={"print-file-lab-#{@patient.gsrn}-#{@lab_result.id}"}
          >
            <div class="flex gap-2 items-start">
              <div class="flex flex-col gap-0">
                <div class="flex text-xs gap-0 items-center">
                  GS1 <span class="text-sm">&#174; </span>
                </div>
                <svg
                  id={"8018#{@patient.gsrn}"}
                  phx-hook="datamatrix"
                  class="datamatrix"
                  style="width: 70px; height: 70px; "
                >
                </svg>
              </div>
              <div class="flex w-[50%] text-sm flex-col gap-0">
                <p class="font-semibold">
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

                <%= if @test && @test.name do %>
                  <div class="mt-2">
                    <p class="text-xs font-medium text-slate-700 mb-1">Test Requested:</p>
                    <div class="flex flex-wrap gap-1">
                      <span class="text-xs  py-0.5 bg-slate-100 text-slate-700 rounded font-semibold">
                        {@test.name}
                      </span>
                    </div>
                  </div>
                <% end %>
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

          <.button
            phx-target={@myself}
            phx-click="print"
            phx-value-id={"print-file-lab-#{@patient.gsrn}-#{@lab_result.id}"}
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
