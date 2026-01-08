#!/bin/zsh
set -e

PROJECT="relic_protocol"
echo "Initializing Project: $PROJECT (Gateway to Internet 2)"

# ディレクトリ構造の作成
mkdir -p $PROJECT/{docs,node,gateway,scripts}
cd $PROJECT

# ==========================================
# 1. システム設計書 & API仕様書 (Docs)
# ==========================================
cat << 'EOF' > docs/README.md
# Relic Protocol System Design

## 概要
インターネット2と現実世界を接続するための人格駆動型分散計算ネットワーク。
ユーザーは「Relic（聖遺物）」と呼ばれる計算コントラクトをアップロードし、
それがネットワーク内の「人格（Persona）」たちによって解釈・伝播されることで世界が駆動する。

## アーキテクチャ
1. **Relic (Contract)**
   - 関数 $f$: Pythonコードとして記述されるロジック。
   - 初期値 $x$: ベクトルまたは状態辞書。

2. **Node (Persona)**
   - **Interpretation**: 他ノードからの入力 $x_j$ を自身の人格行列 $P_i$ で変換する ($P_i x_j$)。
   - **Execution**: Relic関数 $f$ を実行する。 $x_{new} = f(x_{self}, P_i x_{neighbor}, \text{HumanInput})$
   - **Adaptation**: 通信後、他者とのズレを最小化するように $P_i$ を微修正する（実験Eに基づく）。

3. **Gateway**
   - ユーザーが Relic をネットワークに注入するためのエンドポイント。
   - ネットワーク全体の状態（曼荼羅）を可視化する。

## API Specification

### Node API (Port 8000-800X)
- `POST /inject_relic`: 新しいRelic（関数と初期値）をインストールする。
- `POST /human_input`: ノードの所有者（人間）が次の計算サイクルに介入するテキスト/値を設定する。
- `POST /gossip`: 他ノードからデータを受け取る（内部通信用）。
- `GET /state`: 現在の思考状態を取得する。

### Gateway API (Port 3000)
- `POST /deploy`: ネットワーク全体、または特定のノードにRelicを配布する。
- `GET /visualize`: 全ノードの状態を取得し可視化用データを返す。
EOF

echo "Generated: docs/README.md"

# ==========================================
# 2. Node 実装 (The Persona Engine)
# ==========================================
cat << 'EOF' > node/requirements.txt
fastapi
uvicorn
numpy
requests
pydantic
EOF

cat << 'EOF' > node/main.py
import os
import logging
import random
import asyncio
import requests
import numpy as np
from fastapi import FastAPI, BackgroundTasks
from pydantic import BaseModel
from typing import List, Optional, Dict, Any

# ロギング設定
logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] Node-%(message)s')
logger = logging.getLogger(__name__)

app = FastAPI()

# --- 設定 ---
DIM = 4
LEARNING_RATE = 0.01  # 人格の適応率
NODE_ID = os.getenv("NODE_ID", "node_unknown")
PEERS = os.getenv("PEERS", "").split(",")

# --- 状態 ---
# 人格行列 (直交行列で初期化)
rng = np.random.default_rng(int(os.getenv("SEED", 0)))
Q, _ = np.linalg.qr(rng.normal(size=(DIM, DIM)))
P = Q

# 現在の状態 (初期値)
state_vector = rng.normal(size=DIM)
human_intervention: Optional[str] = None # 人間の介入テキスト

# --- Relic (動的関数) ---
# デフォルトの「何もしない」Relic
current_relic_code = """
def update(self_state, neighbor_signal, human_input):
    # デフォルト: 隣人の意見を少し聞き入れる平均化
    alpha = 0.1
    return self_state + alpha * (neighbor_signal - self_state)
"""
relic_scope = {}

def compile_relic(code_str: str):
    """Relicコードをコンパイルして実行可能にする"""
    global relic_scope
    try:
        exec(code_str, {}, relic_scope)
        if 'update' not in relic_scope:
            raise Exception("Relic must define an 'update' function.")
        logger.info("New Relic installed successfully.")
    except Exception as e:
        logger.error(f"Failed to compile Relic: {e}")

# 初期コンパイル
compile_relic(current_relic_code)

# --- Models ---
class RelicPayload(BaseModel):
    code: str
    initial_input: List[float]

class GossipPayload(BaseModel):
    sender_id: str
    vector: List[float]

class HumanInput(BaseModel):
    content: str

