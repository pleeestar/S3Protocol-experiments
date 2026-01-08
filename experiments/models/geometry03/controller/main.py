import csv, time, os, random, requests
import numpy as np

node_urls = os.getenv("NODE_URLS").split(",")
steps = int(os.getenv("STEPS", "100"))
dim = int(os.getenv("DIM", "8"))

def wait_for_nodes():
    print("Waiting for nodes...")
    ready = False
    while not ready:
        try:
            for url in node_urls:
                requests.get(url + "/state", timeout=1)
            ready = True
        except:
            time.sleep(1)
            print(".", end="", flush=True)
    print("Nodes ready.")

wait_for_nodes()

print(f"Starting Gossip for {steps} steps with {len(node_urls)} nodes...")

with open("/analysis/experiment_data.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["step", "node_index", "dim_index", "value", "drift"])

    for step in range(steps):
        # 1. Get current states
        current_beliefs = []
        for i, url in enumerate(node_urls):
            resp = requests.get(url + "/state").json()
            belief = resp["belief"]
            drift = resp["drift"]

            # Log data
            for d, v in enumerate(belief):
                writer.writerow([step, i, d, v, drift])
            current_beliefs.append(belief)

        # 2. Interaction (Random Gossip)
        # 各ノードがランダムな相手を選んで話を聞く
        for i, url in enumerate(node_urls):
            target_idx = random.choice([x for x in range(len(node_urls)) if x != i])
            target_belief = current_beliefs[target_idx]

            try:
                requests.post(url + "/tick", json={"belief": target_belief}, timeout=1)
            except Exception as e:
                print(f"Error communicating {i}->{target_idx}: {e}")

        if step % 10 == 0:
            print(f"Step {step}/{steps} completed")

        time.sleep(0.05) # 少し待機

print("Experiment completed.")
