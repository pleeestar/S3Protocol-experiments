import numpy as np
from .presets import generate_persona

class PersonaNode:
    def __init__(self, node_id, dim, persona_name="The Chaos"):
        self.node_id = node_id
        self.dim = dim
        self.name = persona_name

        # Identity Matrix P (The Persona)
        self.P = generate_persona(persona_name, dim)
        self.P_initial = self.P.copy()

        # State Vector x (The Belief)
        self.x = np.random.randn(dim)
        self.x = self.x / np.linalg.norm(self.x)

        # Buffer for incoming gossip
        self.inbox = []

        # Learning Parameters
        self.alpha = 0.6  # Self-confidence
        self.lr = 0.01    # Adaptation rate (Drift)

    def receive(self, vector):
        self.inbox.append(np.array(vector))

    def process_cycle(self, relic_func=None):
        """1ステップの思考サイクル"""
        if not self.inbox:
            return

        # 1. Aggregate Neighbors (Gossip)
        # 他者の意見の平均をとる
        neighbor_signal = np.mean(self.inbox, axis=0)
        self.inbox = [] # Clear inbox

        # 2. Interpretation (The Filter)
        # P @ neighbor
        interpreted = np.tanh(self.P @ neighbor_signal)

        # 3. Relic Execution (Dynamic Function)
        # もしRelic(ユーザーコード)があれば、通常の力学を上書き/修飾する
        if relic_func:
            try:
                # User defined update: f(self_x, interpreted)
                proposed_x = relic_func(self.x, interpreted)
                # Ensure structure
                if isinstance(proposed_x, list): proposed_x = np.array(proposed_x)
            except:
                # Fallback to standard dynamics if code fails
                proposed_x = self.alpha * self.x + (1 - self.alpha) * interpreted
        else:
            # Standard Dynamics (Exp D)
            proposed_x = self.alpha * self.x + (1 - self.alpha) * interpreted

        # Normalize
        norm = np.linalg.norm(proposed_x)
        if norm > 1e-9:
            new_x = proposed_x / norm
        else:
            new_x = proposed_x

        # 4. Adaptation (Exp E - Hebbian Learning)
        # "解釈された結果(new_x)" と "元の入力(neighbor_signal)" の相関でPを更新
        # delta_P = learning_rate * outer(new_x, neighbor_signal)
        # ※ 簡易実装: 直交性を保つための補正は今回は省略(ドリフトを許容)
        delta_P = np.outer(new_x, neighbor_signal)
        self.P = self.P + self.lr * delta_P

        # Update State
        self.x = new_x

    def get_state(self):
        # Calculate Drift
        drift = np.linalg.norm(self.P - self.P_initial)
        return {
            "id": self.node_id,
            "name": self.name,
            "vector": self.x.tolist(),
            "drift": float(drift)
        }
