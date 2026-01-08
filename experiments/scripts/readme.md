# Experiments / Scripts

このディレクトリには、本プロジェクトで行われた**すべての実験を再現するための zsh スクリプト**が含まれています。

本リポジトリにおける成果は「コードそのもの」ではなく、  
**スクリプトによって展開される実験系列と、その結果として創発した構造**にあります。

---

## ⚠️ 最重要ルール：実行ディレクトリ

**必ずこの `experiments/scripts/` ディレクトリに `cd` してから実行してください。**

これらのスクリプトは以下を前提に設計されています：

- 相対パスによるディレクトリ解決
- 結果出力先（`../results/`）の構造
- Docker マウントパス

そのため、別の場所から実行すると  
**結果の保存先が崩れる、または実験が失敗します。**

### ✅ 正しい実行方法

```bash
cd experiments/scripts
./03_geometry/run-geometry02-D.sh
````

### ❌ 間違った実行方法

```bash
./experiments/scripts/03_geometry/run-geometry02-D.sh
```

---

## ディレクトリ構成

```text
experiments/scripts/
├── 01_entropy/        # 人格が崩壊・消失する実験群
│   ├── run-entropy01.sh
│   └── run-entropy02.sh
│
├── 02_projection/     # 解釈射影・意味の歪みを観測する実験群
│   ├── run-projection01.sh
│   └── run-projection02.sh
│
├── 03_geometry/       # 人格を保持したまま社会構造が生まれる実験群
│   ├── run-geometry01-ABC.sh
│   ├── run-geometry02-D.sh
│   └── run-geometry03-E.sh
│
├── logs/              # 各実験の実行ログ
│
└── run-all.md         # 推奨実験順・一括実行ガイド
```

---

## 実験カテゴリの説明

### 01_entropy — 人格の消失実験

人格ベクトルが相互作用の中で急速に拡散・同質化し、
**「個」が消えていく状態**を観測します。

```bash
cd experiments/scripts
./01_entropy/run-entropy01.sh
./01_entropy/run-entropy02.sh
```

**主な出力**

* エントロピー推移
* 人格ノルムの崩壊
* クラスタ構造の消失

---

### 02_projection — 解釈射影実験

人格が入力情報をどのように歪め、
**「同じ情報が異なる意味として伝播するか」**を観測します。

```bash
cd experiments/scripts
./02_projection/run-projection01.sh
./02_projection/run-projection02.sh
```

**主な出力**

* PCA / UMAP 可視化
* Silhouette Score の時間変化
* 射影後の belief 分布

---

### 03_geometry — 人格保存と社会構造の創発

人格を完全には失わずに相互作用した場合、
**「社会的な構造（緩やかなクラスタ）」が生まれるか**を検証します。

```bash
cd experiments/scripts
./03_geometry/run-geometry01-ABC.sh
./03_geometry/run-geometry02-D.sh
./03_geometry/run-geometry03-E.sh
```

**主な出力**

* `personality_drift.png`
* `trajectory_pca.png`
* ノルム変化
* クラスタ指標（Silhouette）

---

## 実行ログについて

各スクリプトの標準出力・エラーは自動的に保存されます。

```text
experiments/scripts/logs/
├── run-entropy01.sh.log
├── run-projection02.sh.log
├── run-geometry02-D.sh.log
└── ...
```

再現性検証・デバッグ時には必ず参照してください。

---

## 実験の推奨実行順

実験は以下の順で実行すると、
**「人格の崩壊 → 解釈の歪み → 社会構造の創発」**という流れが明確に観測できます。

1. `01_entropy`
2. `02_projection`
3. `03_geometry`

詳細な手順は `run-all.md` を参照してください。

---

## 設計思想（重要）

これらのスクリプトは、

* 汎用ツールではありません
* 再利用性より **構造の一貫性**
* 可読性より **再現性**

を優先しています。

「正しく動くこと」よりも
**「同じ条件で、同じ現象が起きること」**
を最重要視しています。

---

## トラブルシューティング

* 実行に失敗する
  → ほぼ確実に **実行ディレクトリが違います**
* 出力が見つからない
  → `../results/` を確認してください
* Docker エラー
  → 各 `.sh` 内の IMAGE / VOLUME 設定を確認してください

---

## 関連ドキュメント

* ルート README：プロジェクト全体の思想と実験結果
* `experiments/results/`：各実験の出力と可視化
* 論文 / レポート：実験結果の理論的考察
