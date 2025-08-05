#!/bin/bash
# Linux/macOS 脚本：生成 SSH 密钥对
# 使用方法：chmod +x generate-ssh-keys.sh && ./generate-ssh-keys.sh

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_KEY_TYPE="ed25519"
DEFAULT_RSA_BITS=4096
SSH_DIR="$(dirname "$0")/root/.ssh"

# 显示帮助信息
show_help() {
    echo -e "${GREEN}SSH 密钥生成脚本${NC}"
    echo -e "${YELLOW}使用方法: $0 [选项]${NC}"
    echo ""
    echo "选项:"
    echo "  -t, --type      密钥类型: ed25519 (默认) 或 rsa"
    echo "  -e, --email     邮箱地址 (可选)"
    echo "  -n, --name      密钥文件名 (可选)"
    echo "  -f, --force     覆盖现有密钥"
    echo "  -h, --help      显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -t ed25519"
    echo "  $0 -t rsa -e user@example.com -n mykey"
}

# 检查是否安装了 OpenSSH
if ! command -v ssh-keygen &> /dev/null; then
    echo -e "${RED}错误: 未检测到 OpenSSH。请先安装 OpenSSH 客户端。${NC}"
    echo -e "${YELLOW}Ubuntu/Debian: sudo apt-get install openssh-client${NC}"
    echo -e "${YELLOW}CentOS/RHEL: sudo yum install openssh-clients${NC}"
    echo -e "${YELLOW}macOS: 系统已预装 OpenSSH${NC}"
    exit 1
fi

# 解析参数
KEY_TYPE="$DEFAULT_KEY_TYPE"
EMAIL=""
KEY_NAME=""
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            KEY_TYPE="$2"
            shift 2
            ;;
        -e|--email)
            EMAIL="$2"
            shift 2
            ;;
        -n|--name)
            KEY_NAME="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}未知选项: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 验证密钥类型
if [[ "$KEY_TYPE" != "ed25519" && "$KEY_TYPE" != "rsa" ]]; then
    echo -e "${RED}错误: 不支持的密钥类型: $KEY_TYPE${NC}"
    echo -e "${YELLOW}支持的类型: ed25519, rsa${NC}"
    exit 1
fi

# 创建 SSH 目录
mkdir -p "$SSH_DIR"

# 设置密钥文件名
if [[ -z "$KEY_NAME" ]]; then
    if [[ "$KEY_TYPE" == "ed25519" ]]; then
        PRIVATE_KEY="id_ed25519"
        PUBLIC_KEY="id_ed25519.pub"
    else
        PRIVATE_KEY="id_rsa"
        PUBLIC_KEY="id_rsa.pub"
    fi
else
    PRIVATE_KEY="$KEY_NAME"
    PUBLIC_KEY="$KEY_NAME.pub"
fi

PRIVATE_KEY_PATH="$SSH_DIR/$PRIVATE_KEY"
PUBLIC_KEY_PATH="$SSH_DIR/$PUBLIC_KEY"

# 检查文件是否存在
if { [[ -f "$PRIVATE_KEY_PATH" ]] || [[ -f "$PUBLIC_KEY_PATH" ]]; } && [[ "$FORCE" == false ]]; then
    echo -e "${YELLOW}警告: 密钥文件已存在!${NC}"
    echo -e "${CYAN}私钥: $PRIVATE_KEY_PATH${NC}"
    echo -e "${CYAN}公钥: $PUBLIC_KEY_PATH${NC}"
    
    read -p "是否覆盖现有密钥? (y/N): " choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        echo -e "${YELLOW}操作已取消${NC}"
        exit 0
    fi
fi

# 生成密钥
echo -e "${GREEN}正在生成 $KEY_TYPE 密钥对...${NC}"

COMMENT=""
if [[ -n "$EMAIL" ]]; then
    COMMENT="-C \"$EMAIL\""
fi

if [[ "$KEY_TYPE" == "ed25519" ]]; then
    ssh-keygen -t ed25519 -f "$PRIVATE_KEY_PATH" -N "" $COMMENT
else
    ssh-keygen -t rsa -b $DEFAULT_RSA_BITS -f "$PRIVATE_KEY_PATH" -N "" $COMMENT
fi

# 检查是否成功生成
if [[ -f "$PRIVATE_KEY_PATH" && -f "$PUBLIC_KEY_PATH" ]]; then
    echo -e "${GREEN}密钥对生成成功!${NC}"
    echo ""
    echo -e "${CYAN}私钥: $PRIVATE_KEY_PATH${NC}"
    echo -e "${CYAN}公钥: $PUBLIC_KEY_PATH${NC}"
    echo ""
    
    # 设置正确的权限
    chmod 600 "$PRIVATE_KEY_PATH"
    chmod 644 "$PUBLIC_KEY_PATH"
    chmod 700 "$SSH_DIR"
    
    # 显示公钥内容
    echo -e "${YELLOW}公钥内容:${NC}"
    echo "----------------------------------------"
    cat "$PUBLIC_KEY_PATH"
    echo "----------------------------------------"
    echo ""
    
    # 可选：复制到剪贴板
    if command -v pbcopy &> /dev/null; then
        # macOS
        cat "$PUBLIC_KEY_PATH" | pbcopy
        echo -e "${GREEN}公钥已复制到剪贴板 (macOS)${NC}"
    elif command -v xclip &> /dev/null; then
        # Linux with xclip
        cat "$PUBLIC_KEY_PATH" | xclip -selection clipboard
        echo -e "${GREEN}公钥已复制到剪贴板 (Linux xclip)${NC}"
    elif command -v xsel &> /dev/null; then
        # Linux with xsel
        cat "$PUBLIC_KEY_PATH" | xsel --clipboard --input
        echo -e "${GREEN}公钥已复制到剪贴板 (Linux xsel)${NC}"
    else
        echo -e "${YELLOW}未检测到剪贴板工具，公钥未复制${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}提示: 公钥已准备好添加到 authorized_keys 文件${NC}"
    echo -e "${YELLOW}你可以复制上面的公钥内容到 authorized_keys 文件中${NC}"
else
    echo -e "${RED}密钥生成失败，请检查错误信息${NC}"
    exit 1
fi