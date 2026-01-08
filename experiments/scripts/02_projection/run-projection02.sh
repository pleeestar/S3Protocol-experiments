#!/bin/zsh
set -e

PROJECT=projection02
mkdir -p ../models/"$PROJECT"
cd ../models/"$PROJECT"

################################
# Directory structure
################################
mkdir -p src output docker

################################
# requirements
################################
cat > docker/requirements.txt << EOF
numpy
pandas
matplotlib
scikit-learn
umap-learn
EOF

################################
# Dockerfile
################################
cat > docker/Dockerfile << EOF
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src ./src
CMD ["python", "src/run.py"]
EOF

################################
# Core experiment code
################################
cat > src/run.py << 'EOF'
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from sklearn.decomposition import PCA
import umap

np.random.seed(0)

N = 20
d = 8
T = 50

# random graph
neighbors = {i: list(np.random.choice(N, 3, replace=False)) for i in range(N)}

# states on sphere
X = np.random.randn(N, d)
X = X / np.linalg.norm(X, axis=1, keepdims=True)

# personalities (orthogonal)
P = np.array([np.linalg.qr(np.random.randn(d, d))[0] for _ in range(N)])

history = []

for t in range(T):
    X_new = np.zeros_like(X)
    for i in range(N):
        agg = sum(P[i] @ X[j] for j in neighbors[i])
        X_new[i] = agg / np.linalg.norm(agg)
    X = X_new
    norms = np.linalg.norm(X, axis=1)
    history.append(norms)

history = np.array(history)
pd.DataFrame(history).to_csv("output/norms.csv", index=False)

# PCA
X_pca = PCA(2).fit_transform(X)
plt.scatter(X_pca[:,0], X_pca[:,1])
plt.title("PCA (final state)")
plt.savefig("output/pca.png")
plt.close()

# UMAP
X_umap = umap.UMAP(n_neighbors=5, min_dist=0.3).fit_transform(X)
plt.scatter(X_umap[:,0], X_umap[:,1])
plt.title("UMAP (final state)")
plt.savefig("output/umap.png")
plt.close()

# norm plot
plt.plot(history.mean(axis=1))
plt.title("Mean norm over time (should be constant)")
plt.savefig("output/norms.png")
plt.close()

print("Experiment complete.")
EOF

################################
# Run docker
################################
cp docker/requirements.txt .
cp docker/Dockerfile .

echo "== building docker image =="
docker build -t fpg-exp .

echo "== running experiment =="
docker run --rm -v $(pwd)/output:/app/output fpg-exp

echo "== done =="
ls output
