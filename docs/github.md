## Following gh orgs
On https://github.com/dgtlmoon/changedetection.io
 - URL: https://api.github.com/graphql
 - Filter: `json:$` (pretty-print)
 - Headers: `Authorization: bearer `[`<0 scope token>`](https://github.com/settings/tokens/new)
   - Shits to GitHub for not allowing public use of publicly accessible data, furthermore, even though they allow it via the REST API.
 - Query:
     ```
     {
     "query": "query { organization(login:\"tailscale\") { repositories(first:5, orderBy:{field:CREATED_AT, direction:ASC}) { edges { node { name }}}}}"
     }
     ```
     - This lists 5 newest repos created, returning only the name slug. The query can be adapted: https://docs.github.com/en/graphql/reference/objects#organization
