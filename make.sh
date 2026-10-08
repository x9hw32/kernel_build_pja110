#!/usr/bin/env bash

set -eo pipefail

TOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${TOP_DIR}"

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${CYAN}[INFO]${NC} $*"; }
log_succ() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_err()  { echo -e "${RED}[ERROR]${NC} $*"; }

# Toolchain configuration
CLANG_DIR="${TOP_DIR}/toolchains/clang-r450784c"
CC="${CLANG_DIR}/bin/clang"
LD="${CLANG_DIR}/bin/ld.lld"
export PATH="${CLANG_DIR}/bin:${PATH}"
OUT_DIR="${TOP_DIR}/out"
COMMON_DIR="${TOP_DIR}/common"
OUT_IMAGES_DIR="${TOP_DIR}/out_images"
STOCK_BOOT="${TOP_DIR}/stock_images/boot.img"
AK3_TEMPLATE="${TOP_DIR}/anykernel3_template"
PACKAGES_DIR="${TOP_DIR}/packages"
APKS_DIR="${PACKAGES_DIR}/apks"
MODULES_DIR="${PACKAGES_DIR}/modules"
ROOTS_DIR="${TOP_DIR}/roots"

mkdir -p "${OUT_IMAGES_DIR}" "${APKS_DIR}" "${MODULES_DIR}" "${ROOTS_DIR}"

JOBS="$(nproc)"
DO_CLEAN=0
ROOT_CHOICE="none"
ENABLE_SUSFS=0
ENABLE_ZERO=0
ENABLE_BBR=1
ENABLE_NTFS=1
ENABLE_BTRFS=1
ENABLE_GUNYAH=0
DO_UPDATE=0
EXPLICIT_BUILD=0
BUILD_MODIFIER_PASSED=0
 
# Root Repositories Catalog
declare -A ROOT_REPOS=(
    ["sukisu"]="https://github.com/SukiSU-Ultra/SukiSU-Ultra.git"
    ["ksun"]="https://github.com/KernelSU-Next/KernelSU-Next.git"
    ["ksu"]="https://github.com/tiann/KernelSU.git"
    ["resuksu"]="https://github.com/cctv18/ReSukiSU.git"
    ["yukisu"]="https://github.com/Rouyashiki/YukiSU.git"
    ["mksu"]="https://github.com/5ec1cff/KernelSU.git"
    ["bakasu"]="https://github.com/Baka-SU/BakaSU.git"
    ["rksu"]="https://github.com/rksuorg/KernelSU.git"
    ["ksulite"]="https://github.com/termux-user-repo/KernelSU-Lite.git"
    ["wildsu"]="https://github.com/WildKernels/Wild_KSU.git"
    ["sakisu"]="https://github.com/XingChenRS/SakiSU.git"
    ["apexsu"]="https://github.com/qrjhamron/ApexSU.git"
)

# Root GitHub Release Repositories (for resolving latest release APK)
declare -A ROOT_RELEASE_REPOS=(
    ["sukisu"]="SukiSU-Ultra/SukiSU-Ultra"
    ["ksun"]="KernelSU-Next/KernelSU-Next"
    ["ksu"]="tiann/KernelSU"
    ["resuksu"]="cctv18/ReSukiSU_CI"
    ["yukisu"]="Rouyashiki/YukiSU"
    ["mksu"]="5ec1cff/KernelSU"
    ["bakasu"]="Baka-SU/BakaSU"
    ["rksu"]="KernelSU-Next/KernelSU-Next"
    ["ksulite"]="tiann/KernelSU"
    ["wildsu"]="WildKernels/Wild_KSU"
    ["sakisu"]="XingChenRS/SakiSU"
    ["apexsu"]="qrjhamron/ApexSU"
)

# Root APKs / Deliverables Catalog (Fallback defaults)
declare -A ROOT_APKS=(
    ["sukisu"]="https://github.com/SukiSU-Ultra/SukiSU-Ultra/releases/download/v4.2.0/SukiSU_v4.2.0_40900-release.apk|SukiSU_v4.2.0.apk"
    ["ksun"]="https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.4.0/KernelSU_Next_v3.4.0_33294-release.apk|KernelSU_Next_v3.4.0.apk"
    ["ksu"]="https://github.com/tiann/KernelSU/releases/download/v3.3.0/KernelSU_v3.3.0_32601-release.apk|KernelSU_v3.3.0.apk"
    ["resuksu"]="https://github.com/cctv18/ReSukiSU_CI/releases/download/ReSukiSU_37180105212/ReSukiSU_v4.2.0-rc3_35203-arm64-v8a-release.apk|ReSukiSU_v4.2.0.apk"
    ["yukisu"]="https://github.com/Rouyashiki/YukiSU/releases/download/v1.7.0/YukiSU_v1.7.0_10397-arm64-v8a-release.apk|YukiSU_v1.7.0.apk"
    ["mksu"]="https://github.com/5ec1cff/KernelSU/releases/download/v9.9.9/KernelSU_v9.9.9_32604-release.apk|More-KernelSU_v9.9.9.apk"
    ["bakasu"]="https://github.com/Baka-SU/BakaSU/releases/download/v4.2.0-rc3/ReSukiSU_v4.2.0-rc3_35171-arm64-v8a-release.apk|BakaSU_v4.2.0.apk"
    ["rksu"]="https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.4.0/KernelSU_Next_v3.4.0_33294-release.apk|KernelSU_Next_v3.4.0.apk"
    ["ksulite"]="https://github.com/tiann/KernelSU/releases/download/v3.3.0/KernelSU_v3.3.0_32601-release.apk|KernelSU_v3.3.0.apk"
    ["wildsu"]="https://github.com/WildKernels/Wild_KSU/releases/download/v3.1.2/Wild_KSU_Spoofed-v3.1.2_33208-release.apk|Wild_KSU_v3.1.2.apk"
    ["sakisu"]="https://github.com/XingChenRS/SakiSU/releases/download/v4.3.0-sakisu.1/SakiSU_v4.3.0-sakisu.1_35039-arm64-v8a-release.apk|SakiSU_v4.3.0.apk"
    ["apexsu"]="https://github.com/qrjhamron/ApexSU/releases/download/v2.0.0-beta.5/ApexSU-v2.0.0-beta.5.apk|ApexSU_v2.0.0-beta.5.apk"
)

