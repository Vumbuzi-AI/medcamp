defmodule Medcamp.Scheduler do
  use GenServer
  alias Medcamp.Accounts

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    unless skip_bootstrap?() do
      spawn(fn -> maybe_create_default_users() end)
    end

    {:ok, state}
  end

  defp skip_bootstrap? do
    Code.ensure_loaded?(Mix) and Mix.env() == :test
  end

  defp maybe_create_default_users do
    for user <- default_test_users() do
      case Accounts.get_user_by_email(user["email"]) do
        nil ->
          Accounts.create_user(user)

        _ ->
          :ok
      end
    end

    maybe_create_default_rooms()
  end

  defp maybe_create_default_rooms do
    for room <- default_rooms() do
      case Medcamp.Rooms.get_room_by_room_number(room.room_number) do
        nil ->
          user = Accounts.get_user_by_email("admin@gmail.com")

          room =
            room
            |> Map.put(:added_by, user.id)

          Medcamp.Rooms.create_room(room)

        _ ->
          :ok
      end
    end
  end

  defp default_test_users do
    [
      %{
        "email" => "doctor@gmail.com",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Doctor",
        "role" => "doctor"
      },
      %{
        "email" => "nurse@gmail.com",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Nurse",
        "role" => "nurse"
      },
      %{
        "email" => "reception@gmail.com",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Reception",
        "role" => "reception"
      },
      %{
        "email" => "labtechnician@gmail.com",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Labtechnician",
        "role" => "labtechnician"
      },
      %{
        "email" => "admin@gmail.com",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Admin",
        "role" => "admin"
      },
      %{
        "email" => "pharmacist@gmail.com",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Pharmacist",
        "role" => "pharmacist"
      },
      %{
        "email" => "inventory@gmail.com",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Inventory Manager",
        "role" => "inventory_manager"
      },
      %{
        "email" => "radiologist@gmail.com",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Radiologist",
        "role" => "radiologist"
      },
      # Added staff from the handwritten list with their corresponding emails
      %{
        "email" => "robert.machani@glocalhealthcentre.org",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Robert Machani",
        "role" => "labtechnician"
      },
      %{
        "email" => "faith.chebet@glocalhealthcentre.org",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Faith Chebet",
        "role" => "reception"
      },
      %{
        "email" => "brigita.mnyiva@glocalhealthcentre.org",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Brigita Mnyiva",
        "role" => "pharmacist"
      },
      %{
        "email" => "rose.migoye@glocalhealthcentre.org",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Rose Migoye",
        "role" => "doctor"
      },
      %{
        "email" => "collins.omune@glocalhealthcentre.org",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Collins Omune",
        "role" => "reception"
      },
      %{
        "email" => "polly.nyawira@glocalhealthcentre.org",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Polly Nyawira",
        "role" => "nurse"
      },
      %{
        "email" => "edah.jepkemboi@glocalhealthcentre.org",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Edah Jepkemboi",
        "role" => "nurse"
      },
      %{
        "email" => "annah.gitonga@glocalhealthcentre.org",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Annah Gitonga",
        "role" => "labtechnician"
      },
      %{
        "email" => "evans.onyango@glocalhealthcentre.org",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Evans Onyango",
        "role" => "doctor"
      },
      %{
        "email" => "phanice.lumumba@glocalhealthcentre.org",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Phanice Lumumba",
        "role" => "reception"
      },
      %{
        "email" => "alfred.otieno@glocalhealthcentre.org",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Alfred Otieno",
        "role" => "reception"
      },
      %{
        "email" => "alfred.aoko@glocalhealthcentre.org",
        "hashed_password" => Bcrypt.hash_pwd_salt("123456"),
        "name" => "Alfred Aoko",
        "role" => "admin"
      }
    ]
  end

  defp default_rooms do
    [
      %{name: "Ward 1", room_number: "6161021096558", type: "Ward"},
      %{name: "Store", room_number: "6161021096557", type: "Office"},
      %{
        name: "Consulatation room 1",
        room_number: "6161021096626",
        type: "Consultation Room"
      },
      %{
        name: "Consulatation room 2",
        room_number: "6161021096619",
        type: "Consultation Room"
      },
      %{name: "Emergency Room", room_number: "6161021096657", type: "Ward"},
      %{name: "Kitchen", room_number: "6161021096510", type: "Office"},
      %{name: "Laboratory", room_number: "6161021096633", type: "Laboratory"},
      %{name: "Nurse Office", room_number: "6161021096589", type: "Office"},
      %{name: "Officer in Charge", room_number: "6161021096572", type: "Office"},
      %{name: "Pharmacy", room_number: "6161021096602", type: "Pharmacy"},
      %{name: "Phlebotomy", room_number: "6161021096503", type: "Office"},
      %{name: "Radiology", room_number: "6161021096565", type: "Office"},
      %{name: "Reception", room_number: "6161021096640", type: "Waiting Area"},
      %{name: "Sterilization Room", room_number: "6161021096480", type: "Office"},
      %{name: "Store", room_number: "6161021096497", type: "Office"},
      %{name: "Theatre", room_number: "6161021096473", type: "Ward"},
      %{name: "Triage", room_number: "6161021096596", type: "Waiting Area"},
      %{name: "Ward Bed 1", room_number: "6161021096558", type: "Ward"},
      %{name: "Ward Bed 2", room_number: "6161021096558", type: "Ward"}
    ]
  end
end
