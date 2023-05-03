defmodule ReqTrinoTest do
  use ExUnit.Case, async: true
  @moduletag :capture_log

  setup do
    Application.put_env(:trino_credentials, :credential_providers, [])
    :ok
  end

  test "executes a query string" do
  end
end
