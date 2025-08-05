# Windows PowerShell 脚本：生成 SSH 密钥对
# 使用方法：右键 -> 使用 PowerShell 运行

param(
    [string]$KeyType = "ed25519",
    [string]$Email = "",
    [string]$KeyName = "",
    [switch]$Overwrite
)

function Show-Help {
    Write-Host "SSH 密钥生成脚本" -ForegroundColor Green
    Write-Host "使用方法: .\generate-ssh-keys.ps1 [参数]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "参数说明:"
    Write-Host "  -KeyType    密钥类型: ed25519 (默认) 或 rsa"
    Write-Host "  -Email      邮箱地址 (可选)"
    Write-Host "  -KeyName    密钥文件名 (可选)"
    Write-Host "  -Overwrite  覆盖现有密钥"
    Write-Host ""
    Write-Host "示例:"
    Write-Host "  .\generate-ssh-keys.ps1 -KeyType ed25519"
    Write-Host "  .\generate-ssh-keys.ps1 -KeyType rsa -Email user@example.com -KeyName mykey"
}

# 检查是否安装了 OpenSSH
if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
    Write-Host "错误: 未检测到 OpenSSH。请先安装 OpenSSH 客户端。" -ForegroundColor Red
    Write-Host "Windows 10/11 用户: 设置 -> 应用 -> 可选功能 -> 添加 OpenSSH 客户端" -ForegroundColor Yellow
    exit 1
}

# 设置密钥目录
$sshDir = Join-Path $PSScriptRoot "root\.ssh"
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}

# 设置密钥文件名
if ([string]::IsNullOrEmpty($KeyName)) {
    if ($KeyType -eq "ed25519") {
        $privateKey = "id_ed25519"
        $publicKey = "id_ed25519.pub"
    } else {
        $privateKey = "id_rsa"
        $publicKey = "id_rsa.pub"
    }
} else {
    $privateKey = "$KeyName"
    $publicKey = "$KeyName.pub"
}

$privateKeyPath = Join-Path $sshDir $privateKey
$publicKeyPath = Join-Path $sshDir $publicKey

# 检查文件是否存在
if ((Test-Path $privateKeyPath -or Test-Path $publicKeyPath) -and -not $Overwrite) {
    Write-Host "警告: 密钥文件已存在!" -ForegroundColor Yellow
    Write-Host "私钥: $privateKeyPath" -ForegroundColor Cyan
    Write-Host "公钥: $publicKeyPath" -ForegroundColor Cyan
    
    $choice = Read-Host "是否覆盖现有密钥? (y/N)"
    if ($choice -ne "y" -and $choice -ne "Y") {
        Write-Host "操作已取消" -ForegroundColor Yellow
        exit 0
    }
}

# 生成密钥
Write-Host "正在生成 $KeyType 密钥对..." -ForegroundColor Green

$comment = if ([string]::IsNullOrEmpty($Email)) { "" } else { "-C `"$Email`"" }

if ($KeyType -eq "ed25519") {
    ssh-keygen -t ed25519 -f $privateKeyPath -N "" $comment
} else {
    ssh-keygen -t rsa -b 4096 -f $privateKeyPath -N "" $comment
}

# 检查是否成功生成
if (Test-Path $privateKeyPath -and Test-Path $publicKeyPath) {
    Write-Host "密钥对生成成功!" -ForegroundColor Green
    Write-Host ""
    Write-Host "私钥: $privateKeyPath" -ForegroundColor Cyan
    Write-Host "公钥: $publicKeyPath" -ForegroundColor Cyan
    Write-Host ""
    
    # 显示公钥内容
    Write-Host "公钥内容:" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    $publicKeyContent = Get-Content $publicKeyPath
    Write-Host $publicKeyContent -ForegroundColor White
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    
    # 设置权限（Windows 不需要，但保留提示）
    Write-Host "提示: 公钥已准备好添加到 authorized_keys 文件" -ForegroundColor Green
    Write-Host "你可以复制上面的公钥内容到 authorized_keys 文件中" -ForegroundColor Yellow
    
    # 可选：复制公钥到剪贴板
    $copyToClipboard = Read-Host "是否将公钥复制到剪贴板? (y/n)"
    if ($copyToClipboard -eq "y" -or $copyToClipboard -eq "Y") {
        $publicKeyContent | Set-Clipboard
        Write-Host "公钥已复制到剪贴板" -ForegroundColor Green
    }
} else {
    Write-Host "密钥生成失败，请检查错误信息" -ForegroundColor Red
}

Pause