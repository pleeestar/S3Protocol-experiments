import pandas as pd
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
import umap

df = pd.read_csv("beliefs.csv")

pivot = df.pivot_table(
    index=["step","node"],
    columns="dim",
    values="value"
).reset_index()

X = pivot.drop(columns=["step","node"]).values

pca = PCA(n_components=2)
Xp = pca.fit_transform(X)

u = umap.UMAP(n_components=2, random_state=0)
Xu = u.fit_transform(X)

plt.figure()
plt.scatter(Xp[:,0], Xp[:,1], s=5)
plt.title("Belief space (PCA)")
plt.savefig("belief_pca.png")

plt.figure()
plt.scatter(Xu[:,0], Xu[:,1], s=5)
plt.title("Belief space (UMAP)")
plt.savefig("belief_umap.png")
