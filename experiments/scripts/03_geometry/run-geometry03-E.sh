#!/bin/zsh
set -e

PROJECT=geometry03
DIM=8
NODES=5
STEPS=100
# 人格の学習率（どれだけ相手に合わせるか）
LEARNING_RATE=0.05
# 自分の意見を保つ強さ
ALPHA=0.6

echo "== create project $PROJECT =="
mkdir -p ../models/"$PROJECT"/{controller,node,analysis}
cd ../models/"$PROJECT"

############################
# docker-compose.yml
############################
# 動的にノードを定義
services_yml=""
node_urls=""

for i in {1..$NODES}; do
  services_yml="${services_yml}
  node${i}:
    build: ./node
    environment:
      - NODE_ID=${i}
      - DIM=${DIM}
      - LR=${LEARNING_RATE}
      - ALPHA=${ALPHA}
"
  if [ -n "$node_urls" ]; then
    node_urls="${node_urls},"
  fi
  node_urls="${node_urls}http://node${i}:8000"
done

cat << EOF > docker-compose.yml
services:
  controller:
    build: ./controller
    depends_on:
$(for i in {1..$NODES}; do echo "      - node${i}"; done)
    environment:
      - NODE_URLS=${node_urls}
      - STEPS=${STEPS}
      - DIM=${DIM}
    volumes:
      - ./analysis:/analysis

${services_yml}
EOF

############################
# node (Adaptive Persona)
############################
cat << 'EOF' > node/app.py
from fastapi import FastAPI
from pydantic import BaseModel
import numpy as np
import os

app = FastAPI()

DIM = int(os.getenv("DIM", "8"))
LR = float(os.getenv("LR", "0.05")) # Hebbian learning rate
ALPHA = float(os.getenv("ALPHA", "0.6"))

seed = int(os.getenv("NODE_ID", "1"))
rng = np.random.default_rng(seed)

# 初期信念 (球面上)
x = rng.normal(size=DIM)
x = x / np.linalg.norm(x)

# 初期人格 (直交行列)
H = rng.normal(size=(DIM, DIM))
U, _, Vt = np.linalg.svd(H)
P = U @ Vt
P_initial = P.copy() # アイデンティティ保持の計測用

class InputData(BaseModel):
    belief: list[float]

@app.get("/state")
def state():
    # 現在のベクトルと、初期人格からの乖離度(Drift)を返す
    drift = np.linalg.norm(P - P_initial, ord='fro')
    return {"belief": x.tolist(), "drift": float(drift)}

@app.post("/tick")
def tick(data: InputData):
    global x, P
    incoming = np.array(data.belief)

    # 1. Interpretation with Non-linearity
    # 相手の言葉(incoming)を自分の人格(P)で解釈し、tanhで特徴を尖らせる
    interpretation = np.tanh(P @ incoming)

    # 2. State Update (Residual connection)
    raw_new_x = ALPHA * x + (1 - ALPHA) * interpretation
    new_x = raw_new_x / (np.linalg.norm(raw_new_x) + 1e-9)

    # 3. Hebbian Learning of Persona (The Experiment E Core)
    # 「この入力(incoming)は、こういう解釈(new_x)になるべきだったんだな」とPを更新
    # update = outer(output, input)
    delta_P = np.outer(new_x, incoming)
    P_temp = P + LR * delta_P

    # 4. Orthogonalization (人格の崩壊を防ぐ / 拘束条件)
    # これにより、Pは常に「回転」または「反射」であり続ける
    U_p, _, Vt_p = np.linalg.svd(P_temp)
    P = U_p @ Vt_p

    x = new_x
    return {"belief": x.tolist()}
EOF

cat << 'EOF' > node/requirements.txt
fastapi
uvicorn
numpy
pydantic
EOF

cat << 'EOF' > node/Dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

############################
# controller
############################
cat << 'EOF' > controller/main.py
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
EOF

cat << 'EOF' > controller/requirements.txt
requests
numpy
EOF

cat << 'EOF' > controller/Dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .
CMD ["python", "main.py"]
EOF

############################
# analysis
############################
cat << 'EOF' > analysis/analyze.py
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
from sklearn.metrics import silhouette_score
import umap

print("Loading data...")
df = pd.read_csv("experiment_data.csv")

# 1. データ整形
nodes = df['node_index'].unique()
steps = df['step'].unique()
last_step = steps[-1]

# Pivot for clustering analysis
pivot = df.pivot_table(
    index=["step","node_index"],
    columns="dim_index",
    values="value"
).reset_index()

# 2. ラストステップの構造解析
final_state = pivot[pivot["step"] == last_step].copy()
X_final = final_state.drop(columns=["step", "node_index"]).values

# Silhouette Score Check
# クラスタ数=2～(Node数-1)で評価してみる
best_sil = -1
if len(nodes) > 2:
    try:
        from sklearn.cluster import KMeans
        # 仮にクラスタがあるとしたら...
        kmeans = KMeans(n_clusters=max(2, len(nodes)//2), n_init=10).fit(X_final)
        labels = kmeans.labels_
        if len(set(labels)) > 1:
            best_sil = silhouette_score(X_final, labels)
    except:
        pass

print(f"Final Step Silhouette Score Estimate: {best_sil}")

# 3. Visualization

# (A) PCA Trajectory
pca = PCA(n_components=2)
all_vectors = pivot.drop(columns=["step", "node_index"]).values
pca.fit(all_vectors) # 全期間でフィット

plt.figure(figsize=(10, 8))
for n in nodes:
    node_data = pivot[pivot["node_index"] == n]
    coords = pca.transform(node_data.drop(columns=["step", "node_index"]).values)

    # 軌跡を描画
    plt.plot(coords[:,0], coords[:,1], alpha=0.5, label=f"Node {n}")
    # 始点と終点
    plt.scatter(coords[0,0], coords[0,1], marker='x', s=50)
    plt.scatter(coords[-1,0], coords[-1,1], marker='o', s=50)

plt.title(f"Trajectory in PCA Space (Exp E)\nEst. Silhouette: {best_sil:.3f}")
plt.legend()
plt.grid(True, alpha=0.3)
plt.savefig("trajectory_pca.png")

# (B) Personality Drift (Identity Crisis Graph)
# 時間経過とともに、各ノードの人格(P)が初期値からどれだけ乖離したか
plt.figure(figsize=(10, 6))
drift_data = df.pivot_table(index="step", columns="node_index", values="drift")
for n in nodes:
    plt.plot(drift_data.index, drift_data[n], label=f"Node {n}")

plt.title("Personality Drift (Frobenius Norm from Initial P)")
plt.xlabel("Step")
plt.ylabel("Distance from Original Self")
plt.legend()
plt.grid(True)
plt.savefig("personality_drift.png")

print("Analysis Done.")
print("Generated: trajectory_pca.png, personality_drift.png")
EOF

############################
# Run
############################
echo "== docker compose up =="
# ビルドして実行
docker compose up --build --exit-code-from controller

echo "== analysis =="
# 解析コンテナを実行 (Volumeマウントでデータ共有)
docker run --rm -v $(pwd)/analysis:/data python:3.11-slim bash -c \
"pip install pandas matplotlib scikit-learn umap-learn && cd /data && python analyze.py"

echo "DONE"
