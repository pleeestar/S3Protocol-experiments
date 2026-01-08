#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXPERIMENTS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PROJECT_NAME=geometry01
IMAGE_NAME=belief-exp:latest

echo "=== [1] Project bootstrap ==="

BASE_DIR="$EXPERIMENTS_DIR/models/$PROJECT_NAME"
mkdir -p "$BASE_DIR"/{docker,src,configs,results}
cd "$BASE_DIR"

#####################################
# Dockerfile
#####################################
cat << 'EOF' > docker/Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY docker/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ src/
COPY configs/ configs/

ENTRYPOINT ["python", "src/run_experiment.py"]
EOF

#####################################
# requirements
#####################################
cat << 'EOF' > docker/requirements.txt
numpy
scipy
scikit-learn
matplotlib
pandas
umap-learn
pyyaml
EOF

#####################################
# configs
#####################################
cat << 'EOF' > configs/expA.yaml
name: expA
graph: fixed
projection: identity
seed: 42
EOF

cat << 'EOF' > configs/expB.yaml
name: expB
graph: random
projection: identity
seed: 42
EOF

cat << 'EOF' > configs/expC.yaml
name: expC
graph: random
projection: gossip
seed: 42
EOF

#####################################
# Python
#####################################
cat << 'EOF' > src/run_experiment.py
import yaml, sys, os
import numpy as np
from sklearn.metrics import silhouette_score
from sklearn.decomposition import PCA
import umap
import matplotlib.pyplot as plt

def run(config_path):
    with open(config_path) as f:
        cfg = yaml.safe_load(f)

    np.random.seed(cfg["seed"])
    name = cfg["name"]

    out_dir = f"results/{name}"
    os.makedirs(out_dir, exist_ok=True)

    X = np.random.randn(200, 16)
    if cfg["projection"] == "gossip":
        X = X @ np.random.randn(16, 16)

    labels = np.random.randint(0, 5, size=len(X))
    sil = silhouette_score(X, labels)

    with open(f"{out_dir}/metrics.txt", "w") as f:
        f.write(f"silhouette={sil}\n")

    X_pca = PCA(n_components=2).fit_transform(X)
    plt.scatter(X_pca[:,0], X_pca[:,1], c=labels, s=5)
    plt.savefig(f"{out_dir}/pca.png")
    plt.clf()

    X_umap = umap.UMAP(n_components=2).fit_transform(X)
    plt.scatter(X_umap[:,0], X_umap[:,1], c=labels, s=5)
    plt.savefig(f"{out_dir}/umap.png")
    plt.clf()

    print(f"[DONE] {name}")

if __name__ == "__main__":
    run(sys.argv[1])
EOF

#####################################
# build
#####################################
echo "=== [2] Build docker image ==="
docker build -t "$IMAGE_NAME" -f docker/Dockerfile .

#####################################
# run
#####################################
echo "=== [3] Run experiments A/B/C ==="

for EXP in expA expB expC
do
  docker run --rm \
    -v "$BASE_DIR/results:/app/results" \
    "$IMAGE_NAME" configs/${EXP}.yaml
done

echo "=== ALL EXPERIMENTS FINISHED ==="
