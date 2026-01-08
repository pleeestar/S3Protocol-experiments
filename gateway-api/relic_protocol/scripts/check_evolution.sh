#!/bin/bash
echo "Monitoring Internet 2 Evolution..."
for i in {1..10}
do
  echo "--- Step $i ---"
  curl -s http://localhost:3000/status | jq -r '.[] | "\(.node): \(.vector)"'
  sleep 3
done
