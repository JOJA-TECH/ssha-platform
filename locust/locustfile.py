"""Locust para CaribeShop.

Perfil escalonado (P1.2): subida -> carga sostenida -> bajada, >= 25 min.
Se ejecuta con: locust -f locust/locustfile.py --host=http://<LB-IP> --csv
evidencias/p1 --html evidencias/p1/reporte.html

Los umbrales y tiempos son parametros de entrada del escenario, no del codigo.
"""
from locust import HttpUser, between, task, StagesShape

USERS_RAMP = 50          # usuarios maximos en la meseta
RAMP_UP = "5m"           # subida
SUSTAIN = "15m"          # carga sostenida
RAMP_DOWN = "5m"         # bajada


class CaribeShopUser(HttpUser):
    wait_time = between(1, 3)
    host = None  # se establece con --host

    @task(3)
    def index(self):
        self.client.get("/")

    @task(1)
    def health(self):
        self.client.get("/health")

    @task(1)
    def secret(self):
        # P3.1: el endpoint devuelve huella, nunca el valor del secreto.
        self.client.get("/secret")


class StagedLoad(StagesShape):
    """Subida lineal, meseta, bajada lineal (perfil escalonado P1.2)."""

    def stages(self):
        total_ramp = self._parse(RAMP_UP)
        sustain = self._parse(SUSTAIN)
        total_down = self._parse(RAMP_DOWN)
        t1 = total_ramp
        t2 = t1 + sustain
        t3 = t2 + total_down
        return [
            {"duration": t1, "users": USERS_RAMP, "spawn_rate": USERS_RAMP / total_ramp},
            {"duration": t2, "users": USERS_RAMP, "spawn_rate": 0},
            {"duration": t3, "users": 0, "spawn_rate": USERS_RAMP / total_down},
            {"duration": t3 + 60, "users": 0, "spawn_rate": 0},
        ]

    def _parse(self, value):
        if value.endswith("m"):
            return int(value[:-1]) * 60
        if value.endswith("s"):
            return int(value[:-1])
        return int(value)
