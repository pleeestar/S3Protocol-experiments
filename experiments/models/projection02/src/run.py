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
