defmodule MedcampWeb.PublicTenant do
  @moduledoc """
  Establishes the tenant on the routes that have no session to read it from.

  The public camp pages are reached by scanning a card - `/8017/:gsrn`,
  `/8018/:gsrn`, `/8018/:gsrn/medical-camp/...` - and the pharmacy scan API is
  called with a GS1 DataMatrix payload. In both cases the scanned record is
  what tells us which organisation we are in, so it has to be looked up
  unscoped and the organisation set from it before anything else runs.

  GSRNs are globally unique, which is what makes this safe: a given code
  resolves to exactly one organisation's record or to nothing at all.
  """

  alias Medcamp.Organisations
  alias Medcamp.Patients
  alias Medcamp.Tenancy

  @doc """
  Resolves a patient from a scanned GSRN and enters their organisation.

  Returns `{:ok, patient, organisation}`, or `:error` when the code matches no
  patient. The organisation is left set on the process, so every subsequent
  query in this request or LiveView is scoped to it.
  """
  def resolve_patient(gsrn) when is_binary(gsrn) do
    with %{organisation_id: org_id} = patient when not is_nil(org_id) <-
           Patients.resolve_patient_by_gsrn(gsrn) do
      Tenancy.put_org_id(org_id)
      {:ok, patient, Organisations.get_organisation(org_id)}
    else
      _ -> :error
    end
  end

  def resolve_patient(_), do: :error

  @doc """
  Same as `resolve_patient/1` but returns just the patient, or `nil`.

  For the camp pages that only need the patient and already handle (or crash
  on) an unknown code the same way they did before tenancy existed.
  """
  def resolve_patient!(gsrn) do
    case resolve_patient(gsrn) do
      {:ok, patient, _organisation} -> patient
      :error -> nil
    end
  end

  @doc """
  Enters `organisation_id`'s tenant and returns the organisation.

  For entry points that already hold a record carrying an organisation - the
  scan API resolving a drug batch, say - rather than a GSRN.
  """
  def enter(organisation_id) when is_integer(organisation_id) do
    Tenancy.put_org_id(organisation_id)
    Organisations.get_organisation(organisation_id)
  end

  def enter(_), do: nil

  @doc """
  Assigns `:patient` and `:current_organisation` on a LiveView socket from a
  scanned GSRN, or `nil` for both when the code is unknown.

  The branding in the camp layout reads `@current_organisation`, so a camp
  page reached by scan wears the right organisation's colours even though
  nobody is logged in.
  """
  def assign_from_gsrn(socket, gsrn) do
    case resolve_patient(gsrn) do
      {:ok, patient, organisation} ->
        Phoenix.Component.assign(socket, patient: patient, current_organisation: organisation)

      :error ->
        Phoenix.Component.assign(socket, patient: nil, current_organisation: nil)
    end
  end
end
