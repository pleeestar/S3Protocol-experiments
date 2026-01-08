#!/bin/zsh
set -e

PROJECT=entropy01
echo "== create project =="

mkdir -p ../models/"$PROJECT"/{controller,node,analysis,paper}
cd ../models/"$PROJECT"/

##################################
# docker-compose.yml
##################################
cat << 'EOF' > docker-compose.yml
services:
  controller:
    build: ./controller
    depends_on:
      - node1
      - node2
      - node3
    volumes:
      - ./analysis:/analysis

  node1:
    build: ./node
    environment:
      - ALPHA=0.9
  node2:
    build: ./node
    environment:
      - ALPHA=0.5
  node3:
    build: ./node
    environment:
      - ALPHA=0.1
EOF

##################################
# node
##################################
cat << 'EOF' > node/app.py
from fastapi import FastAPI
import random, os

app = FastAPI()
alpha = float(os.getenv("ALPHA", 0.5))
belief = random.random()

@app.get("/state")
def state():
    return {"belief": belief}

@app.post("/tick")
def tick(data: dict):
    global belief
    incoming = data["belief"]
    old = belief
    belief = alpha * belief + (1 - alpha) * incoming
    print(f"[alpha={alpha}] {old:.3f} -> {belief:.3f}", flush=True)
    return {"belief": belief}
EOF

cat << 'EOF' > node/requirements.txt
fastapi
uvicorn
EOF

cat << 'EOF' > node/Dockerfile
FROM python:3.11
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

##################################
# controller
##################################
cat << 'EOF' > controller/main.py
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

EOF

cat << 'EOF' > controller/requirements.txt
requests
EOF

cat << 'EOF' > controller/Dockerfile
FROM python:3.11
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY main.py .
CMD ["python", "main.py"]
EOF

##################################
# analysis
##################################
cat << 'EOF' > analysis/plot.py
import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("beliefs.csv")

for node, g in df.groupby("node"):
    plt.plot(g["step"], g["belief"], label=node)

plt.legend()
plt.xlabel("step")
plt.ylabel("belief")
plt.title("Gossip-based Persona Convergence")
plt.savefig("beliefs.png")
EOF

##################################
# paper
##################################
cat << 'EOF' > paper/outline.md
# Gossip-based Persona Formation

## 1. Introduction
Persona is treated not as a static vector but as a dynamic belief updated via decentralized gossip.

## 2. Model
Each node holds belief b_i.
Update rule:
b_i <- α_i b_i + (1-α_i) b_j

## 3. Experiment
Different α values represent personality rigidity.

## 4. Result
Beliefs converge, but trajectory depends on α distribution.

## 5. Discussion
Persona emerges as a morphism composition, not an object.

## 6. Future Work
Introduce semantic vectors and LLM-based belief transforms.
EOF

##################################
# run
##################################
echo "== build & run =="
docker compose up --build --abort-on-container-exit --exit-code-from controller

echo "== plot =="
docker run --rm -v $(pwd)/analysis:/data python:3.11 bash -c \
"pip install pandas matplotlib && cd /data && python plot.py"

echo "DONE: analysis/beliefs.png generated"
