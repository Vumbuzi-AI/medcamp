defmodule Medcamp.Procurement.Dashboard do
  @moduledoc """
  Aggregates used by the supplier and procurement dashboards.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Suppliers.Supplier

  alias Medcamp.Procurement.{
    Rfq,
    RfqInvitation,
    Quote,
    PurchaseOrder,
    Invoice,
    ShipmentAdvice,
    GoodsReceivedNote
  }

  # ---------------------------------------------------------------------------
  # Supplier dashboard
  # ---------------------------------------------------------------------------

  @doc """
  Stats for a single supplier: open RFQs, submitted quotes, open POs, pending
  invoices, and the next RFQ deadline.
  """
  def supplier_stats(supplier_id) do
    today = Date.utc_today()

    open_rfqs =
      from(r in Rfq,
        join: inv in RfqInvitation,
        on: inv.rfq_id == r.id,
        where: inv.supplier_id == ^supplier_id and r.status == "sent"
      )
      |> Repo.aggregate(:count, :id)

    submitted_quotes =
      from(q in Quote, where: q.supplier_id == ^supplier_id and q.status != "rejected")
      |> Repo.aggregate(:count, :id)

    open_pos =
      from(p in PurchaseOrder,
        where: p.supplier_id == ^supplier_id and p.status in ["sent", "acknowledged"]
      )
      |> Repo.aggregate(:count, :id)

    pending_invoices =
      from(i in Invoice,
        where: i.supplier_id == ^supplier_id and i.status in ["submitted", "pending_grn"]
      )
      |> Repo.aggregate(:count, :id)

    next_deadline =
      from(r in Rfq,
        join: inv in RfqInvitation,
        on: inv.rfq_id == r.id,
        where:
          inv.supplier_id == ^supplier_id and r.status == "sent" and
            r.quote_deadline >= ^today,
        order_by: [asc: r.quote_deadline],
        limit: 1,
        select: r.quote_deadline
      )
      |> Repo.one()

    %{
      open_rfqs: open_rfqs,
      submitted_quotes: submitted_quotes,
      open_purchase_orders: open_pos,
      pending_invoices: pending_invoices,
      next_deadline: next_deadline
    }
  end

  @doc """
  RFQs invited to a supplier whose deadline falls within `days_window`.
  """
  def upcoming_deadlines(supplier_id, days_window \\ 14) do
    today = Date.utc_today()
    horizon = Date.add(today, days_window)

    from(r in Rfq,
      join: inv in RfqInvitation,
      on: inv.rfq_id == r.id,
      where:
        inv.supplier_id == ^supplier_id and r.status == "sent" and
          r.quote_deadline >= ^today and r.quote_deadline <= ^horizon,
      order_by: [asc: r.quote_deadline]
    )
    |> Repo.all()
  end

  @doc """
  Last `limit` significant events for a supplier, newest first.

  Returns a list of `%{type, title, at, resource_type, resource_id}`.
  """
  def supplier_activity(supplier_id, limit \\ 5) do
    quotes =
      from(q in Quote,
        where: q.supplier_id == ^supplier_id,
        select: %{
          type: :quote,
          title: q.reference,
          status: q.status,
          at: q.updated_at,
          resource_type: "quote",
          resource_id: q.id
        }
      )
      |> Repo.all()

    pos =
      from(p in PurchaseOrder,
        where: p.supplier_id == ^supplier_id,
        select: %{
          type: :purchase_order,
          title: p.reference,
          status: p.status,
          at: p.updated_at,
          resource_type: "purchase_order",
          resource_id: p.id
        }
      )
      |> Repo.all()

    invoices =
      from(i in Invoice,
        where: i.supplier_id == ^supplier_id,
        select: %{
          type: :invoice,
          title: i.reference,
          status: i.status,
          at: i.updated_at,
          resource_type: "invoice",
          resource_id: i.id
        }
      )
      |> Repo.all()

    (quotes ++ pos ++ invoices)
    |> Enum.sort_by(& &1.at, {:desc, NaiveDateTime})
    |> Enum.take(limit)
  end

  # ---------------------------------------------------------------------------
  # Procurement team dashboard
  # ---------------------------------------------------------------------------

  @doc """
  Top-level procurement stats: pending registrations, open RFQs, quotes awaiting
  decision, invoices awaiting approval.
  """
  def procurement_stats do
    pending_registrations =
      from(s in Supplier, where: s.status in ["pending", "under_review"])
      |> Repo.aggregate(:count, :id)

    active_rfqs =
      from(r in Rfq, where: r.status == "sent")
      |> Repo.aggregate(:count, :id)

    quotes_awaiting =
      from(q in Quote, where: q.status in ["submitted", "under_review"])
      |> Repo.aggregate(:count, :id)

    invoices_awaiting =
      from(i in Invoice, where: i.status in ["submitted", "pending_grn", "grn_confirmed"])
      |> Repo.aggregate(:count, :id)

    shipments_pending =
      from(s in ShipmentAdvice, where: s.status in ["submitted", "received"])
      |> Repo.aggregate(:count, :id)

    grns_flagged =
      from(g in GoodsReceivedNote, where: g.status == "flagged")
      |> Repo.aggregate(:count, :id)

    %{
      pending_registrations: pending_registrations,
      active_rfqs: active_rfqs,
      quotes_awaiting: quotes_awaiting,
      invoices_awaiting: invoices_awaiting,
      shipments_pending: shipments_pending,
      grns_flagged: grns_flagged
    }
  end

  @doc """
  Items requiring procurement attention. Returns a list of
  `%{kind, reference, resource_id, priority}` maps.
  """
  def action_queue do
    pending_grn =
      from(g in GoodsReceivedNote,
        where: g.status == "pending_review",
        select: %{kind: :grn, reference: g.reference, resource_id: g.id, priority: :high}
      )
      |> Repo.all()

    pending_invoices =
      from(i in Invoice,
        where: i.status == "grn_confirmed",
        select: %{kind: :invoice, reference: i.reference, resource_id: i.id, priority: :high}
      )
      |> Repo.all()

    pending_quotes =
      from(q in Quote,
        where: q.status == "submitted",
        select: %{kind: :quote, reference: q.reference, resource_id: q.id, priority: :normal}
      )
      |> Repo.all()

    pending_registrations =
      from(s in Supplier,
        where: s.status in ["pending", "under_review"],
        select: %{
          kind: :supplier,
          reference: s.reference,
          resource_id: s.id,
          priority: :normal
        }
      )
      |> Repo.all()

    pending_grn ++ pending_invoices ++ pending_quotes ++ pending_registrations
  end
end
