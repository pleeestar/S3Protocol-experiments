import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
from sklearn.metrics import silhouette_score
import umap

print("Loading data...")
df = pd.read_csv("experiment_data.csv")

# 1. データ整形
nodes = df['node_index'].unique()
steps = df['step'].unique()
last_step = steps[-1]

# Pivot for clustering analysis
pivot = df.pivot_table(
    index=["step","node_index"],
    columns="dim_index",
    values="value"
).reset_index()

# 2. ラストステップの構造解析
final_state = pivot[pivot["step"] == last_step].copy()
X_final = final_state.drop(columns=["step", "node_index"]).values

# Silhouette Score Check
# クラスタ数=2～(Node数-1)で評価してみる
best_sil = -1
if len(nodes) > 2:
    try:
        from sklearn.cluster import KMeans
        # 仮にクラスタがあるとしたら...
        kmeans = KMeans(n_clusters=max(2, len(nodes)//2), n_init=10).fit(X_final)
        labels = kmeans.labels_
        if len(set(labels)) > 1:
            best_sil = silhouette_score(X_final, labels)
    except:
        pass

print(f"Final Step Silhouette Score Estimate: {best_sil}")

# 3. Visualization

# (A) PCA Trajectory
pca = PCA(n_components=2)
all_vectors = pivot.drop(columns=["step", "node_index"]).values
pca.fit(all_vectors) # 全期間でフィット

plt.figure(figsize=(10, 8))
for n in nodes:
    node_data = pivot[pivot["node_index"] == n]
    coords = pca.transform(node_data.drop(columns=["step", "node_index"]).values)

    # 軌跡を描画
    plt.plot(coords[:,0], coords[:,1], alpha=0.5, label=f"Node {n}")
    # 始点と終点
    plt.scatter(coords[0,0], coords[0,1], marker='x', s=50)
    plt.scatter(coords[-1,0], coords[-1,1], marker='o', s=50)

plt.title(f"Trajectory in PCA Space (Exp E)\nEst. Silhouette: {best_sil:.3f}")
plt.legend()
plt.grid(True, alpha=0.3)
plt.savefig("trajectory_pca.png")

# (B) Personality Drift (Identity Crisis Graph)
# 時間経過とともに、各ノードの人格(P)が初期値からどれだけ乖離したか
plt.figure(figsize=(10, 6))
drift_data = df.pivot_table(index="step", columns="node_index", values="drift")
for n in nodes:
    plt.plot(drift_data.index, drift_data[n], label=f"Node {n}")

plt.title("Personality Drift (Frobenius Norm from Initial P)")
plt.xlabel("Step")
plt.ylabel("Distance from Original Self")
plt.legend()
plt.grid(True)
plt.savefig("personality_drift.png")

print("Analysis Done.")
print("Generated: trajectory_pca.png, personality_drift.png")
