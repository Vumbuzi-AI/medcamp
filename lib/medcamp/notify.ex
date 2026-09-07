defmodule Medcamp.Notify do
  def api_url(), do: "https://api.tiaraconnect.io/api/messaging/sendsms"

  def sms_headers(),
    do: [
      {
        "Content-Type",
        "application/json"
      },
      {
        "Authorization",
        "Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiIyOTAiLCJvaWQiOjI5MCwidWlkIjoiYWUzMGRjZTItMjIzYi00ODUzLWJmMDItNDE5ZWI2MzMzY2Y5IiwiYXBpZCI6MTgzLCJpYXQiOjE2OTM1OTAzNDksImV4cCI6MjAzMzU5MDM0OX0.mG9d0tTkmx49OQKMKQFYKnIQMHFQEIckHBnGe5jTjg3fU95aHLxrtouqsPGr7Yi3GKFt674_ImiLtJavAa4OIw"
      }
    ]

  def send_reset_password_link(
        email,
        name,
        link
      ) do
    html_email_content = """
    Hello #{name}, you have been added as a user on Medcamp ERP . You can reset your password here: #{link}

    """

    Medcamp.Postal.deliver(
      email,
      "Medcamp ERP - Password Reset",
      html_email_content
    )
  end
end