show_help() {
    echo -e "${BOLD}Usage:${NC} ./make.sh [OPTIONS]  (or ./make [OPTIONS])

${BOLD}Root Options:${NC}
  --sukisu       Enable SukiSU-Ultra (SukiSU)
  --ksun         Enable KernelSU-Next
  --ksu          Enable Official KernelSU
  --resuksu      Enable ReSukiSU
  --yukisu       Enable YukiSU
  --mksu         Enable More-KernelSU (MKSU)
  --bakasu       Enable BakaSU
  --rksu         Enable Restricted-KernelSU
  --ksulite      Enable KernelSU-Lite
  --wildsu       Enable WildSU (Wild_KSU)
  --sakisu       Enable SakiSU
  --apexsu       Enable ApexSU
  --no-root      Build stock kernel without root (Default when no root specified)

${BOLD}Addon / Feature Flags:${NC}
  --susfs        Enable SusFS v2.3.0 (and output companion module)
  --no-susfs     Disable SusFS
  --zero         Enable ZeroMount native VFS kernel driver & companion module
  --no-zero      Disable ZeroMount
  --gunyah       Enable Gunyah VM support (VirtIO drivers + /dev/udmabuf)
  --no-gunyah    Disable Gunyah VM support
  --no-bbr       Disable TCP BBR congestion control (default: ON)
  --no-ntfs      Disable native NTFS3 filesystem driver (default: ON)
  --no-btrfs     Disable Btrfs filesystem driver (default: ON)

${BOLD}Update Options:${NC}
  --update       Update all root repositories & download latest APKs
  --update --<root>   Update only the specified root repository & its APK
  --build        Force building the kernel after update

${BOLD}Build Options:${NC}
  --clean        Clean output directory before build
  -j<N>          Specify number of compile jobs (default: ${JOBS})
  -h, --help     Show this help message

${BOLD}Examples:${NC}
  ./make --update                       # Update all root repositories and APKs
  ./make --update --sukisu              # Update only SukiSU repository & APK
  ./make --sukisu --susfs               # Build SukiSU + SusFS (BBR/NTFS/Btrfs built-in)
  ./make --sukisu --susfs --gunyah      # Build SukiSU + SusFS + Gunyah VM support
  ./make --wildsu --susfs --zero        # Build WildSU + SusFS + ZeroMount
  ./make                                # Build stock kernel without root"
    exit 0
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --update)   DO_UPDATE=1            ; shift ;;
        --build)    EXPLICIT_BUILD=1       ; shift ;;

        --sukisu)   ROOT_CHOICE="sukisu"   ; shift ;;
        --ksun)     ROOT_CHOICE="ksun"     ; shift ;;
        --ksu)      ROOT_CHOICE="ksu"      ; shift ;;
        --resuksu)  ROOT_CHOICE="resuksu"  ; shift ;;
        --yukisu)   ROOT_CHOICE="yukisu"   ; shift ;;
        --mksu)     ROOT_CHOICE="mksu"     ; shift ;;
        --bakasu)   ROOT_CHOICE="bakasu"   ; shift ;;
        --rksu)     ROOT_CHOICE="rksu"     ; shift ;;
        --ksulite)  ROOT_CHOICE="ksulite"  ; shift ;;
        --wildsu)   ROOT_CHOICE="wildsu"   ; shift ;;
        --sakisu)   ROOT_CHOICE="sakisu"   ; shift ;;
        --apexsu)   ROOT_CHOICE="apexsu"   ; shift ;;
        --no-root|--stock) ROOT_CHOICE="none" ; shift ;;

        --susfs)     ENABLE_SUSFS=1         ; BUILD_MODIFIER_PASSED=1 ; shift ;;
        --no-susfs)  ENABLE_SUSFS=0         ; shift ;;
        --zero)      ENABLE_ZERO=1          ; BUILD_MODIFIER_PASSED=1 ; shift ;;
        --no-zero)   ENABLE_ZERO=0          ; shift ;;
        --gunyah)    ENABLE_GUNYAH=1        ; BUILD_MODIFIER_PASSED=1 ; shift ;;
        --no-gunyah) ENABLE_GUNYAH=0        ; shift ;;
        --bbr)       ENABLE_BBR=1           ; BUILD_MODIFIER_PASSED=1 ; shift ;;
        --no-bbr)    ENABLE_BBR=0           ; BUILD_MODIFIER_PASSED=1 ; shift ;;
        --ntfs)      ENABLE_NTFS=1          ; BUILD_MODIFIER_PASSED=1 ; shift ;;
        --no-ntfs)   ENABLE_NTFS=0          ; BUILD_MODIFIER_PASSED=1 ; shift ;;
        --btrfs)     ENABLE_BTRFS=1         ; BUILD_MODIFIER_PASSED=1 ; shift ;;
        --no-btrfs)  ENABLE_BTRFS=0         ; BUILD_MODIFIER_PASSED=1 ; shift ;;
        --extras)    ENABLE_BBR=1 ; ENABLE_NTFS=1 ; ENABLE_BTRFS=1 ; BUILD_MODIFIER_PASSED=1 ; shift ;;
        --clean)    DO_CLEAN=1             ; BUILD_MODIFIER_PASSED=1 ; shift ;;
        -j*)
            if [[ "$1" =~ ^-j([0-9]+)$ ]]; then
                JOBS="${BASH_REMATCH[1]}"
            else
                shift
                JOBS="$1"
            fi
            shift
            ;;
        -h|--help)  show_help ;;
        *)
            log_err "Unknown option: $1"
            show_help
            ;;
    esac
