import numpy as np
import matplotlib.pyplot as plt
from config import *
from tile import step

tile_w = GRID_SIZE // TILES_X
tile_h = GRID_SIZE // TILES_Y

tiles = [[np.zeros((tile_h, tile_w)) for _ in range(TILES_X)] for _ in range(TILES_Y)]

# 初期条件：中央高温スポット
cx, cy = GRID_SIZE // 2, GRID_SIZE // 2
tx, ty = cx // tile_w, cy // tile_h
tiles[ty][tx][cy % tile_h, cx % tile_w] = 100.0

for _ in range(STEPS):
    new_tiles = [[None]*TILES_X for _ in range(TILES_Y)]
    for y in range(TILES_Y):
        for x in range(TILES_X):
            north = tiles[y-1][x][-1,:] if y > 0 else None
            south = tiles[y+1][x][0,:] if y < TILES_Y-1 else None
            west  = tiles[y][x-1][:,-1] if x > 0 else None
            east  = tiles[y][x+1][:,0] if x < TILES_X-1 else None

            new_tiles[y][x] = step(
                tiles[y][x], north, south, west, east, ALPHA
            )
    tiles = new_tiles

# 結果合成
grid = np.zeros((GRID_SIZE, GRID_SIZE))
for y in range(TILES_Y):
    for x in range(TILES_X):
        grid[
            y*tile_h:(y+1)*tile_h,
            x*tile_w:(x+1)*tile_w
        ] = tiles[y][x]

plt.imshow(grid, cmap="hot")
plt.colorbar()
plt.title("2D Diffusion (Tiled / Pseudo-Distributed)")
plt.savefig("output/result.png")
print("saved: output/result.png")
