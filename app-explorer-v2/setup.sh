#!/bin/zsh

# ==========================================
# Project: S3Protocol Relic (RESEARCH EDITION)
# Description: Distributed Consensus Network with Dynamic Python Injection
# Stack: FastAPI, Next.js, shadcn/ui, Docker, Monaco, Recharts
# ==========================================

# 0. Clean Slate
echo "🔥 Purging previous universe..."
rm -rf app

echo "🌌 Initializing S3Protocol Relic: The Programmable Gateway..."

# 1. Directory Structure
mkdir -p app/{backend,frontend/src/app,frontend/src/components/ui,frontend/src/lib,frontend/src/hooks,frontend/public}
cd app

# ==========================================
# 2. Infrastructure (Docker)
# ==========================================

echo "📦 Materializing Infrastructure..."

cat << 'EOF' > docker-compose.yml
services:
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    volumes:
      - ./backend:/app
    environment:
      - RELIC_ENV=production

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    volumes:
      - ./frontend/src:/app/src
      - /app/node_modules
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8000
    depends_on:
      - backend
EOF

# ==========================================
# 3. Backend (FastAPI + Exec Engine)
# ==========================================

echo "🧠 Injecting Neural Matrices & Execution Engine..."

cat << 'EOF' > backend/requirements.txt
fastapi
uvicorn
numpy
pydantic
websockets
python-multipart
EOF

cat << 'EOF' > backend/Dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
EOF

cat << 'EOF' > backend/main.py
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
EOF

# ==========================================
# 4. Frontend (Next.js 14 + Monaco + Injection Logic)
# ==========================================

echo "🖥️ Forging the Interface..."

cat << 'EOF' > frontend/package.json
{
  "name": "s3-protocol",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "14.1.0",
    "react": "^18",
    "react-dom": "^18",
    "framer-motion": "^11.0.3",
    "lucide-react": "^0.330.0",
    "recharts": "^2.12.0",
    "@monaco-editor/react": "^4.6.0",
    "clsx": "^2.1.0",
    "tailwind-merge": "^2.2.1",
    "tailwindcss-animate": "^1.0.7",
    "@radix-ui/react-slot": "^1.0.2",
    "@radix-ui/react-tabs": "^1.0.4",
    "@radix-ui/react-switch": "^1.0.3",
    "@radix-ui/react-scroll-area": "^1.0.5",
    "@radix-ui/react-dialog": "^1.0.5",
    "@radix-ui/react-label": "^2.0.2"
  },
  "devDependencies": {
    "typescript": "^5",
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "autoprefixer": "^10.0.1",
    "postcss": "^8",
    "tailwindcss": "^3.3.0"
  }
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

# -- Configs --

cat << 'EOF' > frontend/postcss.config.js
module.exports = { plugins: { tailwindcss: {}, autoprefixer: {}, }, }
EOF

cat << 'EOF' > frontend/tailwind.config.ts
import type { Config } from "tailwindcss";
const config: Config = {
  darkMode: ["class"],
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: { DEFAULT: "hsl(var(--primary))", foreground: "hsl(var(--primary-foreground))" },
        secondary: { DEFAULT: "hsl(var(--secondary))", foreground: "hsl(var(--secondary-foreground))" },
        destructive: { DEFAULT: "hsl(var(--destructive))", foreground: "hsl(var(--destructive-foreground))" },
        muted: { DEFAULT: "hsl(var(--muted))", foreground: "hsl(var(--muted-foreground))" },
        accent: { DEFAULT: "hsl(var(--accent))", foreground: "hsl(var(--accent-foreground))" },
        card: { DEFAULT: "hsl(var(--card))", foreground: "hsl(var(--card-foreground))" },
      },
      borderRadius: { lg: "var(--radius)", md: "calc(var(--radius) - 2px)", sm: "calc(var(--radius) - 4px)" },
    },
  },
  plugins: [require("tailwindcss-animate")],
};
export default config;
EOF

