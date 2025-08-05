#!/bin/bash
# 构建并启动 systemd-sshd 容器
# 包含密码生成和SSH密钥检查

set -e

echo "=== systemd-sshd 构建脚本 ==="

# 检查并生成随机密码
PASSWORD_FILE="password.txt"
if [[ ! -f "$PASSWORD_FILE" ]]; then
    echo "生成随机密码..."
    if command -v openssl &> /dev/null; then
        openssl rand -base64 12 | tr -d "=+/" | cut -c1-16 > "$PASSWORD_FILE"
    else
        tr -dc 'A-Za-z0-9_!@#$%^&*' < /dev/urandom | head -c 16 > "$PASSWORD_FILE"
    fi
    echo "密码已生成并保存到: $PASSWORD_FILE"
else
    echo "密码文件已存在，跳过生成"
fi

# 检查并生成SSH密钥
echo "检查SSH密钥..."
SSH_DIR="root/.ssh"
mkdir -p "$SSH_DIR"

# 检查ED25519密钥
if [[ ! -f "$SSH_DIR/id_ed25519" ]]; then
    echo "生成ED25519 SSH密钥..."
    ssh-keygen -t ed25519 -f "$SSH_DIR/id_ed25519" -N ""
    chmod 600 "$SSH_DIR/id_ed25519"
    chmod 644 "$SSH_DIR/id_ed25519.pub"
    echo "ED25519密钥已生成"
else
    echo "ED25519密钥已存在，跳过生成"
fi

# 检查RSA密钥
if [[ ! -f "$SSH_DIR/id_rsa" ]]; then
    echo "生成RSA SSH密钥..."
    ssh-keygen -t rsa -b 4096 -f "$SSH_DIR/id_rsa" -N ""
    chmod 600 "$SSH_DIR/id_rsa"
    chmod 644 "$SSH_DIR/id_rsa.pub"
    echo "RSA密钥已生成"
else
    echo "RSA密钥已存在，跳过生成"
fi

# 确保authorized_keys存在并包含公钥
if [[ ! -f "$SSH_DIR/authorized_keys" ]]; then
    echo "创建authorized_keys文件..."
    touch "$SSH_DIR/authorized_keys"
    chmod 600 "$SSH_DIR/authorized_keys"
fi

# 将公钥添加到authorized_keys（如果尚未添加）
if [[ -f "$SSH_DIR/id_ed25519.pub" ]]; then
    PUB_KEY=$(cat "$SSH_DIR/id_ed25519.pub")
    if ! grep -q "$PUB_KEY" "$SSH_DIR/authorized_keys"; then
        echo "$PUB_KEY" >> "$SSH_DIR/authorized_keys"
        echo "ED25519公钥已添加到authorized_keys"
    fi
fi

if [[ -f "$SSH_DIR/id_rsa.pub" ]]; then
    PUB_KEY=$(cat "$SSH_DIR/id_rsa.pub")
    if ! grep -q "$PUB_KEY" "$SSH_DIR/authorized_keys"; then
        echo "$PUB_KEY" >> "$SSH_DIR/authorized_keys"
        echo "RSA公钥已添加到authorized_keys"
    fi
fi

# 设置目录权限
chmod 700 "$SSH_DIR"

echo "构建并启动容器..."
docker-compose up --build -d

echo ""
echo "=== 构建完成 ==="
echo "容器已启动，端口映射: 22222:22"
echo "SSH密码: $(cat $PASSWORD_FILE)"
echo ""
echo "使用以下命令连接:"
echo "ssh root@localhost -p 22222"