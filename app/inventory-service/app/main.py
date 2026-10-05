"""inventory-service: stores stock in Cosmos DB and reduces it when orders are placed."""
import json
import logging
import os
import threading
import time
from contextlib import asynccontextmanager

from azure.cosmos import CosmosClient, PartitionKey
from azure.cosmos.exceptions import CosmosHttpResponseError, CosmosResourceNotFoundError
from azure.identity import DefaultAzureCredential
from azure.servicebus import ServiceBusClient
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("inventory")
logging.getLogger("azure").setLevel(logging.WARNING)  # hide verbose Azure SDK request logs

# ---------- Configuration ----------
COSMOS_ENDPOINT = os.getenv("COSMOS_ENDPOINT", "http://localhost:8081/")
COSMOS_KEY = os.getenv("COSMOS_KEY")  # local emulator only
COSMOS_DATABASE = os.getenv("COSMOS_DATABASE", "nimbus")
COSMOS_CONTAINER = os.getenv("COSMOS_CONTAINER", "inventory")

SB_CONNECTION_STRING = os.getenv("SERVICEBUS_CONNECTION_STRING")  # local emulator only
SB_NAMESPACE = os.getenv("SERVICEBUS_NAMESPACE")
SB_QUEUE = os.getenv("SERVICEBUS_QUEUE", "order-placed")

container = None  # Cosmos container client, set at startup
_credential = None


def get_credential():
    global _credential
    if _credential is None:
        _credential = DefaultAzureCredential()
    return _credential


# ---------- Cosmos DB ----------
def init_cosmos(retries: int = 20, delay: int = 5):
    global container
    for attempt in range(1, retries + 1):
        try:
            if COSMOS_KEY:
                # Local emulator: key auth, and we may create the database/container ourselves
                client = CosmosClient(COSMOS_ENDPOINT, credential=COSMOS_KEY, enable_endpoint_discovery=False)
                db = client.create_database_if_not_exists(COSMOS_DATABASE)
                container = db.create_container_if_not_exists(
                    id=COSMOS_CONTAINER, partition_key=PartitionKey(path="/id")
                )
            else:
                # Azure: Entra ID auth. Entra identities may read/write items but not create
                # databases or containers, so Terraform creates those.
                client = CosmosClient(COSMOS_ENDPOINT, credential=get_credential())
                container = client.get_database_client(COSMOS_DATABASE).get_container_client(COSMOS_CONTAINER)
                container.read()  # fail fast if it doesn't exist or access is denied
            log.info("Cosmos DB ready")
            return
        except Exception as exc:  # emulator can take a while to start
            log.warning("Cosmos DB not ready (attempt %d/%d): %s", attempt, retries, exc)
            time.sleep(delay)
    raise RuntimeError("Could not initialise Cosmos DB")


def reserve_stock(product_id: str, quantity: int):
    try:
        item = container.read_item(item=product_id, partition_key=product_id)
    except CosmosResourceNotFoundError:
        log.warning("Product %s not in inventory; nothing to reserve", product_id)
        return
    item["quantity"] = max(item["quantity"] - quantity, 0)
    container.replace_item(item=item["id"], body=item)
    log.info("Stock for %s is now %d", product_id, item["quantity"])


# ---------- Service Bus consumer (background thread) ----------
def consume_orders(stop: threading.Event):
    if SB_CONNECTION_STRING:
        make_client = lambda: ServiceBusClient.from_connection_string(SB_CONNECTION_STRING)
    elif SB_NAMESPACE:
        make_client = lambda: ServiceBusClient(SB_NAMESPACE, get_credential())
    else:
        log.warning("Service Bus not configured; consumer not started")
        return

    while not stop.is_set():
        try:
            with make_client() as client, client.get_queue_receiver(SB_QUEUE) as receiver:
                log.info("Listening on queue %s", SB_QUEUE)
                while not stop.is_set():
                    for msg in receiver.receive_messages(max_message_count=10, max_wait_time=5):
                        try:
                            event = json.loads(str(msg))
                            reserve_stock(event["product_id"], int(event["quantity"]))
                            receiver.complete_message(msg)  # done: remove from queue
                        except Exception:
                            log.exception("Failed to process message; it will be retried")
                            receiver.abandon_message(msg)   # put back for another try
        except Exception as exc:
            log.warning("Service Bus connection problem, retrying in 5s: %s", exc)
            time.sleep(5)


# ---------- API ----------
@asynccontextmanager
async def lifespan(app: FastAPI):
    init_cosmos()
    stop = threading.Event()
    worker = threading.Thread(target=consume_orders, args=(stop,), daemon=True)
    worker.start()
    yield
    stop.set()


app = FastAPI(title="inventory-service", lifespan=lifespan)


class StockIn(BaseModel):
    quantity: int = Field(ge=0, le=100000)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/ready")
def ready():
    try:
        container.read()
        return {"status": "ready"}
    except (CosmosHttpResponseError, AttributeError):
        raise HTTPException(status_code=503, detail="cosmos unavailable")


@app.get("/inventory")
def list_inventory():
    items = container.query_items(
        query="SELECT TOP 100 c.id, c.quantity FROM c", enable_cross_partition_query=True
    )
    return list(items)


@app.get("/inventory/{product_id}")
def get_stock(product_id: str):
    try:
        item = container.read_item(item=product_id, partition_key=product_id)
    except CosmosResourceNotFoundError:
        raise HTTPException(status_code=404, detail="product not found")
    return {"id": item["id"], "quantity": item["quantity"]}


@app.put("/inventory/{product_id}")
def set_stock(product_id: str, stock: StockIn):
    item = {"id": product_id, "quantity": stock.quantity}
    container.upsert_item(item)
    return item