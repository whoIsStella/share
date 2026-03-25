import requests


def lookup_asn(ip: str) -> dict:
    try:
        resp = requests.get(
            f"https://ipinfo.io/{ip}/json",
            headers={"Accept": "application/json"},
            timeout=5,
        )
        resp.raise_for_status()
        data = resp.json()

        # org field format: "AS14061 DIGITALOCEAN-ASN"
        org_field = data.get("org", "")
        asn, _, org_name = org_field.partition(" ")

        return {
            "asn":     asn or None,
            "org":     org_name or None,
            "country": data.get("country"),
            "city":    data.get("city"),
        }
    except Exception:
        return {"asn": None, "org": None, "country": None, "city": None}
