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
            docker rmi "${proxy}/xhofe/alist:latest"
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
    # 检查 Alist 容器是否存在
    if docker ps -a --format '{{.Names}}' | grep -q '^alist$'; then
        echo "Alist 容器已存在。"
        read -p "是否删除现有的容器和镜像？这可能会删除所有数据，请做好备份。(y/n): " confirm
        if [ "$confirm" = "y" ]; then
            remove_alist_image
        else
            echo "安装已取消。"
            exit 1
        fi
    fi

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
        echo "用户名: admin"
        echo "密码: admin"
        echo "访问地址: 设备IP:5244"
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

# 定义函数来删除 Alist 镜像
remove_alist_image() {
    echo "检查 Alist 容器状态..."

    # 检查容器是否存在
    if docker ps -a --format '{{.Names}}' | grep -q '^alist$'; then
        echo "Alist 容器存在。"

        # 检查容器是否正在运行
        if docker ps --format '{{.Names}}' | grep -q '^alist$'; then
            echo "正在停止 Alist 容器..."
            if ! docker stop alist; then
                echo "停止 Alist 容器失败。"
                exit 1
            fi
        fi

        # 删除容器
        echo "正在删除 Alist 容器..."
        if ! docker rm alist; then
            echo "删除 Alist 容器失败。"
            exit 1
        fi
    else
        echo "Alist 容器不存在。"
    fi

    # 删除镜像
    echo "正在删除 Alist 镜像..."
    if docker rmi xhofe/alist:latest; then
        echo "Alist 镜像已删除。"
    else
        echo "删除 Alist 镜像失败。"
        exit 1
    fi
}

# 定义函数来恢复默认用户名和密码
reset_admin_credentials() {
    # 检查 Alist 容器是否存在
    if docker ps -a --format '{{.Names}}' | grep -q '^alist$'; then
        echo "正在恢复默认用户名和密码..."
        docker exec -it alist ./alist admin set admin
        if [ $? -eq 0 ]; then
            echo "恢复默认账号成功。"
            echo "用户名: admin"
            echo "密码: admin"
        else
            echo "恢复默认账号失败。"
            exit 1
        fi
    else
        echo "Alist 容器不存在。"
        exit 1
    fi
}

# 显示菜单选项
echo "请选择一个操作："
echo "1. 安装 Alist"
echo "2. 更新 Alist"
echo "3. 卸载 Alist"
echo "4. 删除 Alist 镜像"
echo "5. 恢复默认用户名和密码"
echo "6. 退出"
read -p "请输入您的选择（1/2/3/4/5/6）：" choice

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
    4)
        remove_alist_image
        ;;
    5)
        reset_admin_credentials
        ;;
    6)
        echo "退出脚本。"
        exit 0
        ;;
    *)
        echo "无效的选择，请输入 1、2、3、4、5 或 6。"
        exit 1
        ;;
esac
