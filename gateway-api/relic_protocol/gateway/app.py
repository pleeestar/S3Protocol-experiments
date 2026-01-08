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
