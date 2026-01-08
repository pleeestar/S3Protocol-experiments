import asyncio
import logging
import random
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
import numpy as np

from .node import PersonaNode

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- System State ---
DIM = 8
NODE_COUNT = 6
NODES = []
# Pre-defined personalities
PERSONAS = ["The Yes Man", "The Contrarian", "The Rotator", "The Filter", "The Chaos", "The Chaos"]

# Initialize Nodes
for i in range(NODE_COUNT):
    p_name = PERSONAS[i % len(PERSONAS)]
    NODES.append(PersonaNode(f"node_{i}", DIM, p_name))

# Relic Code Storage
current_relic_code = None
compiled_relic = None

class DeployPayload(BaseModel):
    code: str

def compile_user_code(code_str):
    """ユーザーのPythonコードを安全でない方法でコンパイルする (MVP仕様)"""
    scope = {}
    try:
        # Expected function: update(self_vec, neighbor_vec) -> new_vec
        exec(code_str, {}, scope)
        if 'update' in scope:
            return scope['update']
    except Exception as e:
        print(f"Compilation Error: {e}")
    return None

# --- Background Simulation Loop ---
async def simulation_loop():
    while True:
        # 1. Random Gossip
        for node in NODES:
            # Pick a random target
            target = random.choice([n for n in NODES if n != node])
            target.receive(node.x)

        # 2. Process & Evolve
        for node in NODES:
            node.process_cycle(relic_func=compiled_relic)

        await asyncio.sleep(0.5)

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(simulation_loop())

# --- Endpoints ---

@app.get("/state")
def get_state():
    return [n.get_state() for n in NODES]

@app.post("/deploy")
def deploy_relic(payload: DeployPayload):
    global current_relic_code, compiled_relic
    current_relic_code = payload.code
    compiled_relic = compile_user_code(payload.code)
    return {"status": "deployed", "valid": compiled_relic is not None}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            # Stream the entire network state
            data = [n.get_state() for n in NODES]
            await websocket.send_json(data)
            await asyncio.sleep(0.1)
    except Exception:
        pass
