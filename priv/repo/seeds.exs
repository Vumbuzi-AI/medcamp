# Seeds a medical camp with one login per role, a lab test catalogue and a
# small drug stock, so a fresh database is immediately usable.
#
#     mix run priv/repo/seeds.exs
#
# Idempotent: re-running updates the seeded records rather than duplicating
# them. Every account uses the same demo password - change or remove these
# before running a real camp.

alias Medcamp.Accounts
alias Medcamp.Accounts.User
alias Medcamp.DrugBatches
alias Medcamp.Drugs
alias Medcamp.Drugs.Drug
alias Medcamp.InventoriesReceived
alias Medcamp.InventoriesReceived.InventoryReceived
alias Medcamp.LabTests
alias Medcamp.LabTests.LabTest
alias Medcamp.Organisations
alias Medcamp.Repo
alias Medcamp.Tenancy

password = "123456"
now = DateTime.utc_now() |> DateTime.truncate(:second)

unwrap! = fn
  {:ok, record}, _label -> record
  {:error, changeset}, label -> raise "#{label} failed: #{inspect(changeset.errors)}"
end

## Organisation ------------------------------------------------------------
#
# Everything below is tenant-scoped, so the organisation has to exist and be
# entered before a single record is written.

organisation =
  case Organisations.get_organisation_by_slug("default") do
    nil ->
      unwrap!.(
        Organisations.create_organisation(%{
          "name" => "GHC Excellence",
          "slug" => "default",
          "location" => "Kenya",
          "logo" => "/images/logo.png",
          "primary_color" => "#373896",
          "accent_color" => "#6667ab"
        }),
        "default organisation"
      )

    existing ->
      existing
  end

Tenancy.put_org_id(organisation.id)

## Staff -------------------------------------------------------------------

otp_for_email = fn email, desired_otp ->
  case Repo.get_by(User, otp: desired_otp) do
    nil -> desired_otp
    %User{email: ^email} -> desired_otp
    _other_user -> nil
  end
end

ensure_user = fn attrs ->
  user =
    case Accounts.get_user_by_email(attrs.email) do
      nil ->
        registration = %{
          "email" => attrs.email,
          "password" => password,
          "role" => attrs.role,
          "name" => attrs.name,
          "otp" => attrs.otp
        }

        case Accounts.register_user(registration) do
          {:ok, user} ->
            user

          {:error, changeset} ->
            email_error = Keyword.get(changeset.errors, :email)

            if match?({_, metadata} when is_list(metadata), email_error) and
                 Keyword.get(elem(email_error, 1), :constraint) == :unique do
              # The lookup and insert are separate queries. If another seed
              # process (or a concurrent request) inserted this email between
              # them, use the row protected by the unique index.
              case Accounts.get_user_by_email(attrs.email) do
                nil -> unwrap!.({:error, changeset}, "user #{attrs.email}")
                user -> user
              end
            else
              unwrap!.({:error, changeset}, "user #{attrs.email}")
            end
        end

      user ->
        user
    end

  user =
    user
    |> User.password_changeset(%{"password" => password})
    |> Repo.update!()

  desired_changes = %{
    name: attrs.name,
    role: attrs.role,
    organisation_id: organisation.id,
    is_active: true,
    confirmed_at: user.confirmed_at || now
  }

  desired_changes =
    case otp_for_email.(attrs.email, attrs.otp) do
      nil -> desired_changes
      otp -> Map.put(desired_changes, :otp, otp)
    end

  user
  |> Ecto.Changeset.change(desired_changes)
  |> Repo.update!()
end

users =
  [
    %{name: "Admin User", email: "admin@gmail.com", role: "admin", otp: "1001"},
    %{name: "Dr Amina Demo", email: "doctor@gmail.com", role: "doctor", otp: "1002"},
    %{name: "Nurse Brian Demo", email: "nurse@gmail.com", role: "nurse", otp: "1003"},
    %{name: "Pharmacist Demo", email: "pharmacist@gmail.com", role: "pharmacist", otp: "1005"},
    %{
      name: "Lab Technician Demo",
      email: "labtechnician@gmail.com",
      role: "labtechnician",
      otp: "1006"
    }
  ]
  |> Enum.map(&{&1.role, ensure_user.(&1)})
  |> Map.new()

pharmacist = users["pharmacist"]

## Superadmins -------------------------------------------------------------
#
# Platform accounts land at /superadmin/organisations. The current schema
# requires every user to have an organisation, so these accounts sit in the
# default organisation for storage only; `is_superadmin`, not `role`, gives
# them platform access. Add another entry here to seed a fellow superadmin.

