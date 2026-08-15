$ErrorActionPreference = 'Stop'

$Version = '2.0.9.5'
$AssetUrl = 'https://github.com/lijiaolu130-tech/hsjm-geo-connector-installer/releases/download/hsjm-installer-v2.0.9.5-fix1/hsjm-geo-connector-v2.0.9.5-secure.5.zip'
$AssetApiUrl = 'https://api.github.com/repos/lijiaolu130-tech/hsjm-geo-connector-installer/releases/assets/515312955'
$ExpectedSha256 = '776e8cfa71276895a1e73496cbe91bffd3fa9f81afb11ea08aee686720ac0dd6'
$DownloadDir = Join-Path $env:USERPROFILE 'Downloads'
$LegacyZipPath = Join-Path $DownloadDir "hsjm-geo-connector-v$Version.zip"
$VersionedZipPath = Join-Path $DownloadDir "hsjm-geo-connector-v$Version-$($ExpectedSha256.Substring(0, 8)).zip"
$TargetDir = Join-Path $env:LOCALAPPDATA "HSJM-GEO-Connector\v$Version-$($ExpectedSha256.Substring(0, 8))"
$ProfileDir = Join-Path $env:LOCALAPPDATA 'HSJM-GEO-Connector\browser-profile'
$PortalUrl = 'https://huasheng-jinma-geo-portal.lijiaolu130.chatgpt.site/'
$Headers = @{ Accept = 'application/octet-stream'; 'X-GitHub-Api-Version' = '2022-11-28' }

Write-Host "华昇金玛 GEO 连接器安装助手 $Version"
Write-Host '只下载并校验扩展包，不读取账号、Cookie、验证码或密钥。'
New-Item -ItemType Directory -Force -Path $DownloadDir, $TargetDir | Out-Null

Write-Host '[1/4] 下载公开安装包…'
$ZipPath = $null
foreach ($Candidate in @($LegacyZipPath, $VersionedZipPath)) {
  if (Test-Path -LiteralPath $Candidate) {
    $CandidateSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $Candidate).Hash.ToLowerInvariant()
    if ($CandidateSha256 -eq $ExpectedSha256) {
      $ZipPath = $Candidate
      Write-Host "发现已校验安装包，跳过网络下载：$ZipPath"
      break
    }
  }
}

if (-not $ZipPath) {
  $RunId = Get-Date -Format 'yyyyMMdd-HHmmss'
  $ZipPath = Join-Path $DownloadDir "hsjm-geo-connector-v$Version-$($ExpectedSha256.Substring(0, 8))-$RunId.zip"
  try {
    Invoke-WebRequest -UseBasicParsing -Uri $AssetApiUrl -Headers $Headers -OutFile "$ZipPath.part" -MaximumRedirection 10 -TimeoutSec 180
    Write-Host '已通过 GitHub API 安装包入口下载。'
  } catch {
    Write-Host 'API 入口失败，切换公开 Release 直链重试…'
    Invoke-WebRequest -UseBasicParsing -Uri $AssetUrl -OutFile "$ZipPath.part" -MaximumRedirection 10 -TimeoutSec 180
  }
  Move-Item "$ZipPath.part" $ZipPath
}

Write-Host '[2/4] 校验安装包…'
$ActualSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $ZipPath).Hash.ToLowerInvariant()
if ($ActualSha256 -ne $ExpectedSha256) {
  throw "SHA-256 校验失败。期望 $ExpectedSha256，实际 $ActualSha256"
}

Write-Host '[3/4] 解压到版本化目录…'
Expand-Archive -LiteralPath $ZipPath -DestinationPath $TargetDir -Force
if (-not (Test-Path (Join-Path $TargetDir 'manifest.json'))) {
  throw '解压后没有找到 manifest.json，请不要选择 ZIP、assets 或 src 文件夹。'
}

Write-Host '[4/4] 启动 GEO 专用 Chrome 并自动载入连接器…'
$Chrome = Get-Command chrome.exe -ErrorAction SilentlyContinue
if ($Chrome) {
  New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null
  Start-Process -FilePath $Chrome.Source -ArgumentList @(
    "--user-data-dir=$ProfileDir",
    "--load-extension=$TargetDir",
    '--no-first-run',
    '--no-default-browser-check',
    '--new-window',
    $PortalUrl
  )
  Write-Host 'GEO 专用 Chrome 已启动，连接器已通过 --load-extension 自动载入。'
  Write-Host "专用浏览器配置目录：$ProfileDir"
} else {
  Start-Process 'https://support.google.com/chrome/answer/95346'
  Write-Host '未找到 chrome.exe，已打开 Chrome 安装帮助页。'
}

Write-Host ''
Write-Host '已完成下载、校验、解压和自动载入。不会读取账号、Cookie、验证码或密钥。'
Write-Host '首次使用请在 GEO 专用 Chrome 中完成门户所有者登录；平台验证码、实名和风控按平台要求人工完成。'
