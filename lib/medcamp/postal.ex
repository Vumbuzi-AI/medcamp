defmodule Medcamp.Postal do
  @moduledoc """
  Delivers application email through the MailSafi Postal HTTP API.
  """

  @default_api_url "https://postalmail.mailsafi.com/api/v1/send/message"
  @default_from "no-reply@gs1kenya.org"

  def deliver(recipient, subject, body) do
    send_email(recipient, subject, text_body: body)
  end

  @doc false
  # The shared Tibasasa email shell — the one template every transactional
  # message uses. Styled to match the app's utility pages (see error_html/*):
  # logo lockup, one white card on an off-white ground, navy heading, optional
  # navy pill CTA + monospace link fallback, a single hairline footer line -
  # no dark bar, no gradients. Table layout + inline styles only.
  #
  # Assigns:
  #   * `heading`    - required, the <h1> and <title>
  #   * `intro`      - required, the lead paragraph
  #   * `body`       - optional, a list of extra paragraph strings
  #   * `highlight`  - optional `%{label: "...", value: "..."}`, a tinted box
  #                    (used for the patient PIN)
  #   * `cta_label` + `url` - optional; together they render the pill button and
  #                    the "paste this link" fallback. Omit both for a
  #                    notification-only email.
  #   * `outro`      - optional closing line
  def tibasasa_email(%{} = a) do
    font =
      "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"

    logo = MedcampWeb.Endpoint.url() <> "/images/tibasasa-ai-logo.png"

    body_paras =
      Enum.map_join(
        a[:body] || [],
        "",
        &"<p style='margin:0 0 16px 0; font-size:15px; line-height:1.6; color:#475569;'>#{&1}</p>"
      )

    highlight_block =
      case a[:highlight] do
        %{value: value} = h ->
          """
          <table role='presentation' width='100%' cellpadding='0' cellspacing='0' style='margin:8px 0 24px 0;'>
            <tr>
              <td align='center' style='background-color:#eef2fb; border:1px solid #dbe4f3; border-radius:12px; padding:20px;'>
                <p style='margin:0 0 8px 0; font-size:12px; font-weight:600; letter-spacing:0.08em; text-transform:uppercase; color:#0C2765;'>#{h[:label] || "Code"}</p>
                <p style='margin:0; font-family:ui-monospace,SFMono-Regular,Menlo,monospace; font-size:30px; letter-spacing:8px; font-weight:700; color:#0C2765;'>#{value}</p>
              </td>
            </tr>
          </table>
          """

        _ ->
          ""
      end

    cta_block =
      if a[:cta_label] && a[:url] do
        """
        <table role='presentation' cellpadding='0' cellspacing='0'>
          <tr>
            <td align='center' bgcolor='#0C2765' style='border-radius:9999px;'>
              <a href='#{a.url}' target='_blank' style='display:inline-block; padding:13px 30px; font-size:15px; font-weight:600; line-height:1; color:#ffffff; text-decoration:none; border-radius:9999px;'>#{a.cta_label}</a>
            </td>
          </tr>
        </table>
        <p style='margin:22px 0 0 0; font-size:13px; line-height:1.6; color:#94a3b8;'>
          Button not working? Paste this link:<br />
          <a href='#{a.url}' style='color:#64748b; word-break:break-all;'>#{a.url}</a>
        </p>
        """
      else
        ""
      end

    outro_block =
      case a[:outro] do
        outro when is_binary(outro) and outro != "" ->
          "<p style='margin:16px 0 0 0; font-size:13px; line-height:1.6; color:#94a3b8;'>#{outro}</p>"

        _ ->
          ""
      end

    """
    <!DOCTYPE html>
    <html lang='en'>
    <head>
      <meta charset='utf-8' />
      <meta name='viewport' content='width=device-width, initial-scale=1.0' />
      <title>#{a.heading}</title>
    </head>
    <body style="margin:0; padding:0; background-color:#f6f8fb; font-family:#{font}; -webkit-font-smoothing:antialiased;">
      <table role='presentation' width='100%' cellpadding='0' cellspacing='0' style='background-color:#f6f8fb;'>
        <tr>
          <td align='center' style='padding:40px 16px;'>
            <table role='presentation' width='480' cellpadding='0' cellspacing='0' style='max-width:480px; width:100%; background-color:#ffffff; border:1px solid #e2e8f0; border-radius:16px;'>
              <tr>
                <td style='padding:36px 36px 28px 36px;'>
                  <img src='#{logo}' width='30' height='30' alt='Tibasasa' style='display:block; border:0; border-radius:7px; margin-bottom:24px;' />

                  <h1 style='margin:0 0 12px 0; font-size:22px; line-height:1.3; font-weight:700; letter-spacing:-0.01em; color:#0C2765;'>#{a.heading}</h1>
                  <p style='margin:0 0 #{if(body_paras == "" and highlight_block == "" and cta_block == "", do: "0", else: "20px")} 0; font-size:15px; line-height:1.6; color:#475569;'>#{a.intro}</p>
                  #{body_paras}
                  #{highlight_block}
                  #{cta_block}
                  #{outro_block}
                </td>
              </tr>
              <tr>
                <td style='padding:16px 36px; border-top:1px solid #eef2f7;'>
                  <p style='margin:0; font-size:12px; color:#94a3b8;'>
                    <span style='font-weight:600; color:#64748b;'>Tibasasa</span> &middot; Medical Camp Management
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
    """
  end

  @doc false
  # Plaintext twin of `tibasasa_email/1` from the same assigns, so every send is
  # multipart (better deliverability + readable in text-only clients / AT).
  def tibasasa_email_text(%{} = a) do
    parts =
      [a.heading, "", a.intro] ++
        (a[:body] || []) ++
        highlight_text(a[:highlight]) ++
        cta_text(a[:cta_label], a[:url]) ++
        outro_text(a[:outro]) ++
        ["", "--", "Tibasasa · Medical Camp Management"]

    parts |> Enum.reject(&is_nil/1) |> Enum.join("\n")
  end

  defp highlight_text(%{value: value} = h), do: ["", "#{h[:label] || "Code"}: #{value}"]
  defp highlight_text(_), do: []

  defp cta_text(label, url) when is_binary(label) and is_binary(url), do: ["", "#{label}:", url]
  defp cta_text(_label, _url), do: []

  defp outro_text(outro) when is_binary(outro) and outro != "", do: ["", outro]
  defp outro_text(_), do: []

  # Sends one transactional message built from the shared shell, HTML + text.
  defp deliver_tibasasa(recipient, subject, %{} = assigns) do
    send_email(recipient, subject,
      html_body: tibasasa_email(assigns),
      text_body: tibasasa_email_text(assigns)
    )
  end

  @doc """
  Deliver a patient's account PIN to their email. `opts[:first_name]` and
  `opts[:organisation_name]` personalise the greeting when available.
  """
  def deliver_pin_to_patient(patient_email, patient_pin, opts \\ []) do
    greeting =
      if opts[:first_name] in [nil, ""], do: "Hello,", else: "Hello #{opts[:first_name]},"

    org = opts[:organisation_name]
    org_phrase = if is_binary(org) and org != "", do: "Your #{org} account", else: "Your account"

    deliver_tibasasa(patient_email, "Your patient PIN", %{
      heading: "Your patient PIN",
      intro: "#{greeting} #{org_phrase} is ready. Use this PIN when you visit a camp station.",
      highlight: %{label: "Your PIN", value: patient_pin},
      outro:
        "Keep this PIN private - it identifies you at the camp. Please don't reply to this email."
    })
  end

  def deliver_feedback_request_email(patient_name, patient_email, visit_date) do
    name = if patient_name in [nil, ""], do: "Hello,", else: "Hello #{patient_name},"

    intro =
      "#{name} thank you for visiting us#{if visit_date, do: " on #{visit_date}", else: ""}. " <>
        "We'd value a moment of your time to tell us how it went."

    deliver_tibasasa(patient_email, "How was your visit?", %{
      heading: "How was your visit?",
      intro: intro,
      outro: "If you'd rather not, no problem - you can ignore this email."
    })
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    _ = user

    deliver_tibasasa(user.email, "Confirmation instructions", %{
      heading: "Confirm your email",
      intro: "Confirm this address to finish setting up your account.",
      cta_label: "Confirm email",
      url: url,
      outro: "If you didn't create an account, you can safely ignore this email."
    })
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    _ = user

    deliver_tibasasa(user.email, "Reset password instructions", %{
      heading: "Reset your password",
      intro:
        "We received a request to reset your password. Choose a new one with the button below.",
      cta_label: "Reset password",
      url: url,
      outro: "If you didn't request this, you can safely ignore this email."
    })
  end

  @doc """
  Invites a staff member (any role) to activate their account by choosing a
  password. Framed as an invitation, not a password reset.
  """
  def deliver_staff_invitation_instructions(user, url, opts \\ []) do
    role = opts[:role] || user.role
    org = opts[:organisation_name]

    org_phrase = if is_binary(org) and org != "", do: " on #{org}", else: ""
    role_phrase = if is_binary(role) and role != "", do: " as a #{role}", else: ""

    deliver_tibasasa(user.email, "Set up your account", %{
      heading: "Set up your account",
      intro:
        "An administrator created an account for you#{org_phrase}#{role_phrase}. " <>
          "Choose a password to activate it.",
      cta_label: "Set your password",
      url: url
    })
  end

  @doc """
  Invites a new organisation admin to set their password.
  """
  def deliver_admin_invitation_instructions(user, organisation, url) do
    deliver_tibasasa(user.email, "Set up your #{organisation.name} admin account", %{
      heading: "Set up your admin account",
      intro:
        "You have been invited to administer #{organisation.name}. " <>
          "Choose a password below, then sign in with #{user.email}.",
      cta_label: "Set your password",
      url: url,
      outro: "If you weren't expecting this invitation, you can ignore this email."
    })
  end

  @doc """
  Notifies a pending organisation's first admin that the tenant has been approved.
  """
  def deliver_organisation_approved_instructions(user, organisation, url) do
    deliver_tibasasa(user.email, "#{organisation.name} is approved - set your admin password", %{
      heading: "#{organisation.name} is approved",
      intro:
        "Your organisation is now active. Set your admin password below, then sign in with " <>
          "#{user.email}.",
      cta_label: "Set your admin password",
      url: url,
      outro: "If you weren't expecting this, please contact support."
    })
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    _ = user

    deliver_tibasasa(user.email, "Update email instructions", %{
      heading: "Confirm your new email",
      intro: "Confirm your new email address with the button below.",
      cta_label: "Confirm email",
      url: url,
      outro: "If you didn't request this change, you can safely ignore this email."
    })
  end

  defp send_email(recipient, subject, body_options) do
    config = Application.get_env(:medcamp, __MODULE__, [])

    with {:ok, api_key} <- required_config(config, :api_key) do
      payload =
        %{
          "to" => List.wrap(recipient),
          "from" => format_from(config),
          "subject" => subject
        }
        |> maybe_put_body("plain_body", body_options[:text_body])
        |> maybe_put_body("html_body", body_options[:html_body])

      headers = [
        {"x-server-api-key", api_key},
        {"content-type", "application/json"},
        {"accept", "application/json"}
      ]

      http_client = Keyword.get(config, :http_client, Medcamp.Postal.FinchClient)
      api_url = Keyword.get(config, :api_url, @default_api_url)

      api_url
      |> http_client.post(Jason.encode!(payload), headers)
      |> process_response()
    end
  end

  defp maybe_put_body(payload, _key, nil), do: payload
  defp maybe_put_body(payload, key, body), do: Map.put(payload, key, body)

  defp format_from(config) do
    address = Keyword.get(config, :from, @default_from)

    case config |> Keyword.get(:from_name) |> to_string() |> String.trim() do
      "" -> address
      name -> "#{name} <#{address}>"
    end
  end

  defp required_config(config, key) do
    case config |> Keyword.get(key) |> to_string() |> String.trim() do
      "" -> {:error, {:missing_config, key}}
      value -> {:ok, value}
    end
  end

  defp process_response({:ok, %{status: status, body: body} = response})
       when status in 200..299 do
    {:ok, body, response}
  end

  defp process_response({:ok, response}), do: {:error, response}
  defp process_response({:error, reason}), do: {:error, reason}
end

defmodule Medcamp.Postal.FinchClient do
  @moduledoc false

  def post(url, body, headers) do
    :post
    |> Finch.build(url, headers, body)
    |> Finch.request(Medcamp.Finch)
  rescue
    error -> {:error, Exception.message(error)}
  catch
    kind, reason -> {:error, {kind, reason}}
  end
end
