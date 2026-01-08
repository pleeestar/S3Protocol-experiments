#!/bin/zsh
set -e

PROJECT="relic-explorer"
echo "=================================================="
echo "   RELIC EXPLORER: ALL-IN-ONE DEPLOYMENT"
echo "   Status: Initializing Internet 2 Gateway..."
echo "=================================================="

# クリーンアップとディレクトリ作成
rm -rf $PROJECT
mkdir -p $PROJECT/{backend/app,frontend/app,frontend/public}
cd $PROJECT

# ---------------------------------------------------------
# BACKEND: Requirements & Logic
# ---------------------------------------------------------
echo ">>> Building Backend (The Brain)..."

cat << 'EOF' > backend/requirements.txt
fastapi
uvicorn
numpy
pydantic
websockets
EOF

cat << 'EOF' > backend/app/presets.py
import numpy as np

def random_orthogonal(dim):
    H = np.random.randn(dim, dim)
    Q, _ = np.linalg.qr(H)
    return Q

def generate_persona(name, dim):
    base = np.eye(dim)
    if name == "The Yes Man": return base
    elif name == "The Contrarian": return -1 * base
    elif name == "The Rotator":
        P = np.zeros((dim, dim))
        for i in range(0, dim-1, 2):
            P[i, i+1], P[i+1, i] = -1, 1
        if dim % 2 != 0: P[-1, -1] = 1
        return P
    elif name == "The Filter":
        P = np.eye(dim)
        for i in range(dim // 2, dim): P[i, i] = 0
        return P
    else: return random_orthogonal(dim)
EOF

cat << 'EOF' > backend/app/node.py
import numpy as np
from .presets import generate_persona

class PersonaNode:
    def __init__(self, node_id, dim, persona_name="The Chaos"):
        self.node_id = node_id
        self.dim = dim
        self.name = persona_name
        self.P = generate_persona(persona_name, dim)
        self.P_initial = self.P.copy()
        self.x = np.random.randn(dim)
        self.x /= np.linalg.norm(self.x)
        self.inbox = []
        self.alpha = 0.6
        self.lr = 0.01

    def receive(self, vector):
        self.inbox.append(np.array(vector))

    def process_cycle(self, relic_func=None):
        if not self.inbox: return
        neighbor_signal = np.mean(self.inbox, axis=0)
        self.inbox = []
        interpreted = np.tanh(self.P @ neighbor_signal)

        if relic_func:
            try:
                proposed_x = relic_func(self.x, interpreted)
                if isinstance(proposed_x, list): proposed_x = np.array(proposed_x)
            except:
                proposed_x = self.alpha * self.x + (1 - self.alpha) * interpreted
        else:
            proposed_x = self.alpha * self.x + (1 - self.alpha) * interpreted

        norm = np.linalg.norm(proposed_x)
        new_x = proposed_x / norm if norm > 1e-9 else proposed_x

        # Adaptation (Exp E)
        delta_P = np.outer(new_x, neighbor_signal)
        self.P = self.P + self.lr * delta_P
        self.x = new_x

    def get_state(self):
        drift = np.linalg.norm(self.P - self.P_initial)
        return {"id": self.node_id, "name": self.name, "vector": self.x.tolist(), "drift": float(drift)}
EOF

cat << 'EOF' > backend/app/main.py
import asyncio
import random
import numpy as np
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from .node import PersonaNode

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

DIM, NODE_COUNT = 8, 6
PERSONAS = ["The Yes Man", "The Contrarian", "The Rotator", "The Filter", "The Chaos", "The Chaos"]
NODES = [PersonaNode(f"node_{i}", DIM, PERSONAS[i % len(PERSONAS)]) for i in range(NODE_COUNT)]
compiled_relic = None

class DeployPayload(BaseModel):
    code: str

def compile_user_code(code_str):
    scope = {}
    try:
        exec(code_str, {}, scope)
        return scope.get('update')
    except: return None

async def simulation_loop():
    while True:
        for node in NODES:
            target = random.choice([n for n in NODES if n != node])
            target.receive(node.x)
        for node in NODES:
            node.process_cycle(relic_func=compiled_relic)
        await asyncio.sleep(0.5)

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(simulation_loop())

@app.get("/state")
def get_state(): return [n.get_state() for n in NODES]

@app.post("/deploy")
def deploy_relic(payload: DeployPayload):
    global compiled_relic
    compiled_relic = compile_user_code(payload.code)
    return {"status": "deployed", "valid": compiled_relic is not None}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            await websocket.send_json([n.get_state() for n in NODES])
            await asyncio.sleep(0.1)
    except: pass
EOF

cat << 'EOF' > backend/Dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app ./app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# ---------------------------------------------------------
# FRONTEND: Modern UI & Patches Integrated
# ---------------------------------------------------------
echo ">>> Building Frontend (The Interface with Web3 Patch)..."

cat << 'EOF' > frontend/package.json
{
  "name": "relic-explorer-ui",
  "version": "2.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "14.0.0",
    "react": "^18",
    "react-dom": "^18",
    "framer-motion": "^10.16.4",
    "lucide-react": "^0.292.0",
    "recharts": "^2.9.0",
    "clsx": "^2.0.0",
    "tailwind-merge": "^2.0.0",
    "@monaco-editor/react": "^4.6.0"
  },
  "devDependencies": {
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.31",
    "tailwindcss": "^3.3.5",
    "typescript": "^5",
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18"
  }
}
EOF