done

echo -e "${BOLD}${BLUE}====================================================${NC}"
echo -e "${BOLD}${BLUE}   OnePlus Ace 2 Pro (PJA110) Kernel Builder        ${NC}"
echo -e "${BOLD}${BLUE}   Author: rajok                                    ${NC}"
echo -e "${BOLD}${BLUE}====================================================${NC}"

# Helper to fetch package if missing
fetch_pkg() {
    local dest="$1"
    local url="$2"
    if [[ -f "${dest}" && $(stat -c%s "${dest}" 2>/dev/null || echo 0) -gt 1000 ]]; then
        return 0
    fi
    log_info "Fetching $(basename "${dest}") from release..."
    if curl -fL --retry 3 --retry-delay 2 -s -S "${url}" -o "${dest}" 2>/dev/null; then
        log_succ "Downloaded $(basename "${dest}")"
    else
        log_warn "Failed to download from ${url}"
        rm -f "${dest}"
    fi
}

# Resolve latest APK info from GitHub Releases
get_latest_apk_info() {
    local repo="$1"
    local tag=""
    local location=""
    
    # 1. Try redirect on releases/latest
    location=$(curl -sIL --max-time 5 "https://github.com/${repo}/releases/latest" 2>/dev/null | grep -i "^location:" | tr -d '\r' | tail -n 1 | awk '{print $2}')
    if [[ "${location}" =~ /releases/tag/([^/]+) ]]; then
        tag="${BASH_REMATCH[1]}"
    fi
    
    # 2. If tag empty, try fetching first tag from /tags (for repos using pre-releases)
    if [[ -z "${tag}" ]]; then
        local first_tag_path
        first_tag_path=$(curl -sL --max-time 5 "https://github.com/${repo}/tags" 2>/dev/null | grep -o "/${repo}/releases/tag/[^\"]*" | head -n 1)
        if [[ "${first_tag_path}" =~ /releases/tag/([^/]+) ]]; then
            tag="${BASH_REMATCH[1]}"
        fi
    fi
    
    if [[ -z "${tag}" ]]; then
        return 1
    fi
    
    # 3. Fetch expanded assets for this tag
    local html
    html=$(curl -sL --max-time 7 "https://github.com/${repo}/releases/expanded_assets/${tag}" 2>/dev/null)
    local apks
    apks=$(echo "${html}" | grep -o "/${repo}/releases/download/[^\"]*\.apk" | sort -u)
    if [[ -z "${apks}" ]]; then
        return 1
    fi
    
    # Prefer arm64-v8a or release
    local chosen=""
    chosen=$(echo "${apks}" | grep -E "arm64|v8a" | head -n 1)
    if [[ -z "${chosen}" ]]; then
        chosen=$(echo "${apks}" | grep "release" | head -n 1)
    fi
    if [[ -z "${chosen}" ]]; then
        chosen=$(echo "${apks}" | head -n 1)
    fi
    
    local download_url="https://github.com${chosen}"
    local filename="$(basename "${chosen}")"
    echo "${download_url}|${filename}"
}

resolve_root_apk() {
    local key="$1"
    local cache_file="${APKS_DIR}/.${key}.latest"
    local repo="${ROOT_RELEASE_REPOS[$key]}"
    
    if [[ -n "${repo}" ]]; then
        local latest_info
        latest_info=$(get_latest_apk_info "${repo}")
        if [[ -n "${latest_info}" && "${latest_info}" =~ \| ]]; then
            echo "${latest_info}" > "${cache_file}"
            ROOT_APKS["$key"]="${latest_info}"
            return 0
        fi
    fi
    
    # Fallback to cache if available
    if [[ -f "${cache_file}" ]]; then
        local cached_val
        cached_val=$(head -n 1 "${cache_file}")
        if [[ -n "${cached_val}" && "${cached_val}" =~ \| ]]; then
            ROOT_APKS["$key"]="${cached_val}"
            return 0
        fi
    fi
    
    return 0
}

# Update Helper
update_single_root() {
    local key="$1"
    local dir="${ROOTS_DIR}/${key}"
    local url="${ROOT_REPOS[$key]}"
    echo -e "${BOLD}${CYAN}--> [${key}]${NC} (${url})"
    if [[ ! -d "${dir}" ]]; then
        log_info "Cloning ${key}..."
        git clone --depth 1 "${url}" "${dir}" >/dev/null 2>&1 || git clone "${url}" "${dir}"
    else
        log_info "Pulling latest commits for ${key}..."
        if git -C "${dir}" pull --rebase origin $(git -C "${dir}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main") >/dev/null 2>&1; then
            log_succ "${key} repository is up-to-date!"
        elif git -C "${dir}" pull --rebase >/dev/null 2>&1; then
            log_succ "${key} repository is up-to-date!"
        else
            log_warn "Pull --rebase failed, fetching depth 1..."
            git -C "${dir}" fetch --depth 1 >/dev/null 2>&1 || true
        fi
    fi
    local rev msg
    rev=$(git -C "${dir}" rev-parse --short HEAD 2>/dev/null || echo "unknown")
    msg=$(git -C "${dir}" log -1 --pretty=format:"%s" 2>/dev/null || echo "")
    echo -e "    Commit : ${YELLOW}${rev}${NC} - ${msg}"

    # Also resolve and update latest release APK
    resolve_root_apk "${key}"
    local entry="${ROOT_APKS[$key]}"
    if [[ -n "${entry}" ]]; then
        local apk_url="${entry%%|*}"
        local apk_name="${entry##*|}"
        local apk_dest="${APKS_DIR}/${apk_name}"
        if [[ ! -f "${apk_dest}" ]]; then
            fetch_pkg "${apk_dest}" "${apk_url}"
        fi
        if [[ -f "${apk_dest}" ]]; then
            echo -e "    APK    : ${GREEN}${apk_name}${NC} ($(stat -c%s "${apk_dest}" | numfmt --to=iec-i --suffix=B 2>/dev/null || echo "OK"))"
            echo -e "    Source : ${CYAN}${apk_url}${NC}"
        fi
    fi
    echo ""
}

