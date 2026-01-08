import csv, time, requests
import numpy as np

nodes = [
    "http://node1:8000",
    "http://node2:8000",
    "http://node3:8000"
]

def wait():
    for n in nodes:
        while True:
            try:
                if requests.get(n + "/state", timeout=1).status_code == 200:
                    break
            except:
                time.sleep(0.5)

wait()

steps = 30

with open("/analysis/beliefs.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["step", "node", "dim", "value"])

    for step in range(steps):
        states = {}
        for n in nodes:
            states[n] = requests.get(n + "/state").json()["belief"]

        for n in nodes:
            j = np.random.choice(nodes)
            r = requests.post(n + "/tick", json={"belief": states[j]})
            b = r.json()["belief"]
            for d, v in enumerate(b):
                writer.writerow([step, n, d, v])

        time.sleep(0.2)
