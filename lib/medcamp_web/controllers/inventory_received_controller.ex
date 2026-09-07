defmodule MedcampWeb.APIController do
  use MedcampWeb, :controller
  alias Medcamp.InventoriesReceived
  alias Medcamp.Batches
  alias Medcamp.Suppliers
  alias Medcamp.Rooms

  def create_inventory_received(conn, params) do
    url = get_image_url(params["image"].filename)

    copyImageToServer(conn, params["image"], url)

    {:ok, list} = Jason.decode(url)
    extracted_string = List.first(list)

    params =
      params
      |> Map.put("user_id", params["user_id"] |> String.to_integer())
      |> Map.put("room_id", params["room_id"] |> String.to_integer())
      |> Map.put("image", extracted_string)

    IO.inspect(params, label: "Params in create_inventory_received")

    case InventoriesReceived.create_inventory_received(params) do
      {:ok, inventory_received} ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            message: "Success",
            inventory_received: %{
              id: inventory_received.id,
              type: inventory_received.type,
              description: inventory_received.description,
              image: inventory_received.image,
              brand_name: inventory_received.brand_name,
              generic_name: inventory_received.generic_name,
              supplier: inventory_received.supplier,
              room_id: inventory_received.room_id,
              user_id: inventory_received.user_id,
              inserted_at: inventory_received.inserted_at,
              updated_at: inventory_received.updated_at
            }
          })
        )

      {:error, changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          422,
          Jason.encode!(%{message: "Error", errors: errors})
        )
    end
  end

  def create_batch(conn, params) do
    params =
      params
      |> Map.put("inventory_manager_id", params["user_id"] |> String.to_integer())
      |> Map.put("inventory_received_id", params["inventory_received_id"] |> String.to_integer())

    case Batches.create_batch(params) do
      {:ok, inventory_received} ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            message: "Success",
            batch: %{
              id: inventory_received.id,
              serial: inventory_received.serial,
              batch: inventory_received.batch,
              expiry_date: inventory_received.expiry,
              quantity: inventory_received.quantity,
              gtin: inventory_received.gtin,
              price_per_unit: inventory_received.price_per_unit,
              remaining_quantity: inventory_received.remaining_quantity,
              weight: inventory_received.weight,
              uom: inventory_received.uom
            }
          })
        )

      {:error, changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          422,
          Jason.encode!(%{message: "Error", errors: errors})
        )
    end
  end

  def get_all_suppliers(conn, _) do
    suppliers = Suppliers.list_suppliers()

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(
      200,
      Jason.encode!(%{
        message: "Success",
        suppliers:
          Enum.map(suppliers, fn supplier ->
            %{
              id: supplier.id,
              description: supplier.description,
              name: supplier.name,
              contact: supplier.contact,
              email: supplier.email,
              location: supplier.location,
              created_at: supplier.inserted_at,
              updated_at: supplier.updated_at
            }
          end)
      })
    )
  end

  def get_all_rooms(conn, _) do
    rooms = Rooms.list_rooms()

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(
      200,
      Jason.encode!(%{
        message: "Success",
        room:
          Enum.map(rooms, fn room ->
            %{
              id: room.id,
              room_number: room.room_number,
              description: room.description,
              type: room.type,
              name: room.name
            }
          end)
      })
    )
  end

  defp copyImageToServer(conn, upload, image_url) do
    case File.exists?(upload.path) do
      true ->
        case File.cp(upload.path, "./priv/static" <> format_string(image_url)) do
          :ok ->
            IO.write("Successfully copied the file")

          {:error, reason} ->
            send_resp(conn, 200, "Failed to copy #{reason}")
        end

      false ->
        send_resp(conn, 200, "could not find the file")
    end
  end

  defp format_string(str) do
    String.slice(str, 2..-3//-1)
  end

  defp get_extension(filename) do
    Path.extname(filename)
  end

  defp get_image_url(filename) do
    get_datetimestamps =
      Timex.local()
      |> Timex.format!("{YYYY}{0M}{0D}{h24}{m}{s}")

    image_name =
      to_string(Enum.random(10_000_000_000..99_999_999_999)) <>
        "-" <> get_datetimestamps

    Jason.encode!(["/images/uploads/#{image_name}#{get_extension(filename)}"])
  end
end
