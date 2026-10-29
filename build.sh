#!/bin/sh
set -e

# Build OpenWrt for EcoNet EN7528 (DASAN H660GM-A) from the MOST COMPLETE branch.
# e7528-gphy-pr (Sep 2026) is the cumulative tip: H660GM-A + DSA switch + UBI (persistent
# config) + pin controller + GPHY LED offload + flash-partition fix + Airtel/Generic variants.
BRANCH="e7528-gphy-pr"

git clone https://github.com/naseef/openwrt.git
cd openwrt || exit 1
git checkout "$BRANCH"
git --no-pager log -1 --oneline

./scripts/feeds update -a
./scripts/feeds install -a

cat > .config <<'CFG'
CONFIG_TARGET_econet=y
CONFIG_TARGET_econet_en7528=y
CONFIG_TARGET_MULTI_PROFILE=y
CONFIG_TARGET_DEVICE_econet_en7528_DEVICE_en7528_generic=y
CONFIG_TARGET_DEVICE_PACKAGES_econet_en7528_DEVICE_en7528_generic=""
CONFIG_TARGET_DEVICE_econet_en7528_DEVICE_dasan_h660gm-a-airtel=y
CONFIG_TARGET_DEVICE_PACKAGES_econet_en7528_DEVICE_dasan_h660gm-a-airtel=""
CONFIG_TARGET_DEVICE_econet_en7528_DEVICE_dasan_h660gm-a-generic=y
CONFIG_TARGET_DEVICE_PACKAGES_econet_en7528_DEVICE_dasan_h660gm-a-generic=""
CONFIG_TARGET_PER_DEVICE_ROOTFS=y
CONFIG_IMAGEOPT=y
# Wi-Fi (mt76: MT7603 2.4G + MT7615/MT7663 5G) - matches H660/H680 hardware
CONFIG_PACKAGE_kmod-cfg80211=y
CONFIG_PACKAGE_kmod-mac80211=y
CONFIG_PACKAGE_kmod-mt76-core=y
CONFIG_PACKAGE_kmod-mt76-connac=y
CONFIG_PACKAGE_kmod-mt7603=y
CONFIG_PACKAGE_kmod-mt7615-common=y
CONFIG_PACKAGE_kmod-mt7615e=y
CONFIG_PACKAGE_kmod-mt7663-firmware-ap=y
CONFIG_PACKAGE_hostapd-common=y
CONFIG_PACKAGE_wpad-basic-mbedtls=y
# Filesystems / USB / misc
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-usb2=y
CONFIG_PACKAGE_kmod-usb3=m
CONFIG_PACKAGE_iperf3=y
CONFIG_PACKAGE_tcpdump=y
# Also emit a RAM-bootable initramfs (for the zero-risk first-boot test via U-Boot)
CONFIG_TARGET_ROOTFS_INITRAMFS=y
CONFIG_TARGET_INITRAMFS_COMPRESSION_NONE=y
CFG

make defconfig
echo "=== Target devices selected ==="; grep -E 'DEVICE_(en7528_generic|dasan_h660gm-a)' .config || true
make "-j$(nproc)" V=s 2>&1 | tail -n 200 || { echo "BUILD FAILED"; exit 1; }

echo "=== Built images ==="
ls -la ./bin/targets/econet/en7528/ || true