cat << 'EOF' > frontend/src/app/globals.css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 240 10% 3.9%;
    --foreground: 0 0% 98%;
    --card: 240 10% 3.9%;
    --card-foreground: 0 0% 98%;
    --popover: 240 10% 3.9%;
    --popover-foreground: 0 0% 98%;
    --primary: 0 0% 98%;
    --primary-foreground: 240 5.9% 10%;
    --secondary: 240 3.7% 15.9%;
    --secondary-foreground: 0 0% 98%;
    --muted: 240 3.7% 15.9%;
    --muted-foreground: 240 5% 64.9%;
    --accent: 240 3.7% 15.9%;
    --accent-foreground: 0 0% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 0 0% 98%;
    --border: 240 3.7% 15.9%;
    --input: 240 3.7% 15.9%;
    --ring: 240 4.9% 83.9%;
    --radius: 0.75rem;
  }
}
@layer base {
  * { @apply border-border; }
  body { @apply bg-background text-foreground antialiased; }
}
EOF

# -- Shadcn UI Mocking --

cat << 'EOF' > frontend/src/lib/utils.ts
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"
export function cn(...inputs: ClassValue[]) { return twMerge(clsx(inputs)) }
EOF

cat << 'EOF' > frontend/src/components/ui/card.tsx
import * as React from "react"
import { cn } from "@/lib/utils"
const Card = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("rounded-xl border bg-card text-card-foreground shadow-sm", className)} {...props} />
))
Card.displayName = "Card"
const CardHeader = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("flex flex-col space-y-1.5 p-6", className)} {...props} />
))
CardHeader.displayName = "CardHeader"
const CardTitle = React.forwardRef<HTMLParagraphElement, React.HTMLAttributes<HTMLHeadingElement>>(({ className, ...props }, ref) => (
  <h3 ref={ref} className={cn("font-semibold leading-none tracking-tight", className)} {...props} />
))
CardTitle.displayName = "CardTitle"
const CardContent = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("p-6 pt-0", className)} {...props} />
))
CardContent.displayName = "CardContent"
export { Card, CardHeader, CardTitle, CardContent }
EOF

cat << 'EOF' > frontend/src/components/ui/button.tsx
import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cn } from "@/lib/utils"
export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> { asChild?: boolean, variant?: "default"|"destructive"|"outline"|"secondary"|"ghost" }
const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(({ className, variant="default", asChild = false, ...props }, ref) => {
  const Comp = asChild ? Slot : "button"
  const variants = {
    default: "bg-primary text-primary-foreground hover:bg-primary/90",
    destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/90",
    outline: "border border-input bg-background hover:bg-accent hover:text-accent-foreground",
    secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80",
    ghost: "hover:bg-accent hover:text-accent-foreground"
  }
  return (
    <Comp className={cn("inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none disabled:pointer-events-none disabled:opacity-50 h-10 px-4 py-2", variants[variant], className)} ref={ref} {...props} />
  )
})
Button.displayName = "Button"
export { Button }
EOF

cat << 'EOF' > frontend/src/components/ui/tabs.tsx
import * as React from "react"
import * as TabsPrimitive from "@radix-ui/react-tabs"
import { cn } from "@/lib/utils"
const Tabs = TabsPrimitive.Root
const TabsList = React.forwardRef<React.ElementRef<typeof TabsPrimitive.List>, React.ComponentPropsWithoutRef<typeof TabsPrimitive.List>>(({ className, ...props }, ref) => (
  <TabsPrimitive.List ref={ref} className={cn("inline-flex h-10 items-center justify-center rounded-md bg-muted p-1 text-muted-foreground", className)} {...props} />
))
TabsList.displayName = TabsPrimitive.List.displayName
const TabsTrigger = React.forwardRef<React.ElementRef<typeof TabsPrimitive.Trigger>, React.ComponentPropsWithoutRef<typeof TabsPrimitive.Trigger>>(({ className, ...props }, ref) => (
  <TabsPrimitive.Trigger ref={ref} className={cn("inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm", className)} {...props} />
))
TabsTrigger.displayName = TabsPrimitive.Trigger.displayName
const TabsContent = React.forwardRef<React.ElementRef<typeof TabsPrimitive.Content>, React.ComponentPropsWithoutRef<typeof TabsPrimitive.Content>>(({ className, ...props }, ref) => (
  <TabsPrimitive.Content ref={ref} className={cn("mt-2 ring-offset-background focus-visible:outline-none", className)} {...props} />
))
TabsContent.displayName = TabsPrimitive.Content.displayName
export { Tabs, TabsList, TabsTrigger, TabsContent }
EOF

