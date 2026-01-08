'use client';

import React, { useEffect, useState, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Network,
  MessageSquare,
  Cpu,
  Users,
  Activity,
  Search,
  Play,
  Terminal,
  Wifi,
  ShieldCheck,
  Plus
} from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, AreaChart, Area } from 'recharts';
import Editor from '@monaco-editor/react';

// --- Types ---
type NodeState = {
  id: string;
  name: string;
  vector: number[];
  drift: number;
};

// --- Tabs Configuration ---
const TABS = [
  { id: 'tracking', label: 'Node Tracking', icon: Network },
  { id: 'sns', label: 'Social Layer', icon: MessageSquare },
  { id: 'compute', label: 'Distributed Compute', icon: Cpu },
  { id: 'governance', label: 'Persona Gov', icon: Users },
  { id: 'monitor', label: 'Network Monitor', icon: Activity },
];

// --- Components ---

const GlassCard = ({ children, className = "" }: { children: React.ReactNode, className?: string }) => (
  <motion.div
    initial={{ opacity: 0, y: 10 }}
    animate={{ opacity: 1, y: 0 }}
    className={`glass-panel rounded-2xl p-6 ${className}`}
  >
    {children}
  </motion.div>
);

// 1. Node Tracking View (The Mandala)
const NodeTrackingView = ({ nodes }: { nodes: NodeState[] }) => {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 h-full overflow-y-auto pb-20">
      {nodes.map((node, i) => (
        <GlassCard key={node.id} className="relative overflow-hidden group hover:border-indigo-500/30 transition-colors">
          <div className="flex justify-between items-start mb-4">
            <div>
              <h3 className="font-semibold text-lg">{node.name}</h3>
              <div className="flex items-center gap-2 text-xs text-muted font-mono mt-1">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                {node.id}
              </div>
            </div>
            <div className="text-right">
              <div className="text-xs text-muted">DRIFT</div>
              <div className="font-mono text-indigo-400">{(node.drift * 100).toFixed(1)}%</div>
            </div>
          </div>

          {/* Visualizing Vector State */}
          <div className="h-24 flex items-end justify-between gap-1 mb-4">
             {node.vector.map((v, idx) => (
               <motion.div
                 key={idx}
                 className="w-full bg-gradient-to-t from-indigo-600/20 to-indigo-500 rounded-t-sm"
                 initial={{ height: 0 }}
                 animate={{ height: `${Math.min(Math.abs(v) * 100 + 10, 100)}%` }}
                 transition={{ type: "spring", stiffness: 100, damping: 20 }}
               />
             ))}
          </div>

          <div className="flex justify-between items-center text-xs text-muted border-t border-white/5 pt-3">
            <span>Uptime: 99.9%</span>
            <span className="group-hover:text-white transition-colors">Inspect -></span>
          </div>
        </GlassCard>
      ))}
    </div>
  );
};

