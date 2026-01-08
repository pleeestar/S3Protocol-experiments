from internet2_computer import Internet2Computer
import numpy as np

def main():
    computer = Internet2Computer()

    print("=== Internet 2 Distributed Computing Demo ===")
    print("Task: Calculate PI using Monte Carlo method via Gossip Protocol")
    print("---------------------------------------------------------------")

    # ---------------------------------------------------------
    # ユーザーのロジック (これを各ノードに配布する)
    # Pythonのインデントに注意（Relic内で実行されるコード）
    # ---------------------------------------------------------
    pi_calculation_logic = """
    # モンテカルロ法による円周率の近似
    # 各ステップで少しずつ試行を行い、自己の信念(memory)を更新する

    # memory[0] = 推定されたPIの値
    # memory[1] = 試行回数カウンタ (正規化されるため近似値)

    trials = 100  # 1回の思考ステップでの試行回数
    hits = 0
    for _ in range(trials):
        x = random.random()
        y = random.random()
        if x*x + y*y <= 1.0:
            hits += 1

    local_pi = 4.0 * (hits / trials)

    # 前回の自分の推定値と、今回の実験結果を混ぜる
    # (学習率 0.1 で新しい実験結果を取り入れる)
    current_pi = memory[0]
    if current_pi == 0: current_pi = 3.0 # 初期値

    updated_pi = 0.9 * current_pi + 0.1 * local_pi

    # 出力ベクトルの作成
    result_vector = memory
    result_vector[0] = updated_pi
    result_vector[1] = memory[1] + 0.01 # カウンタ代わり
    """
    # ---------------------------------------------------------

    # 1. ジョブの投入
    computer.submit_job(
        task_name="MonteCarlo_PI",
        logic_code=pi_calculation_logic,
        initial_memory=[3.0, 0.0, 0.0, 0.0] # 初期推定値 3.0
    )

    # 2. 結果の監視 (噂が広まるのを待つ)
    print("\n[Observe] The nodes are now rolling dice and gossiping about PI...")

    for i in range(1, 6):
        # 少し待ってから集計
        result = computer.gather_result(timeout=3)

        estimated_pi = result[0]
        error = abs(estimated_pi - np.pi)

        print(f"--- Step {i} ---")
        print(f"Network Consensus PI: {estimated_pi:.6f}")
        print(f"Difference from Real PI: {error:.6f}")
        print("Raw Vector (Avg):", result)

    print("\n=== Final Result ===")
    print(f"Real PI: {np.pi}")
    print(f"I2   PI: {estimated_pi}")
    print("Conclusion: The personas discussed and agreed on this value.")

if __name__ == "__main__":
    main()
