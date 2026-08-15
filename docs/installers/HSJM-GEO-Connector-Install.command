#!/bin/bash
set -euo pipefail

VERSION="2.0.9.5"
INSTALLER_REVISION="fix3"
PAGES_ASSET_URL="https://lijiaolu130-tech.github.io/hsjm-geo-connector-installer/downloads/hsjm-geo-connector-v2.0.9.5-secure.5.zip"
RAW_ASSET_URL="https://raw.githubusercontent.com/lijiaolu130-tech/hsjm-geo-connector-installer/main/hsjm-geo-connector-v2.0.9.5-secure.5.zip"
RELEASE_ASSET_URL="https://github.com/lijiaolu130-tech/hsjm-geo-connector-installer/releases/download/hsjm-installer-v2.0.9.5-fix3/hsjm-geo-connector-v2.0.9.5-secure.5.zip"
ASSET_API_URL="https://api.github.com/repos/lijiaolu130-tech/hsjm-geo-connector-installer/releases/assets/515428281"
EXPECTED_SHA256="776e8cfa71276895a1e73496cbe91bffd3fa9f81afb11ea08aee686720ac0dd6"
DOWNLOAD_DIR="${HOME}/Downloads"
LEGACY_ZIP_PATH="${DOWNLOAD_DIR}/hsjm-geo-connector-v${VERSION}.zip"
VERSIONED_ZIP_PATH="${DOWNLOAD_DIR}/hsjm-geo-connector-v${VERSION}-${EXPECTED_SHA256:0:8}.zip"
TARGET_DIR="${HOME}/Library/Application Support/HSJM-GEO-Connector/v${VERSION}-${EXPECTED_SHA256:0:8}-${INSTALLER_REVISION}"
PROFILE_DIR="${HOME}/Library/Application Support/HSJM-GEO-Connector/browser-profile-${INSTALLER_REVISION}"
CFT_ROOT="${HOME}/Library/Application Support/HSJM-GEO-Connector/chrome-for-testing"
CFT_META_URL="https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json"
PORTAL_URL="https://huasheng-jinma-geo-portal.lijiaolu130.chatgpt.site/"

echo "华昇金玛 GEO 连接器安装助手 ${VERSION}"
echo "只下载并校验扩展包，不读取账号、Cookie、验证码或密钥。"
mkdir -p "${DOWNLOAD_DIR}" "${TARGET_DIR}"

if ! command -v curl >/dev/null 2>&1; then
  echo "错误：找不到 curl。请使用系统自带 macOS，或从门户手动下载 ZIP。"
  exit 1
fi

echo "[1/4] 下载公开安装包…"
ZIP_PATH=""
for candidate in "${LEGACY_ZIP_PATH}" "${VERSIONED_ZIP_PATH}"; do
  if [[ -f "${candidate}" ]]; then
    candidate_sha256="$(shasum -a 256 "${candidate}" | awk '{print $1}')"
    if [[ "${candidate_sha256}" == "${EXPECTED_SHA256}" ]]; then
      ZIP_PATH="${candidate}"
      echo "发现已校验安装包，跳过网络下载：${ZIP_PATH}"
      break
    fi
  fi
done

if [[ -z "${ZIP_PATH}" ]]; then
  run_id="$(date '+%Y%m%d-%H%M%S')"
  ZIP_PATH="${DOWNLOAD_DIR}/hsjm-geo-connector-v${VERSION}-${EXPECTED_SHA256:0:8}-${run_id}.zip"
  PART_PATH="${ZIP_PATH}.part"
  CURL_ARGS=(--fail --location --http1.1 --retry 4 --retry-delay 2 --connect-timeout 15 --max-time 180 --output "${PART_PATH}")
  downloaded="false"
  for candidate in \
    "${PAGES_ASSET_URL}" \
    "${RAW_ASSET_URL}" \
    "${RELEASE_ASSET_URL}" \
    "${ASSET_API_URL}"; do
    echo "尝试安装包入口：${candidate}"
    if curl "${CURL_ARGS[@]}" -H 'Accept: application/octet-stream' -H 'X-GitHub-Api-Version: 2022-11-28' "${candidate}" && [[ -s "${PART_PATH}" ]]; then
      downloaded="true"
      break
    fi
  done
  if [[ "${downloaded}" != "true" ]]; then
    echo "错误：所有公开安装包入口均下载失败，请检查网络后重试。"
    exit 1
  fi
  mv "${PART_PATH}" "${ZIP_PATH}"
fi

echo "[2/4] 校验安装包…"
ACTUAL_SHA256="$(shasum -a 256 "${ZIP_PATH}" | awk '{print $1}')"
if [[ "${ACTUAL_SHA256}" != "${EXPECTED_SHA256}" ]]; then
  echo "错误：SHA-256 校验失败。"
  echo "期望：${EXPECTED_SHA256}"
  echo "实际：${ACTUAL_SHA256}"
  exit 1
fi

echo "[3/4] 解压到版本化目录…"
unzip -q -n "${ZIP_PATH}" -d "${TARGET_DIR}"
if [[ ! -f "${TARGET_DIR}/manifest.json" ]]; then
  echo "错误：解压后没有找到 manifest.json，请不要选择 ZIP、assets 或 src 文件夹。"
  exit 1
