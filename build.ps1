# Windows PowerShell 构建脚本
# 构建并启动 systemd-sshd 容器
# 包含密码生成和SSH密钥检查

Write-Host "=== systemd-sshd 构建脚本 ===" -ForegroundColor Green

# 检查并生成随机密码
$passwordFile = "password.txt"
if (-not (Test-Path $passwordFile)) {
    Write-Host "生成随机密码..." -ForegroundColor Yellow
    
    # 生成16位随机密码
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
    $password = -join (1..16 | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    $password | Out-File -FilePath $passwordFile -Encoding UTF8
    
    Write-Host "密码已生成并保存到: $passwordFile" -ForegroundColor Green
} else {
    Write-Host "密码文件已存在，跳过生成" -ForegroundColor Yellow
}

# 检查并生成SSH密钥
Write-Host "检查SSH密钥..." -ForegroundColor Yellow
$sshDir = "root\.ssh"
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}

# 检查ED25519密钥
$ed25519Private = "$sshDir\id_ed25519"
$ed25519Public = "$sshDir\id_ed25519.pub"

if (-not (Test-Path $ed25519Private)) {
    Write-Host "生成ED25519 SSH密钥..." -ForegroundColor Yellow
    
    # 检查是否安装了 OpenSSH
    if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
        Write-Host "错误: 未检测到 OpenSSH。请先安装 OpenSSH 客户端。" -ForegroundColor Red
        Write-Host "Windows 10/11 用户: 设置 -> 应用 -> 可选功能 -> 添加 OpenSSH 客户端" -ForegroundColor Yellow
        exit 1
    }
    
    ssh-keygen -t ed25519 -f $ed25519Private -N ""
    Write-Host "ED25519密钥已生成" -ForegroundColor Green
} else {
    Write-Host "ED25519密钥已存在，跳过生成" -ForegroundColor Yellow
}

# 检查RSA密钥
$rsaPrivate = "$sshDir\id_rsa"
$rsaPublic = "$sshDir\id_rsa.pub"

if (-not (Test-Path $rsaPrivate)) {
    Write-Host "生成RSA SSH密钥..." -ForegroundColor Yellow
    ssh-keygen -t rsa -b 4096 -f $rsaPrivate -N ""
    Write-Host "RSA密钥已生成" -ForegroundColor Green
} else {
    Write-Host "RSA密钥已存在，跳过生成" -ForegroundColor Yellow
}

# 确保authorized_keys存在并包含公钥
$authorizedKeys = "$sshDir\authorized_keys"
if (-not (Test-Path $authorizedKeys)) {
    Write-Host "创建authorized_keys文件..." -ForegroundColor Yellow
    New-Item -ItemType File -Path $authorizedKeys -Force | Out-Null
}

# 将公钥添加到authorized_keys
function Add-KeyToAuthorized {
    param($publicKeyPath, $keyType)
    if (Test-Path $publicKeyPath) {
        $pubKeyContent = Get-Content $publicKeyPath
        $authKeysContent = Get-Content $authorizedKeys -ErrorAction SilentlyContinue
        
        if ($authKeysContent -notcontains $pubKeyContent) {
            Add-Content -Path $authorizedKeys -Value $pubKeyContent
            Write-Host "$keyType 公钥已添加到authorized_keys" -ForegroundColor Green
        }
    }
}

Add-KeyToAuthorized -publicKeyPath $ed25519Public -keyType "ED25519"
Add-KeyToAuthorized -publicKeyPath $rsaPublic -keyType "RSA"

# 设置权限（Windows不需要，但保留提示）
Write-Host "SSH密钥配置完成" -ForegroundColor Green

# 构建并启动容器
Write-Host "构建并启动容器..." -ForegroundColor Yellow
docker-compose up --build -d

Write-Host ""
Write-Host "=== 构建完成 ===" -ForegroundColor Green
Write-Host "容器已启动，端口映射: 22222:22" -ForegroundColor Cyan
Write-Host "SSH密码: $(Get-Content $passwordFile)" -ForegroundColor Yellow
Write-Host ""
Write-Host "使用以下命令连接:" -ForegroundColor Cyan
Write-Host "ssh root@localhost -p 22222" -ForegroundColor White

# 可选：显示公钥内容
Write-Host ""
$showKeys = Read-Host "是否显示公钥内容? (y/n)"
if ($showKeys -eq "y" -or $showKeys -eq "Y") {
    Write-Host ""
    Write-Host "ED25519公钥:" -ForegroundColor Green
    if (Test-Path $ed25519Public) {
        Get-Content $ed25519Public
    }
    Write-Host ""
    Write-Host "RSA公钥:" -ForegroundColor Green
    if (Test-Path $rsaPublic) {
        Get-Content $rsaPublic
    }
}

Pause