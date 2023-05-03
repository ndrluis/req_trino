# ReqTrino

[Req](https://github.com/wojtekmach/req) plugin for [Trino](https://trino.io/).

ReqTrino makes it easy to make Trino queries. Query results are decoded into the `ReqTrino.Result` struct.
The struct implements the `Table.Reader` protocol and thus can be efficiently traversed by rows or columns.

*This is a project that was created based on the code from ReqAthena.*

We only supports Basic Authentication!


## Usage

```elixir
Mix.install([
  {:req, "~> 0.3.5"},
  {:req_trino, "~> 0.1.0"}
])

opts = [
  host: my.trino.host,
  user: trino_user,
  password: *******,
  catalog: "raw"
]

req = Req.new() |> ReqTrino.attach(opts)

query = \"""
SHOW TABLES FROM system.runtime;
\"""

Req.post!(req, trino: query).body
#=>
# %ReqTrino.Result{
#   columns: [],
#   query_id: "a034610b-daaf-4c8d-aa61-d1a706231062",
#   rows: [],
#   statement_name: nil
# }

# With plain string query
query = "SELECT id, type, tags, members, timestamp, visible FROM planet WHERE id = 470454 and type = 'relation'"

Req.post!(req, trino: query).body
#=>
# %ReqTrino.Result{
#   columns: ["id", "type", "tags", "members", "timestamp", "visible"],
#   query_id: "c594d5df-9879-4bf7-8796-780e0b87a673",
#   rows: [
#     [470454, "relation",
#      "{ref=17229A, site=geodesic, name=Mérignac A, source=©IGN 2010 dans le cadre de la cartographie réglementaire, type=site, url=http://geodesie.ign.fr/fiches/index.php?module=e&action=fichepdf&source=carte&sit_no=17229A, network=NTF-5}",
#      "[{type=node, ref=670007839, role=}, {type=node, ref=670007840, role=}]",
#      ~N[2017-01-21 12:51:34.000], true]
#   ],
#   statement_name: nil
# }
```
