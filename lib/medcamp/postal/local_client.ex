defmodule Medcamp.Postal.LocalClient do
  @moduledoc """
  Development stand-in for the Postal HTTP client. Instead of POSTing the
  message to the MailSafi Postal API, it renders it into the Swoosh local
  mailbox so it can be read at `http://localhost:<port>/dev/mailbox`.

  Wired up in `config/dev.exs` (`:http_client`). Without it, `Medcamp.Postal`
  has no `:api_key` in dev and every send is silently dropped before any
  delivery attempt.
  """

  import Swoosh.Email

  @spec post(String.t(), iodata(), list()) :: {:ok, map()} | {:error, term()}
  def post(_url, body, _headers) do
    payload = Jason.decode!(body)

    email =
      new()
      |> to(payload["to"] |> List.wrap())
      |> from(parse_from(payload["from"]))
      |> subject(payload["subject"] || "(no subject)")
      |> put_body(payload)

    case Medcamp.Mailer.deliver(email) do
      {:ok, _meta} ->
        {:ok, %{status: 200, body: Jason.encode!(%{"id" => "dev-mailbox"})}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp put_body(email, %{"html_body" => html}) when is_binary(html) and html != "",
    do: html_body(email, html)

  defp put_body(email, %{"plain_body" => text}) when is_binary(text) and text != "",
    do: text_body(email, text)

  defp put_body(email, _payload), do: text_body(email, "(empty body)")

  defp parse_from(nil), do: {"GHCE (dev)", "no-reply@localhost"}

  defp parse_from(from) when is_binary(from) do
    case Regex.run(~r/^(.*?)\s*<(.+)>$/, String.trim(from)) do
      [_, name, address] -> {String.trim(name), address}
      _ -> {nil, from}
    end
  end
end
