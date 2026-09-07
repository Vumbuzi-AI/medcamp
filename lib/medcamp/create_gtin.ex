defmodule Medcamp.CreateGtin do
  def create(name, description, uom) do
    uom = String.downcase(uom)

    body = %{
      user_id: 11_544_169,
      classify: ["10005845"],
      color: ["color"],
      depth: ["depth"],
      description: [description],
      height: ["height"],
      name: [name],
      packing_type: ["packing_type"],
      size: ["weight"],
      style: ["style"],
      target_market: ["KE"],
      uom: [uom],
      weight: ["10"],
      width: ["width"]
    }

    url = "https://gs1kenya.org/ghc/api/create_gtin"

    headers = [
      {"Authorization",
       "Bearer cc271cf52392d0ba8da0ecf21b31caf2ff59152688fb7e6b149b84077cbf7a83700e17b884148d161b84f1901a37d145a95012ef5ac6:"},
      {"Cache-Control", "no-cache"},
      {"Content-Type", "application/json"}
    ]

    req_options = [
      headers: headers,
      json: body,
      retry: :transient,
      max_retries: 5,
      receive_timeout: 60_000
    ]

    Req.post(url, req_options)
  end

  def create() do
    body = %{
      user_id: 11_544_169,
      classify: ["10005845"],
      color: ["color"],
      depth: ["depth"],
      description: ["description"],
      height: ["height"],
      name: ["name"],
      packing_type: ["packing_type"],
      size: ["weight"],
      style: ["style"],
      target_market: ["KE"],
      uom: ["uom"],
      weight: ["10"],
      width: ["width"]
    }

    url = "https://gs1kenya.org/ghc/api/create_gtin"

    headers = [
      {"Authorization",
       "Bearer cc271cf52392d0ba8da0ecf21b31caf2ff59152688fb7e6b149b84077cbf7a83700e17b884148d161b84f1901a37d145a95012ef5ac6:"},
      {"Cache-Control", "no-cache"},
      {"Content-Type", "application/json"}
    ]

    req_options = [
      headers: headers,
      json: body,
      retry: :transient,
      max_retries: 5,
      receive_timeout: 60_000
    ]

    Req.post(url, req_options)
  end
end
