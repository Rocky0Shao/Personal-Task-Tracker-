"""
Crossy-Queen (Python): Minimal Crossy-Road style using pygame
- Uses the same spritesheet as the MATLAB version: learning/retro_pack.png
- Arrow keys to move; Esc to quit

Requires: pygame
    pip install pygame
"""
from __future__ import annotations
import os
import sys
import random
from typing import List

import pygame

# --- Config ---
TILE_W = 16
TILE_H = 16
SPACING = 1          # 1px spacing between sprites in the sheet
ZOOM = 5
ROWS = 18
COLS = 32
FPS = 15
CAR_DENSITY = 0.18

# Sprite indices (1-based to match MATLAB script)
BLANK = 1
GRASS = 6
ROAD  = 9
GOAL  = 1
CAR_L = 32*3 + 31
CAR_R = 32*3 + 31
QUEEN = 32*3 + 30


def load_spritesheet(path: str, tile_w: int, tile_h: int, spacing: int) -> List[pygame.Surface | None]:
    sheet = pygame.image.load(path).convert_alpha()
    sw, sh = sheet.get_width(), sheet.get_height()
    cols = (sw + 1) // (tile_w + spacing)
    rows = (sh + 1) // (tile_h + spacing)
    sprites: List[pygame.Surface | None] = [None]  # pad index 0 so we can use 1-based IDs
    for r in range(rows):
        for c in range(cols):
            x = c * (tile_w + spacing)
            y = r * (tile_h + spacing)
            sub = sheet.subsurface(pygame.Rect(x, y, tile_w, tile_h))
            # scale for zoom (nearest neighbor)
            sub = pygame.transform.scale(sub, (tile_w * ZOOM, tile_h * ZOOM))
            sprites.append(sub)
    return sprites


def build_lanes():
    lane_type = ["" for _ in range(ROWS)]
    lane_spd = [0 for _ in range(ROWS)]
    lane_type[0] = "goal"
    lane_type[ROWS - 1] = "grass"
    lane_spd[ROWS - 1] = 0
    # Alternate rows between road and grass with slow speeds (1 cell/tick), flipping direction
    for r in range(1, ROWS - 1):  # 0-based
        if (r + 1) % 2 == 0:
            lane_type[r] = "road"
            lane_spd[r] = 1 * (-1) ** (r + 1)
        else:
            lane_type[r] = "grass"
            lane_spd[r] = 0
    return lane_type, lane_spd


def init_cars(lane_type):
    cars = [[False for _ in range(COLS)] for _ in range(ROWS)]
    for r in range(ROWS):
        if lane_type[r] == "road":
            row = [random.random() < CAR_DENSITY for _ in range(COLS)]
            if not any(row):
                row[random.randrange(COLS)] = True
            cars[r] = row
    return cars


def step_cars(cars, lane_spd):
    for r in range(ROWS):
        s = lane_spd[r]
        if s == 0:
            continue
        if s > 0:
            for _ in range(s):
                last = cars[r][-1]
                cars[r] = [last] + cars[r][:-1]
        else:
            for _ in range(-s):
                first = cars[r][0]
                cars[r] = cars[r][1:] + [first]


def draw_frame(screen, sprites, lane_type, lane_spd, cars, pi, pj):
    screen.fill((0, 0, 0))
    # Draw background
    for i in range(ROWS):
        for j in range(COLS):
            if lane_type[i] == "grass":
                bg_id = GRASS
            elif lane_type[i] == "road":
                bg_id = ROAD
            elif lane_type[i] == "goal":
                bg_id = GOAL
            else:
                bg_id = BLANK
            bg = sprites[bg_id]
            screen.blit(bg, (j * TILE_W * ZOOM, i * TILE_H * ZOOM))

    # Draw cars on roads
    for i in range(ROWS):
        if lane_type[i] != "road":
            continue
        car_id = CAR_L if lane_spd[i] < 0 else CAR_R
        car_sprite = sprites[car_id]
        for j in range(COLS):
            if cars[i][j]:
                screen.blit(car_sprite, (j * TILE_W * ZOOM, i * TILE_H * ZOOM))

    # Draw player
    screen.blit(sprites[QUEEN], (pj * TILE_W * ZOOM, pi * TILE_H * ZOOM))

    pygame.display.flip()


def crossy_road_python():
    pygame.init()
    random.seed(1)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    sheet_path = os.path.join(script_dir, "retro_pack.png")
    if not os.path.exists(sheet_path):
        # try repo root learning path if run from a different cwd
        alt_path = os.path.join(os.getcwd(), "learning", "retro_pack.png")
        if os.path.exists(alt_path):
            sheet_path = alt_path
    sprites = load_spritesheet(sheet_path, TILE_W, TILE_H, SPACING)

    screen = pygame.display.set_mode((COLS * TILE_W * ZOOM, ROWS * TILE_H * ZOOM))
    pygame.display.set_caption("Crossy-Queen (Python)")

    lane_type, lane_spd = build_lanes()
    cars = init_cars(lane_type)

    # Player start at bottom center
    pi = ROWS - 1
    pj = COLS // 2

    clock = pygame.time.Clock()
    tick = 0
    running = True

    print("Controls: arrows to move, Esc to quit")

    while running:
        tick += 1
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    running = False
                elif event.key == pygame.K_UP and pi > 0:
                    pi -= 1
                elif event.key == pygame.K_DOWN and pi < ROWS - 1:
                    pi += 1
                elif event.key == pygame.K_LEFT and pj > 0:
                    pj -= 1
                elif event.key == pygame.K_RIGHT and pj < COLS - 1:
                    pj += 1

        # Move cars every other tick to slow them down
        if tick % 2 == 0:
            step_cars(cars, lane_spd)

        # Collision on road
        if lane_type[pi] == "road" and cars[pi][pj]:
            pi = ROWS - 1
            pj = COLS // 2

        # Reached goal
        if lane_type[pi] == "goal":
            # Reset without increasing speed (keep it chill)
            pi = ROWS - 1
            pj = COLS // 2

        draw_frame(screen, sprites, lane_type, lane_spd, cars, pi, pj)
        clock.tick(FPS)

    pygame.quit()


if __name__ == "__main__":
    try:
        crossy_road_python()
    except pygame.error as e:
        print("pygame error:", e)
        sys.exit(1)
