#!/bin/bash

# 获取并验证脚本环境
setup_script_environment() {
    local exit_cmd="exit 1"

    # 判断执行方式，选择正确的退出命令
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
        # 被 source 执行时使用 return
        exit_cmd="return 1"
    fi

    # 获取脚本所在目录的绝对路径（兼容两种执行方式）
    if [ -n "$GITHUB_WORKSPACE" ]; then
        # 在 GitHub Actions 环境中
        SCRIPT_DIR="$GITHUB_WORKSPACE"
        echo "检测到 GitHub Actions 环境，使用工作目录: $SCRIPT_DIR"
    else
        # 本地环境 - 使用 BASH_SOURCE 获取脚本真实路径
        local script_source="${BASH_SOURCE[0]:-$0}"
        SCRIPT_DIR="$(cd "$(dirname "$script_source")" && pwd)"
    fi

    # 验证关键目录是否存在
    local missing_dir=""

    if [ ! -d "${SCRIPT_DIR}/u-boot-2016" ]; then
        echo "错误: u-boot-2016 目录不存在"
        echo "期望路径: ${SCRIPT_DIR}/u-boot-2016"
        missing_dir="u-boot-2016"
    fi

    if [ ! -d "${SCRIPT_DIR}/staging_dir" ]; then
        if [ -n "$missing_dir" ]; then
            missing_dir="$missing_dir 和 staging_dir"
        else
            missing_dir="staging_dir"
        fi
        echo "错误: staging_dir 目录不存在"
        echo "期望路径: ${SCRIPT_DIR}/staging_dir"
    fi

    # 如果有缺失的目录，显示详细信息并退出
    if [ -n "$missing_dir" ]; then
        echo "缺失目录: $missing_dir"
        echo "当前目录内容:"
        ls -la "$SCRIPT_DIR"
        eval "$exit_cmd"
    fi

    # 验证通过，返回成功
    return 0
}

# 日志文件设置
LOG_FILE=""
setup_logging() {
    if [ ! -d "${SCRIPT_DIR}/bin/${COMPILE_DATE}" ]; then
        mkdir -p "${SCRIPT_DIR}/bin/${COMPILE_DATE}"
    fi

    if [ -z "$LOG_FILE" ]; then
        LOG_FILE="${SCRIPT_DIR}/bin/${COMPILE_DATE}/log-${COMPILE_DATE}.txt"
        echo "日志文件: $(basename "$LOG_FILE")"
        echo "==========================================" >> "$LOG_FILE"
        echo "编译开始时间: $(TZ=UTC-8 date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
        echo "编译版本号: $uboot_version" >> "$LOG_FILE"
        echo "==========================================" >> "$LOG_FILE"
    fi
}

# 日志输出函数
log_message() {
    local message="$*"
    local timestamp=$(TZ=UTC-8 date '+%Y-%m-%d %H:%M:%S')

    # 输出到标准输出
    echo "$message"

    # 输出到日志文件（带时间戳）
    if [ -n "$LOG_FILE" ]; then
        echo "[$timestamp] $message" >> "$LOG_FILE"
    fi
}

# 设置编译时间信息
setup_build_info() {
    # 使用同一时间戳确保完全一致
    local unified_time=$(TZ=UTC-8 date +"%s")

    export COMPILE_DATE=$(TZ=UTC-8 date -d "@$unified_time" +"%y.%m.%d-%H.%M.%S")
    export uboot_version=$(TZ=UTC-8 date -d "@$unified_time" +"%y%m%d.%H%M%S")

    log_message "设置版本号: $uboot_version"
    log_message "设置编译时间: $COMPILE_DATE"

    # 设置日志文件
    setup_logging
}

# 设置编译环境函数
setup_build_env() {
    log_message "设置编译环境"
    export ARCH=arm
    export TARGETCC=arm-openwrt-linux-gcc
    export CROSS_COMPILE=arm-openwrt-linux-
    export STAGING_DIR="${SCRIPT_DIR}/staging_dir"
    export HOSTLDFLAGS="-L${STAGING_DIR}/usr/lib -znow -zrelro -pie"
    export PATH="${STAGING_DIR}/toolchain-arm_cortex-a7_gcc-5.2.0_musl-1.1.16_eabi/bin:$PATH"
}