# Handle --update flag
if [[ ${DO_UPDATE} -eq 1 ]]; then
    echo -e "${BOLD}${MAGENTA}>>> Updating Root Repositories & Packages... <<<${NC}\n"
    if [[ "${ROOT_CHOICE}" != "none" ]]; then
        log_info "Updating specific root: ${BOLD}${ROOT_CHOICE}${NC}"
        update_single_root "${ROOT_CHOICE}"
    else
        log_info "Updating ALL root repositories..."
        for k in sukisu ksun ksu resuksu yukisu mksu bakasu rksu ksulite wildsu sakisu apexsu; do
            update_single_root "${k}"
        done
        # Also update companion modules
        log_info "Checking companion modules (SusFS, ZeroMount)..."
        fetch_pkg "${MODULES_DIR}/ksu_module_susfs_1.5.2+.zip" "https://github.com/sidex15/susfs4ksu-module/releases/download/v1.5.2%2B_R28/ksu_module_susfs_1.5.2%2B.zip"
        fetch_pkg "${MODULES_DIR}/zeromount-v2.0.216-dev.zip" "https://github.com/Enginex0/zeromount/releases/download/v2.0.216-dev/zeromount-v2.0.216-dev.zip"
    fi
    log_succ "All requested updates completed successfully!"

    # If user did NOT pass build flags (like --build, --susfs, --clean), exit after update
    if [[ ${EXPLICIT_BUILD} -eq 0 && ${BUILD_MODIFIER_PASSED} -eq 0 ]]; then
        echo -e "\n${BOLD}${GREEN}Update complete! To build kernel with any root, run:${NC}"
        echo -e "  ./make --sukisu --susfs"
        echo -e "  ./make --ksun --susfs"
        echo -e "  ./make --wildsu --susfs"
        echo -e "  ./make --${ROOT_CHOICE:-sukisu}"
        exit 0
    fi
    echo -e "${BOLD}${BLUE}>>> Proceeding to kernel build as requested... <<<${NC}\n"
fi

# Verify Clang toolchain presence (auto-download from Google AOSP if missing)
if [[ ! -x "${CC}" ]]; then
    log_warn "Clang compiler not found at ${CC}!"
    log_info "Downloading official AOSP Clang toolchain (llvm-r450784)..."
    mkdir -p "${CLANG_DIR}"
    if curl -fL --retry 3 "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/llvm-r450784.tar.gz" | tar -xz -C "${CLANG_DIR}"; then
        chmod -R +x "${CLANG_DIR}/bin" 2>/dev/null || true
        export PATH="${CLANG_DIR}/bin:${PATH}"
        log_succ "Clang toolchain downloaded and unpacked successfully!"
    else
        log_err "Failed to download Clang. Please check network connection or manually extract Clang to ${CLANG_DIR}"
        exit 1
    fi
fi
if [[ ! -f "${STOCK_BOOT}" ]]; then
    log_warn "Stock boot.img not found at ${STOCK_BOOT}. Standalone boot.img creation will be skipped."
    log_info "AnyKernel3 flashable zip will still be generated (it patches boot on-device)."
fi

# Define Mapping for Roots: (TAG, ROOT_DIR, APK_FILE, APK_DOWNLOAD_URL)
ROOT_TAG="Stock"
ROOT_REPO_DIR=""
ROOT_APK_NAME=""
ROOT_APK_URL=""

if [[ "${ROOT_CHOICE}" != "none" ]]; then
    # Dynamically resolve latest APK mapping for selected root
    resolve_root_apk "${ROOT_CHOICE}"
    local_apk_entry="${ROOT_APKS[$ROOT_CHOICE]}"
    if [[ -n "${local_apk_entry}" ]]; then
        ROOT_APK_URL="${local_apk_entry%%|*}"
        ROOT_APK_NAME="${local_apk_entry##*|}"
    fi
fi

case "${ROOT_CHOICE}" in
    sukisu)
        ROOT_TAG="SukiSU"
        ROOT_REPO_DIR="${ROOTS_DIR}/sukisu"
        ;;
    ksun)
        ROOT_TAG="KernelSU-Next"
        ROOT_REPO_DIR="${ROOTS_DIR}/ksun"
        ;;
    ksu)
        ROOT_TAG="KernelSU"
        ROOT_REPO_DIR="${ROOTS_DIR}/ksu"
        ;;
    resuksu)
        ROOT_TAG="ReSukiSU"
        ROOT_REPO_DIR="${ROOTS_DIR}/resuksu"
        ;;
    yukisu)
        ROOT_TAG="YukiSU"
        ROOT_REPO_DIR="${ROOTS_DIR}/yukisu"
        ;;
    mksu)
        ROOT_TAG="More-KernelSU"
        ROOT_REPO_DIR="${ROOTS_DIR}/mksu"
        ;;
    bakasu)
        ROOT_TAG="BakaSU"
        ROOT_REPO_DIR="${ROOTS_DIR}/bakasu"
        ;;
    rksu)
        ROOT_TAG="Restricted-KernelSU"
        ROOT_REPO_DIR="${ROOTS_DIR}/rksu"
        ;;
    ksulite)
        ROOT_TAG="KernelSU-Lite"
        ROOT_REPO_DIR="${ROOTS_DIR}/ksulite"
        ;;
    wildsu)
        ROOT_TAG="WildSU"
        ROOT_REPO_DIR="${ROOTS_DIR}/wildsu"
        ;;
    sakisu)
        ROOT_TAG="SakiSU"
        ROOT_REPO_DIR="${ROOTS_DIR}/sakisu"
        ;;
    apexsu)
        ROOT_TAG="ApexSU"
        ROOT_REPO_DIR="${ROOTS_DIR}/apexsu"
        ;;
    none)
        ROOT_TAG="Stock"
        ROOT_REPO_DIR=""
        ROOT_APK_NAME=""
        ROOT_APK_URL=""
        ;;
