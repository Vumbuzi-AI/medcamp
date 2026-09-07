defmodule Medcamp.PostalTest do
  use ExUnit.Case, async: false

  alias Medcamp.Postal

  defmodule CaptureClient do
    def post(url, body, headers) do
      send(self(), {:postal_request, url, Jason.decode!(body), headers})
      {:ok, %{status: 200, body: ~s({"status":"success"})}}
    end
  end

  setup do
    previous_config = Application.get_env(:medcamp, Postal)

    Application.put_env(:medcamp, Postal,
      api_url: "https://postal.example.test/api/v1/send/message",
      api_key: "server-api-key",
      from: "no-reply@gs1kenya.org",
      from_name: "GHCE",
      http_client: CaptureClient
    )

    on_exit(fn -> Application.put_env(:medcamp, Postal, previous_config) end)
  end

  test "delivers plain text using the Postal message schema and API key header" do
    assert {:ok, _, %{status: 200}} =
             Postal.deliver(
               "patient@example.com",
               "Appointment",
               "Your appointment is confirmed."
             )

    assert_receive {:postal_request, url, payload, headers}
    assert url == "https://postal.example.test/api/v1/send/message"
    assert payload["to"] == ["patient@example.com"]
    assert payload["from"] == "GHCE <no-reply@gs1kenya.org>"
    assert payload["subject"] == "Appointment"
    assert payload["plain_body"] == "Your appointment is confirmed."
    assert {"x-server-api-key", "server-api-key"} in headers
    refute Map.has_key?(payload, "html_body")
  end

  test "returns a configuration error without an API key" do
    Application.put_env(:medcamp, Postal, api_key: nil, http_client: CaptureClient)

    assert Postal.deliver("patient@example.com", "Appointment", "Body") ==
             {:error, {:missing_config, :api_key}}

    refute_received {:postal_request, _, _, _}
  end
end
