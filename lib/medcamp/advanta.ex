defmodule Medcamp.Advanta do
  def send_message(message, number) do
    url = "https://quicksms.advantasms.com/api/services/sendsms/"

    body = %{
      apikey: "fd7c73bc458ab5b608b4e1f2e7c6975a",
      partnerID: "13823",
      message: message,
      shortcode: "GHC-E",
      mobile: number
    }

    headers = [
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]

    req_options = [
      headers: headers,
      json: body,
      retry: :transient,
      max_retries: 5,
      receive_timeout: 60_000
    ]

    Req.post(url, req_options)
  end
end
