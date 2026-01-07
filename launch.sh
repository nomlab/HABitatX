#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

case "$1" in
    start)
        echo "Starting HABitatX containers..."
        exec docker compose up
        ;;
    stop)
        echo "Stopping HABitatX containers..."
        docker compose down
        echo "HABitatX stopped successfully."
        ;;
    restart)
        echo "Restarting HABitatX containers..."
        docker compose down
        docker compose up -d
        echo "HABitatX restarted successfully."
        ;;
    status)
        docker compose ps
        ;;
    logs)
        docker compose logs -f
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        exit 1
        ;;
esac

exit 0
