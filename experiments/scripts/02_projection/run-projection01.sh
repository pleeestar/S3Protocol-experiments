#!/usr/bin/env zsh
set -e

PROJECT=projection01

echo "== initializing project =="
mkdir -p ../models/"$PROJECT"/{docker,src,output}
cd ../models/

############################
# Docker setup
############################

cat <<EOF > $PROJECT/docker/requirements.txt
numpy
pandas
scikit-learn
matplotlib
umap-learn
scipy
EOF

cat <<EOF > $PROJECT/docker/Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src ./src
CMD ["python", "src/simulate.py"]
EOF

############################
# Simulation
############################

cat <<'EOF' > $PROJECT/src/simulate.py
import numpy as np
import pandas as pd
from sklearn.cluster import KMeans

np.random.seed(0)

N = 30
D = 5
T = 50
alpha = 0.5

belief = np.random.randn(N, D)
records = []

for t in range(T):
    mean = belief.mean(axis=0)
    belief = belief + alpha * (mean - belief)
    for i in range(N):
        records.append({
            "t": t,
            "agent": i,
            **{f"x{d}": belief[i, d] for d in range(D)}
        })

df = pd.DataFrame(records)
df.to_csv("output/belief.csv", index=False)

from metrics import compute_silhouette
compute_silhouette(df)

from visualize import visualize
visualize(df)
EOF

############################
# Metrics
############################

cat <<'EOF' > $PROJECT/src/metrics.py
import pandas as pd
import numpy as np
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score

def compute_silhouette(df):
    out = []
    for t, g in df.groupby("t"):
        X = g[[c for c in g.columns if c.startswith("x")]].values
        if len(X) < 5:
            s = np.nan
        else:
            k = 2
            labels = KMeans(n_clusters=k, n_init="auto").fit_predict(X)
            s = silhouette_score(X, labels)
        out.append({"t": t, "silhouette": s})
    pd.DataFrame(out).to_csv("output/silhouette_time.csv", index=False)
EOF

############################
# Visualization
############################

cat <<'EOF' > $PROJECT/src/visualize.py
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
import umap

def visualize(df):
    sil = pd.read_csv("output/silhouette_time.csv")

    plt.figure()
    plt.plot(sil["t"], sil["silhouette"])
    plt.xlabel("time")
    plt.ylabel("silhouette")
    plt.savefig("output/silhouette_time.png")

    last = df[df["t"] == df["t"].max()]
    X = last[[c for c in last.columns if c.startswith("x")]].values

    pca = PCA(n_components=2)
    Xp = pca.fit_transform(X)

    plt.figure()
    plt.scatter(Xp[:,0], Xp[:,1])
    plt.title("belief PCA")
    plt.savefig("output/belief_pca.png")

    reducer = umap.UMAP()
    Xu = reducer.fit_transform(X)

    plt.figure()
    plt.scatter(Xu[:,0], Xu[:,1])
    plt.title("belief UMAP")
    plt.savefig("output/belief_umap.png")
EOF

############################
# Run docker
############################

cd $PROJECT
cp docker/requirements.txt .
cp docker/Dockerfile .

echo "== building docker image =="
docker build -t belief-exp .

echo "== running experiment =="
docker run --rm -v $(pwd)/output:/app/output belief-exp

echo "== done =="
ls output
