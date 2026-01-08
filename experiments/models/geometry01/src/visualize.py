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
