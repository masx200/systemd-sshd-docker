# Windows PowerShell 脚本：生成随机密码
# 使用方法：右键 -> 使用 PowerShell 运行

function Generate-RandomPassword {
    param(
        [int]$Length = 16,
        [switch]$IncludeSpecial
    )
    
    if ($IncludeSpecial) {
        # 包含特殊字符的密码
        $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+-=[]{}|;:,.<>?"
    } else {
        # 仅字母数字的密码
        $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    }
    
    $password = -join (1..$Length | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    return $password
}

# 生成密码
$randomPassword = Generate-RandomPassword -Length 16 -IncludeSpecial

# 保存到文件
$passwordFile = Join-Path $PSScriptRoot "password.txt"
$randomPassword | Out-File -FilePath $passwordFile -Encoding UTF8

# 显示密码
Write-Host "随机密码已生成并保存到: $passwordFile" -ForegroundColor Green
Write-Host "生成的密码: $randomPassword" -ForegroundColor Yellow
Write-Host ""
Write-Host "你可以使用以下命令查看密码:" -ForegroundColor Cyan
Write-Host "Get-Content '$passwordFile'" -ForegroundColor White

# 可选：复制到剪贴板
$copyToClipboard = Read-Host "是否将密码复制到剪贴板? (y/n)"
if ($copyToClipboard -eq "y" -or $copyToClipboard -eq "Y") {
    $randomPassword | Set-Clipboard
    Write-Host "密码已复制到剪贴板" -ForegroundColor Green
}

Pause