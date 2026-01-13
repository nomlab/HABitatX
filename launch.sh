#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# .envファイルからRAILS_ENVを読み込む
if [ -f .env ]; then
    export $(grep -v '^#' .env | grep RAILS_ENV | xargs)
fi

# RAILS_ENVに応じてdocker composeコマンドを設定
if [ "$RAILS_ENV" = "production" ]; then
    COMPOSE_CMD="docker compose -f docker-compose.yml -f docker-compose.prod.yml"
    ENV_NAME="production"
else
    COMPOSE_CMD="docker compose"
    ENV_NAME="development"
fi

case "$1" in
    start)
        echo "Starting HABitatX containers ($ENV_NAME)..."
        exec $COMPOSE_CMD up
        ;;
    stop)
        echo "Stopping HABitatX containers ($ENV_NAME)..."
        $COMPOSE_CMD down
        echo "HABitatX stopped successfully."
        ;;
    restart)
        echo "Restarting HABitatX containers ($ENV_NAME)..."
        $COMPOSE_CMD down
        $COMPOSE_CMD up -d
        echo "HABitatX restarted successfully."
        ;;
    status)
        $COMPOSE_CMD ps
        ;;
    logs)
        $COMPOSE_CMD logs -f
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        echo "Environment: $ENV_NAME (set RAILS_ENV in .env to change)"
        exit 1
        ;;
esac

exit 0
