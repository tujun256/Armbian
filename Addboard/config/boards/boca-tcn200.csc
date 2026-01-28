# BOCA TCN200 MB-R50(CMCC) Rockchip RK3588s Octa core 4GB-32GB eMMC GBE TYPEC SATA USB2
BOARD_NAME="BOCA TCN200 RK3588"
BOARDFAMILY="rockchip-rk3588"
BOOT_SOC="rk3588"
BOARD_MAINTAINER="r-mt"
KERNEL_TARGET="legacy,vendor"
BOOTCONFIG="rk3588_defconfig"
# 新增：显式禁用 OPTEE 编译（核心1）
BUILD_OPTEE="no"
OPTEE_PLATFORM=""
OPTEE_TARGET=""
# 新增：禁止 U-Boot 加载 OPTEE 镜像（核心2）
BOOT_SCRIPT_ADDITION='setenv tee_addr ""; setenv tee_file ""; setenv tee_ready "yes";'
# 原有配置不变
BOOT_FDT_FILE="rockchip/rk3588s-boca-tcn200.dtb"
BOOT_LOGO="desktop"
FULL_DESKTOP="yes"
IMAGE_PARTITION_TABLE="gpt"
ENABLE_EXTENSIONS="mesa-vpu"
# SRC_EXTLINUX="yes"
# SRC_CMDLINE="rootwait earlycon=uart8250,mmio32,0xfeb50000 console=ttyFIQ0 irqchip.gicv3_pseudo_nmi=0 rootfstype=ext4"

# 原有函数不变
function post_family_config__boca-tcn200_kernel() {
	display_alert "$BOARD" "mainline BOOTPATCHDIR" "info"	
	if [[ ${BRANCH} = "legacy" ]] ; then
		KERNELPATCHDIR="rockchip-5.10-boca-tcn200"
	else
		KERNELPATCHDIR="rockchip-6.1-boca-tcn200"
	fi	
}

function post_family_tweaks__boca-tcn200_enable_services() {
	display_alert "fix armbian upgrade; hold kernel and dtb"
	if [[ ${BRANCH} = "legacy" ]] ; then
		display_alert "$BOARD" "Enabling boca-tcn200 upgrade lock dtb adn kernel" "info"
		chroot_sdcard apt-mark hold linux-dtb-legacy-rk35xx
		#chroot_sdcard apt-mark hold linux-image-legacy-rk35xx
		chroot_sdcard apt-mark hold linux-u-boot-boca-tcn200-legacy
		chroot_sdcard ssh-keygen -A
	else
		display_alert "$BOARD" "Enabling boca-tcn200 upgrade lock dtb adn kernel" "info"
		chroot_sdcard apt-mark hold linux-dtb-vendor-rk35xx
		#chroot_sdcard apt-mark hold linux-image-vendor-rk35xx
		chroot_sdcard apt-mark hold linux-u-boot-boca-tcn200-vendor
	fi
	return 0
}

function pre_umount_final_image__fix_mpv() {
	display_alert "fix_mpv.conf"
	if [[ "${BUILD_DESKTOP}" == "yes" ]]; then
		cat <<- EOF > ${MOUNT}/etc/mpv/mpv.conf
			fs=yes
			hwdec=rkmpp
			vd-lavc-o=afbc=on
			vf=scale_rkrga=force_yuv=8bit
			slang=zh,chi,cht
			alang=en,chi,cht
			sid=auto
		EOF
	fi
}

# 新增函数：禁用 U-Boot 中的 OPTEE 编译选项（核心3）
function pre_uboot_config__disable_optee_boca_tcn200() {
    display_alert "$BOARD" "Disabling OPTEE in U-Boot config" "info"
    # 编辑 U-Boot defconfig，显式关闭 CONFIG_OPTEE
    sed -i '/CONFIG_OPTEE=/d' ${UBOOT_DIR}/.config
    echo "# CONFIG_OPTEE is not set" >> ${UBOOT_DIR}/.config
    # 移除所有 OPTEE 相关配置
    sed -i '/CONFIG_CMD_OPTEE=/d' ${UBOOT_DIR}/.config
    sed -i '/CONFIG_OPTEE_MEM_BASE=/d' ${UBOOT_DIR}/.config
    sed -i '/CONFIG_OPTEE_MEM_SIZE=/d' ${UBOOT_DIR}/.config
}
