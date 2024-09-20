#!/bin/bash

# 定义代理地址数组
PROXY_ADDRESSES=("dockerpull.com" "docker.registry.cyou" "docker-cf.registry.cyou" "dockerproxy" "cndocker.1panel.live")

# 定义函数来尝试拉取镜像
pull_image() {
    local image_pulled=false
    for proxy in "${PROXY_ADDRESSES[@]}"; do
        echo "尝试从 $proxy 拉取 Alist 镜像..."
        if docker pull "${proxy}/xhofe/alist:latest"; then
            echo "从 $proxy 成功拉取 Alist 镜像。"
            docker tag "${proxy}/xhofe/alist:latest" xhofe/alist:latest
            image_pulled=true
            break
        else
            echo "从 $proxy 拉取 Alist 镜像失败，尝试下一个代理地址..."
        fi
    done
    if [ "$image_pulled" = false ]; then
        echo "所有代理地址都未能成功拉取 Alist 镜像。"
        return 1
    fi
    return 0
}

# 定义函数来安装alist
install_alist() {
    echo "正在创建 /opt/alist 目录..."
    if mkdir -p /opt/alist; then
        echo "/opt/alist 目录创建成功。"
    else
        echo "创建目录失败。"
        exit 1
    fi

    # 尝试拉取镜像
    pull_image || { echo "镜像拉取失败，无法继续安装。"; exit 1; }

    echo "正在启动 Alist 容器..."
    docker run -d --restart=unless-stopped -v /opt/alist:/opt/alist/data -p 5244:5244 -e PUID=1000 -e PGID=1000 -e UMASK=022 --name="alist" xhofe/alist:latest

    # 等待容器启动
    sleep 5

# 设置管理员用户名和密码为admin
echo "正在设置管理员用户名和密码为admin..."
docker exec -it alist ./alist admin set admin
if [ $? -eq 0 ]; then
    echo "用户名:admin"
    echo "密码:admin"
else
    echo "设置管理员用户名和密码失败。"
    exit 1
fi

    echo "Alist 已安装。"
}

# 定义函数来更新alist
update_alist() {
    echo "正在停止 Alist 容器..."
    if ! docker stop alist; then
        echo "停止容器失败。"
        exit 1
    fi

    echo "正在删除旧的 Alist 容器..."
    if ! docker rm alist; then
        echo "删除容器失败。"
        exit 1
    fi

    # 尝试拉取最新的镜像
    pull_image || { echo "镜像拉取失败，无法继续更新。"; exit 1; }

    echo "正在启动更新后的 Alist 容器..."
    docker run -d --restart=unless-stopped -v /opt/alist:/opt/alist/data -p 5244:5244 -e PUID=1000 -e PGID=1000 -e UMASK=022 --name="alist" xhofe/alist:latest
    echo "Alist 已更新。"
}

# 定义函数来卸载alist
uninstall_alist() {
    echo "正在停止 Alist 容器..."
    if ! docker stop alist; then
        echo "停止容器失败。"
        exit 1
    fi

    echo "正在删除 Alist 容器..."
    if ! docker rm alist; then
        echo "删除容器失败。"
        exit 1
    fi

    echo "正在删除 /opt/alist 目录..."
    if ! rm -rf /opt/alist; then
        echo "删除目录失败。"
        exit 1
    fi
    echo "Alist 已卸载。"
}

# 显示菜单选项
echo "请选择一个操作："
echo "1. 安装 Alist"
echo "2. 更新 Alist"
echo "3. 卸载 Alist"
read -p "请输入您的选择（1/2/3）：" choice

# 根据用户输入执行相应的操作
case $choice in
    1)
        install_alist
        ;;
    2)
        update_alist
        ;;
    3)
        uninstall_alist
        ;;
    *)
        echo "无效的选择，请输入 1、2 或 3。"
        exit 1
        ;;
esac
