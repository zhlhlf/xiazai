install_if_missing() {
    local cmds=("$@")  # 将所有参数存储到数组中
    local missing_cmds=()  # 存储未安装的命令
    
    # 首先检查哪些命令缺失
    for cmd in "${cmds[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_cmds+=("$cmd")
            echo "命令 '$cmd' 未找到，将尝试安装"
        fi
    done
    
    # 如果有缺失的命令，尝试安装
    if [ ${#missing_cmds[@]} -gt 0 ]; then
        echo "正在尝试安装缺失的命令..."
        if sudo apt update &> /dev/null; then
            for cmd in "${missing_cmds[@]}"; do
                if sudo apt install -y "$cmd" &> /dev/null; then
                    echo "命令 '$cmd' 安装成功"
                else
                    echo "错误：无法安装命令 '$cmd'"
                    return 1
                fi
            done
        else
            echo "错误：无法更新软件包列表"
            return 1
        fi
    else
        echo "所有命令均已安装，无需操作"
        return 0
    fi
}