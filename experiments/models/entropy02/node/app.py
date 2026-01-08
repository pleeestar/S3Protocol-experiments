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
