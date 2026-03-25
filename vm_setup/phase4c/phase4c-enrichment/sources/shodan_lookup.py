import shodan
from config import SHODAN_API_KEY


def lookup_ip(ip: str) -> dict:
    if not SHODAN_API_KEY:
        raise EnvironmentError("SHODAN_API_KEY is not set")

    api = shodan.Shodan(SHODAN_API_KEY)
    try:
        host = api.host(ip)
        return {
            "open_ports":  host.get("ports", []),
            "tags":        host.get("tags", []),
            "os":          host.get("os"),
            "hostnames":   host.get("hostnames", []),
            "last_update": host.get("last_update"),
        }
    except shodan.APIError:
        # IP not in Shodan's index — not an error
        return {
            "open_ports":  [],
            "tags":        [],
            "os":          None,
            "hostnames":   [],
            "last_update": None,
        }
