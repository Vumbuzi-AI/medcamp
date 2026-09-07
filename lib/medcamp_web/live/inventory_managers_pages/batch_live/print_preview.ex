defmodule MedcampWeb.BatchLive.PrintPreview do
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
        <div class="flex w-[100%] mt-4">
          <div class="w-[100%]   flex justify-center items-center">
            <div class=" p-4 w-[100%]  flex gap-1 flex-col items-start" id={"print-file-#{@batch.id}"}>
              <div class=" text-xs  flex justify-between max-w-[800px] text-sm">
                <div class="flex flex-col w-[100%] gap-0">
                  <div class="flex gap-0 items-center" style="font-size: 10px;">
                    GS1 <span style="font-size: 10px;">&#174; </span>
                  </div>
                  <svg
                    id={@svg_id}
                    phx-hook="datamatrix"
                    class={"#{@batch.batch} datamatrix"}
                    style="width: 70px; height: 70px; "
                  >
                  </svg>
                </div>
                <div class="flex w-[60%]  flex-col gap-0" style="font-size: 10px;">
                  <div class="flex w-[100%] text-xs flex-col gap-1">
                    <div style="font-size: 10px;" class="w-[100%] flex gap-1">
                      <span> (01) </span> {@batch.gtin}
                    </div>
                    <div style="font-size: 10px;" class="w-[100%] flex gap-1">
                      <span> (10) </span> {@batch.batch}
                    </div>
                    <div style="font-size: 10px;" class="w-[100%] flex gap-1">
                      <span>(17) </span> {parse_and_convert(@batch.expiry)}
                    </div>

                    <p style="font-size: 10px;">
                      <span> (11) </span> {convert_date(@batch.manufacture_date)}
                    </p>

                    <p :if={@batch.serial} style="font-size: 10px;">
                      <span> (21) </span> {maybe_add_serial(@batch)}
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

            <.button phx-target={@myself} phx-click="print" phx-value-id={"print-file-#{@batch.id}"}>
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
    gs = <<29>>

    assigns.batch.manufacture_date
    assigns.batch.expiry

    # Format dates as YYMMDD
    manufacture_date = format_date_yymmdd(assigns.batch.manufacture_date)
    expiry_date = format_date_yymmdd(assigns.batch.expiry)

    svg_id =
      "#{gs}010" <>
        assigns.batch.inventory_received.gtin <>
        "10" <>
        assigns.batch.batch <>
        "#{gs}11" <>
        manufacture_date <>
        "#{gs}17" <>
        expiry_date <>
        "#{gs}21" <> maybe_add_serial(assigns.batch)

    {:ok,
     socket
     |> assign(:svg_id, svg_id)
     |> assign(assigns)}
  end

  # Helper function to format Date or string as YYMMDD
  defp format_date_yymmdd(%Date{} = date) do
    year = date.year |> rem(100) |> Integer.to_string() |> String.pad_leading(2, "0")
    month = date.month |> Integer.to_string() |> String.pad_leading(2, "0")
    day = date.day |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{year}#{month}#{day}"
  end

  defp format_date_yymmdd(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> format_date_yymmdd(date)
      # fallback if parsing fails
      _ -> date_string
    end
  end

  @impl true

  def handle_event("print", %{"id" => id, "value" => _value}, socket) do
    {:noreply, push_event(socket, "printDiv", %{id: id})}
  end

  defp convert_date(nil) do
    ""
  end

  defp convert_date(date) do
    Timex.format!(date, "{YY} {0M} {0D}")
  end

  def parse_and_convert(nil) do
    ""
  end

  def parse_and_convert(date) do
    date = Timex.parse!(date, "{YYYY}-{0M}-{0D}")
    Timex.format!(date, "{YY} {0M} {0D}")
  end

  def maybe_add_serial(batch) do
    if batch.serial do
      batch.serial
    else
      ""
    end
  end
end
