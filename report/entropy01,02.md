# 実験報告レポート
## Gossip 型信念更新モデルにおける収束・多様性崩壊の解析

---

## 1. 概要（Abstract）

![beliefs](../experiments/result/entropy01/beliefs.png)
![umap](../experiments/result/entropy02/belief_umap.png)
![pca](../experiments/result/entropy02/belief_pca.png)


本報告では、Gossip 型線形信念更新モデルにおいて観測された**合意形成（consensus）への指数的収束**と、それに伴う**信念多様性の構造的崩壊**について数値実験を通じて分析する。  
特に、スカラー信念モデルからベクトル化された人格表現への拡張を動機とし、線形平均化ダイナミクスが内包する限界を、PCA・UMAP・Silhouette score などの指標を用いて可視化・検証した。

その結果、本モデルは初期に一時的な準安定構造を形成するものの、最終的には単一の合意点へと縮退し、クラスタリングや多様性の概念が数値的に意味を失うことが示された。

---

## 2. 実験データ1：線形 Gossip における収束挙動

### 2.1 観測事実

- 3 ノードすべての信念値が **約 0.9011866 に指数的に収束**
- 初期値の差異（0.93 / 0.76 / 0.72）は完全に消失
- 個体ごとに異なる $\alpha_i$ を設定しても **最終的な収束値は一致**

この挙動は、以下の線形反復写像で記述される：

\[
b_{t+1} = A b_t
\]

ここで行列 $A$ は **確率的 (stochastic)** かつ **primitive（全成分正）** である。

---

### 2.2 理論的背景：Perron–Frobenius 定理

確率的かつ primitive な行列 $A$ に対しては、  
**Perron–Frobenius 定理**により：

- 最大固有値は 1
- 対応する固有ベクトル（定常分布）は一意
- 任意の初期状態はその固有ベクトルに収束

したがって、本系の「全員が同一値に収束する」という結果は、**線形平均化モデルとして必然的**である。

---

## 3. belief のベクトル化：人格表現の拡張

### 3.1 動機

現在の belief はスカラー値 $\mathbb{R}$ 上で定義されているが、これは人格表現としては極めて貧弱である。

- 人格 = 単一信念 ❌  
- 人格 = **意味次元の束（semantic fiber）** ⭕

### 3.2 定義

各エージェント $i$ は次のような $d$ 次元信念ベクトルを持つ：

```text
belief = [
  political_tendency,
  conformity,
  novelty_seeking,
  aggression,
  irony_sensitivity,
  ...
]
````

[
\mathbf{b}_i \in \mathbb{R}^d
]

更新規則（線形 Gossip）は以下で与えられる：

[
\mathbf{b}_i \leftarrow \alpha_i \mathbf{b}_i + (1 - \alpha_i)\mathbf{b}_j
]

---

## 4. 比較対象アルゴリズム

### A. Linear Gossip（現行モデル）

[
\mathbf{b}_i \leftarrow \alpha_i \mathbf{b}_i + (1 - \alpha_i)\mathbf{b}_j
]

* 高速収束
* 数理的に単純
* **全員が同一人格に収束する**

---

### B. Bounded Confidence Model（Deffuant）

[
\text{if } |\mathbf{b}_i - \mathbf{b}_j| < \varepsilon:
\quad \text{update}
]

* Echo chamber の形成
* 非線形
* 現実的な分断構造を生成

---

### C. Nonlinear Activation Gossip

[
\mathbf{b}_i \leftarrow \sigma(\alpha \mathbf{b}_i + (1-\alpha)\mathbf{b}_j)
]

* $\sigma$: tanh / ReLU
* 極性・過激化のモデル化が可能

---

### D. Projection-based Gossip

[
\mathbf{b}_i \leftarrow P_i(\mathbf{b}_j)
]

* 各人格が独自の射影写像を持つ
* 「他人の意見を自分の文脈で歪める」モデル

---

## 5. 実験データ2：構造解析

### 5.1 Silhouette score の時間発展

Silhouette score の推移は、以下の二相構造を示す：

1. **準安定構造期 ($t \lesssim 25$)**

   * 正のスコア
   * 初期分散に由来する一時的クラスタ形成

2. **数値的崩壊期 ($t \gtrsim 30$)**

   * 急激な負値化と激しい振動
   * クラスタ間距離が計算機イプシロンに埋没

これは分化ではなく、**全信念が極端に近接した結果、指標が意味を失った状態**と解釈すべきである。

---

### 5.2 PCA による線形構造解析

PCA 空間における軸スケールは **$10^{-15}$ オーダー**であり、

* belief 空間が **一点へ縮退**
* 観測される散布は浮動小数点誤差由来

すなわち、本系は数学的に完全合意状態に到達している。

---

### 5.3 UMAP による非線形可視化の幻影

UMAP は局所構造を保存しようとするため、

* 微小な数値誤差を拡大解釈
* 実在しない多様体構造を「幻覚」として生成

PCA の結果を踏まえると、UMAP 上のクラスタ構造は**ダイナミクスの帰結ではない**。

---

## 6. 総合考察

### 6.1 多様性の喪失

* 初期の分散は一時的に構造を持つ
* 線形平均化は最終的に必ず均質化を引き起こす
* 人格パラメータ $\alpha$ は「遅延」しか与えない

---

### 6.2 線形平均化の限界

本モデルが内在的に排除している要素：

* 反発（repulsion）
* 非対称信頼
* 意味的歪み
* 非線形境界

その結果、人格の分化・共存は原理的に不可能である。

---

### 6.3 評価指標の再考

Silhouette score は、完全合意極限では無意味となる。
本系に適した指標は：

* 全分散（Total Variance）の減衰率
* 合意形成までの緩和時間
* 有効次元数（effective rank）

---

## 7. 結論

線形 Gossip モデルは、
**合意形成の解析には優れているが、人格・信念の多様性を扱うモデルとしては不適切**である。

今後は、非線形写像・射影構造・有界信頼を導入したモデルにより、
「収束しないこと」そのものを安定解として扱う枠組みが必要である。

---

## 付記

本実験は、「人格を平均すると何が失われるか」を可視化した点で、
モデルの失敗そのものが有意味な結果である。
