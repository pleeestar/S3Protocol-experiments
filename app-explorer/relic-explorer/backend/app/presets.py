import numpy as np

def random_orthogonal(dim):
    """基本: ランダムな直交行列 (Experiment E base)"""
    H = np.random.randn(dim, dim)
    Q, _ = np.linalg.qr(H)
    return Q

def generate_persona(name, dim):
    """名前から人格行列Pを生成するファクトリー"""
    base = np.eye(dim)

    if name == "The Yes Man":
        # 単位行列: 入力をそのまま受け入れる
        return base

    elif name == "The Contrarian":
        # 反転: 全ての意見を逆に解釈する
        return -1 * base

    elif name == "The Rotator":
        # 回転: 議論を常に直交する方向に逸らす (2次元ブロックごとの回転)
        # 簡易的に90度回転行列を作る
        P = np.zeros((dim, dim))
        for i in range(0, dim-1, 2):
            P[i, i+1] = -1
            P[i+1, i] = 1
        # 余りが出たらそのまま
        if dim % 2 != 0:
            P[-1, -1] = 1
        return P

    elif name == "The Filter":
        # 射影: 特定の次元しか見ない (情報落ち)
        P = np.eye(dim)
        # 半分の次元を0にする
        for i in range(dim // 2, dim):
            P[i, i] = 0
        return P

    elif name == "The Chaos":
        # ランダム回転
        return random_orthogonal(dim)

    else:
        # Default to random
        return random_orthogonal(dim)
