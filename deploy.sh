#!/bin/bash

echo "开始部署..."

# 1. 执行前端构建
echo "开始构建前端项目..."
npm run prod

# 检查构建是否成功
if [ $? -ne 0 ]; then
    echo "前端构建失败，退出部署"
    exit 1
fi

# 2. 构建并启动 Docker 容器
echo "开始构建并启动 Docker 容器..."
docker-compose up --build -d

# 检查 Docker 启动状态
if [ $? -ne 0 ]; then
    echo "Docker 容器启动失败"
    exit 1
fi

echo "部署完成！"
