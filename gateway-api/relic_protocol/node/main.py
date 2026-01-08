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
