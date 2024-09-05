#!/bin/bash

# 現在のユーザーの UID を取得
UID=$(id -u)

# Docker イメージのビルド
docker build -t habitatx --build-arg UID=$UID .

# Docker コンテナの起動
docker run -it --name habitatx \
    -v $(pwd)/config/master.key:/home/habitatx/config/master.key \
    -v $(pwd)/db:/home/habitatx/db \
    -v $(pwd)/.env:/home/habitatx/.env \
    -e RAILS_ENV=production \
    -p 3000:3000 habitatx
