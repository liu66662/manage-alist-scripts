#!/bin/bash
2
3# 定义代理地址数组
4PROXY_ADDRESSES=("dockerpull.com" "docker.registry.cyou" "docker-cf.registry.cyou" "dockerproxy" "cndocker.1panel.live")
5
6# 定义函数来尝试拉取镜像
7pull_image() {
8    for proxy in "${PROXY_ADDRESSES[@]}"; do
9        echo "尝试从 $proxy 拉取 Alist 镜像..."
10        if docker pull "${proxy}/xhofe/alist:latest"; then
11            echo "从 $proxy 成功拉取 Alist 镜像。"
12            return 0
13        else
14            echo "从 $proxy 拉取 Alist 镜像失败，尝试下一个代理地址..."
15        fi
16    done
17    echo "所有代理地址都未能成功拉取 Alist 镜像。"
18    return 1
19}
20
21# 定义函数来安装alist
22install_alist() {
23    echo "正在创建 /opt/alist 目录..."
24    mkdir -p /opt/alist && echo "/opt/alist 目录创建成功。" || { echo "创建目录失败。"; exit 1; }
25
26    # 尝试拉取镜像
27    pull_image || { echo "镜像拉取失败，无法继续安装。"; exit 1; }
28
29    echo "正在启动 Alist 容器..."
30    docker run -d --restart=unless-stopped -v /opt/alist:/opt/alist/data -p 5244:5244 -e PUID=1000 -e PGID=1000 -e UMASK=022 --name="alist" xhofe/alist:latest
31
32    # 等待容器启动
33    sleep 5
34
35    # 设置管理员用户名和密码为admin
36    echo "正在设置管理员用户名和密码..."
37    docker exec -it alist ./alist admin set admin
38    if [ $? -eq 0 ]; then
39        echo "管理员用户名: admin"
40        echo "管理员密码: admin"
41    else
42        echo "设置管理员用户名和密码失败。"
43        exit 1
44    fi
45
46    echo "Alist 已安装。"
47}
48
49# 定义函数来更新alist
50update_alist() {
51    echo "正在停止 Alist 容器..."
52    docker stop alist && echo "Alist 容器已停止。" || { echo "停止容器失败。"; exit 1; }
53
54    echo "正在删除旧的 Alist 容器..."
55    docker rm alist && echo "旧的 Alist 容器已删除。" || { echo "删除容器失败。"; exit 1; }
56
57    # 尝试拉取最新的镜像
58    pull_image || { echo "镜像拉取失败，无法继续更新。"; exit 1; }
59
60    echo "正在启动更新后的 Alist 容器..."
61    docker run -d --restart=unless-stopped -v /opt/alist:/opt/alist/data -p 5244:5244 -e PUID=1000 -e PGID=1000 -e UMASK=022 --name="alist" xhofe/alist:latest
62    echo "Alist 已更新。"
63}
64
65# 定义函数来卸载alist
66uninstall_alist() {
67    echo "正在停止 Alist 容器..."
68    docker stop alist && echo "Alist 容器已停止。" || { echo "停止容器失败。"; exit 1; }
69
70    echo "正在删除 Alist 容器..."
71    docker rm alist && echo "Alist 容器已删除。" || { echo "删除容器失败。"; exit 1; }
72
73    echo "正在删除 /opt/alist 目录..."
74    rm -rf /opt/alist && echo "/opt/alist 目录已删除。" || { echo "删除目录失败。"; exit 1; }
75    echo "Alist 已卸载。"
76}
77
78# 显示菜单选项
79echo "请选择一个操作："
80echo "1. 安装 Alist"
81echo "2. 更新 Alist"
82echo "3. 卸载 Alist"
83read -p "请输入您的选择（1/2/3）：" choice
84
85# 根据用户输入执行相应的操作
86case $choice in
87    1) install_alist ;;
88    2) update_alist ;;
89    3) uninstall_alist ;;
90    *) echo "无效的选择，请输入 1, 2 或 3。";;
91esac
