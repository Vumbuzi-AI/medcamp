defmodule Medcamp.Procurement.SchemasTest do
  use Medcamp.DataCase, async: true

  import Medcamp.AccountsFixtures

  alias Medcamp.Procurement.Suppliers
  alias Medcamp.Repo
  alias Medcamp.Suppliers.Supplier
  alias Medcamp.Suppliers.SupplierDocument

  alias Medcamp.Procurement.{
    SupplierDirector,
    Rfq,
    RfqItem,
    RfqInvitation,
    Quote,
    QuoteItem,
    ProformaInvoice,
    PurchaseOrder,
    Invoice,
    ShipmentAdvice,
    GoodsReceivedNote,
    GrnItem,
    ProcurementNotification
  }

  defp valid_supplier_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        name: "Vendor #{System.unique_integer([:positive])}",
        description: "desc",
        email: "vendor#{System.unique_integer([:positive])}@example.com",
        contact: "+254700000000",
        location: "Nairobi"
      },
      overrides
    )
  end

  defp make_supplier!(attrs \\ %{}) do
    %Supplier{}
    |> Supplier.changeset(valid_supplier_attrs(attrs))
    |> Repo.insert!()
  end

  defp make_rfq!(overrides \\ %{}) do
    attrs =
      Map.merge(
        %{
          reference: "RFQ-#{System.unique_integer([:positive])}",
          title: "Bandages Q2",
          quote_deadline: ~D[2026-06-30],
          status: "draft"
        },
        overrides
      )

    %Rfq{}
    |> Rfq.changeset(attrs)
    |> Repo.insert!()
  end

  describe "Supplier registration_changeset" do
    test "accepts spec columns and validates status" do
      cs =
        %Supplier{}
        |> Supplier.registration_changeset(
          valid_supplier_attrs(%{
            legal_name: "MedTech Supplies Ltd",
            reference: "SUP-2026-00001",
            product_categories: ["pharma"],
            status: "under_review",
            compliance_score: 85
          })
        )

      assert cs.valid?

      bad =
        %Supplier{}
        |> Supplier.registration_changeset(valid_supplier_attrs(%{status: "bogus"}))

      refute bad.valid?
      assert %{status: ["is invalid"]} = errors_on(bad)
    end

    test "reference is unique" do
      %Supplier{}
      |> Supplier.registration_changeset(valid_supplier_attrs(%{reference: "SUP-SAME"}))
      |> Repo.insert!()

      {:error, cs} =
        %Supplier{}
        |> Supplier.registration_changeset(valid_supplier_attrs(%{reference: "SUP-SAME"}))
        |> Repo.insert()

      assert %{reference: ["has already been taken"]} = errors_on(cs)
    end
  end

  describe "SupplierDocument" do
    test "accepts new procurement document types and enforces unique per supplier" do
      sup = make_supplier!()

      {:ok, _} =
        %SupplierDocument{}
        |> SupplierDocument.changeset(%{
          supplier_id: sup.id,
          document_type: "registration_cert",
          file_path: "/tmp/a.pdf"
        })
        |> Repo.insert()

      {:error, cs} =
        %SupplierDocument{}
        |> SupplierDocument.changeset(%{
          supplier_id: sup.id,
          document_type: "registration_cert",
          file_path: "/tmp/b.pdf"
        })
        |> Repo.insert()

      assert errors_on(cs)[:supplier_id] == ["has already been taken"] or
               errors_on(cs)[:document_type] == ["has already been taken"]
    end

    test "rejects unknown document_type" do
      sup = make_supplier!()

      cs =
        %SupplierDocument{}
        |> SupplierDocument.changeset(%{
          supplier_id: sup.id,
          document_type: "nope",
          file_path: "/tmp/x.pdf"
        })

      refute cs.valid?
    end

    test "verify_document records verifier and refreshes supplier compliance score" do
      approver =
        %Medcamp.Accounts.User{}
        |> Medcamp.Accounts.User.changeset(%{
          name: "Procurement Reviewer",
          email: unique_user_email(),
          role: "procurement_officer",
          otp: "1234",
          hashed_password: "temporary-hash"
        })
        |> Repo.insert!()

      supplier =
        make_supplier!()
        |> Supplier.registration_changeset(%{
          account_number: "00112233",
          bank_name: "Medcamp Bank",
          kra_pin: "P051234567X"
        })
        |> Repo.update!()

      %SupplierDirector{}
      |> SupplierDirector.changeset(%{
        supplier_id: supplier.id,
        first_name: "Ann",
        last_name: "Doe",
        id_number: "11111111",
        id_document_path: "/uploads/supplier_directors/ann.pdf"
      })
      |> Repo.insert!()

      docs =
        for type <- ~w(registration_cert pin_cert trade_licence) do
          %SupplierDocument{}
          |> SupplierDocument.changeset(%{
            supplier_id: supplier.id,
            document_type: type,
            file_path: "/uploads/supplier_documents/#{type}.pdf"
          })
          |> Repo.insert!()
        end

      assert 80 ==
               supplier.id |> Suppliers.get_supplier!() |> Suppliers.compute_compliance_score()

      Enum.each(docs, fn document ->
        assert {:ok, verified_doc} = Suppliers.verify_document(document, approver)
        assert verified_doc.verified
        assert verified_doc.verified_by_id == approver.id
      end)

      refreshed_supplier = Suppliers.get_supplier!(supplier.id)

      assert refreshed_supplier.compliance_score == 100
      assert Enum.all?(refreshed_supplier.supplier_documents, & &1.verified)
      assert Enum.all?(refreshed_supplier.supplier_documents, &(&1.verified_by_id == approver.id))
    end
  end

  describe "SupplierDirector" do
    test "requires supplier and names" do
      cs = SupplierDirector.changeset(%SupplierDirector{}, %{})
      refute cs.valid?

      sup = make_supplier!()

      {:ok, _} =
        %SupplierDirector{}
        |> SupplierDirector.changeset(%{
          supplier_id: sup.id,
          first_name: "Ann",
          last_name: "Doe",
          id_number: "11111111"
        })
        |> Repo.insert()
    end
  end

  describe "Rfq" do
    test "requires reference + status and validates enums" do
      refute Rfq.changeset(%Rfq{}, %{}).valid?

      bad =
        Rfq.changeset(%Rfq{}, %{
          reference: "RFQ-1",
          title: "T",
          quote_deadline: ~D[2026-07-01],
          status: "open"
        })

      refute bad.valid?
      assert %{status: ["is invalid"]} = errors_on(bad)
    end

    test "reference unique" do
      make_rfq!(%{reference: "RFQ-DUP"})

      {:error, cs} =
        %Rfq{}
        |> Rfq.changeset(%{
          reference: "RFQ-DUP",
          title: "T",
          quote_deadline: ~D[2026-07-01],
          status: "draft"
        })
        |> Repo.insert()

      assert %{reference: ["has already been taken"]} = errors_on(cs)
    end
  end

  describe "RfqItem" do
    test "validates quantity_required > 0" do
      rfq = make_rfq!()

      bad =
        RfqItem.changeset(%RfqItem{}, %{
          rfq_id: rfq.id,
          description: "Gloves",
          quantity_required: 0
        })

      refute bad.valid?

      good =
        RfqItem.changeset(%RfqItem{}, %{
          rfq_id: rfq.id,
          description: "Gloves",
          quantity_required: 10
        })

      assert good.valid?
    end
  end

  describe "RfqInvitation" do
    test "enforces unique [rfq_id, supplier_id]" do
      rfq = make_rfq!()
      sup = make_supplier!()

      {:ok, _} =
        %RfqInvitation{}
        |> RfqInvitation.changeset(%{rfq_id: rfq.id, supplier_id: sup.id})
        |> Repo.insert()

      {:error, cs} =
        %RfqInvitation{}
        |> RfqInvitation.changeset(%{rfq_id: rfq.id, supplier_id: sup.id})
        |> Repo.insert()

      assert errors_on(cs) |> Map.keys() |> Enum.any?(&(&1 in [:rfq_id, :supplier_id]))
    end
  end

  describe "Quote + QuoteItem" do
    test "unique per rfq+supplier and item FK set" do
      rfq = make_rfq!()
      sup = make_supplier!()

      rfq_item =
        %RfqItem{}
        |> RfqItem.changeset(%{rfq_id: rfq.id, description: "Mask", quantity_required: 100})
        |> Repo.insert!()

      {:ok, quote1} =
        %Quote{}
        |> Quote.changeset(%{
          reference: "QT-1",
          rfq_id: rfq.id,
          supplier_id: sup.id,
          status: "submitted"
        })
        |> Repo.insert()

      {:error, cs} =
        %Quote{}
        |> Quote.changeset(%{
          reference: "QT-2",
          rfq_id: rfq.id,
          supplier_id: sup.id,
          status: "submitted"
        })
        |> Repo.insert()

      assert errors_on(cs) |> Map.keys() |> Enum.any?(&(&1 in [:rfq_id, :supplier_id]))

      {:ok, qi} =
        %QuoteItem{}
        |> QuoteItem.changeset(%{
          quote_id: quote1.id,
          rfq_item_id: rfq_item.id,
          unit_price: Decimal.new("1.50"),
          quantity_available: Decimal.new("100")
        })
        |> Repo.insert()

      assert qi.quote_id == quote1.id
    end
  end

  describe "PurchaseOrder" do
    test "exposes all 5 checklist booleans on the struct" do
      po = %PurchaseOrder{}

      for field <- PurchaseOrder.checklist_fields() do
        assert Map.has_key?(po, field)
        assert Map.get(po, field) == false
      end
    end

    test "validates status inclusion" do
      sup = make_supplier!()

      bad =
        PurchaseOrder.changeset(%PurchaseOrder{}, %{
          reference: "PO-1",
          supplier_id: sup.id,
          status: "weird"
        })

      refute bad.valid?
    end
  end

  describe "Invoice + ShipmentAdvice status inclusion" do
    test "rejects invalid invoice + shipment statuses" do
      refute Invoice.changeset(%Invoice{}, %{
               reference: "INV-1",
               purchase_order_id: 1,
               supplier_id: 1,
               status: "nope"
             }).valid?

      refute ShipmentAdvice.changeset(%ShipmentAdvice{}, %{
               reference: "SA-1",
               purchase_order_id: 1,
               invoice_id: 1,
               supplier_id: 1,
               status: "nope"
             }).valid?
    end
  end

  describe "ProformaInvoice" do
    test "rejects invalid status" do
      cs =
        ProformaInvoice.changeset(%ProformaInvoice{}, %{
          reference: "PI-1",
          quote_id: 1,
          supplier_id: 1,
          status: "nope"
        })

      refute cs.valid?
    end
  end

  describe "GoodsReceivedNote and GrnItem" do
    test "GRN status inclusion" do
      refute GoodsReceivedNote.changeset(%GoodsReceivedNote{}, %{
               reference: "GRN-1",
               purchase_order_id: 1,
               invoice_id: 1,
               shipment_advice_id: 1,
               supplier_id: 1,
               status: "nope"
             }).valid?
    end

    test "GrnItem computes variance from po_quantity - quantity_received" do
      cs =
        GrnItem.changeset(%GrnItem{}, %{
          grn_id: 1,
          purchase_order_item_id: 1,
          condition: "accepted",
          po_quantity: Decimal.new("100"),
          quantity_received: Decimal.new("96")
        })

      assert Decimal.equal?(Ecto.Changeset.get_field(cs, :variance), Decimal.new("4"))
    end

    test "GrnItem rejects invalid condition" do
      cs =
        GrnItem.changeset(%GrnItem{}, %{
          grn_id: 1,
          purchase_order_item_id: 1,
          condition: "maybe"
        })

      refute cs.valid?
    end
  end

  describe "ProcurementNotification" do
    test "rejects unknown type" do
      refute ProcurementNotification.changeset(%ProcurementNotification{}, %{
               user_id: 1,
               type: "bogus"
             }).valid?
    end
  end
end