fi

echo "[4/4] 启动 GEO 专用 Chrome 并自动载入连接器…"
BROWSER_APP=""
BROWSER_LABEL=""
find_cft_bin() {
  local root="$1"
  find "${root}" -type f -path '*/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing' -perm -111 -print -quit 2>/dev/null || true
}

for cft_root in "${HOME}/Library/Caches/ms-playwright" "${CFT_ROOT}"; do
  if [[ -d "${cft_root}" ]]; then
    CFT_BIN="$(find_cft_bin "${cft_root}")"
    if [[ -n "${CFT_BIN}" ]]; then
      BROWSER_APP="${CFT_BIN%/Contents/MacOS/Google Chrome for Testing}"
      BROWSER_LABEL="Google Chrome for Testing"
      break
    fi
  fi
done

if [[ -z "${BROWSER_APP}" ]]; then
  echo "未发现 Chrome for Testing，正在下载官方隔离浏览器（只保存到 GEO 专用目录）…"
  mkdir -p "${CFT_ROOT}"
  cft_platform=""
  case "$(uname -m)" in
    arm64) cft_platform="mac-arm64" ;;
    x86_64) cft_platform="mac-x64" ;;
    *) echo "未识别的 Mac 架构，跳过自动浏览器下载。" ;;
  esac
  if [[ -n "${cft_platform}" ]]; then
    cft_run_id="$(date '+%Y%m%d-%H%M%S')"
    cft_meta_path="${CFT_ROOT}/metadata-${cft_run_id}.json"
    if curl --fail --location --http1.1 --retry 4 --retry-delay 2 --connect-timeout 15 --max-time 90 --output "${cft_meta_path}" "${CFT_META_URL}"; then
      CFT_URL="$(grep -Eo 'https://storage.googleapis.com/chrome-for-testing-public/[0-9.]+/'"${cft_platform}"'/chrome-[^\"]+\.zip' "${cft_meta_path}" | head -1 || true)"
      if [[ -n "${CFT_URL}" ]]; then
        cft_version="$(printf '%s' "${CFT_URL}" | awk -F/ '{print $5}')"
        cft_dir="${CFT_ROOT}/${cft_version}-${cft_platform}"
        cft_zip="${CFT_ROOT}/chrome-${cft_version}-${cft_platform}.zip"
        cft_part="${cft_zip}.part"
        if [[ ! -f "${cft_zip}" ]]; then
          curl --fail --location --http1.1 --retry 4 --retry-delay 2 --connect-timeout 15 --max-time 900 --output "${cft_part}" "${CFT_URL}"
          mv "${cft_part}" "${cft_zip}"
        fi
        if unzip -tq "${cft_zip}" >/dev/null 2>&1; then
          mkdir -p "${cft_dir}"
          unzip -q -n "${cft_zip}" -d "${cft_dir}"
          CFT_BIN="$(find_cft_bin "${cft_dir}")"
          if [[ -n "${CFT_BIN}" ]]; then
            BROWSER_APP="${CFT_BIN%/Contents/MacOS/Google Chrome for Testing}"
            BROWSER_LABEL="Google Chrome for Testing"
          fi
        fi
      fi
    fi
  fi
fi
if [[ -z "${BROWSER_APP}" ]]; then
  for candidate in \
    "/Applications/Google Chrome.app" \
    "${HOME}/Applications/Google Chrome.app"; do
    if [[ -x "${candidate}/Contents/MacOS/Google Chrome" ]]; then
      BROWSER_APP="${candidate}"
      BROWSER_LABEL="Google Chrome"
      break
    fi
  done
fi

if [[ "${BROWSER_LABEL}" == "Google Chrome for Testing" ]]; then
  mkdir -p "${PROFILE_DIR}"
  open -n -a "${BROWSER_APP}" --args \
    --user-data-dir="${PROFILE_DIR}" \
    --load-extension="${TARGET_DIR}" \
    --no-first-run \
    --no-default-browser-check \
    --new-window "${PORTAL_URL}" \
    >/dev/null 2>&1
  echo "GEO 专用 Chrome 已启动。"
  echo "连接器已通过 --load-extension 自动载入，不修改现有 Chrome 配置。"
  echo "专用浏览器配置目录：${PROFILE_DIR}"
else
  echo "本机没有可接受命令行扩展载入的 Chrome for Testing，普通 Chrome 保留手动安装入口。"
  open -a "Google Chrome" "chrome://extensions/" >/dev/null 2>&1 || true
  open -R "${TARGET_DIR}/manifest.json" >/dev/null 2>&1 || true
  echo "扩展目录：${TARGET_DIR}"
fi

echo
echo "已完成下载、校验和解压。安装助手不会读取账号、Cookie、验证码或密钥。"
if [[ "${BROWSER_LABEL}" == "Google Chrome for Testing" ]]; then
  echo "首次使用请在 GEO 专用 Chrome 中完成门户所有者登录；平台验证码、实名和风控按平台要求人工完成。"
else
  echo "普通 Chrome 需手动加载上面的扩展目录；首次使用再完成门户所有者登录。"
fi
