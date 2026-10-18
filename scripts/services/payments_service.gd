extends Node
## Pasarelas por pais. El usuario elige pais al momento de pagar.

const BACKEND_URL := ""

const GATEWAYS := {
    "PE": ["yape", "plin", "paypal", "stripe", "mercadopago"],
    "ES": ["paypal", "stripe", "sepa"],
    "MX": ["mercadopago", "paypal", "stripe"],
    "CO": ["mercadopago", "paypal", "stripe"],
    "CL": ["mercadopago", "paypal", "stripe"],
    "AR": ["mercadopago", "paypal"],
    "US": ["paypal", "stripe"],
    "GLOBAL": ["paypal", "stripe"]
}

const COUNTRIES := [
    ["Peru", "PE"], ["Espana", "ES"], ["Mexico", "MX"], ["Colombia", "CO"],
    ["Chile", "CL"], ["Argentina", "AR"], ["Estados Unidos", "US"], ["Global", "GLOBAL"]
]

func gateways_for(country: String) -> Array:
    var c := country.to_upper()
    if GATEWAYS.has(c): return GATEWAYS[c]
    return GATEWAYS["GLOBAL"]

func gateway_label(id: String) -> String:
    match id:
        "yape": return "Yape (QR)"
        "plin": return "Plin (QR)"
        "paypal": return "PayPal"
        "stripe": return "Tarjeta (Stripe)"
        "sepa": return "SEPA (UE)"
        "mercadopago": return "Mercado Pago"
        _: return id.capitalize()

func countries() -> Array:
    return COUNTRIES

func process_purchase(user: String, package_id: String, coins: int, usd: float, country: String, gateway: String) -> bool:
    print("[Payments] user=%s pkg=%s coins=%d usd=%.2f country=%s gateway=%s" % [user, package_id, coins, usd, country, gateway])
    if BACKEND_URL == "":
        await get_tree().create_timer(0.4).timeout
        return true
    var http := HTTPRequest.new(); add_child(http)
    var body := JSON.stringify({"user": user, "package_id": package_id, "coins": coins, "usd": usd, "country": country, "gateway": gateway})
    var headers := PackedStringArray(["Content-Type: application/json", "User-Agent: BitQbadPlayStore"])
    http.request(BACKEND_URL + "/checkout", headers, HTTPClient.METHOD_POST, body)
    var res = await http.request_completed
    http.queue_free()
    if int(res[1]) != 200: return false
    var data = JSON.parse_string(res[3].get_string_from_utf8())
    if not (data is Dictionary) or not data.has("url"): return false
    var url := str(data["url"])
    if OS.has_feature("web"):
        JavaScriptBridge.eval("window.open('%s','_blank')" % url)
    else:
        OS.shell_open(url)
    return false