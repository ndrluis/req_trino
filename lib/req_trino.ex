defmodule ReqTrino do
  alias Req.Request
  alias ReqTrino.Result

  @header_catalog "X-Trino-Catalog"
  @header_schema "X-Trino-Schema"
  @header_user "X-Trino-User"
  @header_source "X-Trino-Source"
  @header_timezone "X-Trino-Time-Zone"
  @header_transaction_id "X-Trino-Transaction-Id"
  @header_prepared_statement "X-Trino-Prepared-Statement"

  @moduledoc """
  `Req` plugin for [Trino](https://trino.io/).

  ReqTrino makes it easy to make Trino queries. Query results are decoded into the `ReqTrino.Result` struct.
  The struct implements the `Table.Reader` protocol and thus can be efficiently traversed by rows or columns.

  """
  require Logger

  alias Req.Request

  @allowed_options ~w(
    host
    user
    password
    catalog
    schema
    trino
  )a

  @doc """
  Attaches to Req request.

  ## Request Options

    * `:host` - Required. The Trino host.

    * `:user` - Required. The Trino user.

    * `:password` - Required. The Trino password.

    * `:catalog` - Required. The default catalog to connect.

    * `:trino` - Required. The query to execute.

  Conditional fields must always be defined, and can be one of the fields or both.

  If you want to set any of these options when attaching the plugin, pass them as the second argument.

  ## Examples

  With plain query string:

      iex> opts = [
      ...>   user: System.fetch_env!("TRINO_USER"),
      ...>   password: System.fetch_env!("TRINO_PASSWORD"),
      ...>   catalog: System.fetch_env!("TRINO_CATALOG"),
      ...>   host: System.fetch_env!("TRINO_HOST")
      ...> ]
      iex> query = "SELECT id, type, tags, members, timestamp, visible FROM planet WHERE id = 470454 and type = 'relation'"
      iex> req = Req.new() |> ReqTrino.attach(opts)
      iex> Req.post!(req, trino: query).body
      %ReqTrino.Result{
        columns: ["id", "type", "tags", "members", "timestamp", "visible"],
        rows: [
          [470454, "relation",
           "{ref=17229A, site=geodesic, name=Mérignac A, source=©IGN 2010 dans le cadre de la cartographie réglementaire, type=site, url=http://geodesie.ign.fr/fiches/index.php?module=e&action=fichepdf&source=carte&sit_no=17229A, network=NTF-5}",
           "[{type=node, ref=670007839, role=}, {type=node, ref=670007840, role=}]",
           ~N[2017-01-21 12:51:34.000], true]
        ],
        statement_name: nil
      }
  """
  def attach(%Request{} = request, options \\ []) do
    request
    |> Request.prepend_request_steps(trino_run: &run/1)
    |> Request.register_options(@allowed_options)
    |> Request.merge_options(options)
  end

  def build_req_params(request, %{password: _ = opts}) do
    request
    |> Request.put_header(@header_user, opts[:user])
    |> Request.put_header(@header_catalog, opts[:catalog])
    |> Request.merge_options(auth: {opts[:user], opts[:password]})
  end

  def build_req_params(request, opts) do
    Request.put_header(request, @header_user, opts[:user])
  end

  defp run(%Request{options: %{trino: query, host: host}} = request) do
    %{request | url: URI.parse("#{host}/v1/statement"), body: query}
    |> build_req_params(request.options)
    |> Request.append_response_steps(trino_result: &handle_trino_result/1)
  end

  defp run(request), do: request

  defp stream_results(initial_body, request_options) do
    Stream.unfold({:initial, initial_body}, fn
      {:initial, body} ->
        {body["data"], body}

      %{"nextUri" => next_uri, "stats" => %{"state" => "RUNNING"}} ->
        new_request =
          Req.new(url: URI.parse(next_uri))
          |> build_req_params(request_options)

        case Req.get(new_request) do
          {_response, %{status: 200, body: body}} ->
            {body["data"], body}
        end

      _ ->
        nil
    end)
    |> Stream.filter(&(&1 != nil))
    |> Stream.flat_map(& &1)
    |> Enum.to_list()
  end

  defp handle_trino_result({request, %{status: 200, body: body} = response}) do
    case body do
      %{"nextUri" => _, "stats" => %{"state" => "RUNNING"}} ->
        {
          request,
          update_in(response.body, &decode_body(&1, request.options))
        }

      %{"nextUri" => next_uri, "stats" => %{"state" => _}} ->
        new_request = %{request | url: URI.parse(next_uri), method: :get}

        {Request.halt(request), Req.get!(new_request)}

      %{"stats" => %{"state" => _state}} ->
        {Request.halt(request), response}
    end
  end

  defp handle_trino_result(response), do: response

  def decode_body(body, request_options) do
    %Result{
      columns: body["columns"] |> Enum.map(& &1["name"]),
      rows: stream_results(body, request_options),
      query_id: body["id"]
    }
  end
end
