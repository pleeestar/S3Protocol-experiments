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