cat << 'EOF' > frontend/postcss.config.js
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

cat << 'EOF' > frontend/tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      fontFamily: { sans: ['Inter', 'sans-serif'], mono: ['JetBrains Mono', 'monospace'] },
      colors: {
        background: '#09090b', surface: '#18181b', border: '#27272a',
        primary: '#fafafa', muted: '#a1a1aa',
        accent: { start: '#4f46e5', end: '#ec4899' }
      }
    }
  },
  plugins: [],
}
EOF

cat << 'EOF' > frontend/app/globals.css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono&display=swap');
@tailwind base; @tailwind components; @tailwind utilities;

body { color: #fafafa; background: #09090b; font-family: 'Inter', sans-serif; overflow: hidden; }
.glass-panel { background: rgba(24, 24, 27, 0.6); backdrop-filter: blur(12px); border: 1px solid rgba(255, 255, 255, 0.08); }
.gradient-text { background: linear-gradient(to right, #818cf8, #e879f9); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
EOF

cat << 'EOF' > frontend/app/layout.tsx
import './globals.css'
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <body className="antialiased">{children}</body>
    </html>
  )
}
EOF

# Main UI Implementation
cat << 'EOF' > frontend/app/page.tsx
'use client';
import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Network, MessageSquare, Cpu, Users, Activity, Terminal, Play, Cpu as CpuIcon, ShieldCheck } from 'lucide-react';
import { AreaChart, Area, ResponsiveContainer, XAxis, YAxis, Tooltip } from 'recharts';
import Editor from '@monaco-editor/react';

const TABS = [
  { id: 'tracking', label: 'Nodes', icon: Network },
  { id: 'sns', label: 'SNS', icon: MessageSquare },
  { id: 'compute', label: 'Relic', icon: Cpu },
];

