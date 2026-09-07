defmodule Medcamp.Procurement.References do
  @moduledoc """
  Generates padded sequential references for procurement resources.

  Format: `PREFIX-YYYY-NNNNN` (5-digit padded, yearly sequence).
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Suppliers.Supplier

  alias Medcamp.Procurement.{
    Rfq,
    Quote,
    ProformaInvoice,
    PurchaseOrder,
    Invoice,
    ShipmentAdvice,
    GoodsReceivedNote
  }

  @pad 5

  @prefixes %{
    supplier: "SUP",
    rfq: "RFQ",
    quote: "QT",
    proforma_invoice: "PI",
    purchase_order: "PO",
    invoice: "INV",
    shipment_advice: "SA",
    grn: "GRN"
  }

  def prefix(kind) when is_map_key(@prefixes, kind), do: Map.fetch!(@prefixes, kind)

  def next_supplier_reference, do: build(:supplier, Supplier)
  def next_rfq_reference, do: build(:rfq, Rfq)
  def next_quote_reference, do: build(:quote, Quote)
  def next_proforma_invoice_reference, do: build(:proforma_invoice, ProformaInvoice)
  def next_purchase_order_reference, do: build(:purchase_order, PurchaseOrder)
  def next_invoice_reference, do: build(:invoice, Invoice)
  def next_shipment_advice_reference, do: build(:shipment_advice, ShipmentAdvice)
  def next_grn_reference, do: build(:grn, GoodsReceivedNote)

  defp build(kind, schema) do
    year = Date.utc_today().year
    pfx = Map.fetch!(@prefixes, kind)
    like = "#{pfx}-#{year}-%"

    count =
      from(r in schema, where: like(r.reference, ^like))
      |> Repo.aggregate(:count, :id)

    seq = (count + 1) |> Integer.to_string() |> String.pad_leading(@pad, "0")
    "#{pfx}-#{year}-#{seq}"
  end
end
