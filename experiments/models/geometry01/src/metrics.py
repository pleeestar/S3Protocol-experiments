import numpy as np
from sklearn.metrics import silhouette_score

def norms(X):
    return np.linalg.norm(X, axis=1)

def silhouette(X, labels):
    if len(set(labels)) < 2:
        return 0.0
    return silhouette_score(X, labels)
