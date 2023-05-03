defmodule IntegrationTest do
  use ExUnit.Case, async: false
  @moduletag :integration

  setup_all do
    %{
      opts: [
        host: "http://localhost:8080",
        user: "test"
      ]
    }
  end

  test "executes a simple query", %{opts: opts} do
    sql = """
      SELECT * FROM (
          values
          (1, 'one', 'a'),
          (2, 'two', 'b'),
          (3, 'three', 'c'),
          (4, 'four', 'd'),
          (5, 'five', 'e')
      ) x (id, name, letter)
    """

    assert response =
             Req.new()
             |> ReqTrino.attach(opts)
             |> Req.post!(trino: sql)

    assert response.status == 200

    assert length(response.body.rows) == 5
  end

  test "executes create, insert and select", %{opts: opts} do
    table_name = TableHelpers.random_identifier("test_execute_many")
    identifier = "memory.default.#{table_name}"

    create_table = """
      CREATE TABLE #{identifier} (key int, value varchar)
    """

    insert_data = """
      INSERT INTO #{identifier} (key, value) VALUES (1, 'one'), (2, 'two'), (3, 'three')
    """

    select_data = """
      SELECT * FROM #{identifier} ORDER BY key
    """

    assert response_create = request(create_table, opts)
    assert(response_create.status == 200)

    assert response_insert = request(insert_data, opts)
    assert(response_insert.status == 200)

    assert response_select = request(select_data, opts)
    assert(response_select.status == 200)

    assert(response_select.body.rows == [[1, "one"], [2, "two"], [3, "three"]])
  end

  defp request(sql, opts) do
    Req.new()
    |> ReqTrino.attach(opts)
    |> Req.post!(trino: sql)
  end
end
