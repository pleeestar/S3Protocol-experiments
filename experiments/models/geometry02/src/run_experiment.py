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
