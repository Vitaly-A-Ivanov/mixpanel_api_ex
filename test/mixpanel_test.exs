defmodule MixpanelTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Mox

  setup :verify_on_exit!

  setup do
    pid = start_supervised!({Mixpanel.Client, [active: true, token: ""]})

    Mixpanel.HTTP.Mock
    |> allow(self(), pid)

    {:ok, client: pid}
  end

  test "retries when HTTP client returns error" do
    Mixpanel.HTTP.Mock
    |> expect(:get, 3, fn _url, _headers, _opts ->
      {:error, ""}
    end)

    capture_log(fn ->
      Mixpanel.track("Signed up", %{"Referred By" => "friend"}, distinct_id: "13793")
      :timer.sleep(50)
    end)
  end

  test "retries when API asks to retry later" do
    Mixpanel.HTTP.Mock
    |> expect(:get, 3, fn _url, _headers, _opts -> {:ok, 503, [], ""} end)

    capture_log(fn ->
      Mixpanel.track("Signed up", %{"Referred By" => "friend"}, distinct_id: "13793")
      :timer.sleep(50)
    end)
  end

  describe "tracks an event" do
    setup do
      Mixpanel.HTTP.Mock
      |> expect(:get, fn url, _headers, _opts ->
        assert url =~ ~r</track$>
        {:ok, 200, [], "1"}
      end)

      :ok
    end

    test "track/1" do
      Mixpanel.track("Signed up")
      :timer.sleep(50)
    end

    test "track/2" do
      Mixpanel.track("Signed up", %{"Referred By" => "friend"})
      :timer.sleep(50)
    end

    test "track/3" do
      Mixpanel.track("Signed up", %{"Referred By" => "friend"}, distinct_id: "13793")
      :timer.sleep(50)
    end

    test "track/3 with IP and timestamp" do
      Mixpanel.track(
        "Level Complete",
        %{"Level Number" => 9},
        distinct_id: "13793",
        time: 1_358_208_000,
        ip: "203.0.113.9"
      )

      :timer.sleep(50)
    end
  end

  describe "tracks a profile update" do
    setup do
      Mixpanel.HTTP.Mock
      |> expect(:get, fn url, _headers, _opts ->
        assert url =~ ~r</engage$>
        {:ok, 200, [], "1"}
      end)

      :ok
    end

    test "engage/2" do
      Mixpanel.engage("13793", "$set")
      :timer.sleep(50)
    end

    test "engage/3" do
      Mixpanel.engage("13793", "$set", %{"Address" => "1313 Mockingbird Lane"})
      :timer.sleep(50)
    end

    test "engage/4" do
      Mixpanel.engage(
        "13793",
        "$set",
        %{"Address" => "1313 Mockingbird Lane"},
        ip: "123.123.123.123"
      )

      :timer.sleep(50)
    end
  end

  describe "creates an identity alias" do
    setup do
      Mixpanel.HTTP.Mock
      |> expect(:post, fn url, _body, _headers, _opts ->
        assert url =~ ~r</track#identity-create-alias$>
        {:ok, 200, [], "1"}
      end)

      :ok
    end

    test "create an alias" do
      Mixpanel.create_alias("13793", "13794")
      :timer.sleep(50)
    end
  end
end