cat << 'EOF' > frontend/src/components/ui/scroll-area.tsx
import * as React from "react"
import * as ScrollAreaPrimitive from "@radix-ui/react-scroll-area"
import { cn } from "@/lib/utils"
const ScrollArea = React.forwardRef<React.ElementRef<typeof ScrollAreaPrimitive.Root>, React.ComponentPropsWithoutRef<typeof ScrollAreaPrimitive.Root>>(({ className, children, ...props }, ref) => (
  <ScrollAreaPrimitive.Root ref={ref} className={cn("relative overflow-hidden", className)} {...props}>
    <ScrollAreaPrimitive.Viewport className="h-full w-full rounded-[inherit]">{children}</ScrollAreaPrimitive.Viewport>
    <ScrollBar />
    <ScrollAreaPrimitive.Corner />
  </ScrollAreaPrimitive.Root>
))
ScrollArea.displayName = ScrollAreaPrimitive.Root.displayName
const ScrollBar = React.forwardRef<React.ElementRef<typeof ScrollAreaPrimitive.ScrollAreaScrollbar>, React.ComponentPropsWithoutRef<typeof ScrollAreaPrimitive.ScrollAreaScrollbar>>(({ className, orientation = "vertical", ...props }, ref) => (
  <ScrollAreaPrimitive.ScrollAreaScrollbar ref={ref} orientation={orientation} className={cn("flex touch-none select-none transition-colors", orientation === "vertical" && "h-full w-2.5 border-l border-l-transparent p-[1px]", orientation === "horizontal" && "h-2.5 flex-col border-t border-t-transparent p-[1px]", className)} {...props}>
    <ScrollAreaPrimitive.ScrollAreaThumb className="relative flex-1 rounded-full bg-border" />
  </ScrollAreaPrimitive.ScrollAreaScrollbar>
))
ScrollBar.displayName = ScrollAreaPrimitive.ScrollAreaScrollbar.displayName
export { ScrollArea, ScrollBar }
EOF

cat << 'EOF' > frontend/src/components/ui/switch.tsx
import * as React from "react"
import * as SwitchPrimitives from "@radix-ui/react-switch"
import { cn } from "@/lib/utils"
const Switch = React.forwardRef<React.ElementRef<typeof SwitchPrimitives.Root>, React.ComponentPropsWithoutRef<typeof SwitchPrimitives.Root>>(({ className, ...props }, ref) => (
  <SwitchPrimitives.Root className={cn("peer inline-flex h-6 w-11 shrink-0 cursor-pointer items-center rounded-full border-2 border-transparent transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background disabled:cursor-not-allowed disabled:opacity-50 data-[state=checked]:bg-primary data-[state=unchecked]:bg-input", className)} {...props} ref={ref}>
    <SwitchPrimitives.Thumb className={cn("pointer-events-none block h-5 w-5 rounded-full bg-background shadow-lg ring-0 transition-transform data-[state=checked]:translate-x-5 data-[state=unchecked]:translate-x-0")} />
  </SwitchPrimitives.Root>
))
Switch.displayName = SwitchPrimitives.Root.displayName
export { Switch }
EOF

