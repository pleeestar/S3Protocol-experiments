<p align="center">
  <img src="./Logo.svg" width="680" alt="S3Protocol Logo" />
</p>

<h1 align="center">S3Protocol Relic</h1>

<p align="center">
  <strong>Persona-based Autonomous Decentralized Network<br/>
  for Internet 2</strong>
</p>

<p align="center">
  <em>
    正しさではなく、人格で合意する。<br/>
    計算ではなく、文脈で伝播する。
  </em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/status-experimental-critical.svg" />
  <img src="https://img.shields.io/badge/domain-Internet%202-black.svg" />
  <img src="https://img.shields.io/badge/focus-Persona%20Consensus-purple.svg" />
</p>

---

## 概要

**S3Protocol Relic** は、  
現実世界の信用・暗号・合意原理から切り離された  
独立計算領域 **「インターネット2（Internet 2）」** を想定し、

> **数理的な正しさではなく  
> 人格（Persona）による動的平衡をもって  
> 合意・情報伝播を行う**

ことを目的とした、  
**実験的・思想駆動型の分散ネットワーク研究プロジェクト**です。

このリポジトリには以下が含まれます：

- 人格ネットワークの **数理モデルとシミュレーション**
- 多数の **失敗を含む実験結果**
- それらを **実システムとして扱うための Gateway / UI 実装**

---

## コンセプト

### 🕸 Internet 2

- 現実世界の「正しさ」「暗号」「合意」が通用しない
- 完全にカプセル化された計算宇宙
- *意味・文脈・噂* が主役のネットワーク

### 🧠 Persona（人格）

- ノードは「値」ではなく **解釈構造**を持つ
- 情報をどう歪め、どう保持し、どう忘れるか
- 人格そのものを **プロトコルのインターフェース**として扱う

### 🎯 目的

> 正解を出すネットワークではなく  
> **納得感が循環し続けるネットワーク**を作る

---

## リポジトリ構成

```text
.
├── README.md
├── Report.md
├── project_snapshot.md
│
├── experiments/
│   ├── models/
│   ├── result/
│   └── scripts/
│
├── report/
│
├── app-explorer/
│
└── gateway-api/
````

---

## 実験テーマ

> **人格（構造・多様性）は、分散ネットワーク内で生き残れるか？**

### 実験系列一覧

| 系列                | 内容                | 結果        |
| ----------------- | ----------------- | --------- |
| entropy01 / 02    | 平均化 Gossip        | 人格は急速に消失  |
| projection01 / 02 | 解釈行列射影            | エネルギー保存のみ |
| geometry01 / 02   | Functorial Gossip | 構造保存に成功   |
| geometry03        | 学習・適応             | 社会的クラスタ創発 |

---

## Entropy Experiments

### ― 人格の死 ―

**特徴**

* 単純平均による情報伝播
* 最速で収束する

**結論**

> 正しい
> 速い
> しかし、人格は残らない

---

## Projection Experiments

### ― 解釈はするが潰れる ―

**特徴**

* 各ノードが人格（解釈行列）を持つ
* 射影後に正規化

**結論**

> エネルギーは保存される
> だが、構造は崩壊する

---

## Geometry Experiments

### ― 人格の保存 ―

**特徴**

* 幾何学的制約付き Gossip
* 構造同型性を維持

**結果**

* 人格構造が長期安定
* 合意しすぎない「液体状態」

---

## Geometry03

### ― 人格・適応・社会 ―

**観測結果**

* Silhouette ≈ **0.25**
* 緩やかな社会的クラスタ
* 人格ドリフト < **0.3**

**解釈**

> 人格を失わずに
> 「話が通じる社会」が生まれた

---

## 実験レポート

```text
report/
├── REPORT.md
├── entropy01,02.md
├── projection01.md
├── projection02.md
├── geometry01.md
├── geometry02.md
└── geometry03.md
```

📖 **推奨読書順**
`REPORT.md` → `geometry03.md`

---

## Gateway API

**Internet 2 への境界装置**

* 現実世界の入力を人格刺激に変換
* 正確な計算は失敗する
* その失敗こそが人格の証拠

```text
gateway-api/
├── relic_protocol/
└── distributed_demo/
```

---

## UI Explorer

人格ネットワークを
**観察・介入・破壊するための UI**

* Next.js / Tailwind
* FastAPI
* Docker Compose 対応

---

## クイックスタート

```bash
cd experiments/scripts
cat readme.md
```

```bash
./02_projection/run-projection02.sh
./03_geometry/run-geometry03-E.sh
```

```bash
cd gateway-api
./setup.sh
```

---

## 結論

* 人格は **保存できる**
* 人格は **計算を歪める**
* だが **社会・噂・納得感**には極めて強い

---



## 実行方法とノード構成

### 状態の取得

バックエンド起動後、以下のコマンドで現在のネットワーク状態を取得できます。

```bash
curl http://localhost:8000/state | jq
```

※ `jq` をインストールしている場合、JSON が整形表示されます。

---

### 「仮想Node」と「ネットワークNode」の違い

現在のシステムは **3つのレイヤー** に分かれています。混乱を避けるため、役割を明示します。

| レイヤー                              | 実体                     | 役割                                                      |
| --------------------------------- | ---------------------- | ------------------------------------------------------- |
| **Virtual Sandbox**               | ブラウザ（JS）上のメモリ          | デプロイ前のテスト用。あなたのPC内だけで完結し、ネットワーク通信は行わない。                 |
| **Local Network Nodes**           | Docker内の12個のPythonプロセス | 現在の実験場。12個の独立ノードが相互通信している。物理的には1台のPCだが、構造は分散型。          |
| **Internet 2 (Real Distributed)** | 外部の他人のPC               | 将来的な拡張。第三者がDockerを立ち上げ、あなたのバックエンドに接続することで真の分散ネットワークになる。 |

---

### 外部Nodeとして参加するには？

現在動作している12個のノードは、Docker内部で **仮想的に分散** されています。これを **本物の分散ネットワーク** にするには、以下の設定が必要です。

#### 1. 外部接続の許可

- `docker-compose.yml` で **ポート 8000** を公開しています。
- あなたのPCのIPアドレスが分かれば、他の人がComputeNodeとして接続可能です。

#### 2. ノードの追加

- 現在はコード内で `NODE_COUNT = 12` と固定されています。
- これを **動的参加制** に変更すると、 世界中の人が立ち上げた ComputeNode が実験に参加し、

> **「世界中のPCを使って飛沫計算をする」**

という状態になります。

---

### 実験結果を読むためのヒント

シミュレーション実行中は、以下のログを確認してください。

```bash
docker compose logs -f backend
```

ログには各ステップでの **平均密度** や **エラー** が出力されます。

- **初期状態**: `Node_0` のみが高い値を持つ
- **拡散中**: 全体平均を保ちつつ、各ノードの値が平滑化
- **終了**: `decay_rate` により、全ノードの値が 0 に収束

---

## 今後

* Persona SNS モード
* World Computer モード
* 両者を切り替える Internet 2 Gateway

---