# 文件大小检查和填充函数
check_and_pad_file() {
    local file_path=$1
    local target_name=$2

    if [ ! -f "$file_path" ]; then
        log_message "错误: 文件不存在: $file_path"
        return 1
    fi

    local current_size_bytes=$(stat -c%s "$file_path")
    local target_size_bytes

    case "$target_name" in
        cmiot_ax18|qihoo_360v6|zn_m2)
            # 针对 NAND 机型，将 U-Boot 填充至 1536 KB
            target_size_bytes=1572864 # 1536 KB = 1572864 Bytes
            ;;
        *)
            target_size_bytes=655360 # 640 KB = 655360 Bytes
            ;;
    esac

    log_message "文件检查: $target_name"
    log_message "文    件: $(basename "$file_path")"
    log_message "当前大小: $current_size_bytes Bytes"
    log_message "目标大小: $target_size_bytes Bytes"

    if [ $current_size_bytes -lt $target_size_bytes ]; then
        log_message "文件当前大小小于目标大小，正在填充..."
        truncate -s $target_size_bytes "$file_path"
        local new_size_bytes=$(stat -c%s "$file_path")
        log_message "填充完成! 新大小: $new_size_bytes Bytes"
    elif [ $current_size_bytes -eq $target_size_bytes ]; then
        log_message "文件已经是目标大小!"
    else
        log_message "WARNING! 文件当前大小大于目标大小!"
        log_message "这可能导致刷写失败，建议检查编译配置"
    fi
}

# 清理编译过程中产生的缓存
clean_cache() {
    # 确保在脚本目录下执行
    cd "$SCRIPT_DIR"

    # 根据 .gitignore 规则深度清理
    if [ -d "${SCRIPT_DIR}/u-boot-2016" ]; then
        find u-boot-2016/ -type f \
            \( \
                -name '.*.cmd' -o \
                -name '.*.tmp' -o \
                -name '*.o' -o \
                -name '*.o.*' -o \
                -name '*.a' -o \
                -name '*.s' -o \
                -name '*.su' -o \
                -name '*.mod.c' -o \
                -name '*.i' -o \
                -name '*.lst' -o \
                -name '*.order' -o \
                -name '*.elf' -o \
                -name '*.swp' -o \
                -name '*.bin' -o \
                -name '*.patch' -o \
                -name '*.cfgtmp' -o \
                -name '*.exe' -o \
                -name 'MLO*' -o \
                -name 'SPL' -o \
                -name 'System.map' -o \
                -name 'LOG' -o \
                -name '*.orig' -o \
                -name '*~' -o \
                -name '#*#' -o \
                -name 'cscope.*' -o \
                -name 'tags' -o \
                -name 'ctags' -o \
                -name 'etags' -o \
                -name 'GPATH' -o \
                -name 'GRTAGS' -o \
                -name 'GSYMS' -o \
                -name 'GTAGS' \
            \) -delete
        rm -rf \
            u-boot-2016/.config \
            u-boot-2016/.gdb_history \
            u-boot-2016/.stgit-edit.txt \
            u-boot-2016/.u-boot* \
            u-boot-2016/arch/arm/dts/dtbtable.S \
            u-boot-2016/httpd/fsdata.c \
            u-boot-2016/include/config \
            u-boot-2016/include/generated \
            u-boot-2016/scripts/kconfig/conf \
            u-boot-2016/scripts/basic/fixdep \
            u-boot-2016/tools/gen_eth_addr \
            u-boot-2016/tools/img2srec \
            u-boot-2016/tools/proftool \
            u-boot-2016/tools/fdtgrep \
            u-boot-2016/tools/envcrc \
            u-boot-2016/tools/dumpimage \
            u-boot-2016/u-boot*
    fi
}

