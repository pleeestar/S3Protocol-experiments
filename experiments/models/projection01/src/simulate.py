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
