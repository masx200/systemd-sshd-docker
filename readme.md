# systemd-sshd Docker 项目

## 项目简介

本项目是为了解决在 **Docker Desktop for Windows** 上使用 **DPanel** 进行远程
Docker 管理的需求而创建的。由于 DPanel 通过 SSH 连接远程 Docker 宿主机时需要访问
`/var/run/docker.sock`，而 Windows 环境的特殊性，我们构建了一个基于 Debian 的
systemd 容器环境，完美支持 DPanel 的远程管理功能。

## 项目结构

```
systemd-sshd/
├── build.sh              # 构建镜像脚本
├── compose.yml           # Docker Compose 配置文件
├── debian.sources        # Debian 软件源配置
├── dockerfile            # Docker 镜像构建文件
├── down.sh              # 停止并移除容器脚本
├── password.txt         # 生成的随机密码文件（自动生成）
├── readme.md            # 项目说明文档
├── start.sh             # 启动容器脚本
├── stop.sh              # 停止容器脚本
├── systemd-sshd.*       # 项目压缩包备份
├── etc/                 # 配置文件目录
│   ├── shadow           # 用户密码配置文件
│   └── ssh/            
│       └── sshd_config  # SSH 服务配置文件
├── root/                # root 用户配置
│   └── .ssh/           
│       ├── authorized_keys  # 授权公钥列表
│       ├── id_ed25519       # ED25519 私钥
│       ├── id_ed25519.pub   # ED25519 公钥
│       ├── id_rsa           # RSA 私钥
│       ├── id_rsa.pub       # RSA 公钥
│       └── known_hosts      # 已知主机列表
├── sources.list         # 软件源列表
└── usr/lib/systemd/system/  # systemd 服务配置
    └── ssh.service      # SSH 服务 systemd 配置
```

## 核心功能

1. **systemd 支持**：容器内完整运行 systemd，支持服务管理
2. **SSH 服务**：预装并配置 OpenSSH 服务，支持远程连接
3. **Docker Socket 访问**：通过卷挂载支持访问 `/var/run/docker.sock`
4. **DPanel 兼容**：专门针对 DPanel 远程管理需求优化
5. **中文环境**：默认配置中文语言和时区

## 快速开始

### 1. 构建镜像

```bash
./build.sh
```

### 2. 启动容器

```bash
./start.sh
```

### 3. 停止容器

```bash
./stop.sh
```

### 4. 完全移除

```bash
./down.sh
```

## 配置说明

### Docker Compose 配置（compose.yml）

- **端口映射**：宿主机 22222 端口映射到容器 22 端口
- **网络配置**：使用 1panel-network 网络，支持 IPv4/IPv6
- **卷挂载**：
  - Docker socket：支持容器内 Docker 管理
  - SSH 配置：持久化 SSH 设置
  - 系统配置：时区、软件源等

修改配置文件 "compose.yml",

把"F:/systemd-sshd"替换为你的项目"systemd-sshd-docker"所在的绝对路径。

### Docker 镜像配置（dockerfile）

- **基础镜像**：Debian Trixie（最新测试版）
- **软件包**：systemd、openssh-server、sudo 等核心组件
- **优化**：清华源加速、清理缓存减小镜像体积

## 安全配置

### 生成随机密码

首次启动时会自动生成随机密码，保存在 `password.txt` 文件中：

```bash
cat password.txt
```

如需重新生成密码：

**Windows (PowerShell)**：

```powershell
# 生成16位随机密码
-join ((33..126) | Get-Random -Count 16 | ForEach-Object {[char]$_}) | Out-File -FilePath password.txt
```

**Linux/macOS**：

```bash
# 生成16位随机密码
tr -dc 'A-Za-z0-9_!@#$%^&*' < /dev/urandom | head -c 16 > password.txt
```

### 生成 SSH 密钥对

#### ED25519 密钥（推荐）

**Windows (PowerShell)**：

```powershell
# 生成ED25519密钥
ssh-keygen -t ed25519 -f root/.ssh/id_ed25519 -N ""

# 查看公钥
cat root/.ssh/id_ed25519.pub
```

**Linux/macOS**：

```bash
# 生成ED25519密钥
ssh-keygen -t ed25519 -f root/.ssh/id_ed25519 -N ""

# 查看公钥
cat root/.ssh/id_ed25519.pub
```

#### RSA 密钥

**Windows (PowerShell)**：

```powershell
# 生成RSA 4096位密钥
ssh-keygen -t rsa -b 4096 -f root/.ssh/id_rsa -N ""

# 查看公钥
cat root/.ssh/id_rsa.pub
```

**Linux/macOS**：

```bash
# 生成RSA 4096位密钥
ssh-keygen -t rsa -b 4096 -f root/.ssh/id_rsa -N ""

# 查看公钥
cat root/.ssh/id_rsa.pub
```

### 配置 SSH 免密登录

1. 将客户端的公钥添加到容器的 `root/.ssh/authorized_keys` 文件中
2. 确保文件权限正确：
   ```bash
   chmod 600 root/.ssh/authorized_keys
   chmod 700 root/.ssh
   ```

## DPanel 配置指南

### 添加远程环境

1. 在 DPanel 中进入【系统】-【多服务端】-【添加服务端】
2. 选择【通过 SSH 添加】
3. 填写连接信息：
   - **主机地址**：localhost（或容器宿主机IP）
   - **端口**：22222
   - **用户名**：root
   - **密码**：查看 password.txt 文件
   - **认证方式**：密码或密钥认证

### 注意事项

1. **版本兼容性**：确保 Docker Desktop 与 DPanel 的 Docker SDK 版本兼容
2. **权限配置**：非 root 用户需要添加到 docker 组
3. **网络配置**：确保 1panel-network 网络已创建

## 故障排查

### 常见问题

1. **连接失败**：检查端口映射和防火墙设置
2. **权限问题**：确认容器以特权模式运行
3. **服务未启动**：检查 systemd 服务状态

### 调试命令

```bash
# 查看容器日志
docker logs systemd-sshd

# 进入容器调试
docker exec -it systemd-sshd bash

# 检查 SSH 服务状态
systemctl status ssh

# 检查 Docker socket 权限
ls -la /var/run/docker.sock
```

## 项目维护

### 更新镜像

```bash
# 停止并删除旧容器
./down.sh

# 重新构建
./build.sh

# 启动新容器
./start.sh
```

### 备份配置

```bash
# 备份 SSH 密钥和配置
cp -r root/.ssh backup-$(date +%Y%m%d)
cp etc/ssh/sshd_config backup-$(date +%Y%m%d)/
```

## 许可证

本项目采用 MIT 许可证，详见项目根目录 LICENSE 文件。

## 技术支持

如有问题，请通过以下方式获取支持：

- 查看容器日志：`docker logs systemd-sshd`
- 检查 DPanel 官方文档：[DPanel 文档](https://dpanel.cc/)
- 提交 Issue 到项目仓库

---

_本项目专为 DPanel + Docker Desktop for Windows 场景优化，提供完整的 systemd +
SSH 环境，简化远程 Docker 管理配置。_

### 修改默认用户的密码

修改默认用户的密码的哈希值,然后写入到`/etc/shadow` 文件中

```bash
openssl passwd -6 "你的密码"
```

输出示例：`$6$随机盐值$加密后的哈希值`，其中 `$6$` 表示 SHA-512 算法 。

```text
root:$6$随机盐值$加密后的哈希值:1970:0:99999:7:::
```

## dpanel文档

https://dpanel.cc/manual/system-env