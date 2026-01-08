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
