defmodule Medcamp.Postal do
  @moduledoc """
  Delivers application email through the MailSafi Postal HTTP API.
  """

  @default_api_url "https://postalmail.mailsafi.com/api/v1/send/message"
  @default_from "no-reply@gs1kenya.org"

  def deliver(recipient, subject, body) do
    send_email(recipient, subject, text_body: body)
  end

  defp deliver_with_template(user, type, subject, url) do
    html = generate_email_html(user, type, url)
    send_email(user.email, subject, html_body: html)
  end

  def deliver_combined_receipt(recipient_email, receipts) when is_list(receipts) do
    html = generate_combined_receipt_html(receipts)

    total =
      receipts
      |> Enum.map(& &1.amount)
      |> Enum.reduce(0, fn amt, acc ->
        case amt do
          a when is_float(a) ->
            acc + a

          a when is_integer(a) ->
            acc + a

          a when is_binary(a) ->
            case Float.parse(a) do
              {f, _} -> acc + f
              :error -> acc
            end

          _ ->
            acc
        end
      end)

    send_email(recipient_email, "Combined Payment Receipt – KES #{format_amount(total)}",
      html_body: html
    )
  end

  defp generate_combined_receipt_html(receipts) do
    rows =
      receipts
      |> Enum.with_index(1)
      |> Enum.map(fn {r, idx} ->
        receipt_ref = r[:receipt_number] || "—"
        service = r[:service_details] || "Payment"
        amount = format_amount(r[:amount])
        date = format_date(r[:transaction_date])

        """
        <tr style='border-bottom: 1px solid #e7e7ff;'>
          <td style='padding: 12px 8px; color: #6c757d;'>#{idx}</td>
          <td style='padding: 12px 8px; color: #373896; font-weight: 500;'>#{service}</td>
          <td style='padding: 12px 8px; color: #6c757d;'>#{receipt_ref}</td>
          <td style='padding: 12px 8px; color: #6c757d;'>#{date}</td>
          <td style='padding: 12px 8px; color: #373896; font-weight: 600; text-align: right;'>KES #{amount}</td>
        </tr>
        """
      end)
      |> Enum.join("\n")

    total =
      receipts
      |> Enum.reduce(0, fn r, acc ->
        case r[:amount] do
          a when is_float(a) ->
            acc + a

          a when is_integer(a) ->
            acc + a

          a when is_binary(a) ->
            case Float.parse(a) do
              {f, _} -> acc + f
              :error -> acc
            end

          _ ->
            acc
        end
      end)

    """
    <!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>
    <html xmlns='http://www.w3.org/1999/xhtml'>
    <head>
      <meta http-equiv='Content-Type' content='text/html; charset=UTF-8' />
      <title>Glocal Health Centre – Combined Receipt</title>
      <meta name='viewport' content='width=device-width, initial-scale=1.0'/>
    </head>
    <body style='margin: 0; padding: 0; background-color: #f8f8ff; font-family: Segoe UI, Tahoma, Geneva, Verdana, sans-serif;'>
      <div style='width: 100%; background-color: #f8f8ff; padding: 30px 0;'>
        <table align='center' border='0' cellpadding='0' cellspacing='0' width='640'
               style='border-collapse: collapse; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1);'>

          <!-- Header -->
          <tr>
            <td style='background-color: #373896; padding: 20px 30px;'>
              <table border='0' cellpadding='0' cellspacing='0' width='100%'>
                <tr>
                  <td style='color: white; font-size: 22px; font-weight: bold;'>Combined Payment Receipt</td>
                  <td align='right'>
                    <span style='color: #c7c7ff; font-size: 13px;'>Glocal Health Centre</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style='padding: 35px 30px;'>
              <h2 style='color: #373896; margin-top: 0; margin-bottom: 16px; font-weight: 600;'>Thank You for Your Payments</h2>
              <p style='color: #444; font-size: 15px; line-height: 1.6; margin-bottom: 24px;'>
                Below is a summary of all your recent payments at Glocal Health Centre.
              </p>

              <!-- Payments table -->
              <table border='0' cellpadding='0' cellspacing='0' width='100%'
                     style='background-color: #f0f0ff; border: 1px solid #e7e7ff; border-radius: 8px; overflow: hidden;'>
                <thead>
                  <tr style='background-color: #373896;'>
                    <th style='padding: 10px 8px; color: white; font-size: 13px; text-align: left;'>#</th>
                    <th style='padding: 10px 8px; color: white; font-size: 13px; text-align: left;'>Service</th>
                    <th style='padding: 10px 8px; color: white; font-size: 13px; text-align: left;'>Receipt No.</th>
                    <th style='padding: 10px 8px; color: white; font-size: 13px; text-align: left;'>Date</th>
                    <th style='padding: 10px 8px; color: white; font-size: 13px; text-align: right;'>Amount</th>
                  </tr>
                </thead>
                <tbody>
                  #{rows}
                </tbody>
                <tfoot>
                  <tr style='background-color: #e7e7ff;'>
                    <td colspan='4' style='padding: 14px 8px; font-weight: 700; color: #373896; font-size: 15px;'>Total</td>
                    <td style='padding: 14px 8px; font-weight: 700; color: #373896; font-size: 18px; text-align: right;'>KES #{format_amount(total)}</td>
                  </tr>
                </tfoot>
              </table>

              <p style='color: #444; font-size: 15px; line-height: 1.6; margin-top: 28px;'>
                If you have any questions about these payments, please contact our support team.
              </p>
              <p style='color: #444; font-size: 15px;'>
                Thank you for choosing Glocal Health Centre,<br />
                <span style='color: #373896; font-weight: 500;'>The Glocal Health Centre Team</span>
              </p>
            </td>
          </tr>

          <!-- Separator -->
          <tr><td style='height: 2px; background-color: #f0f0ff;'></td></tr>

          <!-- Footer -->
          <tr>
            <td bgcolor='#f8f8ff' style='padding: 20px 30px; text-align: center;'>
              <p style='color: #6c757d; font-size: 13px; margin: 0;'>
                &copy; #{Date.utc_today().year} Glocal Health Centre. All Rights Reserved.
              </p>
              <p style='color: #6c757d; font-size: 12px; margin: 6px 0 0 0;'>
                This is an automated message, please do not reply to this email.
              </p>
            </td>
          </tr>

        </table>
      </div>
    </body>
    </html>
    """
  end

  def deliver_purchase_receipt(patient_email, receipt_data) do
    html = generate_receipt_email_html(patient_email, receipt_data)

    send_email(patient_email, "Payment Confirmation - #{receipt_data.service_details} Receipt",
      html_body: html
    )
  end

  # Generate the HTML template for receipt emails
  defp generate_receipt_email_html(_patient_email, receipt_data) do
    """
    <!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>
    <html xmlns='http://www.w3.org/1999/xhtml'>
    <head>
      <meta http-equiv='Content-Type' content='text/html; charset=UTF-8' />
      <title>Glocal Health Centre</title>
      <meta name='viewport' content='width=device-width, initial-scale=1.0'/>
      <style type='text/css'>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
      </style>
    </head>
    <body style='margin: 0; padding: 0; background-color: #f8f8ff;'>
      <div style='width: 100%; background-color: #f8f8ff; padding: 30px 0;'>
        <table align='center' border='0' cellpadding='0' cellspacing='0' width='600' style='border-collapse: collapse; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);'>
          <!-- Header -->
          <tr>
            <td style='background-color: #373896; padding: 20px 30px;'>
              <table border='0' cellpadding='0' cellspacing='0' width='100%'>
                <tr>
                  <td style='color: white; font-size: 24px; font-weight: bold;'>
                    Payment Confirmation :
                  </td>
                  <td align='right'>
                    <span style='color: white; font-size: 16px; margin-left: 10px;'>#{format_date(receipt_data.transaction_date)}</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Content -->
          <tr>
            <td style='padding: 40px 30px;'>
              <table border='0' cellpadding='0' cellspacing='0' width='100%'>
                <tr>
                  <td>
                    <h2 style='color: #373896; margin-top: 0; margin-bottom: 20px; font-weight: 600;'>Thank You for Your Payment</h2>
                    <p style='color: #444; font-size: 16px; line-height: 1.6; margin-bottom: 25px;'>
                      Hello,
                    </p>
                    <p style='color: #444; font-size: 16px; line-height: 1.6; margin-bottom: 25px;'>
                      Your payment for <strong>#{receipt_data.service_details}</strong> has been successfully processed. Below are the details of your transaction:
                    </p>

                    <!-- Receipt details box -->
                    <div style='background-color: #f0f0ff; border: 1px solid #e7e7ff; border-radius: 8px; padding: 25px; margin: 20px 0 30px 0;'>
                      <table border='0' cellpadding='0' cellspacing='0' width='100%'>
                        <tr>
                          <td style='color: #6c757d; padding-bottom: 15px;'>Receipt Number:</td>
                          <td style='color: #373896; font-weight: 500; text-align: right; padding-bottom: 15px;'>#{receipt_data.receipt_number}</td>
                        </tr>
                        <tr>
                          <td style='color: #6c757d; padding-bottom: 15px;'>Amount Paid:</td>
                          <td style='color: #373896; font-weight: 600; text-align: right; padding-bottom: 15px; font-size: 18px;'>KES #{format_amount(receipt_data.amount)}</td>
                        </tr>
                        <tr>
                          <td style='color: #6c757d; padding-bottom: 15px;'>Payment Method:</td>
                          <td style='color: #373896; font-weight: 500; text-align: right; padding-bottom: 15px;'>#{receipt_data[:payment_method] || "M-PESA"}</td>
                        </tr>
                        <tr>
                          <td style='color: #6c757d; padding-bottom: 15px;'>Phone Number:</td>
                          <td style='color: #373896; font-weight: 500; text-align: right; padding-bottom: 15px;'>#{format_phone(receipt_data[:phone_number])}</td>
                        </tr>
                        <tr>
                          <td style='color: #6c757d; padding-bottom: 15px;'>Service:</td>
                          <td style='color: #373896; font-weight: 500; text-align: right; padding-bottom: 15px;'>#{receipt_data.service_details}</td>
                        </tr>



                        <tr>
                          <td style='color: #6c757d;'>Status:</td>
                          <td style='text-align: right;'>
                            <span style='background-color: #28a745; color: white; font-size: 12px; font-weight: 500; padding: 4px 10px; border-radius: 30px;'>
                              PAID
                            </span>
                          </td>
                        </tr>
                      </table>
                    </div>

                    <!-- View Payment Button -->
                    <div style='text-align: center; margin: 30px 0;'>
                      <a href='https://glocalhealthcentre.org/payment/#{receipt_data.receipt_number}'
                         style='display: inline-block; background-color: #373896; color: white; text-decoration: none;
                                padding: 12px 30px; border-radius: 6px; font-weight: 600; font-size: 16px;
                                transition: background-color 0.3s ease;'>
                        View Payment Details
                      </a>
                    </div>

                    <p style='color: #444; font-size: 16px; line-height: 1.6; margin-top: 30px;'>
                      Your payment has been confirmed and your service has been processed. If you have any questions or need assistance, please contact our support team.
                    </p>
                    <p style='color: #444; font-size: 16px; line-height: 1.6;'>
                      Thank you for choosing Glocal Health Centre,<br />
                      <span style='color: #373896; font-weight: 500;'>The Glocal Health Centre Team</span>
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Separator -->
          <tr>
            <td style='height: 2px; background-color: #f0f0ff;'></td>
          </tr>

          <!-- Footer -->
          <tr>
            <td bgcolor='#f8f8ff' style='padding: 20px 30px;'>
              <table border='0' cellpadding='0' cellspacing='0' width='100%'>
                <tr>
                  <td style='color: #6c757d; font-size: 14px; text-align: center;'>
                    &copy; <span id='year'></span> Glocal Health Centre. All Rights Reserved.
                    <script>document.getElementById('year').textContent = new Date().getFullYear();</script>
                  </td>
                </tr>
                <tr>
                  <td style='padding-top: 10px; text-align: center;'>
                    <a href='#' style='color: #6667ab; text-decoration: none; font-size: 14px; margin: 0 10px;'>Privacy Policy</a>
                    <a href='#' style='color: #6667ab; text-decoration: none; font-size: 14px; margin: 0 10px;'>Terms of Service</a>
                    <a href='#' style='color: #6667ab; text-decoration: none; font-size: 14px; margin: 0 10px;'>Contact Us</a>
                  </td>
                </tr>
                <tr>
                  <td style='padding-top: 20px; text-align: center;'>
                    <p style='color: #6c757d; font-size: 12px; margin: 0;'>
                      This is an automated message, please do not reply to this email.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </div>
    </body>
    </html>
    """
  end

  # Helper functions for formatting display values
  defp format_date(nil), do: "—"

  defp format_date(timestamp) when is_binary(timestamp) do
    case Integer.parse(timestamp) do
      {unix_time, _} -> format_date(unix_time)
      :error -> timestamp
    end
  end

  defp format_date(timestamp) when is_integer(timestamp) do
    # Convert timestamp to DateTime, add 3 hours, and format
    {:ok, datetime} = DateTime.from_unix(timestamp)
    adjusted_datetime = DateTime.add(datetime, 3, :hour)
    date_str = Calendar.strftime(adjusted_datetime, "%B %d, %Y")
    time_str = Calendar.strftime(adjusted_datetime, "%I:%M %p")
    "#{date_str} at #{time_str}"
  rescue
    _ -> "#{timestamp}"
  end

  defp format_amount(amount) when is_float(amount) do
    :erlang.float_to_binary(amount, decimals: 2)
  end

  defp format_amount(amount) when is_integer(amount) do
    "#{amount}.00"
  end

  defp format_amount(amount) when is_binary(amount) do
    case Float.parse(amount) do
      {float_amount, _} -> format_amount(float_amount)
      :error -> amount
    end
  end

  defp format_amount(nil), do: "0.00"

  defp format_phone(nil), do: "N/A"
  defp format_phone(""), do: "N/A"

  defp format_phone(phone) when is_binary(phone) do
    if String.starts_with?(phone, "254") do
      "+#{phone}"
    else
      phone
    end
  end

  defp format_phone(phone) when is_integer(phone) do
    format_phone(Integer.to_string(phone))
  end

  # Adapter kept for the confirm / reset / change-email callers.
  defp generate_email_html(user, type, url) do
    {heading, intro, cta} =
      case type do
        "reset" ->
          {"Reset your password",
           "We received a request to reset the password for your account. Choose a new one with the button below.",
           "Reset password"}

        "confirm" ->
          {"Confirm your email", "Confirm this address to finish setting up your account.",
           "Confirm email"}

        _ ->
          {"Confirm your new email", "Confirm your new email address with the button below.",
           "Confirm email"}
      end

    _ = user

    tibasasa_email(%{
      heading: heading,
      intro: intro,
      cta_label: cta,
      url: url,
      outro: "If you didn't request this, you can safely ignore this email."
    })
  end

  @doc false
  # The shared Tibasasa email shell, styled to match the app's utility pages
  # (see error_html/*): logo lockup, one white card on an off-white ground,
  # navy heading, navy pill CTA, monospace link fallback, a single hairline
  # footer line - no dark bar. Table layout + inline styles only, so it holds
  # up across email clients.
  def tibasasa_email(%{} = a) do
    font =
      "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"

    logo = MedcampWeb.Endpoint.url() <> "/images/tibasasa-ai-logo.png"

    outro = a[:outro] || "If you weren't expecting this, you can ignore this email."

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
                  <p style='margin:0 0 24px 0; font-size:15px; line-height:1.6; color:#475569;'>#{a.intro}</p>

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
                  <p style='margin:16px 0 0 0; font-size:13px; line-height:1.6; color:#94a3b8;'>#{outro}</p>
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

  # Create a specific HTML template for the PIN email
  defp generate_pin_email_html(_patient_email, pin) do
    """
    <!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>
    <html xmlns='http://www.w3.org/1999/xhtml'>
    <head>
      <meta http-equiv='Content-Type' content='text/html; charset=UTF-8' />
      <title>Glocal Health Centre</title>
      <meta name='viewport' content='width=device-width, initial-scale=1.0'/>
      <style type='text/css'>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
      </style>
    </head>
    <body style='margin: 0; padding: 0; background-color: #f8f8ff;'>
      <div style='width: 100%; background-color: #f8f8ff; padding: 30px 0;'>
        <table align='center' border='0' cellpadding='0' cellspacing='0' width='600' style='border-collapse: collapse; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);'>


          <!-- Content -->
          <tr>
            <td style='padding: 40px 30px;'>
              <table border='0' cellpadding='0' cellspacing='0' width='100%'>
                <tr>
                  <td>
                    <h2 style='color: #373896; margin-top: 0; margin-bottom: 20px; font-weight: 600;'>Your Patient Account PIN</h2>
                    <p style='color: #444; font-size: 16px; line-height: 1.6; margin-bottom: 15px;'>
                      Hello,
                    </p>
                    <p style='color: #444; font-size: 16px; line-height: 1.6; margin-bottom: 25px;'>
                      Your Glocal Health Centre account has been set up successfully. Below is your PIN, which you'll need for accessing our services:
                    </p>

                    <!-- PIN display box -->
                    <div style='background-color: #f0f0ff; border: 1px solid #e7e7ff; border-radius: 8px; padding: 20px; text-align: center; margin: 30px 0;'>
                      <p style='color: #373896; font-size: 14px; margin: 0 0 10px 0; font-weight: 500;'>YOUR PIN</p>
                      <p style='color: #373896; font-size: 32px; letter-spacing: 8px; font-weight: 700; margin: 0;'>#{pin}</p>
                    </div>

                    <p style='color: #444; font-size: 16px; line-height: 1.6; margin-bottom: 15px;'>
                      Please keep this PIN private and do not share it with anyone. You'll need it when visiting our health center.
                    </p>
                    <p style='color: #444; font-size: 16px; line-height: 1.6; margin-bottom: 15px;'>
                      If you have any questions or need assistance, please contact our support team.
                    </p>
                    <p style='color: #444; font-size: 16px; line-height: 1.6;'>
                      Thank you for choosing Glocal Health Centre,<br />
                      <span style='color: #373896; font-weight: 500;'>The Glocal Health Centre Team</span>
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Separator -->
          <tr>
            <td style='height: 2px; background-color: #f0f0ff;'></td>
          </tr>

          <!-- Footer -->
          <tr>
            <td bgcolor='#f8f8ff' style='padding: 20px 30px;'>
              <table border='0' cellpadding='0' cellspacing='0' width='100%'>
                <tr>
                  <td style='color: #6c757d; font-size: 14px; text-align: center;'>
                    &copy; <span id='year'></span> Glocal Health Centre. All Rights Reserved.
                    <script>document.getElementById('year').textContent = new Date().getFullYear();</script>
                  </td>
                </tr>
                <tr>
                  <td style='padding-top: 10px; text-align: center;'>
                    <a href='#' style='color: #6667ab; text-decoration: none; font-size: 14px; margin: 0 10px;'>Privacy Policy</a>
                    <a href='#' style='color: #6667ab; text-decoration: none; font-size: 14px; margin: 0 10px;'>Terms of Service</a>
                    <a href='#' style='color: #6667ab; text-decoration: none; font-size: 14px; margin: 0 10px;'>Contact Us</a>
                  </td>
                </tr>
                <tr>
                  <td style='padding-top: 20px; text-align: center;'>
                    <p style='color: #6c757d; font-size: 12px; margin: 0;'>
                      This is an automated message, please do not reply to this email.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </div>
    </body>
    </html>
    """
  end

  def generate_feedback_request_email_html(patient_name, visit_date) do
    """
    <!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>
    <html xmlns='http://www.w3.org/1999/xhtml'>
    <head>
      <meta http-equiv='Content-Type' content='text/html; charset=UTF-8' />
      <title>Glocal Health Centre - Your Feedback Matters</title>
      <meta name='viewport' content='width=device-width, initial-scale=1.0'/>
      <style type='text/css'>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
      </style>
    </head>
    <body style='margin: 0; padding: 0; background-color: #f8f8ff;'>
      <div style='width: 100%; background-color: #f8f8ff; padding: 30px 0;'>
        <table align='center' border='0' cellpadding='0' cellspacing='0' width='600' style='border-collapse: collapse; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);'>

          <!-- Header -->
          <tr>
            <td bgcolor='#373896' style='padding: 30px 30px 25px 30px;'>
              <table border='0' cellpadding='0' cellspacing='0' width='100%'>
                <tr>
                  <td style='text-align: center;'>
                    <h1 style='color: white; margin: 0; font-size: 28px; font-weight: 600;'>Thank You for Your Visit!</h1>
                    <p style='color: #e7e7ff; margin: 8px 0 0 0; font-size: 16px;'>Your feedback helps us improve our care</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Content -->
          <tr>
            <td style='padding: 40px 30px;'>
              <table border='0' cellpadding='0' cellspacing='0' width='100%'>
                <tr>
                  <td>
                    <h2 style='color: #373896; margin-top: 0; margin-bottom: 20px; font-weight: 600;'>How Was Your Experience?</h2>
                    <p style='color: #444; font-size: 16px; line-height: 1.6; margin-bottom: 15px;'>
                      Hello #{patient_name || "Valued Patient"},
                    </p>
                    <p style='color: #444; font-size: 16px; line-height: 1.6; margin-bottom: 15px;'>
                      We hope your visit to Glocal Health Centre on #{visit_date || "your recent visit"} went well and that you received the quality care you deserved.
                    </p>
                    <p style='color: #444; font-size: 16px; line-height: 1.6; margin-bottom: 25px;'>
                      Your feedback is incredibly valuable to us. It helps us understand what we're doing well and where we can improve to better serve you and other patients in our community.
                    </p>

                    <!-- Feedback Call-to-Action Box -->
                    <div style='background: linear-gradient(135deg, #f0f0ff 0%, #e7e7ff 100%); border: 1px solid #d0d0ff; border-radius: 12px; padding: 30px; text-align: center; margin: 30px 0;'>
                      <div style='margin-bottom: 20px;'>
                        <span style='font-size: 48px; margin-bottom: 15px; display: block;'>💬</span>
                        <p style='color: #373896; font-size: 18px; margin: 0; font-weight: 600;'>Share Your Experience</p>
                        <p style='color: #666; font-size: 14px; margin: 5px 0 0 0;'>Takes just 2-3 minutes</p>
                      </div>

                      <!-- Feedback Button -->
                      <a href='https://glocalhealthcentre.org/feedback' style='display: inline-block; background: linear-gradient(135deg, #373896 0%, #4a4ba8 100%); color: white; text-decoration: none; padding: 15px 30px; border-radius: 8px; font-weight: 600; font-size: 16px; box-shadow: 0 4px 8px rgba(55, 56, 150, 0.3); transition: all 0.3s ease;'>
                        Give Feedback Now
                      </a>

                      <p style='color: #666; font-size: 12px; margin: 15px 0 0 0; line-height: 1.4;'>
                        Your responses are confidential and help us improve our services
                      </p>
                    </div>

                    <!-- Benefits of Feedback -->
                    <div style='background-color: #f8f9fa; border-left: 4px solid #373896; padding: 20px; margin: 25px 0; border-radius: 0 8px 8px 0;'>
                      <h3 style='color: #373896; margin-top: 0; margin-bottom: 15px; font-size: 16px; font-weight: 600;'>Your feedback helps us:</h3>
                      <ul style='color: #444; font-size: 14px; line-height: 1.6; margin: 0; padding-left: 20px;'>
                        <li style='margin-bottom: 8px;'>Improve our services and patient care quality</li>
                        <li style='margin-bottom: 8px;'>Train our staff to better serve your needs</li>
                        <li style='margin-bottom: 8px;'>Enhance our facilities and processes</li>
                        <li style='margin-bottom: 0;'>Ensure every patient receives excellent care</li>
                      </ul>
                    </div>

                    <p style='color: #444; font-size: 16px; line-height: 1.6; margin-bottom: 15px;'>
                      We truly appreciate you taking the time to share your thoughts with us. Every piece of feedback helps us become better.
                    </p>
                    <p style='color: #444; font-size: 16px; line-height: 1.6;'>
                      Thank you for choosing Glocal Health Centre for your healthcare needs,<br />
                      <span style='color: #373896; font-weight: 500;'>The Glocal Health Centre Team</span>
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Separator -->
          <tr>
            <td style='height: 2px; background-color: #f0f0ff;'></td>
          </tr>

          <!-- Footer -->
          <tr>
            <td bgcolor='#f8f8ff' style='padding: 20px 30px;'>
              <table border='0' cellpadding='0' cellspacing='0' width='100%'>
                <tr>
                  <td style='color: #6c757d; font-size: 14px; text-align: center;'>
                    &copy; <span id='year'></span> Glocal Health Centre. All Rights Reserved.
                    <script>document.getElementById('year').textContent = new Date().getFullYear();</script>
                  </td>
                </tr>
                <tr>
                  <td style='padding-top: 10px; text-align: center;'>
                    <a href='#' style='color: #6667ab; text-decoration: none; font-size: 14px; margin: 0 10px;'>Privacy Policy</a>
                    <a href='#' style='color: #6667ab; text-decoration: none; font-size: 14px; margin: 0 10px;'>Terms of Service</a>
                    <a href='#' style='color: #6667ab; text-decoration: none; font-size: 14px; margin: 0 10px;'>Contact Us</a>
                  </td>
                </tr>
                <tr>
                  <td style='padding-top: 15px; text-align: center;'>
                    <p style='color: #6c757d; font-size: 12px; margin: 0 0 10px 0;'>
                      Questions about your visit? Call us at <a href='tel:+254726776293' style='color: #373896; text-decoration: none;'>+254 726 776 293</a>
                    </p>
                    <p style='color: #6c757d; font-size: 12px; margin: 0;'>
                      This is an automated message, please do not reply to this email.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </div>
    </body>
    </html>
    """
  end

  # Function to generate email HTML for low assigned tags notification
  defp generate_assigned_tags_notification_email_html(_admin_email, tags_data) do
    """
    <!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>
    <html xmlns='http://www.w3.org/1999/xhtml'>
    <head>
      <meta http-equiv='Content-Type' content='text/html; charset=UTF-8' />
      <title>Glocal Health Centre - Low Assigned Tags Alert</title>
      <meta name='viewport' content='width=device-width, initial-scale=1.0'/>
      <style type='text/css'>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
      </style>
    </head>
    <body style='margin: 0; padding: 0; background-color: #f8f8ff;'>
      <div style='width: 100%; background-color: #f8f8ff; padding: 30px 0;'>
        <table align='center' border='0' cellpadding='0' cellspacing='0' width='600' style='border-collapse: collapse; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);'>
          <!-- Header -->
          <tr>
            <td style='background-color: #ff6b35; padding: 20px 30px;'>
              <table border='0' cellpadding='0' cellspacing='0' width='100%'>
                <tr>
                  <td style='color: white; font-size: 24px; font-weight: bold;'>
                    ⚠️ Low Stock Alert
                  </td>
                  <td align='right'>
                    <span style='color: white; font-size: 16px; margin-left: 10px;'>#{format_current_date()}</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Content -->
          <tr>
            <td style='padding: 40px 30px;'>
              <table border='0' cellpadding='0' cellspacing='0' width='100%'>
                <tr>
                  <td>
                    <h2 style='color: #373896; margin-top: 0; margin-bottom: 20px; font-weight: 600;'>Assigned Tags Running Low</h2>
                    <p style='color: #444; font-size: 16px; line-height: 1.6; margin-bottom: 25px;'>
                      Hello Admin,
                    </p>
                    <p style='color: #444; font-size: 16px; line-height: 1.6; margin-bottom: 25px;'>
                      This is an automated notification to inform you that your assigned tags inventory has reached the <strong>low stock threshold of 20 remaining tags</strong>. Please consider ordering more tags to avoid service interruptions.
                    </p>

                    <!-- Alert details box -->
                    <div style='background-color: #fff5f5; border: 2px solid #fed7d7; border-radius: 8px; padding: 25px; margin: 20px 0 30px 0;'>
                      <table border='0' cellpadding='0' cellspacing='0' width='100%'>
                        <tr>
                          <td style='color: #6c757d; padding-bottom: 15px;'>Alert Type:</td>
                          <td style='color: #e53e3e; font-weight: 600; text-align: right; padding-bottom: 15px;'>LOW STOCK WARNING</td>
                        </tr>
                        <tr>
                          <td style='color: #6c757d; padding-bottom: 15px;'>Current Remaining Tags:</td>
                          <td style='color: #e53e3e; font-weight: 600; text-align: right; padding-bottom: 15px; font-size: 18px;'>#{tags_data.remaining_number} tags</td>
                        </tr>
                        <tr>
                          <td style='color: #6c757d; padding-bottom: 15px;'>Threshold Level:</td>
                          <td style='color: #373896; font-weight: 500; text-align: right; padding-bottom: 15px;'>20 tags</td>
                        </tr>


                        <tr>
                          <td style='color: #6c757d;'>Status:</td>
                          <td style='text-align: right;'>
                            <span style='background-color: #ff6b35; color: white; font-size: 12px; font-weight: 500; padding: 4px 10px; border-radius: 30px;'>
                              ACTION REQUIRED
                            </span>
                          </td>
                        </tr>
                      </table>
                    </div>

                    <!-- Action Buttons -->
                    <div style='text-align: center; margin: 30px 0;'>
                      <table border='0' cellpadding='0' cellspacing='0' style='margin: 0 auto;'>
                        <tr>
                          <td style='padding-right: 10px;'>
                            <a href='https://glocalhealthcentre.org/admin/assigned_tags'
                               style='display: inline-block; background-color: #373896; color: white; text-decoration: none;
                                      padding: 12px 25px; border-radius: 6px; font-weight: 600; font-size: 14px;
                                      transition: background-color 0.3s ease;'>
                              View Assigned Tags
                            </a>
                          </td>
                          <td style='padding-left: 10px;'>
                            <a href='https://glocalhealthcentre.org/admin/assigned_tags/new'
                               style='display: inline-block; background-color: #38a169; color: white; text-decoration: none;
                                      padding: 12px 25px; border-radius: 6px; font-weight: 600; font-size: 14px;
                                      transition: background-color 0.3s ease;'>
                              Add New Tags
                            </a>
                          </td>
                        </tr>
                      </table>
                    </div>

                    <!-- Recommendation Box -->
                    <div style='background-color: #e6fffa; border: 1px solid #b2f5ea; border-radius: 8px; padding: 20px; margin: 25px 0;'>
                      <h4 style='color: #319795; margin: 0 0 10px 0; font-size: 16px; font-weight: 600;'>💡 Recommended Actions:</h4>
                      <ul style='color: #2d3748; font-size: 14px; margin: 0; padding-left: 20px; line-height: 1.5;'>
                        <li>Order additional assigned tags immediately</li>
                        <li>Review current tag usage patterns</li>
                        <li>Consider adjusting reorder threshold if necessary</li>
                        <li>Notify relevant staff about the low inventory</li>
                      </ul>
                    </div>

                    <p style='color: #444; font-size: 16px; line-height: 1.6; margin-top: 30px;'>
                      This automated alert helps ensure continuous service availability. Please take appropriate action to replenish your assigned tags inventory.
                    </p>
                    <p style='color: #444; font-size: 16px; line-height: 1.6;'>
                      Best regards,<br />
                      <span style='color: #373896; font-weight: 500;'>Glocal Health Centre System</span>
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Separator -->
          <tr>
            <td style='height: 2px; background-color: #f0f0ff;'></td>
          </tr>

          <!-- Footer -->
          <tr>
            <td bgcolor='#f8f8ff' style='padding: 20px 30px;'>
              <table border='0' cellpadding='0' cellspacing='0' width='100%'>
                <tr>
                  <td style='color: #6c757d; font-size: 14px; text-align: center;'>
                    &copy; <span id='year'></span> Glocal Health Centre. All Rights Reserved.
                    <script>document.getElementById('year').textContent = new Date().getFullYear();</script>
                  </td>
                </tr>
                <tr>
                  <td style='padding-top: 10px; text-align: center;'>
                    <a href='#' style='color: #6667ab; text-decoration: none; font-size: 14px; margin: 0 10px;'>Privacy Policy</a>
                    <a href='#' style='color: #6667ab; text-decoration: none; font-size: 14px; margin: 0 10px;'>Terms of Service</a>
                    <a href='#' style='color: #6667ab; text-decoration: none; font-size: 14px; margin: 0 10px;'>Contact Us</a>
                  </td>
                </tr>
                <tr>
                  <td style='padding-top: 20px; text-align: center;'>
                    <p style='color: #6c757d; font-size: 12px; margin: 0;'>
                      This is an automated system notification. Please do not reply to this email.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </div>
    </body>
    </html>
    """
  end

  defp format_current_date do
    DateTime.utc_now()
    # Adjust for your timezone (3 hours ahead of UTC)
    |> DateTime.add(3, :hour)
    |> Calendar.strftime("%B %d, %Y at %I:%M %p")
  end

  # Function to send low assigned tags notification email
  def send_assigned_tags_low_stock_notification(admin_email, tags_data) do
    html_body = generate_assigned_tags_notification_email_html(admin_email, tags_data)
    send_email(admin_email, "Low Assigned Tags Stock Alert", html_body: html_body)
  end

  @doc """
  Deliver patient PIN to patient's email
  """
  def deliver_pin_to_patient(patient_email, patient_pin) do
    html = generate_pin_email_html(patient_email, patient_pin)
    send_email(patient_email, "Your Glocal Health Centre PIN", html_body: html)
  end

  def deliver_feedback_request_email(patient_name, patient_email, visit_date) do
    html = generate_feedback_request_email_html(patient_name, visit_date)
    send_email(patient_email, "Your Feedback Matters - Glocal Health Centre", html_body: html)
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver_with_template(user, "confirm", "Confirmation instructions", url)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver_with_template(user, "reset", "Reset password instructions", url)
  end

  @doc """
  Invites a staff member (any role) to activate their account by choosing a
  password. Framed as an invitation, not a password reset.
  """
  def deliver_staff_invitation_instructions(user, url, opts \\ []) do
    role = opts[:role] || user.role
    org = opts[:organisation_name]

    org_phrase =
      if is_binary(org) and org != "", do: " on #{org}", else: ""

    role_phrase =
      if is_binary(role) and role != "", do: " as a #{role}", else: ""

    html =
      tibasasa_email(%{
        heading: "Set up your account",
        intro:
          "An administrator created an account for you#{org_phrase}#{role_phrase}. " <>
            "Choose a password to activate it.",
        cta_label: "Set your password",
        url: url
      })

    send_email(user.email, "Set up your account", html_body: html)
  end

  @doc """
  Invites a new organisation admin to set their password.
  """
  def deliver_admin_invitation_instructions(user, organisation, url) do
    body = """
    Hello #{user.name || user.email},

    You have been invited to administer #{organisation.name} on Tibasasa Medical Camp.

    Set your password using the secure link below, then sign in with #{user.email}:

    #{url}

    If you were not expecting this invitation, please ignore this email.
    """

    deliver(user.email, "Set up your #{organisation.name} admin account", body)
  end

  @doc """
  Notifies a pending organisation's first admin that the tenant has been approved.
  """
  def deliver_organisation_approved_instructions(user, organisation, url) do
    body = """
    Hello #{user.name || user.email},

    #{organisation.name} has been approved on Tibasasa Medical Camp.

    Set your admin password using the secure link below, then sign in with #{user.email}:

    #{url}

    If you were not expecting this approval email, please contact support.
    """

    deliver(user.email, "#{organisation.name} is approved - set your admin password", body)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver_with_template(user, "change your email to", "Update email instructions", url)
  end

  @doc """
  Sends a low-stock alert email to a supplier. batches: list of %Batch{} with :inventory_received preloaded.
  threshold: the reorder level used (e.g. 20).
  """
  def send_supplier_low_stock_email(supplier_email, supplier_name, batches, threshold \\ 20) do
    html_body = generate_supplier_low_stock_email_html(supplier_name, batches, threshold)

    send_email(supplier_email, "Low Stock Alert – Items You Supply Need Replenishment",
      html_body: html_body
    )
  end

  defp generate_supplier_low_stock_email_html(supplier_name, batches, threshold) do
    rows =
      Enum.map_join(batches, fn b ->
        item_name =
          if b.inventory_received do
            b.inventory_received.brand_name || b.inventory_received.generic_name || "—"
          else
            "—"
          end

        """
        <tr>
          <td style='padding: 10px 12px; border-bottom: 1px solid #e5e7eb;'>#{item_name}</td>
          <td style='padding: 10px 12px; border-bottom: 1px solid #e5e7eb;'>#{b.batch || "—"}</td>
          <td style='padding: 10px 12px; border-bottom: 1px solid #e5e7eb; text-align: right;'>#{b.remaining_quantity}</td>
          <td style='padding: 10px 12px; border-bottom: 1px solid #e5e7eb; text-align: right;'>#{threshold}</td>
        </tr>
        """
      end)

    """
    <!DOCTYPE html>
    <html>
    <head><meta charset='utf-8'/><style>body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;}</style></head>
    <body style='margin:0;padding:0;background:#f8f8ff;'>
      <div style='max-width:600px;margin:0 auto;padding:24px;'>
        <p style='font-size:16px;color:#374151;'>Hello #{supplier_name},</p>
        <p style='font-size:15px;color:#4b5563;'>
          This is an automated notification from Glocal Health Centre. The following items you supply have reached a <strong>low stock level</strong> (at or below #{threshold} units remaining). Please consider restocking to avoid supply interruptions.
        </p>
        <table style='width:100%;border-collapse:collapse;background:#fff;border:1px solid #e5e7eb;border-radius:8px;margin:16px 0;'>
          <thead>
            <tr style='background:#f3f4f6;'>
              <th style='padding:10px 12px;text-align:left;font-size:12px;text-transform:uppercase;color:#6b7280;'>Item</th>
              <th style='padding:10px 12px;text-align:left;font-size:12px;text-transform:uppercase;color:#6b7280;'>Batch</th>
              <th style='padding:10px 12px;text-align:right;font-size:12px;text-transform:uppercase;color:#6b7280;'>Remaining</th>
              <th style='padding:10px 12px;text-align:right;font-size:12px;text-transform:uppercase;color:#6b7280;'>Reorder at</th>
            </tr>
          </thead>
          <tbody>
            #{rows}
          </tbody>
        </table>
        <p style='font-size:14px;color:#6b7280;'>If you have any questions, please contact the facility.</p>
        <p style='font-size:14px;color:#6b7280;'>— Glocal Health Centre</p>
      </div>
    </body>
    </html>
    """
  end

  @doc """
  Sends a quote request email to a supplier. item_description: name of the drug/item.
  quantity: number requested. notes: optional string from the requester.
  """
  def send_supplier_quote_request_email(
        supplier_email,
        supplier_name,
        item_description,
        quantity,
        notes \\ ""
      ) do
    html_body =
      generate_supplier_quote_request_email_html(supplier_name, item_description, quantity, notes)

    send_email(supplier_email, "Quote Request – #{item_description} (#{quantity} units)",
      html_body: html_body
    )
  end

  defp generate_supplier_quote_request_email_html(
         supplier_name,
         item_description,
         quantity,
         notes
       ) do
    notes_html =
      if is_binary(notes) and notes != "" do
        "<p style='font-size:14px;color:#4b5563;'><strong>Additional notes:</strong><br/>#{notes}</p>"
      else
        ""
      end

    """
    <!DOCTYPE html>
    <html>
    <head><meta charset='utf-8'/></head>
    <body style='margin:0;padding:0;background:#f8f8ff;font-family:Segoe UI,Tahoma,Geneva,Verdana,sans-serif;'>
      <div style='max-width:600px;margin:0 auto;padding:24px;'>
        <p style='font-size:16px;color:#374151;'>Hello #{supplier_name},</p>
        <p style='font-size:15px;color:#4b5563;'>
          Glocal Health Centre would like to request a quote for the following:
        </p>
        <table style='width:100%;border-collapse:collapse;background:#fff;border:1px solid #e5e7eb;border-radius:8px;margin:16px 0;'>
          <tr style='background:#f3f4f6;'>
            <th style='padding:10px 12px;text-align:left;font-size:12px;text-transform:uppercase;color:#6b7280;'>Item</th>
            <td style='padding:10px 12px;'>#{item_description}</td>
          </tr>
          <tr>
            <th style='padding:10px 12px;text-align:left;font-size:12px;text-transform:uppercase;color:#6b7280;'>Quantity requested</th>
            <td style='padding:10px 12px;font-weight:600;'>#{quantity} units</td>
          </tr>
        </table>
        #{notes_html}
        <p style='font-size:14px;color:#6b7280;'>Please provide your quote at your earliest convenience.</p>
        <p style='font-size:14px;color:#6b7280;'>— Glocal Health Centre</p>
      </div>
    </body>
    </html>
    """
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
