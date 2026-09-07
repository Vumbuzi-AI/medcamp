defmodule Medcamp.Accounts.LoginOtpTest do
  use Medcamp.DataCase, async: true

  import Medcamp.AccountsFixtures
  alias Medcamp.Accounts.LoginOtp

  test "accepts the correct code before expiry" do
    challenge = LoginOtp.build_challenge(user_fixture(), "012345", false, now: 1_000)

    assert {:ok, ^challenge} = LoginOtp.verify(challenge, "012345", now: 1_299)
    assert {:error, :invalid, _challenge} = LoginOtp.verify(challenge, "012345", now: 1_299)
  end

  test "expires a code after five minutes" do
    challenge = LoginOtp.build_challenge(user_fixture(), "123456", false, now: 1_000)

    assert {:error, :expired} = LoginOtp.verify(challenge, "123456", now: 1_300)
  end

  test "limits invalid attempts" do
    challenge = LoginOtp.build_challenge(user_fixture(), "123456", false)

    assert {:error, :invalid, challenge} = LoginOtp.verify(challenge, "000000")
    assert challenge["attempts_left"] == 4

    challenge = Map.put(challenge, "attempts_left", 1)
    assert {:error, :too_many_attempts} = LoginOtp.verify(challenge, "000000")
  end
end