# -- Main Application --

cat << 'EOF' > frontend/src/app/layout.tsx
import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "S3Protocol", description: "Consensus Gateway" };
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <body className="antialiased min-h-screen bg-background font-sans selection:bg-primary/20">{children}</body>
    </html>
  );
}
EOF

cat << 'EOF' > frontend/src/app/page.tsx
'use client';

import React, { useEffect, useState } from 'react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Switch } from '@/components/ui/switch';
import { AreaChart, Area, ResponsiveContainer } from 'recharts';
import { Activity, Cpu, MessageSquare, Shield, Network, Zap, Terminal, Plus, Trash2, Play } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import Editor from '@monaco-editor/react';
import { cn } from '@/lib/utils';

// --- Types ---
type Node = {
  id: number;
  name: string;
  vector: number[];
  drift: number;
  peers: number[];
};

type Gossip = {
  id: string;
  node: string;
  msg: string;
  time: string;
};

// --- Monitor Visualization Component ---
const MonitorCanvas = ({ nodes }: { nodes: Node[] }) => {
  return (
    <div className="relative w-full h-[500px] bg-black/50 rounded-xl overflow-hidden border border-white/5">
      <svg className="absolute inset-0 w-full h-full">
         <defs>
            <radialGradient id="grad1" cx="50%" cy="50%" r="50%" fx="50%" fy="50%">
              <stop offset="0%" style={{stopColor:'rgb(255,255,255)', stopOpacity:0.2}} />
              <stop offset="100%" style={{stopColor:'rgb(0,0,0)', stopOpacity:0}} />
            </radialGradient>
         </defs>
        {nodes.map((n, i) => {
           // Arrange in a circle
           const angle = (i / nodes.length) * 2 * Math.PI;
           const cx = 50 + 35 * Math.cos(angle);
           const cy = 50 + 35 * Math.sin(angle);

           return n.peers.map(pid => {
             const peerIdx = nodes.findIndex(p => p.id === pid);
             if(peerIdx < 0) return null;
             const pAngle = (peerIdx / nodes.length) * 2 * Math.PI;
             const px = 50 + 35 * Math.cos(pAngle);
             const py = 50 + 35 * Math.sin(pAngle);
             return (
               <motion.line
                  key={`${n.id}-${pid}`}
                  x1={`${cx}%`} y1={`${cy}%`} x2={`${px}%`} y2={`${py}%`}
                  stroke="rgba(255,255,255,0.15)" strokeWidth="1"
               />
             )
           })
        })}
        {nodes.map((n, i) => {
           const angle = (i / nodes.length) * 2 * Math.PI;
           const cx = 50 + 35 * Math.cos(angle);
           const cy = 50 + 35 * Math.sin(angle);
           const intensity = Math.abs(n.vector[0]);
           return (
             <g key={n.id}>
               <circle cx={`${cx}%`} cy={`${cy}%`} r={4 + intensity * 5} fill={intensity > 0.8 ? "#ef4444" : "#fff"} opacity="0.8" />
               <text x={`${cx}%`} y={`${cy}%`} dy={20} textAnchor="middle" fill="white" fontSize="10" className="font-mono opacity-50">{n.name}</text>
             </g>
           )
        })}
      </svg>
    </div>
  )
}

// --- Default Algorithm (Graph Diffusion) ---
const DEFAULT_CODE = `# Graph Diffusion Equation: d/dt = D * Laplacian
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
`;

