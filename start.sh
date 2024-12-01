#!/bin/bash

# コマンドに応じて操作を分岐
case "$1" in
    up)
    # 現在のユーザーの UID を取得
    UID=$(id -u)
    # Docker イメージのビルドとコンテナの作成
    docker build -t habitatx --build-arg UID=$UID .
    docker run -d --name habitatx \
        -v $(pwd)/config/master.key:/home/habitatx/config/master.key \
        -v $(pwd)/db:/home/habitatx/db \
        -v $(pwd)/.env:/home/habitatx/.env \
        -e RAILS_ENV=production \
        -p 3000:3000 habitatx
    ;;
  
  start)
    # コンテナの起動
    docker start habitatx
    ;;
  
  restart)
    # コンテナの再起動
    docker restart habitatx
    ;;
  
  stop)
    # コンテナの停止
    docker stop habitatx
    ;;
  
  *)
    echo "使用方法: habitatx.sh {up|start|restart|stop}"
    exit 1
    ;;
esac
