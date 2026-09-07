defmodule Medcamp.Accounts.LoginOtp do
  @moduledoc """
  Builds and verifies short-lived, single-use codes for password logins.

  The code verifier is kept in the server-side user token store. The browser
  session only receives a random nonce and token reference, so the short code
  cannot be guessed offline from the session cookie.
  """

  import Ecto.Query

  alias Medcamp.Accounts.UserToken
  alias Medcamp.Postal
  alias Medcamp.Repo

  @validity_seconds 5 * 60
  @max_attempts 5
  @context "login_otp"

  def validity_seconds, do: @validity_seconds

  def issue(user, remember_me?) do
    invalidate_for_user(user.id)

    code = generate_code()
    challenge = build_challenge(user, code, remember_me?)

    body = """
    Hi #{user.name || user.email},

    Your Glocal Health Centre login verification code is:

    #{code}

    This code expires in 5 minutes. If you did not try to sign in, please contact your administrator.
    """

    case Postal.deliver(user.email, "Your login verification code", body) do
      {:ok, _body, _response} ->
        {:ok, challenge}

      {:error, reason} ->
        delete_challenge(challenge)
        {:error, reason}
    end
  end

  @doc false
  def build_challenge(user, code, remember_me?, opts \\ []) do
    now = Keyword.get(opts, :now, System.system_time(:second))
    nonce = :crypto.strong_rand_bytes(32)

    token =
      Repo.insert!(%UserToken{
        user_id: user.id,
        token: digest(code, nonce),
        context: @context,
        sent_to: user.email
      })

    %{
      "user_id" => user.id,
      "token_id" => token.id,
      "nonce" => Base.url_encode64(nonce, padding: false),
      "expires_at" => now + @validity_seconds,
      "attempts_left" => @max_attempts,
      "remember_me" => remember_me? == true
    }
  end

  def verify(challenge, code, opts \\ [])

  def verify(
        %{
          "token_id" => token_id,
          "nonce" => encoded_nonce,
          "expires_at" => expires_at,
          "attempts_left" => attempts_left
        } = challenge,
        code,
        opts
      )
      when is_integer(token_id) and is_binary(encoded_nonce) and is_integer(expires_at) and
             is_integer(attempts_left) do
    now = Keyword.get(opts, :now, System.system_time(:second))
    token = Repo.get(UserToken, token_id)

    cond do
      expires_at <= now ->
        delete_challenge(challenge)
        {:error, :expired}

      attempts_left <= 0 ->
        delete_challenge(challenge)
        {:error, :too_many_attempts}

      valid_token?(token, challenge, code, encoded_nonce) ->
        delete_challenge(challenge)
        {:ok, challenge}

      attempts_left == 1 ->
        delete_challenge(challenge)
        {:error, :too_many_attempts}

      true ->
        {:error, :invalid, Map.put(challenge, "attempts_left", attempts_left - 1)}
    end
  end

  def verify(_challenge, _code, _opts), do: {:error, :invalid_challenge}

  def delete_challenge(%{"token_id" => token_id}) when is_integer(token_id) do
    Repo.delete_all(from token in UserToken, where: token.id == ^token_id)
    :ok
  end

  def delete_challenge(_challenge), do: :ok

  defp invalidate_for_user(user_id) do
    Repo.delete_all(
      from token in UserToken,
        where: token.user_id == ^user_id and token.context == @context
    )
  end

  defp valid_token?(
         %UserToken{context: @context, user_id: user_id, token: expected_digest},
         %{"user_id" => user_id},
         code,
         encoded_nonce
       ) do
    with {:ok, nonce} <- Base.url_decode64(encoded_nonce, padding: false) do
      submitted_digest = digest(code |> to_string() |> String.trim(), nonce)
      secure_match?(expected_digest, submitted_digest)
    else
      :error -> false
    end
  end

  defp valid_token?(_token, _challenge, _code, _nonce), do: false

  defp generate_code do
    :crypto.strong_rand_bytes(4)
    |> :binary.decode_unsigned()
    |> rem(1_000_000)
    |> Integer.to_string()
    |> String.pad_leading(6, "0")
  end

  defp digest(code, nonce), do: :crypto.hash(:sha256, [nonce, code])

  defp secure_match?(left, right) when byte_size(left) == byte_size(right) do
    Plug.Crypto.secure_compare(left, right)
  end

  defp secure_match?(_left, _right), do: false
end
