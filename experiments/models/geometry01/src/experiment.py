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