# --- Core Logic ---

def process_integration(neighbor_vec: np.ndarray):
    """人格フィルターを通して計算し、状態を更新する"""
    global state_vector, P, human_intervention

    # 1. Interpretation (人格による解釈)
    # Experiment E: P * x_neighbor
    interpreted_signal = P @ neighbor_vec

    # 2. Execution (Relic関数の実行)
    try:
        func = relic_scope.get('update')
        # 関数に (自分の状態, 解釈された相手の意見, 人間の介入) を渡す
        new_state = func(state_vector, interpreted_signal, human_intervention)

        # 結果がNumpy配列かリストかチェックして正規化
        if isinstance(new_state, list):
            new_state = np.array(new_state)

        # 発散防止の正規化 (球面上の状態を維持するため)
        norm = np.linalg.norm(new_state)
        if norm > 0:
            state_vector = new_state / norm

        # 介入は一度使ったら消費される（あるいは持続させる設計も可）
        human_intervention = None

    except Exception as e:
        logger.error(f"Error executing Relic: {e}")

    # 3. Adaptation (人格の微修正 - Experiment E)
    # 相手の意見を理解しようとして、Pを少し回転させる
    # P_new = P - eta * (Error) ... 簡易的なHebbian
    # ここではシンプルに「解釈後のベクトル」が「自分の新しい状態」に近づくようにPを更新
    # update_direction = np.outer(state_vector, neighbor_vec)
    # P = P + LEARNING_RATE * update_direction
    # (直交性を維持するために本当はもっと複雑だが、ここでは簡易実装)
    pass

# --- Tasks ---

async def gossip_loop():
    """定期的に噂話をするバックグラウンドタスク"""
    while True:
        await asyncio.sleep(random.uniform(1.0, 3.0))
        if not PEERS or PEERS == ['']:
            continue

        target = random.choice(PEERS)
        try:
            # 自分の状態を送信
            requests.post(
                f"http://{target}:8000/gossip",
                json={"sender_id": NODE_ID, "vector": state_vector.tolist()},
                timeout=0.5
            )
        except Exception as e:
            # オフラインのノードは無視
            pass

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(gossip_loop())

# --- Endpoints ---

@app.post("/inject_relic")
def inject_relic(payload: RelicPayload):
    """新しいRelic（契約）をインストール"""
    global current_relic_code, state_vector
    current_relic_code = payload.code
    state_vector = np.array(payload.initial_input)
    # 再コンパイル
    compile_relic(current_relic_code)
    return {"status": "Relic updated", "node": NODE_ID}

@app.post("/human_input")
def set_human_input(payload: HumanInput):
    """所有者(人間)からの介入テキストを設定"""
    global human_intervention
    human_intervention = payload.content
    logger.info(f"Human intervention received: {payload.content}")
    return {"status": "Input accepted", "node": NODE_ID}

@app.post("/gossip")
def receive_gossip(payload: GossipPayload):
    """他ノードからの入力を受け取り、思考を回す"""
    incoming_vec = np.array(payload.vector)
    process_integration(incoming_vec)
    return {"status": "ack"}

@app.get("/state")
def get_state():
    """現在の状態と思考のスナップショット"""
    return {
        "node": NODE_ID,
        "vector": state_vector.tolist(),
        "human_input_buffer": human_intervention
    }
EOF

cat << 'EOF' > node/Dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

echo "Generated: node code & Dockerfile"

# ==========================================
# 3. Gateway 実装 (The Interface)
# ==========================================
cat << 'EOF' > gateway/requirements.txt
flask
requests
numpy
EOF

cat << 'EOF' > gateway/app.py
from flask import Flask, jsonify, request
import requests
import os
import json

app = Flask(__name__)

NODES = os.getenv("NODES", "").split(",")

@app.route('/')
def index():
    return jsonify({
        "system": "Internet 2 Gateway",
        "nodes_online": NODES,
        "usage": {
            "POST /deploy": "Deploy a Relic to all nodes",
            "GET /status": "Get network belief state"
        }
    })

@app.route('/deploy', methods=['POST'])
def deploy_relic():
    """全ノードにRelicを一斉送信（または伝播の起点を作成）"""
    data = request.json
    results = {}

    # 実際の運用では1つのノードに投げてGossipで広めるのが筋だが、
    # MVPとしては一斉配信で「世界の上書き」を行う
    for node in NODES:
        try:
            resp = requests.post(f"http://{node}:8000/inject_relic", json=data, timeout=1)
            results[node] = resp.json()
        except:
            results[node] = "offline"

    return jsonify(results)

