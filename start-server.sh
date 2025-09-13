#!/bin/bash

# Quick start script for TabMonitor

echo "🚀 Starting TabMonitor Server..."
echo "================================="

cd "$(dirname "$0")/python-server"

# Start the Python server
./../.venv/bin/python tabmonitor_server.py
