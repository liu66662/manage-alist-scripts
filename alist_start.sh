#!/bin/sh

# 定义函数来安装alist
install_alist() {
    echo "正在创建 /opt/alist 目录..."
    mkdir -p /opt/alist
    echo "正在启动 Alist 容器..."
    docker run -d --restart=unless-stopped -v /etc/alist:/opt/alist/data -p 5244:5244 -e PUID=0 -e PGID=0 -e UMASK=022 --name="alist" dockerpull.com/xhofe/alist:latest

    # 等待容器启动
    sleep 5

  # 执行命令来设置管理员用户名和密码
echo "正在设置管理员用户名和密码..."
output=$(docker exec -it alist ./alist admin set admin)
if [ $? -eq 0 ]; then
    echo "用户名：admin"
    echo "密码：admin"
else
    echo "设置管理员用户名和密码失败。"
fi

    echo "Alist 已安装。"
}

# 定义函数来更新alist
update_alist() {
    echo "正在停止 Alist 容器..."
    docker stop alist
    echo "正在删除旧的 Alist 容器..."
    docker rm alist
    echo "正在拉取最新的 Alist 镜像..."
    docker pull dockerpull.com/xhofe/alist:latest
    echo "正在启动更新后的 Alist 容器..."
    docker run -d --restart=unless-stopped -v /etc/alist:/opt/alist/data -p 5244:5244 -e PUID=0 -e PGID=0 -e UMASK=022 --name="alist" dockerpull.com/xhofe/alist:latest
    echo "Alist 已更新。"
}

# 定义函数来卸载alist
uninstall_alist() {
    echo "正在停止 Alist 容器..."
    docker stop alist
    echo "正在删除 Alist 容器..."
    docker rm alist
    echo "正在删除 /opt/alist 目录..."
    rm -rf /opt/alist
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
        ;;
esac
