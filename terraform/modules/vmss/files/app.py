"""CaribeShop app: solo stdlib.

Endpoints:
  GET /        -> presentacion
  GET /health  -> 200 ok, 503 si existe /opt/caribeshop/unhealthy (prueba P2.1)
  GET /secret  -> huella del secreto (longitud + SHA-256 truncado), NUNCA el valor

Lee el secreto de Key Vault con la identidad administrada del VMSS:
  1. token de IMDS (169.254.169.254)
  2. GET al Key Vault con Bearer token
"""
import hashlib
import json
import os
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(os.environ.get("PORT", "8080"))
SECRET_NAME = os.environ.get("SECRET_NAME", "app-secret")
KEY_VAULT_URI = os.environ.get("KEY_VAULT_URI", "")
UNHEALTHY_FLAG = "/opt/caribeshop/unhealthy"


def imds_token():
    url = (
        "http://169.254.169.254/metadata/identity/oauth2/token"
        "?api-version=2018-02-01&resource=https://vault.azure.net"
    )
    req = urllib.request.Request(
        url, headers={"Metadata": "true"}, method="GET"
    )
    with urllib.request.urlopen(req, timeout=5) as resp:
        return json.load(resp)["access_token"]


def secret_fingerprint():
    """Devuelve una huella del secreto, nunca el valor (S3)."""
    if not KEY_VAULT_URI:
        return "keyvault-not-configured"
    try:
        token = imds_token()
        url = f"{KEY_VAULT_URI}/secrets/{SECRET_NAME}?api-version=7.1"
        req = urllib.request.Request(
            url, headers={"Authorization": f"Bearer {token}"}, method="GET"
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.load(resp)
        value = data.get("value", "")
        digest = hashlib.sha256(value.encode()).hexdigest()
        return f"len={len(value)} sha256={digest[:16]}"
    except Exception as exc:  # nunca filtrar el valor ni el traceback completo
        return f"error={type(exc).__name__}"


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body):
        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(body.encode("utf-8"))

    def do_GET(self):
        if self.path == "/health":
            if os.path.exists(UNHEALTHY_FLAG):
                self._send(503, "unhealthy\n")
            else:
                self._send(200, "ok\n")
        elif self.path == "/secret":
            self._send(200, secret_fingerprint() + "\n")
        else:
            self._send(200, "CaribeShop platform. Endpoints: /health /secret\n")

    def log_message(self, *args):
        # No se registran peticiones (podrian tocar el secreto).
        pass


HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
