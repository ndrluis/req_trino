defmodule ReqTrino.Result do
  @moduledoc """
  Result struct returned from any successful query.

  Its fields are:

    * `columns` - The column names;
    * `rows` - The result set. A list of lists, each inner list corresponding to a
      row, each element in the inner list corresponds to a column;
    * `statement_name` - The statement name from executed query;
    * `query_execution_id` - The id from executed query;
  """

  @type t :: %__MODULE__{
          columns: [String.t()],
          rows: [[term()]],
          statement_name: binary(),
          query_id: binary()
        }

  defstruct [:statement_name, :query_id, rows: [], columns: []]
end

if Code.ensure_loaded?(Table.Reader) do
  defimpl Table.Reader, for: ReqTrino.Result do
    def init(result) do
      {:rows, %{columns: result.columns}, result.rows}
    end
  end
end

if Code.ensure_loaded?(Kino.Render) do
  defimpl Kino.Render, for: ReqTrino.Result do
    def to_livebook(result) do
      result
      |> Kino.DataTable.new(name: "Results")
      |> Kino.Render.to_livebook()
    end
  end
end