# 编译函数（先清理后编译）
compile_target_after_cache_clean() {
    local arch_name=$1
    local target_name=$2
    local config_name=$3

    log_message "编译目标: $target_name"

    # 清理编译缓存
    log_message "清理编译缓存"
    clean_cache

    # 设置编译环境
    setup_build_env

    log_message "进入编译目录"
    cd "${SCRIPT_DIR}/u-boot-2016/"

    log_message "构建配置: $config_name"
    make ${config_name}_defconfig

    log_message "开始编译"
    if [ -n "$LOG_FILE" ]; then
        # 同时输出到屏幕和日志文件
        make V=s 2>&1 | tee -a "$LOG_FILE"
        # 获取 make 命令的退出状态
        MAKE_EXIT_STATUS=${PIPESTATUS[0]}
    else
        # 如果没有日志文件，正常执行
        make V=s
        MAKE_EXIT_STATUS=$?
    fi

    if [ $MAKE_EXIT_STATUS -ne 0 ]; then
        log_message "错误: 编译失败!"
        return 1
    fi

    log_message "Strip elf"
    arm-openwrt-linux-strip u-boot

    log_message "转换 elf 到 mbn"
    python3 -B tools/elftombn.py -f ./u-boot -o ./u-boot.mbn -v 6

    if [ ! -d "${SCRIPT_DIR}/bin/${COMPILE_DATE}" ]; then
        mkdir -p "${SCRIPT_DIR}/bin/${COMPILE_DATE}"
    fi

	local output_file="${SCRIPT_DIR}/bin/${COMPILE_DATE}/uboot-${arch_name}-${target_name}-${uboot_version}.bin"
    log_message "移动 u-boot.mbn 到 bin/${COMPILE_DATE}/ 并重命名"
    mv ./u-boot.mbn "$output_file"

    # 调用文件大小检查和填充函数
    check_and_pad_file "$output_file" "$target_name"

    log_message "编译完成: $target_name"
    log_message " "

    # 返回脚本目录
    cd "$SCRIPT_DIR"
}

