#!/bin/zsh
set -e

PROJECT=entropy02
DIM=4
STEPS=30

echo "== create project $PROJECT =="
mkdir -p ../models/"$PROJECT"/{controller,node,analysis}
cd ../models/"$PROJECT"

############################
# docker-compose.yml
############################
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
      - SEED=1
  node2:
    build: ./node
    environment:
      - SEED=2
  node3:
    build: ./node
    environment:
      - SEED=3
EOF

############################
# node
############################
cat << 'EOF' > node/app.py
from fastapi import FastAPI
import numpy as np
import os

app = FastAPI()

DIM = 4
ETA = 0.3

seed = int(os.getenv("SEED", "0"))
rng = np.random.default_rng(seed)

x = rng.normal(size=DIM)

# 人格 = 解釈行列（直交）
Q, _ = np.linalg.qr(rng.normal(size=(DIM, DIM)))
P = Q

@app.get("/state")
def state():
    return {"belief": x.tolist()}

@app.post("/tick")
def tick(data: dict):
    global x
    incoming = np.array(data["belief"])
    interpreted = P @ incoming
    x = x + ETA * (interpreted - x)
    return {"belief": x.tolist()}
EOF

cat << 'EOF' > node/requirements.txt
fastapi
uvicorn
numpy
EOF

cat << 'EOF' > node/Dockerfile
FROM python:3.11
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

############################
# controller
############################
cat << 'EOF' > controller/main.py
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
EOF

cat << 'EOF' > controller/requirements.txt
requests
numpy
EOF

cat << 'EOF' > controller/Dockerfile
FROM python:3.11
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY main.py .
CMD ["python", "main.py"]
EOF

############################
# analysis
############################
cat << 'EOF' > analysis/analyze.py
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
import umap

df = pd.read_csv("beliefs.csv")

pivot = df.pivot_table(
    index=["step","node"],
    columns="dim",
    values="value"
).reset_index()

X = pivot.drop(columns=["step","node"]).values

pca = PCA(n_components=2)
Xp = pca.fit_transform(X)

u = umap.UMAP(n_components=2, random_state=0)
Xu = u.fit_transform(X)

plt.figure()
plt.scatter(Xp[:,0], Xp[:,1], s=5)
plt.title("Belief space (PCA)")
plt.savefig("belief_pca.png")

plt.figure()
plt.scatter(Xu[:,0], Xu[:,1], s=5)
plt.title("Belief space (UMAP)")
plt.savefig("belief_umap.png")
EOF

############################
# run
############################
echo "== docker compose up =="
docker compose up --build --abort-on-container-exit --exit-code-from controller

echo "== analysis =="
docker run --rm -v $(pwd)/analysis:/data python:3.11 bash -c \
"pip install pandas matplotlib scikit-learn umap-learn && cd /data && python analyze.py"

echo "DONE"
echo "Generated:"
echo " - analysis/belief_pca.png"
echo " - analysis/belief_umap.png"
