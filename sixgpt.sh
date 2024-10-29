#!/bin/bash

# 显示 ziqing logo
echo -e "\033[1;34m================================================="
echo -e "███████╗██╗██████╗ ██╗ ██████╗ ██╗███╗   ██╗"
echo -e "██╔════╝██║██╔══██╗██║██╔═══██╗██║████╗  ██║"
echo -e "█████╗  ██║██████╔╝██║██║   ██║██║██╔██╗ ██║"
echo -e "██╔══╝  ██║██╔═══╝ ██║██║   ██║██║██║╚██╗██║"
echo -e "██║     ██║██║     ██║╚██████╔╝██║██║ ╚████║"
echo -e "╚═╝     ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝"
echo -e "               ziqing"
echo -e "=================================================\033[0m"

# 系统更新及 RAM 缓存清理函数
function system_update_and_clean() {
    echo -e "\033[1;33m正在更新系统并清理 RAM 缓存...\033[0m"
    sudo apt update -y && sudo apt upgrade -y
    sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"
    echo -e "\033[1;32mRAM 缓存已清理。\033[0m"
}

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo -e "\033[1;34m================================================================"
        echo -e "                           MAIN MENU"
        echo -e "================================================================\033[0m"
        echo -e "\033[1;36m1) 启动节点\033[0m"
        echo -e "\033[1;36m2) 查看日志\033[0m"
        echo -e "\033[1;36m3) 删除节点\033[0m"
        echo -e "\033[1;36m4) 清理 RAM 缓存\033[0m"
        echo -e "\033[1;36m5) 退出\033[0m"
        echo -e "\033[1;34m================================================================\033[0m"
        
        read -p "请输入选择的数字: " choice
        
        case $choice in
            1) start_node ;;
            2) view_logs ;;
            3) delete_node ;;
            4) clean_ram_cache ;;
            5) echo -e "\033[1;32m退出脚本。\033[0m"; exit 0 ;;
            *) echo -e "\033[1;31m无效选择，请重试。\033[0m"; read -p "按任意键继续..." ;;
        esac
    done
}

# 启动节点的函数
function start_node() {
    system_update_and_clean

    # 检查 Docker 是否已安装
    if ! command -v docker &> /dev/null; then
        echo -e "\033[1;33mDocker 未安装，正在安装 Docker...\033[0m"
        sudo apt-get install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        sudo apt update -y && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        echo -e "\033[1;32mDocker 安装完成！\033[0m"
    else
        echo -e "\033[1;32mDocker 已安装，跳过安装。\033[0m"
    fi

    mkdir -p ~/sixgpt
    cd ~/sixgpt

    read -p "请输入你的 VANA 私钥: " vana_private_key
    export VANA_PRIVATE_KEY=$vana_private_key
    export VANA_NETWORK="moksha"  # 默认设置网络为 moksha

    # 生成最新的 docker-compose.yml 文件
    cat <<EOL >docker-compose.yml
version: '3.8'

services:
  ollama:
    image: ollama/ollama:0.3.12
    ports:
      - "11439:11434"
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
      - OLLAMA_API_URL=http://ollama:11434/api
    restart: no

volumes:
  ollama:
EOL

    echo -e "\033[1;33m正在启动 SixGPT 矿工...\033[0m"
    docker compose up -d
    echo -e "\033[1;32mSixGPT 矿工已启动！\033[0m"
    read -p "按任意键返回主菜单..."
}

# 查看日志的函数
function view_logs() {
    echo -e "\033[1;33m正在查看 Docker Compose 日志...\033[0m"
    docker compose logs -fn 100
    read -p "按任意键返回主菜单..."
}

# 删除节点的函数
function delete_node() {
    echo -e "\033[1;33m正在停止并删除所有 Docker Compose 服务...\033[0m"
    docker compose down
    echo -e "\033[1;32m所有 Docker Compose 服务已停止并删除。\033[0m"
    read -p "按任意键返回主菜单..."
}

# 清理 RAM 缓存的函数
function clean_ram_cache() {
    echo -e "\033[1;33m正在清理 RAM 缓存...\033[0m"
    sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"
    echo -e "\033[1;32mRAM 缓存已清理。\033[0m"
    read -p "按任意键返回主菜单..."
}

# 调用主菜单函数
main_menu
