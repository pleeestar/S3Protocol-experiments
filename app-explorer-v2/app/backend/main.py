import asyncio
import numpy as np
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Dict
import random
import json
import time
import traceback

app = FastAPI(title="S3Protocol Relic Node")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Default Research Algorithm (Diffusion) ---
DEFAULT_ALGO = """# Graph Diffusion Equation: d/dt = D * Laplacian
# 'vector' = Self State (Current Node)
# 'neighbors' = List of Neighbor Vectors
# 'np' = NumPy Library

D = 0.1  # Diffusion Coefficient

if len(neighbors) > 0:
    # 1. Calculate Mean Field (Average of neighbors)
    neighbor_matrix = np.array(neighbors)
    mean_field = np.mean(neighbor_matrix, axis=0)

    # 2. Compute Laplacian (Mean - Self)
    laplacian = mean_field - vector

    # 3. Update State
    result = vector + (D * laplacian)
else:
    # No neighbors, strict conservation
    result = vector
"""

# --- State ---
class SystemState:
    def __init__(self):
        self.mode = "PERSONA" # PERSONA (Distorted) or COMPUTE (Pure)
        self.code_snippet = DEFAULT_ALGO
        self.global_vector = np.random.rand(3)

system = SystemState()

class NodePersona:
    def __init__(self, id: int, name: str):
        self.id = id
        self.name = name
        # Personality Matrix (-1 to 1)
        self.matrix = np.random.rand(3, 3) * 2 - 1
        # Vector State (initially random)
        self.current_vector = np.random.rand(3)
        self.drift = random.uniform(0.01, 0.05)
        self.peers = [] # List of peer IDs

    def run_code(self, neighbor_vectors: List[np.ndarray], code_str: str, mode: str):
        """
        Dynamically executes code injected from Frontend.
        """
        # 1. Prepare Sandbox Context
        local_scope = {
            "vector": self.current_vector,
            "neighbors": neighbor_vectors,
            "np": np,
            "result": None
        }

        # 2. Execute Injected Logic
        try:
            exec(code_str, {}, local_scope)

            # Retrieve result (or fallback to current if script failed to set result)
            calc_result = local_scope.get("result")
            if calc_result is None:
                calc_result = self.current_vector

            # Ensure shape consistency
            calc_result = np.array(calc_result, dtype=float)
            if calc_result.shape != (3,):
                 calc_result = self.current_vector # Fallback on shape mismatch

        except Exception:
            # On math error, stagnate
            calc_result = self.current_vector

        # 3. Apply Mode Logic
        if mode == "COMPUTE":
            # Pure Research Mode: Accept math result directly
            self.current_vector = calc_result
        else:
            # Persona Mode: Math is an 'opinion' filtered through personality
            # The calculation is the "Input Logic", the Matrix is the "Bias"

            # Blend calculated result with Matrix distortion
            distortion = np.dot(calc_result, self.matrix)

            # Apply drift noise
            noise = np.random.normal(0, self.drift, 3)

            # Update: 80% Retention, 20% New distorted logic
            self.current_vector = (self.current_vector * 0.8) + (distortion * 0.2) + noise

        # Normalize to prevent explosion (unless doing pure unchecked compute)
        if mode == "PERSONA":
            norm = np.linalg.norm(self.current_vector)
            if norm > 5: self.current_vector = (self.current_vector / norm) * 5

        return self.current_vector

    def speak(self):
        intensity = np.linalg.norm(self.current_vector)
        if intensity > 3.0: return f"⚠️ {self.name}: DATA SURGE ({intensity:.2f})"
        if intensity < 0.1: return f"💤 {self.name}: Awaiting input."

        det = np.linalg.det(self.matrix)
        if system.mode == "COMPUTE":
            return f"🧮 {self.name}: Computed result {self.current_vector[0]:.4f}"

        if det > 0: return f"✅ {self.name}: Logic integrated."
        return f"🛑 {self.name}: Deviating from consensus."

# Initial Nodes
names = ["Cynic", "Optimist", "Architect", "Oracle", "Soldier", "Poet", "Merchant", "Thief", "Judge", "Healer", "Jester", "Ghost"]
nodes = [NodePersona(i, n) for i, n in enumerate(names)]

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []
    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)
    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)

manager = ConnectionManager()

# --- Simulation Loop (10Hz) ---
async def universe_tick():
    while True:
        updates = []
        gossips = []

        # 1. Update Topology (Dynamic Mesh for Diffusion)
        # In a real grid, neighbors are static. Here we simulate a shifting p2p mesh.
        # Each node gets 2 random neighbors per tick.

        node_map = {n.id: n for n in nodes}

        snapshot_vectors = {n.id: n.current_vector.copy() for n in nodes}

        for node in nodes:
            # Assign Neighbors (Topology)
            potential_peers = [n for n in nodes if n.id != node.id]
            # Use fixed seed based on time to stabilize topology slightly for diffusion to look nice
            # Or fully random for chaos. Let's do fully random for now.
            peers = random.sample(potential_peers, k=min(len(potential_peers), 3))
            node.peers = [p.id for p in peers]

            neighbor_vectors = [snapshot_vectors[pid] for pid in node.peers]

            # 2. RUN INJECTED CODE
            vec = node.run_code(neighbor_vectors, system.code_snippet, system.mode)

            # Generate Gossip
            if random.random() < 0.02:
                gossips.append({
                    "id": str(time.time()),
                    "node": node.name,
                    "msg": node.speak(),
                    "time": time.strftime("%H:%M:%S")
                })

            updates.append({
                "id": node.id,
                "name": node.name,
                "vector": vec.tolist(),
                "drift": node.drift,
                "peers": node.peers
            })

        # 3. Broadcast
        payload = json.dumps({
            "type": "TICK",
            "mode": system.mode,
            "nodes": updates,
            "gossip": gossips
        })
        try:
            await manager.broadcast(payload)
        except:
            pass

        await asyncio.sleep(0.1)

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(universe_tick())

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            msg = json.loads(data)

            if msg['type'] == 'DEPLOY_CODE':
                # Update the global execution logic
                system.code_snippet = msg['payload']
                await manager.broadcast(json.dumps({
                    "type": "SYS_EVENT",
                    "msg": "⚡ NEW ALGORITHM DEPLOYED TO MESH"
                }))

            elif msg['type'] == 'SET_MODE':
                system.mode = msg['payload'] # PERSONA or COMPUTE
                await manager.broadcast(json.dumps({
                    "type": "SYS_EVENT",
                    "msg": f"System Mode switched to {system.mode}"
                }))

            elif msg['type'] == 'PURGE':
                global nodes
                nodes = [n for n in nodes if n.id != msg['payload']]

            elif msg['type'] == 'SPAWN':
                new_id = len(nodes) + int(time.time())
                nodes.append(NodePersona(new_id, "Anomaly"))

    except WebSocketDisconnect:
        manager.disconnect(websocket)
