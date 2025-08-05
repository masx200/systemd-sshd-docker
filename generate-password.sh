#!/bin/bash
# Linux/macOS 脚本：生成随机密码
# 使用方法：chmod +x generate-password.sh && ./generate-password.sh

# 设置默认密码长度
DEFAULT_LENGTH=16

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 生成随机密码函数
generate_password() {
    local length=$1
    local use_special=${2:-true}
    
    if [[ "$use_special" == "true" ]]; then
        # 包含特殊字符
        tr -dc 'A-Za-z0-9!@#$%^&*()_+-=[]{}|;:,.<>?' < /dev/urandom | head -c "$length"
    else
        # 仅字母数字
        tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
    fi
}

# 询问密码长度
echo -e "${CYAN}请输入密码长度 (默认: $DEFAULT_LENGTH):${NC}"
read -r length_input
if [[ -z "$length_input" ]]; then
    length=$DEFAULT_LENGTH
else
    length=$length_input
fi

# 询问是否包含特殊字符
echo -e "${CYAN}是否包含特殊字符? (y/n, 默认: y):${NC}"
read -r special_input
if [[ "$special_input" == "n" || "$special_input" == "N" ]]; then
    use_special=false
else
    use_special=true
fi

# 生成密码
password=$(generate_password "$length" "$use_special")

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASSWORD_FILE="$SCRIPT_DIR/password.txt"

# 保存密码到文件
echo "$password" > "$PASSWORD_FILE"

# 显示结果
echo -e "${GREEN}随机密码已生成并保存到: $PASSWORD_FILE${NC}"
echo -e "${YELLOW}生成的密码: $password${NC}"
echo ""
echo -e "${CYAN}你可以使用以下命令查看密码:${NC}"
echo "cat $PASSWORD_FILE"

# 可选：复制到剪贴板（如果可用）
if command -v pbcopy &> /dev/null; then
    # macOS
    echo "$password" | pbcopy
    echo -e "${GREEN}密码已复制到剪贴板 (macOS)${NC}"
elif command -v xclip &> /dev/null; then
    # Linux with xclip
    echo "$password" | xclip -selection clipboard
    echo -e "${GREEN}密码已复制到剪贴板 (Linux)${NC}"
elif command -v xsel &> /dev/null; then
    # Linux with xsel
    echo "$password" | xsel --clipboard --input
    echo -e "${GREEN}密码已复制到剪贴板 (Linux)${NC}"
else
    echo -e "${YELLOW}未检测到剪贴板工具，密码未复制${NC}"
fi

echo ""
echo -e "${CYAN}按任意键继续...${NC}"
read -n 1 -s