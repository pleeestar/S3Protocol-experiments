from internet2_computer import Internet2Computer
import numpy as np
import sys

def main():
    # Dockerネットワーク内なので http://gateway:3000 を指定
    computer = Internet2Computer(gateway_url="http://gateway:3000")

    print("\n=== Internet 2 Distributed PI Demo ===")

    pi_logic = """
    trials = 100
    hits = 0
    for _ in range(trials):
        if random.random()**2 + random.random()**2 <= 1.0:
            hits += 1
    local_pi = 4.0 * (hits / trials)
    current_pi = memory[0] if memory[0] > 0 else 3.0
    updated_pi = 0.9 * current_pi + 0.1 * local_pi

    result_vector = memory
    result_vector[0] = updated_pi
    result_vector[1] = memory[1] + 0.01
    """

    computer.submit_job("MonteCarlo_PI", pi_logic, [3.0, 0.0, 0.0, 0.0])

    for i in range(1, 11):
        result = computer.gather_result(timeout=2)
        if result is not None:
            est_pi = result[0]
            print(f"Step {i:02}: Persona Consensus PI = {est_pi:.6f} (Diff: {abs(est_pi - np.pi):.6f})")
        else:
            print(f"Step {i:02}: Waiting for nodes...")

if __name__ == "__main__":
    main()
