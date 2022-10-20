import requests
from pprint import pprint

public_ip_address = [
    "168.61.49.116",
    "168.61.50.64",
    "168.61.49.75",
]

for ip in public_ip_address:
    proxy = {
        'http': 'socks5:{}:46642'.format(ip),
        'https': 'socks5:{}:46642'.format(ip)
    }
    pprint(proxy)
    res = requests.get(
        'https://www.google.com',
        proxies=proxy
    )
    print(res.status_code)