superadmin_accounts = [
  %{
    name: "Superadmin",
    email: "superadmin@gmail.com",
    role: "admin",
    otp: "1000"
  }
]

for attrs <- superadmin_accounts do
  attrs
  |> ensure_user.()
  |> Ecto.Changeset.change(%{is_superadmin: true})
  |> Repo.update!()
end

## Lab test catalogue ------------------------------------------------------

lab_tests = [
  %{name: "Malaria RDT", price: 0},
  %{name: "Blood Sugar (RBS)", price: 0},
  %{name: "Haemoglobin (Hb)", price: 0},
  %{name: "Full Blood Count", price: 0},
  %{name: "Urinalysis", price: 0},
  %{name: "HIV Screening", price: 0},
  %{name: "Pregnancy Test (HCG)", price: 0},
  %{name: "Stool for Ova & Cysts", price: 0}
]

for attrs <- lab_tests do
  case Repo.get_by(LabTest, name: attrs.name) do
    nil -> unwrap!.(LabTests.create_lab_test(attrs), "lab test #{attrs.name}")
    lab_test -> lab_test
  end
end

# Keep the structured result templates aligned with this catalogue.
Code.require_file(Path.expand("seeds/current_lab_test_templates.exs", __DIR__))

## Drug stock --------------------------------------------------------------

# Each drug needs an item-master row (`inventories_received`) keyed by GTIN -
# that is the identity a prescription and a dispense are recorded against.
drug_stock = [
  %{
    gtin: "06161021090001",
    generic_name: "Paracetamol 500mg",
    brand_name: "Panadol",
    batch: "PCM-2601",
    expiry: "2027-06-30",
    quantity: 500
  },
  %{
    gtin: "06161021090002",
    generic_name: "Amoxicillin 250mg",
    brand_name: "Amoxil",
    batch: "AMX-2602",
    expiry: "2027-03-31",
    quantity: 300
  },
  %{
    gtin: "06161021090003",
    generic_name: "Artemether/Lumefantrine 20/120mg",
    brand_name: "Coartem",
    batch: "ALU-2603",
    expiry: "2026-12-31",
    quantity: 200
  },
  %{
    gtin: "06161021090004",
    generic_name: "Albendazole 400mg",
    brand_name: "Zentel",
    batch: "ALB-2604",
    expiry: "2028-01-31",
    quantity: 400
  },
  %{
    gtin: "06161021090005",
    generic_name: "Oral Rehydration Salts",
    brand_name: "ORS",
    batch: "ORS-2605",
    expiry: "2027-09-30",
    quantity: 250
  }
]

for attrs <- drug_stock do
  item =
    case Repo.get_by(InventoryReceived, gtin: attrs.gtin) do
      nil ->
        unwrap!.(
          InventoriesReceived.create_inventory_received(%{
            "gtin" => attrs.gtin,
            "brand_name" => attrs.brand_name,
            "generic_name" => attrs.generic_name,
            "type" => "Drug",
            "category" => "Pharmaceuticals",
            "uom" => "Tablets",
            "user_id" => pharmacist.id
          }),
          "item master #{attrs.gtin}"
        )

      item ->
        item
    end

  drug =
    case Repo.get_by(Drug, inventory_received_id: item.id) do
      nil ->
        unwrap!.(
          Drugs.create_drug(%{
            inventory_received_id: item.id,
            inventory_manager_id: pharmacist.id,
            generic_name: attrs.generic_name,
            brand_name: attrs.brand_name,
            is_otc: true
          }),
          "drug #{attrs.generic_name}"
        )

      drug ->
        drug
    end

  unless Repo.get_by(Medcamp.Batches.Batch, gtin: attrs.gtin, batch: attrs.batch) do
    unwrap!.(
      DrugBatches.take_in_batch(%{
        drug_id: drug.id,
        inventory_received_id: item.id,
        inventory_manager_id: pharmacist.id,
        quantity: attrs.quantity,
        gtin: attrs.gtin,
        batch: attrs.batch,
        expiry: attrs.expiry
      }),
      "batch #{attrs.batch}"
    )
  end
end

IO.puts("""
Seeded medical camp:
  #{map_size(users)} staff logins (password: #{password})
  #{length(lab_tests)} lab tests
  #{length(drug_stock)} drugs, each with one active batch

Log in as admin@gmail.com to add the rest of your camp staff.
New batches are immediately available for prescribing and dispensing.
""")
