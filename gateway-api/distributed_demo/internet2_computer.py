import requests
import time
import numpy as np

class Internet2Computer:
    def __init__(self, gateway_url="http://gateway:3000"):
        self.gateway_url = gateway_url

    def submit_job(self, task_name, logic_code, initial_memory=None):
        print(f"[*] Translating task '{task_name}' into Relic Protocol...")
        initial_memory = initial_memory or [0.0, 0.0, 0.0, 0.0]

        relic_template = f"""
def update(self_state, interpreted_neighbor, human_input):
    import numpy as np
    import random
    memory = self_state.copy()
    {logic_code}
    alpha = 0.8
    new_state = alpha * result_vector + (1 - alpha) * interpreted_neighbor
    return new_state
"""
        payload = {"code": relic_template, "initial_input": initial_memory}
        try:
            requests.post(f"{self.gateway_url}/deploy", json=payload, timeout=5)
            print(f"[*] Job '{task_name}' deployed to Internet 2.")
        except Exception as e:
            print(f"[!] Deployment failed: {e}")

    def gather_result(self, timeout=3):
        time.sleep(timeout)
        try:
            resp = requests.get(f"{self.gateway_url}/status", timeout=5)
            data = resp.json()
            vectors = [d["vector"] for d in data if "vector" in d]
            return np.mean(np.array(vectors), axis=0) if vectors else None
        except:
            return None
