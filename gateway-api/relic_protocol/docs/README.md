# Relic Protocol System Design

## 概要
インターネット2と現実世界を接続するための人格駆動型分散計算ネットワーク。
ユーザーは「Relic（聖遺物）」と呼ばれる計算コントラクトをアップロードし、
それがネットワーク内の「人格（Persona）」たちによって解釈・伝播されることで世界が駆動する。

## アーキテクチャ
1. **Relic (Contract)**
   - 関数 $f$: Pythonコードとして記述されるロジック。
   - 初期値 $x$: ベクトルまたは状態辞書。

2. **Node (Persona)**
   - **Interpretation**: 他ノードからの入力 $x_j$ を自身の人格行列 $P_i$ で変換する ($P_i x_j$)。
   - **Execution**: Relic関数 $f$ を実行する。 $x_{new} = f(x_{self}, P_i x_{neighbor}, \text{HumanInput})$
   - **Adaptation**: 通信後、他者とのズレを最小化するように $P_i$ を微修正する（実験Eに基づく）。

3. **Gateway**
   - ユーザーが Relic をネットワークに注入するためのエンドポイント。
   - ネットワーク全体の状態（曼荼羅）を可視化する。

## API Specification

### Node API (Port 8000-800X)
- `POST /inject_relic`: 新しいRelic（関数と初期値）をインストールする。
- `POST /human_input`: ノードの所有者（人間）が次の計算サイクルに介入するテキスト/値を設定する。
- `POST /gossip`: 他ノードからデータを受け取る（内部通信用）。
- `GET /state`: 現在の思考状態を取得する。

### Gateway API (Port 3000)
- `POST /deploy`: ネットワーク全体、または特定のノードにRelicを配布する。
- `GET /visualize`: 全ノードの状態を取得し可視化用データを返す。
