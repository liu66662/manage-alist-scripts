#!/bin/bash

# 定义代理地址数组
PROXY_ADDRESSES=("dockerpull.com" "docker.registry.cyou" "docker-cf.registry.cyou" "dockerproxy" "cndocker.1panel.live")

# 定义函数来测试代理地址的连通性
test_proxy() {
    for proxy in "${PROXY_ADDRESSES[@]}"; do
        echo "Testing connectivity to $proxy..."
        if curl --output /dev/null --silent --head --fail "http://${proxy}/"; then
            echo "Connectivity to $proxy is successful."
            echo "$proxy"
            return
        else
            echo "Connectivity to $proxy failed."
        fi
    done
    echo ""
}

# 调用测试代理函数并保存可用的代理地址
usable_proxy=$(test_proxy)
if [ -z "$usable_proxy" ]; then
    echo "No usable proxy found. Exiting."
    exit 1
else
    echo "Using proxy: $usable_proxy"
fi

# 定义函数来安装alist
install_alist() {
    echo "正在创建 /opt/alist 目录..."
    mkdir -p /opt/alist && echo "/opt/alist 目录创建成功。" || { echo "创建目录失败。"; exit 1; }

    echo "正在启动 Alist 容器..."
    docker run -d --restart=unless-stopped -v /opt/alist:/opt/alist/data -p 5244:5244 -e PUID=1000 -e PGID=1000 -e UMASK=022 --name="alist" "${usable_proxy}/xhofe/alist:latest"

    # 等待容器启动
    sleep 5

    # 询问用户输入管理员用户名和密码
    read -p "请输入管理员用户名：" username
    read -sp "请输入管理员密码：" password
    echo
    output=$(docker exec -it alist ./alist admin set --username "$username" --password "$password")
    if [ $? -eq 0 ]; then
        echo "管理员用户名和密码设置成功。"
    else
        echo "设置管理员用户名和密码失败。"
        exit 1
    fi

    echo "Alist 已安装。"
}

# 定义函数来更新alist
update_alist() {
    echo "正在停止 Alist 容器..."
    docker stop alist && echo "Alist 容器已停止。" || { echo "停止容器失败。"; exit 1; }

    echo "正在删除旧的 Alist 容器..."
    docker rm alist && echo "旧的 Alist 容器已删除。" || { echo "删除容器失败。"; exit 1; }

    echo "正在拉取最新的 Alist 镜像..."
    docker pull "${usable_proxy}/xhofe/alist:latest"

    echo "正在启动更新后的 Alist 容器..."
    docker run -d --restart=unless-stopped -v /opt/alist:/opt/alist/data -p 5244:5244 -e PUID=1000 -e PGID=1000 -e UMASK=022 --name="alist" "${usable_proxy}/xhofe/alist:latest"
    echo "Alist 已更新。"
}

# 定义函数来卸载alist
uninstall_alist() {
    echo "正在停止 Alist 容器..."
    docker stop alist && echo "Alist 容器已停止。" || { echo "停止容器失败。"; exit 1; }

    echo "正在删除 Alist 容器..."
    docker rm alist && echo "Alist 容器已删除。" || { echo "删除容器失败。"; exit 1; }

    echo "正在删除 /opt/alist 目录..."
    rm -rf /opt/alist && echo "/opt/alist 目录已删除。" || { echo "删除目录失败。"; exit 1; }
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
        echo "无效选项。退出。"
        exit 1
        ;;
esac
