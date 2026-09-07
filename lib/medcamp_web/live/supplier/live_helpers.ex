defmodule MedcampWeb.Supplier.LiveHelpers do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView

  alias Ecto.Changeset
  alias Medcamp.Accounts.User
  alias Medcamp.Procurement.Suppliers
  alias Medcamp.Repo

  @registration_steps [:company, :address, :contact, :bank, :documents, :directors, :review]
  @required_document_types ~w(registration_cert pin_cert trade_licence)
  @attachment_prefix "ATTACHMENT::"

  def registration_steps, do: @registration_steps
  def required_document_types, do: @required_document_types

  def normalize_step(step) when step in @registration_steps, do: step

  def normalize_step(step) when is_binary(step) do
    condensed = step |> String.trim() |> String.downcase()

    case condensed do
      "1" -> :company
      "company" -> :company
      "2" -> :address
      "address" -> :address
      "3" -> :contact
      "contact" -> :contact
      "4" -> :bank
      "bank" -> :bank
      "5" -> :documents
      "documents" -> :documents
      "6" -> :directors
      "directors" -> :directors
      "7" -> :review
      "review" -> :review
      _ -> :company
    end
  end

  def normalize_step(_), do: :company

  def step_slug(step), do: step |> normalize_step() |> Atom.to_string()
  def registration_path(step), do: "/supplier/registration/#{step_slug(step)}"

  def next_step(step) do
    step = normalize_step(step)
    current_index = Enum.find_index(@registration_steps, &(&1 == step)) || 0
    Enum.at(@registration_steps, min(current_index + 1, length(@registration_steps) - 1))
  end

  def previous_step(step) do
    step = normalize_step(step)
    current_index = Enum.find_index(@registration_steps, &(&1 == step)) || 0
    Enum.at(@registration_steps, max(current_index - 1, 0))
  end

  def load_supplier(%User{} = user, opts \\ []) do
    create? = Keyword.get(opts, :create?, false)

    cond do
      is_integer(user.supplier_id) and user.supplier_id > 0 ->
        case Suppliers.get_supplier(user.supplier_id) do
          nil when create? -> create_supplier_for_user(user)
          nil -> {:error, :missing_supplier}
          supplier -> {:ok, supplier, user}
        end

      create? ->
        create_supplier_for_user(user)

      true ->
        {:error, :missing_supplier}
    end
  end

  def supplier_document_map(supplier) do
    supplier
    |> Map.get(:supplier_documents, [])
    |> Enum.reduce(%{}, fn document, acc -> Map.put(acc, document.document_type, document) end)
  end

  def registration_progress(supplier) do
    supplier = supplier || %{}
    docs = supplier_document_map(supplier)

    progress = %{
      company:
        present?(supplier.legal_name) and present?(supplier.nature_of_business) and
          present?(supplier.product_categories),
      address:
        present?(supplier.country) and present?(supplier.street_address) and
          present?(supplier.city) and
          present?(supplier.county),
      directors: Enum.any?(Map.get(supplier, :directors, [])),
      contact:
        present?(supplier.contact_first_name) and present?(supplier.contact_last_name) and
          present?(supplier.contact_email) and present?(supplier.contact_telephone),
      bank:
        present?(supplier.account_name) and present?(supplier.account_number) and
          present?(supplier.bank_name) and present?(supplier.kra_pin),
      documents: Enum.all?(@required_document_types, &Map.has_key?(docs, &1))
    }

    Map.put(progress, :review, Enum.all?(Map.values(progress)))
  end

  def next_incomplete_step(progress) do
    Enum.find(@registration_steps, :review, fn step -> progress[step] != true end)
  end

  def listify_indexed_params(nil), do: []
  def listify_indexed_params(list) when is_list(list), do: Enum.map(list, &Map.new/1)

  def listify_indexed_params(map) when is_map(map) do
    map
    |> Enum.sort_by(fn {key, _value} -> parse_index(key) end)
    |> Enum.map(fn {_key, value} -> Map.new(value) end)
  end

  def listify_indexed_params(_), do: []

  def decimal(nil), do: Decimal.new(0)
  def decimal(%Decimal{} = value), do: value
  def decimal(value) when is_integer(value), do: Decimal.new(value)
  def decimal(value) when is_float(value), do: Decimal.from_float(value)

  def decimal(value) when is_binary(value) do
    case Decimal.parse(String.trim(value)) do
      {parsed, _rest} -> parsed
      :error -> Decimal.new(0)
    end
  end

  def decimal(_), do: Decimal.new(0)

  def decimal_to_string(value, places \\ 2) do
    value
    |> decimal()
    |> Decimal.round(places)
    |> Decimal.to_string(:normal)
  end

  def money(value), do: "KES #{decimal_to_string(value)}"

  def format_date(nil), do: "TBD"
  def format_date(%Date{} = value), do: Calendar.strftime(value, "%d %b %Y")
  def format_date(value), do: to_string(value)

  def format_datetime(nil), do: "Just now"

  def format_datetime(%NaiveDateTime{} = value),
    do: Calendar.strftime(value, "%d %b %Y %H:%M")

  def format_datetime(%DateTime{} = value),
    do: value |> DateTime.to_naive() |> format_datetime()

  def format_datetime(value), do: to_string(value)

  def maybe_join_list(nil), do: ""
  def maybe_join_list(values) when is_list(values), do: Enum.join(values, ", ")
  def maybe_join_list(value), do: to_string(value)

  def csv_to_list(nil), do: []

  def csv_to_list(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  def csv_to_list(values) when is_list(values), do: values
  def csv_to_list(_), do: []

  def upload_entries_have_errors?(socket, upload_name) do
    upload = socket.assigns.uploads[upload_name]

    Enum.any?(upload.entries, fn entry ->
      entry.valid? == false
    end)
  end

  def store_uploads(socket, upload_name, subdir, prefix) do
    consume_uploaded_entries(socket, upload_name, fn %{path: path}, entry ->
      ext = Path.extname(entry.client_name)
      filename = "#{prefix}_#{System.unique_integer([:positive])}#{ext}"
      destination_dir = Path.join(Application.app_dir(:medcamp, "priv/uploads"), subdir)

      File.mkdir_p!(destination_dir)

      destination = Path.join(destination_dir, filename)
      File.cp!(path, destination)

      {:ok,
       %{
         path: "/uploads/#{subdir}/#{filename}",
         client_name: entry.client_name,
         size: entry.client_size
       }}
    end)
  end

  def merge_attachments(notes, files) when is_list(files) and files != [] do
    attachment_lines =
      files
      |> Enum.map(fn file -> "#{@attachment_prefix}#{file.client_name}|#{file.path}" end)
      |> Enum.join("\n")

    [String.trim(notes || ""), attachment_lines]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join("\n")
  end

  def merge_attachments(notes, _files), do: notes

  def extract_attachments(nil), do: []

  def extract_attachments(notes) when is_binary(notes) do
    notes
    |> String.split("\n", trim: true)
    |> Enum.reduce([], fn line, acc ->
      case String.split(line, @attachment_prefix, parts: 2) do
        [_before, payload] ->
          case String.split(payload, "|", parts: 2) do
            [label, path] -> [%{label: label, path: path} | acc]
            _ -> acc
          end

        _ ->
          acc
      end
    end)
    |> Enum.reverse()
  end

  def plain_notes(nil), do: nil

  def plain_notes(notes) when is_binary(notes) do
    notes
    |> String.split("\n", trim: true)
    |> Enum.reject(&String.starts_with?(&1, @attachment_prefix))
    |> Enum.join("\n")
    |> String.trim()
    |> case do
      "" -> nil
      value -> value
    end
  end

  def activity_path(%{resource_type: "quote", resource_id: id}), do: "/supplier/quotes/#{id}"

  def activity_path(%{resource_type: "purchase_order", resource_id: id}),
    do: "/supplier/purchase-orders/#{id}"

  def activity_path(%{resource_type: "invoice", resource_id: id}), do: "/supplier/invoices/#{id}"
  def activity_path(_), do: "/supplier/dashboard"

  def deadline_tone(days) when is_integer(days) and days < 7, do: "text-rose-600"
  def deadline_tone(days) when is_integer(days) and days <= 14, do: "text-amber-600"
  def deadline_tone(_days), do: "text-emerald-600"

  def present?(value), do: not blank?(value)

  def blank?(nil), do: true
  def blank?(""), do: true
  def blank?(value) when is_binary(value), do: String.trim(value) == ""
  def blank?(value) when is_list(value), do: Enum.empty?(value)
  def blank?(_), do: false

  def prune_blank_values(attrs) do
    Enum.reduce(attrs, %{}, fn
      {_key, value}, acc when value in [nil, ""] -> acc
      {key, value}, acc -> Map.put(acc, key, value)
    end)
  end

  def step_completion_changeset(step, data, attrs) do
    cast_fields =
      case normalize_step(step) do
        :company ->
          [:name, :legal_name, :nature_of_business, :years_in_operation, :product_categories]

        :address ->
          [:country, :street_address, :city, :county, :po_box, :location]

        :contact ->
          [
            :contact_first_name,
            :contact_last_name,
            :contact_designation,
            :contact_email,
            :contact_telephone,
            :alternate_contact_name,
            :alternate_contact_email,
            :alternate_contact_telephone,
            :email,
            :contact
          ]

        :bank ->
          [
            :account_name,
            :account_number,
            :bank_name,
            :bank_branch,
            :swift_code,
            :currency,
            :payment_terms,
            :kra_pin
          ]

        _ ->
          []
      end

    changeset =
      {data, types_for(cast_fields)}
      |> Changeset.cast(attrs, cast_fields)

    case normalize_step(step) do
      :company ->
        Changeset.validate_required(changeset, [
          :legal_name,
          :nature_of_business,
          :product_categories
        ])

      :address ->
        Changeset.validate_required(changeset, [:country, :street_address, :city, :county])

      :contact ->
        Changeset.validate_required(changeset, [
          :contact_first_name,
          :contact_last_name,
          :contact_email,
          :contact_telephone
        ])

      :bank ->
        Changeset.validate_required(changeset, [
          :account_name,
          :account_number,
          :bank_name,
          :kra_pin
        ])

      _ ->
        changeset
    end
  end

  def maybe_assign_current_user(socket, user), do: assign(socket, :current_user, user)

  defp create_supplier_for_user(%User{} = user) do
    with {:ok, supplier} <- Suppliers.create_supplier_registration(base_supplier_attrs(user)),
         {:ok, updated_user} <- link_user_to_supplier(user, supplier.id) do
      {:ok, Suppliers.get_supplier!(supplier.id), updated_user}
    end
  end

  defp link_user_to_supplier(%User{} = user, supplier_id) do
    user
    |> Changeset.change(%{supplier_id: supplier_id})
    |> Repo.update()
  end

  defp base_supplier_attrs(user) do
    company_name =
      user.name
      |> case do
        nil -> user.email
        "" -> user.email
        value -> value
      end

    %{
      name: company_name,
      legal_name: company_name,
      email: user.email,
      contact_email: user.email,
      contact: user.phone_number,
      contact_telephone: user.phone_number,
      status: "pending"
    }
    |> prune_blank_values()
  end

  defp parse_index(key) do
    key
    |> to_string()
    |> Integer.parse()
    |> case do
      {value, _rest} -> value
      :error -> 0
    end
  end

  defp types_for(fields) do
    field_types = %{
      name: :string,
      legal_name: :string,
      nature_of_business: :string,
      years_in_operation: :integer,
      country: :string,
      product_categories: {:array, :string},
      street_address: :string,
      city: :string,
      county: :string,
      po_box: :string,
      location: :string,
      contact_first_name: :string,
      contact_last_name: :string,
      contact_designation: :string,
      contact_email: :string,
      contact_telephone: :string,
      alternate_contact_name: :string,
      alternate_contact_email: :string,
      alternate_contact_telephone: :string,
      email: :string,
      contact: :string,
      account_name: :string,
      account_number: :string,
      bank_name: :string,
      bank_branch: :string,
      swift_code: :string,
      currency: :string,
      payment_terms: :string,
      kra_pin: :string
    }

    Map.take(field_types, fields)
  end
end
