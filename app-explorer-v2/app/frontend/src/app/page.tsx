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
