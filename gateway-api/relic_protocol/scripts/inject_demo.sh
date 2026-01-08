#!/bin/bash

# Relicコードの定義: 野獣先輩AI
# ここでは「入力テキスト(人間の介入)」を数値変換してベクトルに加算するロジックを含む
RELIC_CODE='
def update(self_state, interpreted_neighbor, human_input):
    import numpy as np

    # 1. アルゴリズム的合意 (neighborとの混合)
    # 人格フィルターを通った他者の意見を30%取り入れる
    mixed = 0.7 * self_state + 0.3 * interpreted_neighbor

    # 2. 人間による介入 (Human Intervention)
    bias = np.zeros_like(self_state)
    if human_input:
        # 文字列のハッシュ値をベクトルに変換する簡易実装
        val = sum(ord(c) for c in human_input) % 100 / 100.0
        # 人間の言葉は世界を特定の方向に強く歪める
        bias[0] = val
        bias[1] = -val

        # コンソールログ（本来はサーバーログに出る）
        print(f"Human said: {human_input} -> Applying bias")

    return mixed + bias * 0.5
'

# JSONペイロードの作成
PAYLOAD=$(jq -n \
                  --arg code "$RELIC_CODE" \
                  --argjson init "[0.1, 0.2, 0.3, 0.4]" \
                  '{code: $code, initial_input: $init}')

echo "Deploying Relic via Gateway..."
curl -X POST -H "Content-Type: application/json" -d "$PAYLOAD" http://localhost:3000/deploy

echo -e "\n\nInjecting Human Input to Node 1..."
curl -X POST -H "Content-Type: application/json" -d '{"content": "i am happy"}' http://localhost:8001/human_input

echo -e "\n\nChecking Status..."
sleep 2
curl http://localhost:3000/status | jq .
