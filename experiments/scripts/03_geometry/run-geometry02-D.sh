#!/bin/bash
set -e

PROJECT=geometry02
echo "== creating project $PROJECT =="

mkdir -p ../models/"$PROJECT"/{docker,src,output}
cd ../models/

############################
# requirements.txt
############################
cat << EOF > $PROJECT/docker/requirements.txt
numpy
scipy
networkx
scikit-learn
matplotlib
umap-learn
EOF

############################
# Dockerfile
############################
cat << EOF > $PROJECT/docker/Dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/
CMD ["python", "src/experiment.py"]
EOF

############################
# dynamics.py
############################
cat << EOF > $PROJECT/src/dynamics.py
import numpy as np

def random_orthogonal(d):
    q, _ = np.linalg.qr(np.random.randn(d, d))
    return q

def normalize(v):
    n = np.linalg.norm(v)
    return v / n if n > 0 else v

def rfpg_step(X, P, G, alpha):
    N, d = X.shape
    X_new = np.zeros_like(X)

    for i in range(N):
        agg = np.zeros(d)
        for j in G[i]:
            agg += P[i] @ X[j]
        X_new[i] = normalize(alpha * X[i] + (1 - alpha) * agg)

    return X_new
EOF

############################
# metrics.py
############################
cat << EOF > $PROJECT/src/metrics.py
import numpy as np
from sklearn.metrics import silhouette_score

def norms(X):
    return np.linalg.norm(X, axis=1)

def silhouette(X, labels):
    if len(set(labels)) < 2:
        return 0.0
    return silhouette_score(X, labels)
EOF

############################
# visualize.py
############################
cat << EOF > $PROJECT/src/visualize.py
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
import umap

def plot_pca(X, path):
    Z = PCA(n_components=2).fit_transform(X)
    plt.figure()
    plt.scatter(Z[:,0], Z[:,1], s=10)
    plt.title("Belief PCA")
    plt.savefig(path)
    plt.close()

def plot_umap(X, path):
    Z = umap.UMAP(n_components=2).fit_transform(X)
    plt.figure()
    plt.scatter(Z[:,0], Z[:,1], s=10)
    plt.title("Belief UMAP")
    plt.savefig(path)
    plt.close()
EOF

############################
# experiment.py
############################
cat << EOF > $PROJECT/src/experiment.py
import numpy as np
import networkx as nx
from dynamics import random_orthogonal, rfpg_step
from metrics import norms, silhouette
from visualize import plot_pca, plot_umap

# ===== parameters =====
N = 50
d = 16
T = 100
alpha = 0.6
clusters = 5
np.random.seed(0)

# ===== graph =====
G_nx = nx.erdos_renyi_graph(N, 0.1)
G = [list(G_nx.neighbors(i)) for i in range(N)]

# ===== labels (for silhouette) =====
labels = np.repeat(range(clusters), N // clusters)

# ===== init =====
X = np.random.randn(N, d)
X = np.array([x / np.linalg.norm(x) for x in X])
P = [random_orthogonal(d) for _ in range(N)]

silhouette_ts = []
norms_ts = []

# ===== dynamics =====
for t in range(T):
    X = rfpg_step(X, P, G, alpha)
    silhouette_ts.append(silhouette(X, labels))
    norms_ts.append(norms(X).mean())

# ===== save metrics =====
np.savetxt("output/silhouette.csv", silhouette_ts, delimiter=",")
np.savetxt("output/norms.csv", norms_ts, delimiter=",")

# ===== visualize final =====
plot_pca(X, "output/belief_pca.png")
plot_umap(X, "output/belief_umap.png")

print("Experiment D finished.")
EOF

############################
# Run docker
############################
cd $PROJECT
cp docker/requirements.txt .
cp docker/Dockerfile .

echo "== building docker image =="
docker build -t belief-exp-d .

echo "== running experiment =="
docker run --rm -v $(pwd)/output:/app/output belief-exp-d

echo "== done =="
ls output
