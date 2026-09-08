defmodule MedcampWeb.AdminUsersLive.StaffCodeComponent do
  use MedcampWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="col-span-full">
        <h3>GS1 GSRN</h3>
        <p>
          Print Data Matrix below for {[@user.email]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")}
        </p>
        <hr class="bg-black h-[2px]" />
      </div>
      <div class="flex">
        <div class=" pt-2 flex justify-between gap-8 items-center">
          <div class=" py-1 flex flex-col gap-0 text-xs rounded-full text-brand-primary font-medium">
            <p>GSRN:</p>
            <p>{@user.gsrn}</p>
          </div>

          <input
            type="text"
            id="text"
            value={"https://glocalhealthcentre.org/8017/#{@user.gsrn}"}
            class="hidden"
          />
        </div>
      </div>
      <div class="flex flex-col gap-1">
        <div class="flex text-xs gap-0 items-center">
          GS1 <span class="text-sm">&#174; </span>
        </div>

        <div class="w-[80px] h-[80px]">
          <div phx-hook="CardQrCode" phx-update="ignore" id="qrcode" class="rounded-md  " />
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
