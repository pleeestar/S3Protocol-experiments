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
