defmodule MedcampWeb.DoctorsPages.EachPatientMchIndex do
  use MedcampWeb, :each_patient_live_view

  alias MedcampWeb.NursesPages.EachPatientMchIndex, as: SharedMch

  @impl true
  def mount(params, session, socket), do: SharedMch.mount(params, session, socket)

  @impl true
  def handle_params(%{"id" => patient_id}, url, socket) do
    SharedMch.handle_params(%{"patient_id" => patient_id}, url, socket)
  end

  @impl true
  def handle_event(event, params, socket), do: SharedMch.handle_event(event, params, socket)

  @impl true
  def render(assigns), do: SharedMch.render(assigns)
end
