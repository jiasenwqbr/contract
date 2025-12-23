#!/bin/bash

while true; do
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running Hardhat test..."

  npx hardhat test \
    ./test/uacbsc_stake/StakeUACOnBsc.test.ts \
    --network ganache \
    --grep "test owner stake batch total is right"
  
  npx hardhat test \
    ./test/uacbsc_stake/StakeUACOnBsc.test.ts \
    --network ganache \
    --grep "test user1 stake batch total is right"

  

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Done. Sleep 5 minutes..."
  echo "------------------------------------------------------------"

  sleep 300
done
