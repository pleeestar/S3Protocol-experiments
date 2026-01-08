import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("beliefs.csv")

for node, g in df.groupby("node"):
    plt.plot(g["step"], g["belief"], label=node)

plt.legend()
plt.xlabel("step")
plt.ylabel("belief")
plt.title("Gossip-based Persona Convergence")
plt.savefig("beliefs.png")
