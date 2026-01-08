import numpy as np

def random_orthogonal(d):
    q, _ = np.linalg.qr(np.random.randn(d, d))
    return q

def normalize(v):
    n = np.linalg.norm(v)
    return v / n if n > 0 else v

def rfpg_step(X, P, G, alpha):
    N, d = X.shape
    X_new = np.zeros_like(X)

    for i in range(N):
        agg = np.zeros(d)
        for j in G[i]:
            agg += P[i] @ X[j]
        X_new[i] = normalize(alpha * X[i] + (1 - alpha) * agg)

    return X_new