export default function Gateway() {
  const [nodes, setNodes] = useState<Node[]>([]);
  const [gossip, setGossip] = useState<Gossip[]>([]);
  const [systemMode, setSystemMode] = useState("PERSONA");
  const [socket, setSocket] = useState<WebSocket | null>(null);
  const [editorCode, setEditorCode] = useState(DEFAULT_CODE);
  const [consoleLogs, setConsoleLogs] = useState<string[]>([]);

  // Connect
  useEffect(() => {
    const ws = new WebSocket('ws://localhost:8000/ws');
    setSocket(ws);
    ws.onmessage = (e) => {
      const data = JSON.parse(e.data);
      if (data.type === 'TICK') {
        setNodes(data.nodes);
        setSystemMode(data.mode);
        if (data.gossip.length > 0) {
          setGossip(prev => [...data.gossip, ...prev].slice(0, 50));
        }
      } else if (data.type === 'SYS_EVENT') {
        setConsoleLogs(prev => [`[${new Date().toLocaleTimeString()}] ${data.msg}`, ...prev].slice(0,10));
      }
    };
    return () => ws.close();
  }, []);

  const sendCommand = (type: string, payload: any) => {
    socket?.send(JSON.stringify({ type, payload }));
  };

  const handleDeploy = () => {
    sendCommand('DEPLOY_CODE', editorCode);
    setConsoleLogs(prev => [`[${new Date().toLocaleTimeString()}] 🚀 Uploading code to Neural Mesh...`, ...prev]);
  };

  return (
    <div className="flex flex-col min-h-screen bg-background text-foreground p-6 font-sans max-w-[1600px] mx-auto space-y-6">

      {/* Header */}
      <header className="flex justify-between items-center border-b border-white/10 pb-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tighter flex items-center gap-2">
            <Shield className="w-8 h-8" />
            S3Protocol Relic
          </h1>
          <p className="text-muted-foreground text-sm font-mono mt-1">
            GATEWAY_ID: <span className="text-primary">ALPHA_CENTAURI</span> // MODE: <span className={systemMode === 'COMPUTE' ? "text-green-400" : "text-yellow-400"}>{systemMode}</span>
          </p>
        </div>
        <div className="flex gap-4 items-center">
           <div className="flex items-center gap-2 text-xs font-mono bg-secondary px-3 py-1 rounded-full">
              <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
              CONNECTED: {nodes.length} NODES
           </div>
        </div>
      </header>

      {/* Main Tabs */}
      <Tabs defaultValue="compute" className="w-full space-y-6">
        <TabsList className="w-full justify-start h-12 bg-secondary/50 p-1 backdrop-blur-sm">
          <TabsTrigger value="compute" className="gap-2"><Cpu className="w-4 h-4"/> Compute (Code)</TabsTrigger>
          <TabsTrigger value="tracking" className="gap-2"><Activity className="w-4 h-4"/> Tracking (Data)</TabsTrigger>
          <TabsTrigger value="sns" className="gap-2"><MessageSquare className="w-4 h-4"/> Communication</TabsTrigger>
          <TabsTrigger value="monitor" className="gap-2"><Network className="w-4 h-4"/> Monitor</TabsTrigger>
          <TabsTrigger value="management" className="gap-2"><Terminal className="w-4 h-4"/> Management</TabsTrigger>
        </TabsList>

        {/* 1. TRACKING TAB (Data) */}
        <TabsContent value="tracking" className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-4">
            {nodes.map(node => (
              <Card key={node.id} className="bg-black/40 border-white/5 backdrop-blur-md">
                <CardHeader className="pb-2">
                  <div className="flex justify-between items-center">
                    <CardTitle className="text-sm font-mono text-primary/80">{node.name}</CardTitle>
                    <Zap className={cn("w-3 h-3", Math.abs(node.vector[0]) > 0.8 ? "text-red-500" : "text-muted-foreground")} />
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="h-[60px] w-full">
                    <ResponsiveContainer width="100%" height="100%">
                      <AreaChart data={node.vector.map((v, i) => ({v, i}))}>
                         <Area type="monotone" dataKey="v" stroke="#fff" fill="#fff" fillOpacity={0.1} strokeWidth={2} isAnimationActive={false} />
                      </AreaChart>
                    </ResponsiveContainer>
                  </div>
                  <div className="flex flex-col mt-2 text-[10px] text-muted-foreground font-mono bg-black/50 p-2 rounded">
                    <div className="flex justify-between"><span>RAW[0]:</span> <span className="text-white">{node.vector[0].toFixed(5)}</span></div>
                    <div className="flex justify-between"><span>RAW[1]:</span> <span className="text-white">{node.vector[1].toFixed(5)}</span></div>
                    <div className="flex justify-between"><span>RAW[2]:</span> <span className="text-white">{node.vector[2].toFixed(5)}</span></div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        {/* 2. COMPUTE TAB (Main Feature) */}
        <TabsContent value="compute">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 h-[600px]">
             {/* Editor */}
             <Card className="lg:col-span-2 border-white/10 bg-black/50 flex flex-col">
                <CardHeader className="flex flex-row items-center justify-between py-4">
                   <div className="flex flex-col">
                       <CardTitle className="font-mono text-sm">Distributed Logic (Python)</CardTitle>
                       <p className="text-[10px] text-muted-foreground">Context: `vector` (self), `neighbors` (list), `np` (numpy)</p>
                   </div>
                   <div className="flex items-center gap-2 bg-secondary/30 p-1 rounded-lg">
                      <span className={cn("text-xs font-bold px-2 py-1 rounded", systemMode === "COMPUTE" ? "bg-green-500/20 text-green-400" : "text-muted-foreground")}>COMPUTE</span>
                      <Switch
                        checked={systemMode === "COMPUTE"}
                        onCheckedChange={(c) => sendCommand('SET_MODE', c ? 'COMPUTE' : 'PERSONA')}
                      />
                      <span className={cn("text-xs font-bold px-2 py-1 rounded", systemMode === "PERSONA" ? "bg-yellow-500/20 text-yellow-400" : "text-muted-foreground")}>PERSONA</span>
                   </div>
                </CardHeader>
                <CardContent className="flex-1 p-0 relative overflow-hidden">
                   <Editor
                     height="100%"
                     defaultLanguage="python"
                     theme="vs-dark"
                     value={editorCode}
                     onChange={(val) => setEditorCode(val || "")}
                     options={{ minimap: { enabled: false }, fontSize: 13 }}
                   />
                </CardContent>
             </Card>

             {/* Deployment & Logs */}
             <Card className="flex flex-col">
                <CardHeader><CardTitle>Execution Control</CardTitle></CardHeader>
                <CardContent className="space-y-4 flex-1 flex flex-col">
                   <Button className="w-full bg-green-600 hover:bg-green-500 text-white" onClick={handleDeploy}>
                      <Play className="mr-2 h-4 w-4"/> Deploy to Mesh
                   </Button>

                   <div className="flex-1 bg-black/80 rounded-md border border-white/10 p-4 font-mono text-xs overflow-hidden flex flex-col">
                      <div className="text-muted-foreground border-b border-white/10 pb-2 mb-2">System Logs</div>
                      <div className="flex-1 overflow-auto space-y-2">
                          {consoleLogs.map((log, i) => (
                              <div key={i} className="text-green-400/80">{log}</div>
                          ))}
                      </div>
                   </div>

                   <div className="text-[10px] text-muted-foreground bg-secondary/50 p-3 rounded-lg border border-white/5">
                      <strong>Logic Flow:</strong><br/>
                      1. Code Broadcast → Nodes<br/>
                      2. `exec(code)` in Sandbox<br/>
                      3. COMPUTE: Result Applied Directly<br/>
                      4. PERSONA: Result * Matrix + Bias
                   </div>
                </CardContent>
             </Card>
          </div>
        </TabsContent>

        {/* 3. SNS TAB */}
        <TabsContent value="sns">
          <Card className="h-[600px] flex flex-col bg-black/20">
             <CardHeader><CardTitle>Gossip Stream</CardTitle></CardHeader>
             <CardContent className="flex-1 overflow-hidden p-0">
                <ScrollArea className="h-full px-6">
                   <div className="space-y-4 py-4">
                     <AnimatePresence initial={false}>
                       {gossip.map((msg) => (
                         <motion.div
                           key={msg.id}
                           initial={{ opacity: 0, x: -20 }}
                           animate={{ opacity: 1, x: 0 }}
                           exit={{ opacity: 0 }}
                           className="flex gap-3 border-b border-white/5 pb-3 last:border-0"
                         >
                            <div className="w-10 h-10 rounded-full bg-secondary flex items-center justify-center font-bold text-xs border border-white/10">
                               {msg.node.substring(0, 2)}
                            </div>
                            <div>
                               <div className="flex items-center gap-2">
                                  <span className="font-semibold text-sm">{msg.node}</span>
                                  <span className="text-[10px] text-muted-foreground">{msg.time}</span>
                               </div>
                               <p className="text-sm mt-1 opacity-90 font-mono text-xs">{msg.msg}</p>
                            </div>
                         </motion.div>
                       ))}
                     </AnimatePresence>
                   </div>
                </ScrollArea>
             </CardContent>
          </Card>
        </TabsContent>

        {/* 4. MONITOR TAB */}
        <TabsContent value="monitor">
           <Card className="border-none bg-transparent shadow-none">
              <CardHeader>
                 <CardTitle>Topology & Diffusion</CardTitle>
              </CardHeader>
              <CardContent>
                 <MonitorCanvas nodes={nodes} />
              </CardContent>
           </Card>
        </TabsContent>

        {/* 5. MANAGEMENT TAB */}
        <TabsContent value="management">
           <Card>
              <CardHeader className="flex flex-row justify-between">
                 <CardTitle>Node Registry</CardTitle>
                 <Button size="sm" variant="outline" onClick={() => sendCommand('SPAWN', null)}>
                    <Plus className="mr-2 h-4 w-4" /> Spawn Node
                 </Button>
              </CardHeader>
              <CardContent>
                 <div className="rounded-md border border-white/10">
                    <table className="w-full text-sm text-left">
                       <thead className="bg-secondary/50 text-muted-foreground uppercase font-mono text-xs">
                          <tr>
                             <th className="px-4 py-3">ID</th>
                             <th className="px-4 py-3">Name</th>
                             <th className="px-4 py-3">Drift</th>
                             <th className="px-4 py-3">Vector Norm</th>
                             <th className="px-4 py-3 text-right">Action</th>
                          </tr>
                       </thead>
                       <tbody className="divide-y divide-white/5">
                          {nodes.map(node => (
                             <tr key={node.id} className="hover:bg-white/5">
                                <td className="px-4 py-3 font-mono">{node.id}</td>
                                <td className="px-4 py-3 font-medium">{node.name}</td>
                                <td className="px-4 py-3">{(node.drift * 100).toFixed(2)}%</td>
                                <td className="px-4 py-3 font-mono text-xs">{Math.sqrt(node.vector.reduce((a,b) => a + b*b, 0)).toFixed(4)}</td>
                                <td className="px-4 py-3 text-right">
                                   <Button variant="ghost" size="sm" className="h-8 w-8 p-0 text-red-400 hover:text-red-500 hover:bg-red-500/10" onClick={() => sendCommand('PURGE', node.id)}>
                                      <Trash2 className="h-4 w-4" />
                                   </Button>
                                </td>
                             </tr>
                          ))}
                       </tbody>
                    </table>
                 </div>
              </CardContent>
           </Card>
        </TabsContent>

      </Tabs>
    </div>
  );
}
EOF

# -- Configuration --
cat << 'EOF' > frontend/tsconfig.json
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

echo "✅ S3Protocol Relic (Research Edition) Deployment Complete."
echo "👉 Run: 'cd app && docker-compose up --build'"
