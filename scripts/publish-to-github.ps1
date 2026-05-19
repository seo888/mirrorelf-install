# 在已执行 gh auth login 后，创建并推送 seo888/mirrorelf-install
# 用法：powershell -File scripts/publish-to-github.ps1

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent

Set-Location $Root

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Error '未找到 gh，请先安装 GitHub CLI 并执行: gh auth login'
}

$status = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
  Write-Error "未登录 GitHub。请运行: gh auth login`n$status"
}

if (-not (Test-Path .git)) {
  git init -b main
  git add .
  git commit -m "Initial commit: MirrorElf Docker one-line install"
}

$exists = $false
try {
  gh repo view seo888/mirrorelf-install 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { $exists = $true }
} catch {
  $exists = $false
}
if (-not $exists) {
  gh repo create mirrorelf-install --public --description "MirrorElf Docker one-line install (compose + install.sh)" --source . --remote origin --push
  Write-Host "已创建并推送: https://github.com/seo888/mirrorelf-install"
} else {
  if (-not (git remote get-url origin 2>$null)) {
    git remote add origin https://github.com/seo888/mirrorelf-install.git
  }
  git push -u origin main
  if ($LASTEXITCODE -ne 0 -and (Test-Path env:HTTPS_PROXY)) {
    Write-Warning '直连 push 失败，可设置 HTTPS_PROXY 后重试'
  }
  Write-Host "已推送到: https://github.com/seo888/mirrorelf-install"
}