# 编译单个目标（包含版本设置）
compile_single_target() {
    local arch_name=$1
    local target_name=$2
    local config_name=$3

    # 开始编译前获取 HTML 文件中的日期 (只提取 index.html 中的日期，请确保所有 HTML 文件中的日期一致)
    local original_date=$(grep -oE '[0-9]{4}\.[0-9]{2}\.[0-9]{2}' "$SCRIPT_DIR/u-boot-2016/httpd/vendors/chenxin/index.html" | head -1)

    setup_build_info

    compile_target_after_cache_clean "$arch_name" "$target_name" "$config_name"

    # 恢复所有 HTML 文件中的日期，防止污染 Git 工作区
    sed -i "s/[0-9]\{4\}\.[0-9]\{2\}\.[0-9]\{2\}/$original_date/g" "$SCRIPT_DIR"/u-boot-2016/httpd/vendors/chenxin/*.html
}

# 编译所有目标
compile_all_targets() {
    # 开始编译前获取 HTML 文件中的日期 (只提取 index.html 中的日期，请确保所有 HTML 文件中的日期一致)
    local original_date=$(grep -oE '[0-9]{4}\.[0-9]{2}\.[0-9]{2}' "$SCRIPT_DIR/u-boot-2016/httpd/vendors/chenxin/index.html" | head -1)

    # 一次性设置版本号，确保所有文件版本一致
    setup_build_info

    log_message "编译所有支持的设备"

    # 依次编译所有设备
    compile_target_after_cache_clean "ipq60xx" "cmiot_ax18"        "ipq6018_cmiot_ax18"
    compile_target_after_cache_clean "ipq60xx" "jdcloud_re-cs-02"  "ipq6018_jdcloud_re_cs_02"
    compile_target_after_cache_clean "ipq60xx" "jdcloud_re-cs-07"  "ipq6018_jdcloud_re_cs_07"
    compile_target_after_cache_clean "ipq60xx" "jdcloud_re-ss-01"  "ipq6018_jdcloud_re_ss_01"
    compile_target_after_cache_clean "ipq60xx" "link_nn6000"       "ipq6018_link_nn6000"
    compile_target_after_cache_clean "ipq60xx" "philips_ly1800"    "ipq6018_philips_ly1800"
    compile_target_after_cache_clean "ipq60xx" "qihoo_360v6"       "ipq6018_qihoo_360v6"
    compile_target_after_cache_clean "ipq60xx" "redmi_ax5-jdcloud" "ipq6018_redmi_ax5_jdcloud"
    compile_target_after_cache_clean "ipq60xx" "sy_y6010"          "ipq6018_sy_y6010"
    compile_target_after_cache_clean "ipq60xx" "zn_m2"             "ipq6018_zn_m2"

    # 恢复所有 HTML 文件中的日期，防止污染 Git 工作区
    sed -i "s/[0-9]\{4\}\.[0-9]\{2\}\.[0-9]\{2\}/$original_date/g" "$SCRIPT_DIR"/u-boot-2016/httpd/vendors/chenxin/*.html

    log_message "所有设备编译完成!"
}

# 帮助文档函数
show_help() {
    echo "用法: ${BASH_SOURCE[0]} [选项]"
    echo ""
    echo "选项:"
    echo "  help                    显示此帮助信息"
    echo "  setup_env               仅设置编译环境 (需使用 source 执行 ${BASH_SOURCE[0]})"
    echo "  clean_cache             清理编译过程中产生的缓存"
    echo "  build_ax18              编译 CMIOT AX18"
    echo "  build_re-cs-02          编译 JDCloud AX6600 (Athena)"
    echo "  build_re-cs-07          编译 JDCloud ER1"
    echo "  build_re-ss-01          编译 JDCloud AX1800 Pro (Arthur)"
    echo "  build_nn6000            编译 Link NN6000 (V1 & V2)"
    echo "  build_ly1800            编译 Philips LY1800"
    echo "  build_360v6             编译 Qihoo 360V6"
    echo "  build_ax5-jdcloud       编译 Redmi AX5 JDCloud"
    echo "  build_y6010             编译 SY Y6010"
    echo "  build_m2                编译 ZN M2"
    echo "  build_all               编译所有支持的设备"
}

# 以上是函数定义，脚本从这里开始执行

# 获取并验证脚本环境
setup_script_environment

# 主逻辑 - 使用 case 语句
case "$1" in
    "setup_env")
        if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
            echo "要在当前 shell 中设置编译环境，请执行: source ${BASH_SOURCE[0]} setup_env"
            exit 1
        fi
        setup_build_env
  		echo "编译环境设置完成"
        ;;

    "clean_cache")
        # 对于非编译操作，不设置日志文件
        clean_cache
        echo "编译缓存清理完成!"
        ;;

    "build_ax18")
        compile_single_target "ipq60xx" "cmiot_ax18" "ipq6018_cmiot_ax18"
        ;;

    "build_re-cs-02")
        compile_single_target "ipq60xx" "jdcloud_re-cs-02" "ipq6018_jdcloud_re_cs_02"
        ;;

    "build_re-cs-07")
        compile_single_target "ipq60xx" "jdcloud_re-cs-07" "ipq6018_jdcloud_re_cs_07"
        ;;

    "build_re-ss-01")
        compile_single_target "ipq60xx" "jdcloud_re-ss-01" "ipq6018_jdcloud_re_ss_01"
        ;;

    "build_nn6000")
        compile_single_target "ipq60xx" "link_nn6000" "ipq6018_link_nn6000"
        ;;

    "build_ly1800")
        compile_single_target "ipq60xx" "philips_ly1800" "ipq6018_philips_ly1800"
        ;;

    "build_360v6")
        compile_single_target "ipq60xx" "qihoo_360v6" "ipq6018_qihoo_360v6"
        ;;

    "build_ax5-jdcloud")
        compile_single_target "ipq60xx" "redmi_ax5-jdcloud" "ipq6018_redmi_ax5_jdcloud"
        ;;

    "build_y6010")
        compile_single_target "ipq60xx" "sy_y6010" "ipq6018_sy_y6010"
        ;;

    "build_m2")
        compile_single_target "ipq60xx" "zn_m2" "ipq6018_zn_m2"
        ;;

    "build_all")
        compile_all_targets
        ;;

    "help"|"")
        show_help
        ;;

    *)
        echo "错误: 未知选项 '$1'"
        echo "使用 '${BASH_SOURCE[0]} help' 查看可用选项"
        if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
            # 被 source 执行时使用 return
            return 1
        else
            exit 1
        fi
        ;;
esac

# 记录编译操作的结束
case "$1" in
    "build_"*)
        if [ -n "$LOG_FILE" ]; then
            echo "==========================================" >> "$LOG_FILE"
            echo "编译结束时间: $(TZ=UTC-8 date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
            echo "==========================================" >> "$LOG_FILE"
        fi
        ;;
esac
