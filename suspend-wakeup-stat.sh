#!/bin/bash

echo ">> [SUSPEND] Times during current boot"
journalctl -b 0 | grep "]: Suspending system..."
echo ">> [WAKE] Times during current boot"
journalctl -b 0 | grep "PM: Finishing wakeup"