import numpy as np

def step(tile, north, south, west, east, alpha):
    padded = np.pad(tile, 1, mode="constant")

    if north is not None:
        padded[0,1:-1] = north
    if south is not None:
        padded[-1,1:-1] = south
    if west is not None:
        padded[1:-1,0] = west
    if east is not None:
        padded[1:-1,-1] = east

    laplacian = (
        padded[0:-2,1:-1] +
        padded[2:,1:-1] +
        padded[1:-1,0:-2] +
        padded[1:-1,2:] -
        4 * tile
    )
    return tile + alpha * laplacian
