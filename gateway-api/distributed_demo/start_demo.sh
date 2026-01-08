#!/bin/bash

# 必要なライブラリのインストール
pip install requests numpy > /dev/null 2>&1

echo "Starting Calculation..."
python3 run_pi_calculation.py
