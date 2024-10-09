#!/bin/bash

# 显示 ziqing logo
echo "================================================="
echo "███████╗██╗██████╗ ██╗ ██████╗ ██╗███╗   ██╗"
echo "██╔════╝██║██╔══██╗██║██╔═══██╗██║████╗  ██║"
echo "█████╗  ██║██████╔╝██║██║   ██║██║██╔██╗ ██║"
echo "██╔══╝  ██║██╔═══╝ ██║██║   ██║██║██║╚██╗██║"
echo "██║     ██║██║     ██║╚██████╔╝██║██║ ╚████║"
echo "╚═╝     ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝"
echo "               ziqing"
echo "================================================="

# 系统更新及 RAM 缓存清理函数
function system_update_and_clean() {
    echo "正在更新系统并清理 RAM 缓存..."
    sudo apt update -y && sudo apt upgrade -y
    sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"
    echo "RAM 缓存已清理。"
}

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "================================================================"
        echo "请选择要执行的操作:"
        echo "1) 启动节点"
        echo "2) 查看日志"
        echo "3) 删除节点"
        echo "4) 清理 RAM 缓存"
        echo "5) 退出"
        
        read -p "请输入选择的数字: " choice
        
        case $choice in
            1) start_node ;;
            2) view_logs ;;
            3) delete_node ;;
            4) clean_ram_cache ;;
            5) echo "退出脚本。"; exit 0 ;;
            *) echo "无效选择，请重试。"; read -p "按任意键继续..." ;;
        esac
    done
}

# 启动节点的函数
function start_node() {
    system_update_and_clean

    # 检查 Docker 是否已安装
    if ! command -v docker &> /dev/null; then
        echo "Docker 未安装，正在安装 Docker..."
        sudo apt-get install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        sudo apt update -y && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        echo "Docker 安装完成！"
    else
        echo "Docker 已安装，跳过安装。"
    fi

    mkdir -p ~/sixgpt
    cd ~/sixgpt

    read -p "请输入你的 VANA 私钥: " vana_private_key
    export VANA_PRIVATE_KEY=$vana_private_key

    read -p "请输入 Vana 网络类型 (satori 或 moksha): " vana_network
    while [[ "$vana_network" != "satori" && "$vana_network" != "moksha" ]]; do
        echo "无效的输入。请输入 'satori' 或 'moksha'。"
        read -p "请输入 Vana 网络类型 (satori 或 moksha): " vana_network
    done
    export VANA_NETWORK=$vana_network

    cat <<EOL >docker-compose.yml
version: '3.8'
services:
  ollama:
    image: ollama/ollama:0.3.12
    ports:
      - "11435:11434"
    volumes:
      - ollama:/root/.ollama
    restart: unless-stopped
  sixgpt3:
    image: sixgpt/miner:latest
    ports:
      - "3015:3000"
    depends_on:
      - ollama
    environment:
      - VANA_PRIVATE_KEY=\${VANA_PRIVATE_KEY}
      - VANA_NETWORK=\${VANA_NETWORK}
    restart: always
volumes:
  ollama:
EOL

    echo "正在启动 SixGPT 矿工..."
    docker compose up -d
    echo "SixGPT 矿工已启动！"
    read -p "按任意键返回主菜单..."
}

# 查看日志的函数
function view_logs() {
    echo "正在查看 Docker Compose 日志..."
    docker compose logs -fn 100
    read -p "按任意键返回主菜单..."
}

# 删除节点的函数
function delete_node() {
    echo "正在停止并删除所有 Docker Compose 服务..."
    docker compose down
    echo "所有 Docker Compose 服务已停止并删除。"
    read -p "按任意键返回主菜单..."
}

# 清理 RAM 缓存的函数
function clean_ram_cache() {
    echo "正在清理 RAM 缓存..."
    sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"
    echo "RAM 缓存已清理。"
    read -p "按任意键返回主菜单..."
}

# 调用主菜单函数
main_menu
