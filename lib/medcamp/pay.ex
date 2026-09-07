defmodule Medcamp.Pay do
  @moduledoc """
  Documentation for `Pay`.
  """

  @doc false
  def get_url do
    if Application.get_env(:medcamp, :mpesa_env) === "sandbox" do
      "https://sandbox.safaricom.co.ke"
    else
      "https://api.safaricom.co.ke"
    end
  end

  @doc false
  def authorize do
    url = get_url() <> "/oauth/v1/generate?grant_type=client_credentials"

    string =
      Application.get_env(:medcamp, :consumer_key) <>
        ":" <> Application.get_env(:medcamp, :consumer_secret)

    token = Base.encode64(string)

    headers = [
      {"Authorization", "Basic #{token}"},
      {"Content-Type", "application/json"}
    ]

    HTTPotion.start()

    case HTTPoison.get(url, headers) do
      {:ok, response} ->
        get_token(response)

      {:error, error} ->
        {:error, error}
    end
  end

  @doc false
  def get_token(%{status_code: 400} = _response) do
    {:error, "Wrong Credentials"}
  end

  @doc false
  def get_token(%{status_code: 200, body: body} = _response) do
    {:ok, body} = body |> Poison.decode()
    {:ok, body["access_token"]}
  end

  def make_request(amount, phone) do
    reference = "reference"
    description = "description"

    case authorize() do
      {:ok, token} ->
        request!(token, amount, phone, reference, description)

      {:error, "Request Timed Out"} ->
        {:error, "Request Timed Out"}

      _ ->
        {:error, ~c"An Error occurred, try again"}
    end
  end

  def make_query(checkout) do
    case authorize() do
      {:ok, token} ->
        query(token, checkout)

      _ ->
        {:error, "An Error occurred, try again"}
    end
  end

  @doc false
  def request!(token, amount, phone, reference, description) do
    url = get_url() <> "/mpesa/stkpush/v1/processrequest"
    paybill = Application.get_env(:medcamp, :mpesa_short_code)
    passkey = Application.get_env(:medcamp, :mpesa_passkey)
    code = Application.get_env(:medcamp, :mpesa_code)
    {:ok, timestamp} = Timex.now() |> Timex.format("%Y%m%d%H%M%S", :strftime)
    password = Base.encode64(paybill <> passkey <> timestamp)

    payload = %{
      "BusinessShortCode" => paybill,
      "Password" => password,
      "Timestamp" => timestamp,
      "TransactionType" => "CustomerPayBillOnline",
      "Amount" => amount,
      "PartyA" => phone,
      "PartyB" => code,
      "PhoneNumber" => phone,
      "CallBackURL" => callback_url(),
      "AccountReference" => reference,
      "TransactionDesc" => description
    }

    request_body = Jason.encode!(payload)

    header = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    :post
    |> Finch.build(url, header, request_body)
    |> Finch.request(Medcamp.Finch)
    |> response()
  end

  def query(token, checkout) do
    url = get_url() <> "/mpesa/stkpushquery/v1/query"
    paybill = Application.get_env(:medcamp, :mpesa_short_code)
    passkey = Application.get_env(:medcamp, :mpesa_passkey)
    {:ok, timestamp} = Timex.now() |> Timex.format("%Y%m%d%H%M%S", :strftime)
    password = Base.encode64(paybill <> passkey <> timestamp)

    payload = %{
      "BusinessShortCode" => paybill,
      "Password" => password,
      "Timestamp" => timestamp,
      "CheckoutRequestID" => checkout
    }

    request_body = Jason.encode!(payload)

    header = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    :post
    |> Finch.build(url, header, request_body)
    |> Finch.request(Medcamp.Finch)
    |> response()
  end

  @doc false
  def get_response_body(%{status_code: 200, body: body} = _response) do
    {:ok, _body} = body |> Poison.decode()
  end

  @doc false
  def get_response_body(%{status_code: 404} = _response) do
    {:error, "Invalid Access Token"}
  end

  @doc false
  def get_response_body(%{status_code: 500} = _response) do
    {:error,
     "Unable to lock subscriber, a transaction is already in process for the current subscriber"}
  end

  def response(resp) do
    case resp do
      {:ok, %Finch.Response{body: body, headers: _headers, status: status_code}} ->
        Jason.decode!(body)
        {:ok, Jason.decode!(body), status_code}

      {:error, %Mint.TransportError{reason: :timeout}} ->
        {:error, "Request Timed Out"}

      _error ->
        {:error, Jason.decode!(resp)}
    end
  end

  ## Functions

  def test do
    case make_request(5, "25440769596") do
      {:ok, params, 200} ->
        IO.puts("Suvcess")

        IO.puts("Error is #{params["errorMessage"]}")

      {:error, "Request Timed Out"} ->
        IO.puts("Request Timed Out")
    end
  end

  # def callback_url do
  #   "https://9bf1d78faa56.ngrok-free.app/api/mpesa"
  # end

  def callback_url do
    "https://glocalhealthcentre.org/api/mpesa"
  end
end