esac

# Helper to check if root choice is an in-tree KernelSU driver
is_ksu_root() {
    local choice="$1"
    case "$choice" in
        sukisu|ksun|ksu|resuksu|yukisu|mksu|bakasu|rksu|ksulite|wildsu|sakisu|apexsu)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# SusFS requires in-tree KernelSU support
if [[ ${ENABLE_SUSFS} -eq 1 ]]; then
    if ! is_ksu_root "${ROOT_CHOICE}"; then
        log_warn "SusFS is an in-kernel addon designed exclusively for KernelSU."
        log_warn "Selected root (${ROOT_TAG}) does not use KernelSU. Disabling SusFS."
        ENABLE_SUSFS=0
    fi
fi

# Build banner tag
BANNER_TAG="${ROOT_TAG}"
if [[ ${ENABLE_SUSFS} -eq 1 ]]; then
    BANNER_TAG="${BANNER_TAG}-SUSFS"
fi
if [[ ${ENABLE_ZERO} -eq 1 ]]; then
    BANNER_TAG="${BANNER_TAG}-ZeroMount"
fi
# Gunyah VM is enabled without cluttering the kernel version string
BANNER_SUFFIX="-android13-${BANNER_TAG}-rajok"

log_info "Selected Root : ${BOLD}${ROOT_TAG}${NC}"
log_info "SusFS Status  : ${BOLD}$([[ ${ENABLE_SUSFS} -eq 1 ]] && echo 'Enabled' || echo 'Disabled')${NC}"
log_info "ZeroMount     : ${BOLD}$([[ ${ENABLE_ZERO} -eq 1 ]] && echo 'Enabled' || echo 'Disabled')${NC}"
log_info "Gunyah VM     : ${BOLD}$([[ ${ENABLE_GUNYAH} -eq 1 ]] && echo 'Enabled' || echo 'Disabled')${NC}"
log_info "TCP BBR       : ${BOLD}$([[ ${ENABLE_BBR} -eq 1 ]] && echo 'Enabled' || echo 'Disabled')${NC}"
log_info "NTFS3 Support : ${BOLD}$([[ ${ENABLE_NTFS} -eq 1 ]] && echo 'Enabled' || echo 'Disabled')${NC}"
log_info "Btrfs Support : ${BOLD}$([[ ${ENABLE_BTRFS} -eq 1 ]] && echo 'Enabled' || echo 'Disabled')${NC}"
log_info "LOCALVERSION  : ${BOLD}${BANNER_SUFFIX}${NC}"

# Setup Root repository link
STUB_DIR="${ROOTS_DIR}/stub"
mkdir -p "${STUB_DIR}/kernel"
if [[ ! -f "${STUB_DIR}/kernel/Kconfig" ]]; then
    cat <<'EOF' > "${STUB_DIR}/kernel/Kconfig"
menu "KernelSU Stub"
config KSU
	bool "KernelSU function support (Stub)"
	default n
endmenu
EOF
fi
if [[ ! -f "${STUB_DIR}/kernel/Makefile" ]]; then
    cat <<'EOF' > "${STUB_DIR}/kernel/Makefile"
# Stub Makefile for non-KSU builds
obj-$(CONFIG_KSU) :=
EOF
fi

if is_ksu_root "${ROOT_CHOICE}"; then
    if [[ ! -d "${ROOT_REPO_DIR}" ]]; then
        log_info "Directory ${ROOT_REPO_DIR} does not exist, cloning..."
        update_single_root "${ROOT_CHOICE}"
    fi
    log_info "Linking KernelSU -> ${ROOT_REPO_DIR}"
    ln -sfn "${ROOT_REPO_DIR}" "${TOP_DIR}/KernelSU"
else
    # Stock or non-KSU choice
    log_info "Using clean stub for KernelSU"
    ln -sfn "${STUB_DIR}" "${TOP_DIR}/KernelSU"
    if [[ "${ROOT_CHOICE}" != "none" && -n "${ROOT_REPO_DIR}" && ! -d "${ROOT_REPO_DIR}" ]]; then
        log_info "Directory ${ROOT_REPO_DIR} does not exist, cloning..."
        update_single_root "${ROOT_CHOICE}"
    fi
fi

