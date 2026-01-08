from fastapi import FastAPI
import random, os

app = FastAPI()
alpha = float(os.getenv("ALPHA", 0.5))
belief = random.random()

@app.get("/state")
def state():
    return {"belief": belief}

@app.post("/tick")
def tick(data: dict):
    global belief
    incoming = data["belief"]
    old = belief
    belief = alpha * belief + (1 - alpha) * incoming
    print(f"[alpha={alpha}] {old:.3f} -> {belief:.3f}", flush=True)
    return {"belief": belief}
