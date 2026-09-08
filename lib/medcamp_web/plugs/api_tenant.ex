defmodule MedcampWeb.Plugs.ApiTenant do
  @moduledoc """
  Establishes the organisation for the pharmacy scan API.

  These endpoints are called by the handheld scanner and carry no session, so
  the tenant has to come out of the scanned payload itself: a `drug_given_id`,
  or a GTIN and batch number (either given directly or encoded in a GS1
  DataMatrix).

  Ids are globally unique, so resolving by `drug_given_id` is unambiguous. A
  GTIN and batch number are not - two organisations may legitimately stock the
  same manufacturer's batch - so when a payload matches batches in more than
  one organisation this refuses the request rather than picking one. Guessing
  would mean dispensing against another organisation's stock.
  """

  import Plug.Conn

  import Ecto.Query, only: [from: 2]

  alias Medcamp.Batches.Batch
  alias Medcamp.DataMatrixParser
  alias Medcamp.DrugsGiven.DrugGiven
  alias Medcamp.Repo
  alias Medcamp.Tenancy

  @unscoped [skip_org_id: true]

  def init(opts), do: opts

  def call(conn, _opts) do
    case resolve(conn.params) do
      {:ok, org_id} ->
        Tenancy.put_org_id(org_id)
        assign(conn, :organisation_id, org_id)

      :not_found ->
        # Let the action answer with its own 404 shape rather than inventing
        # a second one here.
        conn

      :ambiguous ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          409,
          Jason.encode!(%{
            ok: false,
            error: "This code matches stock in more than one organisation"
          })
        )
        |> halt()
    end
  end

  defp resolve(%{"drug_given_id" => id}) do
    case Repo.one(from(d in DrugGiven, where: d.id == ^id, select: d.organisation_id), @unscoped) do
      nil -> :not_found
      org_id -> {:ok, org_id}
    end
  end

  defp resolve(%{"gtin" => gtin, "batch" => batch})
       when is_binary(gtin) and is_binary(batch) do
    from(b in Batch,
      left_join: ir in assoc(b, :inventory_received),
      where:
        b.batch == ^batch and
          (fragment("lpad(?, 14, '0')", b.gtin) == ^gtin or
             fragment("lpad(?, 14, '0')", ir.gtin) == ^gtin),
      distinct: true,
      select: b.organisation_id
    )
    |> Repo.all(@unscoped)
    |> one_organisation()
  end

  defp resolve(%{"datamatrix" => datamatrix}) when is_binary(datamatrix) do
    case DataMatrixParser.extract_gtin(datamatrix) do
      gtin when is_binary(gtin) -> resolve_by_gtin(gtin)
      _ -> :not_found
    end
  end

  defp resolve(_params), do: :not_found

  defp resolve_by_gtin(gtin) do
    from(b in Batch,
      left_join: ir in assoc(b, :inventory_received),
      where:
        fragment("lpad(?, 14, '0')", b.gtin) == ^gtin or
          fragment("lpad(?, 14, '0')", ir.gtin) == ^gtin,
      distinct: true,
      select: b.organisation_id
    )
    |> Repo.all(@unscoped)
    |> one_organisation()
  end

  defp one_organisation([org_id]), do: {:ok, org_id}
  defp one_organisation([]), do: :not_found
  defp one_organisation(_many), do: :ambiguous
end
