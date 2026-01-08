import requests, csv, time

nodes = [
    "http://node1:8000",
    "http://node2:8000",
    "http://node3:8000"
]

def wait_for_nodes(nodes, timeout=30):
    start = time.time()
    while True:
        ready = True
        for node in nodes:
            try:
                requests.get(f"{node}/state", timeout=1)
            except Exception:
                ready = False
                break
        if ready:
            return
        if time.time() - start > timeout:
            raise RuntimeError("Nodes did not become ready")
        time.sleep(1)

print("waiting for nodes...")
wait_for_nodes(nodes)
print("nodes ready")

belief = 0.5
steps = 20

with open("/analysis/beliefs.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["step", "node", "belief"])

    for step in range(steps):
        for node in nodes:
            r = requests.post(f"{node}/tick", json={"belief": belief})
            belief = r.json()["belief"]
            writer.writerow([step, node, belief])
        time.sleep(0.2)