# Clean if requested
if [[ "${DO_CLEAN}" -eq 1 ]]; then
    log_warn "Cleaning ${OUT_DIR}..."
    rm -rf "${OUT_DIR}"/*
fi


# Ensure .config exists
if [[ ! -f "${OUT_DIR}/.config" ]]; then
    log_info "Generating base config from gki_defconfig..."
    make -C "${COMMON_DIR}" O="${OUT_DIR}" ARCH=arm64 \
        CC="${CC}" LD="${LD}" HOSTCC=clang HOSTCXX=clang++ \
        LLVM=1 LLVM_IAS=1 \
        CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-gnu- \
        gki_defconfig
fi

# Config helpers (avoids touching file if already matching, preserving fast builds)
set_config_val() {
    local key="$1"
    local val="$2"
    local cfg="${OUT_DIR}/.config"
    if grep -Fxq "${key}=${val}" "${cfg}" 2>/dev/null; then
        return 0
    fi
    if grep -q "^${key}=" "${cfg}"; then
        sed -i "s|^${key}=.*|${key}=${val}|" "${cfg}"
    elif grep -q "^# ${key} is not set" "${cfg}"; then
        sed -i "s|^# ${key} is not set|${key}=${val}|" "${cfg}"
    else
        echo "${key}=${val}" >> "${cfg}"
    fi
}

unset_config_val() {
    local key="$1"
    local cfg="${OUT_DIR}/.config"
    if grep -Fxq "# ${key} is not set" "${cfg}" 2>/dev/null; then
        return 0
    fi
    if grep -q "^${key}=" "${cfg}"; then
        sed -i "s|^${key}=.*|# ${key} is not set|" "${cfg}"
    elif ! grep -q "^# ${key} is not set" "${cfg}"; then
        echo "# ${key} is not set" >> "${cfg}"
    fi
}

# Update CONFIG_LOCALVERSION
set_config_val "CONFIG_LOCALVERSION" "\"${BANNER_SUFFIX}\""

# Ensure full kallsyms is enabled
set_config_val "CONFIG_KALLSYMS" "y"
set_config_val "CONFIG_KALLSYMS_ALL" "y"

# Update Root Kconfig
if is_ksu_root "${ROOT_CHOICE}"; then
    set_config_val "CONFIG_KSU" "y"
    set_config_val "CONFIG_KSU_FEATURE_ADBROOT" "y"
else
    unset_config_val "CONFIG_KSU"
    unset_config_val "CONFIG_KSU_FEATURE_ADBROOT"
fi

# Update SusFS Kconfig
if [[ "${ENABLE_SUSFS}" -eq 1 ]]; then
    set_config_val "CONFIG_KSU_SUSFS" "y"
    set_config_val "CONFIG_KSU_SUSFS_SUS_PATH" "y"
    set_config_val "CONFIG_KSU_SUSFS_SUS_MOUNT" "y"
    set_config_val "CONFIG_KSU_SUSFS_SUS_KSTAT" "y"
    set_config_val "CONFIG_KSU_SUSFS_SPOOF_UNAME" "y"
    set_config_val "CONFIG_KSU_SUSFS_ENABLE_LOG" "y"
    set_config_val "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS" "y"
    set_config_val "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG" "y"
    set_config_val "CONFIG_KSU_SUSFS_OPEN_REDIRECT" "y"
    set_config_val "CONFIG_KSU_SUSFS_SUS_MAP" "y"
else
    unset_config_val "CONFIG_KSU_SUSFS"
    unset_config_val "CONFIG_KSU_SUSFS_SUS_PATH"
    unset_config_val "CONFIG_KSU_SUSFS_SUS_MOUNT"
    unset_config_val "CONFIG_KSU_SUSFS_SUS_KSTAT"
    unset_config_val "CONFIG_KSU_SUSFS_SPOOF_UNAME"
    unset_config_val "CONFIG_KSU_SUSFS_ENABLE_LOG"
    unset_config_val "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS"
    unset_config_val "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG"
    unset_config_val "CONFIG_KSU_SUSFS_OPEN_REDIRECT"
    unset_config_val "CONFIG_KSU_SUSFS_SUS_MAP"
fi

# Ensure ZeroMount VFS driver is disabled (ZeroMount works via its companion module)
unset_config_val "CONFIG_ZEROMOUNT"

# Ensure SELinux stays enforcing
unset_config_val "CONFIG_SECURITY_SELINUX_DEVELOP"

# Stock CMDLINE (Protected mode for Qualcomm TrustZone / QHEE compatibility)
set_config_val "CONFIG_CMDLINE" "\"stack_depot_disable=on kasan.stacktrace=off kvm-arm.mode=protected cgroup_disable=pressure\""

# Restore Stock HZ and debug settings (required for Qualcomm vendor module KMI stability)
unset_config_val "CONFIG_HZ_300"
set_config_val "CONFIG_HZ_250" "y"
set_config_val "CONFIG_DEBUG_MEMORY_INIT" "y"
set_config_val "CONFIG_SCHEDSTATS" "y"
unset_config_val "CONFIG_ZRAM_WRITEBACK"
unset_config_val "CONFIG_ZRAM_MEMORY_TRACKING"

# Optional TCP BBR
if [[ ${ENABLE_BBR} -eq 1 ]]; then
    set_config_val "CONFIG_TCP_CONG_ADVANCED" "y"
    set_config_val "CONFIG_TCP_CONG_BBR" "y"
    set_config_val "CONFIG_DEFAULT_BBR" "y"
    set_config_val "CONFIG_DEFAULT_TCP_CONG" "\"bbr\""
else
    unset_config_val "CONFIG_TCP_CONG_BBR"
    unset_config_val "CONFIG_DEFAULT_BBR"
    set_config_val "CONFIG_DEFAULT_TCP_CONG" "\"cubic\""
fi

# Optional Native NTFS3 filesystem (Paragon driver)
if [[ ${ENABLE_NTFS} -eq 1 ]]; then
    set_config_val "CONFIG_NTFS3_FS" "y"
    set_config_val "CONFIG_NTFS3_LZX_XPRESS" "y"
    set_config_val "CONFIG_NTFS3_FS_POSIX_ACL" "y"
else
    unset_config_val "CONFIG_NTFS3_FS"
    unset_config_val "CONFIG_NTFS3_LZX_XPRESS"
    unset_config_val "CONFIG_NTFS3_FS_POSIX_ACL"
fi

# Optional Btrfs filesystem
if [[ ${ENABLE_BTRFS} -eq 1 ]]; then
    set_config_val "CONFIG_BTRFS_FS" "y"
    set_config_val "CONFIG_BTRFS_FS_POSIX_ACL" "y"
else
    unset_config_val "CONFIG_BTRFS_FS"
    unset_config_val "CONFIG_BTRFS_FS_POSIX_ACL"
fi

# Ensure bare-metal SM8550 clean state (remove any virtual machine VirtIO / UDMABUF conflicts)
unset_config_val "CONFIG_VIRTIO_PCI"
unset_config_val "CONFIG_VIRTIO_BALLOON"
unset_config_val "CONFIG_VIRTIO_BLK"
unset_config_val "CONFIG_VIRTIO_NET"
unset_config_val "CONFIG_VIRTIO_CONSOLE"
unset_config_val "CONFIG_VIRTIO_INPUT"
unset_config_val "CONFIG_VIRTIO_DMA_SHARED_BUFFER"
unset_config_val "CONFIG_UDMABUF"
unset_config_val "CONFIG_VHOST_NET"
unset_config_val "CONFIG_VIRTIO_VSOCKETS"

# Ensure GKI BTF debug info and module mismatch tolerance are enabled for Android 13 bpfloader and vendor DLKM
set_config_val "CONFIG_DEBUG_INFO_BTF" "y"
set_config_val "CONFIG_DEBUG_INFO_BTF_MODULES" "y"
set_config_val "CONFIG_MODULE_ALLOW_BTF_MISMATCH" "y"

# Ensure all config dependencies are cleanly resolved without prompts
make -C "${COMMON_DIR}" O="${OUT_DIR}" ARCH=arm64 \
    CC="${CC}" LD="${LD}" HOSTCC=clang HOSTCXX=clang++ \
    LLVM=1 LLVM_IAS=1 \
    CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-gnu- \
    olddefconfig >/dev/null 2>&1

# Step 1: Compile Kernel Image
log_info "Compiling kernel with ${JOBS} jobs..."
BUILD_START=$(date +%s)

make -C "${COMMON_DIR}" O="${OUT_DIR}" ARCH=arm64 \
    CC="${CC}" LD="${LD}" HOSTCC=clang HOSTCXX=clang++ \
    LLVM=1 LLVM_IAS=1 \
    CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-gnu- \
    -j"${JOBS}" Image

BUILD_END=$(date +%s)
log_succ "Kernel Image built successfully in $((BUILD_END - BUILD_START))s!"

BUILT_IMAGE="${OUT_DIR}/arch/arm64/boot/Image"
if [[ ! -f "${BUILT_IMAGE}" ]]; then
    log_err "Image file not found at ${BUILT_IMAGE}"
    exit 1
fi

# Step 2: Package boot.img (optional: requires stock_images/boot.img)
if [[ -f "${STOCK_BOOT}" ]]; then
    log_info "Packaging boot.img..."
    TEMP_UNPACK="/tmp/pja110_boot_unpack_$$"
    mkdir -p "${TEMP_UNPACK}"
    trap "rm -rf ${TEMP_UNPACK}" EXIT

    TARGET_BOOT="${OUT_IMAGES_DIR}/boot.img"
    MAGISKBOOT="qemu-arm ${AK3_TEMPLATE}/tools/magiskboot"

    (
        cd "${TEMP_UNPACK}"
        ${MAGISKBOOT} unpack "${STOCK_BOOT}" >/dev/null
        cp -f "${BUILT_IMAGE}" kernel
        export PATCHVBMETAFLAG=true
        ${MAGISKBOOT} repack "${STOCK_BOOT}" "${TARGET_BOOT}" >/dev/null
    )

    cp -p "${TARGET_BOOT}" "${TOP_DIR}/boot.img"
    log_succ "boot.img successfully created with preserved OEM AVB footer!"
else
    log_info "Skipping standalone boot.img creation (no stock_images/boot.img provided)."
fi

# Step 3: Package AnyKernel3 Flashable Zip
log_info "Packaging AnyKernel3 flashable zip..."
AK3_BUILD_DIR="/tmp/pja110_ak3_$$"
mkdir -p "${AK3_BUILD_DIR}"
trap "rm -rf ${TEMP_UNPACK} ${AK3_BUILD_DIR}" EXIT

cp -a "${AK3_TEMPLATE}/anykernel.sh" "${AK3_BUILD_DIR}/"
cp -a "${AK3_TEMPLATE}/tools" "${AK3_BUILD_DIR}/"
cp -a "${AK3_TEMPLATE}/META-INF" "${AK3_BUILD_DIR}/"
cp -a "${BUILT_IMAGE}" "${AK3_BUILD_DIR}/Image"

# Update anykernel.sh banner
sed -i "s|^kernel.string=.*|kernel.string=Kernel [${BANNER_TAG}] by rajok for OnePlus Ace 2 Pro (PJA110)|" "${AK3_BUILD_DIR}/anykernel.sh"

ZIP_FILENAME="AnyKernel3-5.15.180${BANNER_SUFFIX}.zip"
TARGET_AK3_ZIP="${OUT_IMAGES_DIR}/${ZIP_FILENAME}"
rm -f "${TARGET_AK3_ZIP}"

(
    cd "${AK3_BUILD_DIR}"
    zip -r9 "${TARGET_AK3_ZIP}" * >/dev/null
)

ln -sfn "${ZIP_FILENAME}" "${OUT_IMAGES_DIR}/AnyKernel3-latest.zip"
log_succ "AnyKernel3 zip successfully created!"

# Step 4: Copy Root Manager APK to out_images
OUTPUT_APK_PATH=""
if [[ -n "${ROOT_APK_NAME}" ]]; then
    CACHED_APK="${APKS_DIR}/${ROOT_APK_NAME}"
    if [[ ! -f "${CACHED_APK}" && -n "${ROOT_APK_URL}" ]]; then
        fetch_pkg "${CACHED_APK}" "${ROOT_APK_URL}"
    fi

    if [[ -f "${CACHED_APK}" ]]; then
        TARGET_APK="${OUT_IMAGES_DIR}/${ROOT_APK_NAME}"
        cp -p "${CACHED_APK}" "${TARGET_APK}"
        ln -sfn "${ROOT_APK_NAME}" "${OUT_IMAGES_DIR}/manager.apk"
        OUTPUT_APK_PATH="${TARGET_APK}"
        log_succ "Root manager APK prepared: ${TARGET_APK}"
    fi
fi

# Step 5: Copy Companion Modules to out_images
OUTPUT_SUSFS_MODULE=""
if [[ ${ENABLE_SUSFS} -eq 1 ]]; then
    SUSFS_ZIP_NAME="ksu_module_susfs_1.5.2+.zip"
    CACHED_SUSFS="${MODULES_DIR}/${SUSFS_ZIP_NAME}"
    if [[ ! -f "${CACHED_SUSFS}" ]]; then
        fetch_pkg "${CACHED_SUSFS}" "https://github.com/sidex15/susfs4ksu-module/releases/download/v1.5.2%2B_R28/ksu_module_susfs_1.5.2%2B.zip"
    fi
    if [[ -f "${CACHED_SUSFS}" ]]; then
        cp -p "${CACHED_SUSFS}" "${OUT_IMAGES_DIR}/${SUSFS_ZIP_NAME}"
        OUTPUT_SUSFS_MODULE="${OUT_IMAGES_DIR}/${SUSFS_ZIP_NAME}"
        log_succ "SUSFS companion module copied: ${OUTPUT_SUSFS_MODULE}"
    fi
fi

OUTPUT_ZERO_MODULE=""
if [[ ${ENABLE_ZERO} -eq 1 ]]; then
    ZERO_ZIP_NAME="zeromount-v2.0.216-dev.zip"
    CACHED_ZERO="${MODULES_DIR}/${ZERO_ZIP_NAME}"
    if [[ ! -f "${CACHED_ZERO}" ]]; then
        fetch_pkg "${CACHED_ZERO}" "https://github.com/Enginex0/zeromount/releases/download/v2.0.216-dev/zeromount-v2.0.216-dev.zip"
    fi
    if [[ -f "${CACHED_ZERO}" ]]; then
        cp -p "${CACHED_ZERO}" "${OUT_IMAGES_DIR}/${ZERO_ZIP_NAME}"
        OUTPUT_ZERO_MODULE="${OUT_IMAGES_DIR}/${ZERO_ZIP_NAME}"
        log_succ "ZeroMount companion module copied: ${OUTPUT_ZERO_MODULE}"
    fi
fi

# Step 6: Print Final Summary
echo ""
echo -e "${BOLD}${GREEN}======================================================================${NC}"
echo -e "${BOLD}${GREEN}                        BUILD COMPLETE!                               ${NC}"
echo -e "${BOLD}${GREEN}======================================================================${NC}"
echo -e "${BOLD}Kernel Banner :${NC} 5.15.180${BANNER_SUFFIX}"
echo -e "${BOLD}Root Solution :${NC} ${ROOT_TAG}"
echo -e "${BOLD}SusFS Status  :${NC} $([[ ${ENABLE_SUSFS} -eq 1 ]] && echo 'Enabled' || echo 'Disabled')"
echo -e "${BOLD}ZeroMount     :${NC} $([[ ${ENABLE_ZERO} -eq 1 ]] && echo 'Enabled' || echo 'Disabled')"
echo -e "${BOLD}Gunyah VM     :${NC} $([[ ${ENABLE_GUNYAH} -eq 1 ]] && echo 'Enabled' || echo 'Disabled')"
echo -e "${BOLD}TCP BBR       :${NC} $([[ ${ENABLE_BBR} -eq 1 ]] && echo 'Enabled' || echo 'Disabled')"
echo -e "${BOLD}NTFS3 Support :${NC} $([[ ${ENABLE_NTFS} -eq 1 ]] && echo 'Enabled' || echo 'Disabled')"
echo -e "${BOLD}Btrfs Support :${NC} $([[ ${ENABLE_BTRFS} -eq 1 ]] && echo 'Enabled' || echo 'Disabled')"
echo ""
echo -e "${BOLD}${CYAN}Generated Deliverables in out_images/:${NC}"
echo -e "  [Kernel Boot Image]"
echo -e "    * ${TOP_DIR}/boot.img"
echo -e "    * ${TARGET_BOOT}"
echo ""
echo -e "  [Recovery / KernelFlasher AnyKernel3 Zip]"
echo -e "    * ${TARGET_AK3_ZIP}"
echo -e "    * ${OUT_IMAGES_DIR}/AnyKernel3-latest.zip"

if [[ -n "${OUTPUT_APK_PATH}" ]]; then
echo ""
echo -e "  [Manager APK]"
echo -e "    * ${OUTPUT_APK_PATH}"
echo -e "    * ${OUT_IMAGES_DIR}/manager.apk"
fi

if [[ -n "${OUTPUT_SUSFS_MODULE}" || -n "${OUTPUT_ZERO_MODULE}" ]]; then
echo ""
echo -e "  [Companion Addons / Modules]"
[[ -n "${OUTPUT_SUSFS_MODULE}" ]] && echo -e "    * SUSFS Module:    ${OUTPUT_SUSFS_MODULE}"
[[ -n "${OUTPUT_ZERO_MODULE}"  ]] && echo -e "    * ZeroMount Module:${OUTPUT_ZERO_MODULE}"
fi

echo ""
echo -e "Manual Flashing Methods:"
echo -e "  1. Fastboot (PC):      ${BOLD}fastboot flash boot ${TARGET_BOOT}${NC}"
echo -e "  2. Recovery (TWRP):    Install Zip -> ${BOLD}${TARGET_AK3_ZIP}${NC}"
echo -e "  3. KernelFlasher (App): Select and flash -> ${BOLD}${TARGET_AK3_ZIP}${NC}"
echo -e "${BOLD}${GREEN}======================================================================${NC}"