export default function Home() {
  const [activeTab, setActiveTab] = useState('tracking');
  const [nodes, setNodes] = useState([]);
  const [status, setStatus] = useState("Ready");

  useEffect(() => {
    const ws = new WebSocket('ws://localhost:8000/ws');
    ws.onmessage = (e) => setNodes(JSON.parse(e.data));
    return () => ws.close();
  }, []);

  return (
    <div className="h-screen flex flex-col bg-background text-primary">
      {/* Sidebar Navigation */}
      <div className="flex flex-1 overflow-hidden">
        <nav className="w-20 border-r border-border flex flex-col items-center py-8 gap-8 bg-surface/50">
          <div className="w-10 h-10 bg-indigo-600 rounded-xl flex items-center justify-center mb-4 shadow-lg shadow-indigo-500/20">
            <Terminal size={20} />
          </div>
          {TABS.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`p-3 rounded-xl transition-all ${activeTab === tab.id ? 'bg-indigo-600 text-white' : 'text-muted hover:bg-white/5'}`}
            >
              <tab.icon size={24} />
            </button>
          ))}
        </nav>

        {/* Main Content Area */}
        <main className="flex-1 flex flex-col p-8 overflow-hidden">
          <header className="flex justify-between items-center mb-8">
            <div>
              <h1 className="text-3xl font-bold gradient-text">Internet 2 Gateway</h1>
              <p className="text-muted text-sm mt-1">Active Persona Protocol: RELIC_0.9</p>
            </div>
            <div className="flex gap-4">
               <div className="glass-panel px-4 py-2 rounded-full flex items-center gap-2 text-xs">
                 <span className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse" />
                 {nodes.length} NODES SYNCED
               </div>
            </div>
          </header>

          <AnimatePresence mode="wait">
            {activeTab === 'tracking' && (
              <motion.div initial={{opacity:0}} animate={{opacity:1}} className="grid grid-cols-3 gap-6 overflow-y-auto">
                {nodes.map(node => (
                  <div key={node.id} className="glass-panel p-6 rounded-2xl">
                    <div className="flex justify-between mb-4">
                      <span className="font-bold text-indigo-400">{node.name}</span>
                      <span className="text-[10px] text-muted font-mono">{node.id}</span>
                    </div>
                    <div className="h-20 flex items-end gap-1">
                      {node.vector.map((v, i) => (
                        <div key={i} className="flex-1 bg-indigo-500/50 rounded-t" style={{height: `${Math.abs(v)*100}%`}} />
                      ))}
                    </div>
                    <div className="mt-4 pt-4 border-t border-white/5 text-[10px] text-muted flex justify-between">
                      <span>Persona Drift</span>
                      <span>{(node.drift*100).toFixed(2)}%</span>
                    </div>
                  </div>
                ))}
              </motion.div>
            )}

            {activeTab === 'compute' && (
              <motion.div initial={{opacity:0}} animate={{opacity:1}} className="h-full flex flex-col">
                <div className="flex-1 glass-panel rounded-2xl overflow-hidden mb-4">
                   <Editor height="100%" defaultLanguage="python" theme="vs-dark" defaultValue="# Define update(self_v, neighbor_v)" />
                </div>
                <button className="bg-indigo-600 py-4 rounded-xl font-bold hover:bg-indigo-500 transition-all">INJECT RELIC PROTOCOL</button>
              </motion.div>
            )}

            {activeTab === 'sns' && (
               <motion.div initial={{opacity:0}} animate={{opacity:1}} className="max-w-xl mx-auto w-full">
                 <div className="glass-panel p-6 rounded-2xl mb-6">
                    <textarea className="w-full bg-transparent border-none focus:ring-0 text-lg resize-none" placeholder="What's happening in Internet 2?" />
                    <button className="mt-4 bg-white text-black px-6 py-2 rounded-full font-bold ml-auto block">Broadcast</button>
                 </div>
                 <div className="space-y-4">
                    <div className="glass-panel p-4 rounded-xl border border-white/5 opacity-50">Gossip will appear here based on persona interpretation...</div>
                 </div>
               </motion.div>
            )}
          </AnimatePresence>
        </main>
      </div>
    </div>
  );
}
EOF

cat << 'EOF' > frontend/Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
CMD ["npm", "run", "dev"]
EOF

# ---------------------------------------------------------
# ORCHESTRATION: Docker Compose
# ---------------------------------------------------------
echo ">>> Finalizing Infrastructure (Docker Compose)..."

cat << 'EOF' > docker-compose.yml
services:
  backend:
    build: ./backend
    ports: ["8000:8000"]
    volumes: ["./backend/app:/app/app"]
    environment: ["PYTHONUNBUFFERED=1"]

  frontend:
    build: ./frontend
    ports: ["3000:3000"]
    volumes: ["./frontend/app:/app/app", "./frontend/public:/app/public"]
    environment: ["CHOKIDAR_USEPOLLING=true"]
EOF

echo "=================================================="
echo "   DEPLOYMENT READY"
echo "=================================================="
echo "1. cd $PROJECT"
echo "2. docker compose up --build"
echo "3. Access: http://localhost:3000"
