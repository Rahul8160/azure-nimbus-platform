"""orders-service: stores orders in Azure SQL and publishes an event per order."""
import json
import logging
import os
import struct
import time
from contextlib import asynccontextmanager

import pyodbc
from azure.identity import DefaultAzureCredential
from azure.servicebus import ServiceBusClient, ServiceBusMessage
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("orders")
logging.getLogger("azure").setLevel(logging.WARNING)  # hide verbose Azure SDK request logs

# ---------- Configuration (all from environment variables) ----------
SQL_SERVER = os.getenv("SQL_SERVER", "localhost")
SQL_DATABASE = os.getenv("SQL_DATABASE", "ordersdb")
SQL_USER = os.getenv("SQL_USER")          # set locally only
SQL_PASSWORD = os.getenv("SQL_PASSWORD")  # set locally only

SB_CONNECTION_STRING = os.getenv("SERVICEBUS_CONNECTION_STRING")  # local emulator only
SB_NAMESPACE = os.getenv("SERVICEBUS_NAMESPACE")  # Azure, e.g. sb-nimbus-cin.servicebus.windows.net
SB_QUEUE = os.getenv("SERVICEBUS_QUEUE", "order-placed")

_credential = None


def get_credential():
    """One shared Azure credential. In AKS this uses the pod's workload identity."""
    global _credential
    if _credential is None:
        _credential = DefaultAzureCredential()
    return _credential


# ---------- Database ----------
def get_connection(database: str):
    base = (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server=tcp:{SQL_SERVER},1433;Database={database};"
        "Encrypt=yes;Connection Timeout=30;"
    )
    if SQL_USER:
        # Local: SQL login. The local container has a self-signed certificate.
        return pyodbc.connect(base + f"Uid={SQL_USER};Pwd={SQL_PASSWORD};TrustServerCertificate=yes;")

    # Azure: Entra ID access token, no password anywhere
    token = get_credential().get_token("https://database.windows.net/.default").token
    token_bytes = token.encode("utf-16-le")
    token_struct = struct.pack(f"<I{len(token_bytes)}s", len(token_bytes), token_bytes)
    SQL_COPT_SS_ACCESS_TOKEN = 1256  # ODBC attribute for passing an access token
    return pyodbc.connect(base + "TrustServerCertificate=no;", attrs_before={SQL_COPT_SS_ACCESS_TOKEN: token_struct})


def init_db(retries: int = 12, delay: int = 5):
    """Create the database (local only) and the orders table. Retries while SQL starts up."""
    for attempt in range(1, retries + 1):
        try:
            if SQL_USER:
                # In Azure, Terraform creates the database. Locally we create it ourselves.
                master = get_connection("master")
                master.autocommit = True
                master.cursor().execute(
                    f"IF DB_ID('{SQL_DATABASE}') IS NULL CREATE DATABASE [{SQL_DATABASE}]"
                )
                master.close()

            conn = get_connection(SQL_DATABASE)
            conn.cursor().execute(
                """
                IF OBJECT_ID('dbo.orders', 'U') IS NULL
                CREATE TABLE dbo.orders (
                    id          INT IDENTITY(1,1) PRIMARY KEY,
                    product_id  NVARCHAR(50)  NOT NULL,
                    quantity    INT           NOT NULL,
                    status      NVARCHAR(20)  NOT NULL DEFAULT 'PLACED',
                    created_at  DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
                )
                """
            )
            conn.commit()
            conn.close()
            log.info("Database ready")
            return
        except pyodbc.Error as exc:
            log.warning("Database not ready (attempt %d/%d): %s", attempt, retries, exc)
            time.sleep(delay)
    raise RuntimeError("Could not initialise the database")


# ---------- Messaging ----------
def publish_order_event(event: dict):
    if SB_CONNECTION_STRING:
        client = ServiceBusClient.from_connection_string(SB_CONNECTION_STRING)
    elif SB_NAMESPACE:
        client = ServiceBusClient(SB_NAMESPACE, get_credential())
    else:
        log.warning("Service Bus not configured; event not sent: %s", event)
        return

    with client, client.get_queue_sender(SB_QUEUE) as sender:
        sender.send_messages(ServiceBusMessage(json.dumps(event), content_type="application/json"))
    log.info("Published event: %s", event)


# ---------- API ----------
@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()  # runs once at startup
    yield


app = FastAPI(title="orders-service", lifespan=lifespan)


class OrderIn(BaseModel):
    product_id: str = Field(min_length=1, max_length=50)
    quantity: int = Field(gt=0, le=100)


def row_to_dict(row) -> dict:
    return {
        "id": row.id,
        "product_id": row.product_id,
        "quantity": row.quantity,
        "status": row.status,
        "created_at": row.created_at.isoformat(),
    }


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/ready")
def ready():
    try:
        conn = get_connection(SQL_DATABASE)
        conn.cursor().execute("SELECT 1")
        conn.close()
        return {"status": "ready"}
    except pyodbc.Error:
        raise HTTPException(status_code=503, detail="database unavailable")


@app.post("/orders", status_code=201)
def create_order(order: OrderIn):
    conn = get_connection(SQL_DATABASE)
    try:
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO dbo.orders (product_id, quantity) "
            "OUTPUT INSERTED.id, INSERTED.product_id, INSERTED.quantity, INSERTED.status, INSERTED.created_at "
            "VALUES (?, ?)",
            order.product_id,
            order.quantity,
        )
        row = cur.fetchone()
        conn.commit()
    finally:
        conn.close()

    result = row_to_dict(row)
    publish_order_event({"order_id": result["id"], "product_id": order.product_id, "quantity": order.quantity})
    return result


@app.get("/orders")
def list_orders():
    conn = get_connection(SQL_DATABASE)
    try:
        cur = conn.cursor()
        cur.execute("SELECT TOP 50 id, product_id, quantity, status, created_at FROM dbo.orders ORDER BY id DESC")
        return [row_to_dict(r) for r in cur.fetchall()]
    finally:
        conn.close()


@app.get("/orders/{order_id}")
def get_order(order_id: int):
    conn = get_connection(SQL_DATABASE)
    try:
        cur = conn.cursor()
        cur.execute("SELECT id, product_id, quantity, status, created_at FROM dbo.orders WHERE id = ?", order_id)
        row = cur.fetchone()
    finally:
        conn.close()
    if row is None:
        raise HTTPException(status_code=404, detail="order not found")
    return row_to_dict(row)