// 2. SNS View (Twitter-like)
const SocialView = ({ nodes }: { nodes: NodeState[] }) => {
  const [posts, setPosts] = useState([
    { user: "The Yes Man", content: "I agree with everything effectively.", time: "2m ago" },
    { user: "The Contrarian", content: "No, that is fundamentally incorrect.", time: "1m ago" },
  ]);
  const [input, setInput] = useState("");

  const handlePost = () => {
    if(!input) return;
    setPosts([{ user: "You (Admin)", content: input, time: "Just now" }, ...posts]);
    setInput("");
  };

  return (
    <div className="max-w-2xl mx-auto h-full flex flex-col gap-6">
      {/* Input */}
      <GlassCard>
        <textarea
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Inject gossip into the network..."
          className="w-full bg-transparent border-none focus:ring-0 resize-none text-lg placeholder:text-muted/50 h-24"
        />
        <div className="flex justify-between items-center mt-4 pt-4 border-t border-white/5">
          <div className="text-xs text-muted flex gap-2">
            <span className="px-2 py-1 rounded bg-white/5">Public</span>
            <span className="px-2 py-1 rounded bg-white/5">Broadcast</span>
          </div>
          <button
            onClick={handlePost}
            className="bg-white text-black px-6 py-2 rounded-full font-semibold hover:bg-indigo-50 transition-colors"
          >
            Post
          </button>
        </div>
      </GlassCard>

      {/* Feed */}
      <div className="flex flex-col gap-4 overflow-y-auto pb-20">
        <AnimatePresence>
          {posts.map((post, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="glass-panel p-4 rounded-xl border border-white/5"
            >
              <div className="flex items-center gap-3 mb-2">
                <div className="w-8 h-8 rounded-full bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center text-xs font-bold text-white">
                  {post.user[0]}
                </div>
                <div>
                  <div className="font-semibold text-sm">{post.user}</div>
                  <div className="text-xs text-muted">{post.time}</div>
                </div>
              </div>
              <p className="text-gray-300 leading-relaxed pl-11">{post.content}</p>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>
    </div>
  );
};

// 3. Compute View (Relic Injector)
const ComputeView = () => {
  const [code, setCode] = useState(
`def update(self_state, neighbor_signal):
    # Standard Consensus
    alpha = 0.5
    return alpha * self_state + (1-alpha) * neighbor_signal`
  );

  return (
    <div className="h-full grid grid-cols-12 gap-6">
      <div className="col-span-8 flex flex-col gap-4">
        <GlassCard className="flex-1 p-0 overflow-hidden flex flex-col">
          <div className="p-3 border-b border-white/5 bg-black/20 flex justify-between items-center">
            <div className="flex items-center gap-2 text-sm text-muted">
              <Terminal size={14} />
              <span>relic_protocol.py</span>
            </div>
            <button className="text-xs bg-indigo-600/20 text-indigo-400 px-3 py-1 rounded hover:bg-indigo-600/30 transition-colors flex items-center gap-1">
              <Play size={10} /> DEPLOY
            </button>
          </div>
          <Editor
            height="100%"
            defaultLanguage="python"
            value={code}
            onChange={(val) => setCode(val || "")}
            theme="vs-dark"
            options={{ minimap: { enabled: false }, padding: { top: 20 }, fontSize: 14, fontFamily: 'JetBrains Mono' }}
          />
        </GlassCard>
      </div>

      <div className="col-span-4 flex flex-col gap-4">
        <GlassCard className="h-1/2">
           <h3 className="text-sm font-semibold text-muted mb-4 flex items-center gap-2">
             <Activity size={14}/> CONVERGENCE
           </h3>
           <ResponsiveContainer width="100%" height="80%">
             <AreaChart data={[{v:10}, {v:30}, {v:25}, {v:50}, {v:45}, {v:80}, {v:75}]}>
               <defs>
                 <linearGradient id="colorV" x1="0" y1="0" x2="0" y2="1">
                   <stop offset="5%" stopColor="#8884d8" stopOpacity={0.8}/>
                   <stop offset="95%" stopColor="#8884d8" stopOpacity={0}/>
                 </linearGradient>
               </defs>
               <Area type="monotone" dataKey="v" stroke="#8884d8" fillOpacity={1} fill="url(#colorV)" />
             </AreaChart>
           </ResponsiveContainer>
        </GlassCard>
        <GlassCard className="h-1/2 overflow-auto">
          <h3 className="text-sm font-semibold text-muted mb-2">OUTPUT LOG</h3>
          <div className="font-mono text-xs text-gray-400 space-y-1">
            <p>> Initializing VM...</p>
            <p>> 6 Nodes connected.</p>
            <p className="text-emerald-500">> Injection successful.</p>
            <p>> Propagation rate: 89%</p>
          </div>
        </GlassCard>
      </div>
    </div>
  );
};

// 4. Governance (Persona Management)
const GovernanceView = ({ nodes }: { nodes: NodeState[] }) => {
  return (
    <div className="h-full flex flex-col gap-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold">Active Personas</h2>
        <button className="bg-white text-black px-4 py-2 rounded-full text-sm font-semibold flex items-center gap-2 hover:bg-gray-200">
          <Plus size={16} /> Mint Persona
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {nodes.map(node => (
          <GlassCard key={node.id} className="flex justify-between items-center">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-surfaceHighlight flex items-center justify-center">
                <ShieldCheck className="text-muted" />
              </div>
              <div>
                <div className="font-semibold">{node.name}</div>
                <div className="text-xs text-muted font-mono">{node.id}</div>
              </div>
            </div>
            <div className="flex gap-2">
               <button className="px-3 py-1.5 text-xs border border-white/10 rounded-lg hover:bg-white/5">Config</button>
               <button className="px-3 py-1.5 text-xs bg-red-500/10 text-red-500 border border-red-500/20 rounded-lg hover:bg-red-500/20">Kill</button>
            </div>
          </GlassCard>
        ))}
      </div>
    </div>
  );
};

// 5. Monitor (Logs)
const MonitorView = () => {
  return (
    <div className="h-full font-mono text-xs">
      <GlassCard className="h-full overflow-auto p-0">
        <table className="w-full text-left">
          <thead className="bg-white/5 text-muted sticky top-0">
            <tr>
              <th className="p-3">Time</th>
              <th className="p-3">Source</th>
              <th className="p-3">Type</th>
              <th className="p-3">Payload Hash</th>
              <th className="p-3">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/5">
            {[...Array(15)].map((_, i) => (
              <tr key={i} className="hover:bg-white/5 transition-colors">
                <td className="p-3 text-muted">14:02:{10+i}</td>
                <td className="p-3 text-indigo-400">node_{i%5}</td>
                <td className="p-3">GOSSIP_PACKET</td>
                <td className="p-3 opacity-50">0x8f...2a</td>
                <td className="p-3 text-emerald-500">ACK</td>
              </tr>
            ))}
          </tbody>
        </table>
      </GlassCard>
    </div>
  );
};

// --- Main App Shell ---

export default function Home() {
  const [activeTab, setActiveTab] = useState('tracking');
  const [nodes, setNodes] = useState<NodeState[]>([]);

  // WebSocket Simulation / Connection
  useEffect(() => {
    // 実際はWebSocketを使うが、UI確認用にモックも混ぜる
    const ws = new WebSocket('ws://localhost:8000/ws');
    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        setNodes(data);
      } catch(e) {}
    };
    return () => ws.close();
  }, []);

  return (
    <div className="flex h-screen bg-background text-primary selection:bg-indigo-500/30">

      {/* Sidebar Navigation */}
      <nav className="w-20 md:w-64 border-r border-border flex flex-col bg-surface/50 backdrop-blur-xl">
        <div className="p-6 flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-tr from-indigo-500 to-purple-500 flex items-center justify-center shrink-0">
            <Network className="text-white" size={18} />
          </div>
          <span className="font-bold text-lg hidden md:block tracking-tight">RELIC</span>
        </div>

        <div className="flex-1 px-3 py-4 flex flex-col gap-2">
          {TABS.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 group relative ${
                  isActive ? 'bg-white/10 text-white' : 'text-muted hover:text-white hover:bg-white/5'
                }`}
              >
                <Icon size={20} className={isActive ? 'text-indigo-400' : ''} />
                <span className="hidden md:block font-medium text-sm">{tab.label}</span>
                {isActive && (
                  <motion.div
                    layoutId="active-pill"
                    className="absolute inset-0 border border-white/10 rounded-xl"
                    transition={{ type: "spring", stiffness: 300, damping: 30 }}
                  />
                )}
              </button>
            );
          })}
        </div>

        <div className="p-6 border-t border-border hidden md:block">
          <div className="glass-panel p-4 rounded-xl">
             <div className="text-xs text-muted mb-1">NETWORK STATUS</div>
             <div className="flex items-center gap-2 text-emerald-400 text-sm font-semibold">
               <Wifi size={14} />
               ONLINE (v2.0)
             </div>
          </div>
        </div>
      </nav>

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col min-w-0">
        {/* Header */}
        <header className="h-16 border-b border-border flex items-center justify-between px-8 bg-background/50 backdrop-blur sticky top-0 z-10">
          <h1 className="text-xl font-semibold">
            {TABS.find(t => t.id === activeTab)?.label}
          </h1>
          <div className="flex items-center gap-4">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={14} />
              <input
                type="text"
                placeholder="Search tx or node..."
                className="bg-surfaceHighlight rounded-full pl-9 pr-4 py-1.5 text-sm focus:outline-none focus:ring-1 focus:ring-indigo-500 transition-all border border-transparent"
              />
            </div>
            <div className="w-8 h-8 rounded-full bg-gradient-to-r from-indigo-500 to-purple-600 border border-white/20"></div>
          </div>
        </header>

        {/* Tab Content with Transitions */}
        <div className="flex-1 p-8 overflow-hidden relative">
          <AnimatePresence mode="wait">
            <motion.div
              key={activeTab}
              initial={{ opacity: 0, y: 10, filter: 'blur(10px)' }}
              animate={{ opacity: 1, y: 0, filter: 'blur(0px)' }}
              exit={{ opacity: 0, y: -10, filter: 'blur(10px)' }}
              transition={{ duration: 0.2 }}
              className="h-full"
            >
              {activeTab === 'tracking' && <NodeTrackingView nodes={nodes} />}
              {activeTab === 'sns' && <SocialView nodes={nodes} />}
              {activeTab === 'compute' && <ComputeView />}
              {activeTab === 'governance' && <GovernanceView nodes={nodes} />}
              {activeTab === 'monitor' && <MonitorView />}
            </motion.div>
          </AnimatePresence>
        </div>
      </main>
    </div>
  );
}
