#!/bin/zsh
set -e

PROJECT="distributed_demo"
echo "== Setting up Isolated Docker Environment for Internet 2 Demo =="

mkdir -p $PROJECT
cd $PROJECT

# ==========================================
# 1. 共有ライブラリ (Internet 2 Computer Adapter)
# ==========================================
cat << 'EOF' > internet2_computer.py
import requests
import time
import numpy as np

class Internet2Computer:
    def __init__(self, gateway_url="http://gateway:3000"):
        self.gateway_url = gateway_url

    def submit_job(self, task_name, logic_code, initial_memory=None):
        print(f"[*] Translating task '{task_name}' into Relic Protocol...")
        initial_memory = initial_memory or [0.0, 0.0, 0.0, 0.0]

        relic_template = f"""
def update(self_state, interpreted_neighbor, human_input):
    import numpy as np
    import random
    memory = self_state.copy()
    {logic_code}
    alpha = 0.8
    new_state = alpha * result_vector + (1 - alpha) * interpreted_neighbor
    return new_state
"""
        payload = {"code": relic_template, "initial_input": initial_memory}
        try:
            requests.post(f"{self.gateway_url}/deploy", json=payload, timeout=5)
            print(f"[*] Job '{task_name}' deployed to Internet 2.")
        except Exception as e:
            print(f"[!] Deployment failed: {e}")

    def gather_result(self, timeout=3):
        time.sleep(timeout)
        try:
            resp = requests.get(f"{self.gateway_url}/status", timeout=5)
            data = resp.json()
            vectors = [d["vector"] for d in data if "vector" in d]
            return np.mean(np.array(vectors), axis=0) if vectors else None
        except:
            return None
EOF

# ==========================================
# 2. メインロジック (PI Calculation)
# ==========================================
cat << 'EOF' > main.py
from internet2_computer import Internet2Computer
import numpy as np
import sys

def main():
    # Dockerネットワーク内なので http://gateway:3000 を指定
    computer = Internet2Computer(gateway_url="http://gateway:3000")

    print("\n=== Internet 2 Distributed PI Demo ===")

    pi_logic = """
    trials = 100
    hits = 0
    for _ in range(trials):
        if random.random()**2 + random.random()**2 <= 1.0:
            hits += 1
    local_pi = 4.0 * (hits / trials)
    current_pi = memory[0] if memory[0] > 0 else 3.0
    updated_pi = 0.9 * current_pi + 0.1 * local_pi

    result_vector = memory
    result_vector[0] = updated_pi
    result_vector[1] = memory[1] + 0.01
    """

    computer.submit_job("MonteCarlo_PI", pi_logic, [3.0, 0.0, 0.0, 0.0])

    for i in range(1, 11):
        result = computer.gather_result(timeout=2)
        if result is not None:
            est_pi = result[0]
            print(f"Step {i:02}: Persona Consensus PI = {est_pi:.6f} (Diff: {abs(est_pi - np.pi):.6f})")
        else:
            print(f"Step {i:02}: Waiting for nodes...")

if __name__ == "__main__":
    main()
EOF

# ==========================================
# 3. 実行用Dockerfile (使い捨て)
# ==========================================
cat << 'EOF' > Dockerfile
FROM python:3.11-slim
RUN pip install --no-cache-dir requests numpy
WORKDIR /app
COPY . .
CMD ["python", "main.py"]
EOF

# ==========================================
# 4. 実行スクリプト
# ==========================================
# relic_protocol_default ネットワーク（docker-composeが作る標準名）に参加して実行
# ネットワーク名は `docker network ls` で確認可能ですが、
# composeを起動したディレクトリ名が `relic_protocol` なら `relic_protocol_default` です。

echo "--- Checking Docker Network ---"
NETWORK_NAME=$(docker network ls --filter name=relic_protocol -q | head -n 1)
if [ -z "$NETWORK_NAME" ]; then
    # もし見つからなければ、relic_protocolフォルダ内で `docker compose up` していると仮定
    NETWORK_NAME="relic_protocol_default"
fi

echo "Using Network: $NETWORK_NAME"

echo "--- Building Demo Container ---"
docker build -t i2-dist-comp-demo .

echo "--- Running Demo (Ephemeral) ---"
docker run --rm --network "$NETWORK_NAME" i2-dist-comp-demo

echo "--- Cleanup ---"
cd ..
# rm -rf $PROJECT # 必要ならディレクトリも消す