@app.route('/status')
def status():
    """全ノードの状態を収集（神の視点）"""
    network_state = []
    for node in NODES:
        try:
            resp = requests.get(f"http://{node}:8000/state", timeout=0.5)
            network_state.append(resp.json())
        except:
            network_state.append({"node": node, "status": "offline"})
    return jsonify(network_state)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000)
EOF

cat << 'EOF' > gateway/Dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
CMD ["python", "app.py"]
EOF

echo "Generated: gateway code & Dockerfile"

# ==========================================
# 4. Docker Compose (Environment)
# ==========================================
cat << 'EOF' > docker-compose.yml
services:
  gateway:
    build: ./gateway
    ports:
      - "3000:3000"
    environment:
      - NODES=node1,node2,node3,node4,node5
    depends_on:
      - node1

  node1:
    build: ./node
    environment:
      - NODE_ID=node1
      - SEED=1
      - PEERS=node2,node3,node4,node5
    ports: ["8001:8000"]

  node2:
    build: ./node
    environment:
      - NODE_ID=node2
      - SEED=2
      - PEERS=node1,node3,node4,node5
    ports: ["8002:8000"]

  node3:
    build: ./node
    environment:
      - NODE_ID=node3
      - SEED=3
      - PEERS=node1,node2,node4,node5
    ports: ["8003:8000"]

  node4:
    build: ./node
    environment:
      - NODE_ID=node4
      - SEED=4
      - PEERS=node1,node2,node3,node5
    ports: ["8004:8000"]

  node5:
    build: ./node
    environment:
      - NODE_ID=node5
      - SEED=5
      - PEERS=node1,node2,node3,node4
    ports: ["8005:8000"]
EOF

echo "Generated: docker-compose.yml"

# ==========================================
# 5. Helper Script to Inject a Relic
# ==========================================
cat << 'EOF' > scripts/inject_demo.sh
#!/bin/bash

# Relicコードの定義: 野獣先輩AI
# ここでは「入力テキスト(人間の介入)」を数値変換してベクトルに加算するロジックを含む
RELIC_CODE='
def update(self_state, interpreted_neighbor, human_input):
    import numpy as np

    # 1. アルゴリズム的合意 (neighborとの混合)
    # 人格フィルターを通った他者の意見を30%取り入れる
    mixed = 0.7 * self_state + 0.3 * interpreted_neighbor

    # 2. 人間による介入 (Human Intervention)
    bias = np.zeros_like(self_state)
    if human_input:
        # 文字列のハッシュ値をベクトルに変換する簡易実装
        val = sum(ord(c) for c in human_input) % 100 / 100.0
        # 人間の言葉は世界を特定の方向に強く歪める
        bias[0] = val
        bias[1] = -val

        # コンソールログ（本来はサーバーログに出る）
        print(f"Human said: {human_input} -> Applying bias")

    return mixed + bias * 0.5
'

# JSONペイロードの作成
PAYLOAD=$(jq -n \
                  --arg code "$RELIC_CODE" \
                  --argjson init "[0.1, 0.2, 0.3, 0.4]" \
                  '{code: $code, initial_input: $init}')

echo "Deploying Relic via Gateway..."
curl -X POST -H "Content-Type: application/json" -d "$PAYLOAD" http://localhost:3000/deploy

echo -e "\n\nInjecting Human Input to Node 1..."
curl -X POST -H "Content-Type: application/json" -d '{"content": "i am happy"}' http://localhost:8001/human_input

echo -e "\n\nChecking Status..."
sleep 2
curl http://localhost:3000/status | jq .
EOF

cat << 'EOF' > scripts/inject_demo.sh
#!/bin/bash
echo "Monitoring Internet 2 Evolution..."
for i in {1..10}
do
  echo "--- Step $i ---"
  curl -s http://localhost:3000/status | jq -r '.[] | "\(.node): \(.vector)"'
  sleep 3
done

EOF

chmod +x scripts/inject_demo.sh
echo "Generated: scripts/inject_demo.sh"

echo "========================================"
echo "Build Complete."
echo "Run: 'docker compose up --build' to start the Internet 2 capsule."
echo "Then use 'scripts/inject_demo.sh' to inject the first Relic."
echo "========================================"
