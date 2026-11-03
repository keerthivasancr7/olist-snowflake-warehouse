import csv
import hashlib
import json
from pathlib import Path

source = Path.home() / "Downloads/archive"
output = Path("data/simulated_002")
output.mkdir(parents=True, exist_ok=True)

def read_csv(name):
    with (source / name).open(newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        return reader.fieldnames, list(reader)

order_fields, orders = read_csv("olist_orders_dataset.csv")
item_fields, items = read_csv("olist_order_items_dataset.csv")

orders_by_id = {row["order_id"]: row for row in orders}

base_item = next(
    row for row in items
    if orders_by_id[row["order_id"]]["order_status"] == "delivered"
)
base_order = orders_by_id[base_item["order_id"]]

new_id = hashlib.md5(
    b"olist_warehouse_simulated_002_new_order"
).hexdigest()

assert new_id not in orders_by_id

new_order = dict(base_order, order_id=new_id)
new_item = dict(base_item, order_id=new_id, order_item_id="1")

existing = next(
    row for row in orders
    if row["order_status"] == "shipped"
    and row["order_delivered_carrier_date"]
    and row["order_estimated_delivery_date"]
)

changed_order = dict(
    existing,
    order_status="delivered",
    order_delivered_customer_date=existing["order_estimated_delivery_date"],
)

for filename, fields, rows in [
    ("olist_orders_dataset.csv", order_fields, [new_order, changed_order]),
    ("olist_order_items_dataset.csv", item_fields, [new_item]),
]:
    with (output / filename).open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)

manifest = {
    "description": "SIMULATED historical changes; not live CDC",
    "batch_id": "simulated_002",
    "batch_seq": 2,
    "new_order_id": new_id,
    "changed_order_id": existing["order_id"],
    "status_before": "shipped",
    "status_after": "delivered",
    "note": "New order reuses historical dates and existing entity references.",
}

(output / "manifest.json").write_text(json.dumps(manifest, indent=2))
print(json.dumps(manifest, indent=2))
print("Created 2 order records and 1 item record in", output.resolve())
