#!/bin/bash
set -euo pipefail

BIN="ESM_Firmware_KPCCC_LN32_2.92_A00.BIN"
OFFSET=$((0x445e00))
CRAMFS_SIZE=52207616
WORK="work"
OUT="output"

mkdir -p "$WORK" "$OUT"

cmd_extract() {
    echo "=== Extracting ==="
    GZIP_OFF=$(python3 -c "f=open('$BIN','rb'); d=f.read(); print(d.find(b'\x1f\x8b')); f.close()")
    echo "gzip payload at $GZIP_OFF"
    tail -c +$((GZIP_OFF + 1)) "$BIN" | gzip -d > "$WORK/payload.tar"
    tar xf "$WORK/payload.tar" -C "$WORK"
    dd if="$WORK/payload/firmimg.d6" of="$WORK/rootfs.cramfs" bs=1 skip=$OFFSET count=$CRAMFS_SIZE 2>/dev/null
    rm -rf "$WORK/rootfs_rw"
    7z x "$WORK/rootfs.cramfs" -o"$WORK/rootfs_rw" -y 2>&1 | tail -3 || true
}

cmd_patch() {
    echo "=== Patching ==="
    TPL="$WORK/rootfs_rw/usr/local/etc/appweb/appweb.conf.template"
    sed -i 's/^Listen ${AIM_HTTP_PORT}$/Listen [::]:${AIM_HTTP_PORT}/' "$TPL"
    sed -i 's/^Listen ${AIM_HTTPS_PORT}$/Listen [::]:${AIM_HTTPS_PORT}/' "$TPL"
    grep '^Listen' "$TPL"
}

cmd_repack() {
    echo "=== Repacking ==="
    if command -v mkfs.cramfs &>/dev/null; then
        sudo mkfs.cramfs -v "$WORK/rootfs_rw" "$WORK/rootfs_patched.cramfs" 2>&1 | tail -3
    else
        sudo mkcramfs -v -E "$WORK/rootfs_rw" "$WORK/rootfs_patched.cramfs" 2>&1 | tail -3
    fi
    dd if="$WORK/payload/firmimg.d6" of="$OUT/firmimg_patched.d6" bs=1 count=$OFFSET 2>/dev/null
    dd if="$WORK/rootfs_patched.cramfs" of="$OUT/firmimg_patched.d6" bs=1 seek=$OFFSET 2>/dev/null
    truncate -s $(wc -c < "$WORK/payload/firmimg.d6") "$OUT/firmimg_patched.d6"
}

cmd_verify() {
    echo "=== Verify ==="
    local img="$OUT/firmimg_patched.d6"
    local magic=$(python3 -c "f=open('$img','rb'); f.seek(0x200); print(f.read(4).hex()); f.close()")
    echo "uImage magic: $magic (expect 27051956)"
    [ "$magic" = "27051956" ] || { echo "FAIL"; exit 1; }
    local cm=$(python3 -c "f=open('$img','rb'); f.seek($OFFSET); b=f.read(4); print(f'{b[0]:02x} {b[1]:02x} {b[2]:02x} {b[3]:02x}'); f.close()")
    echo "CramFS bytes: $cm (expect 45 3d cd 28)"
    local cm_hex=$(echo "$cm" | tr -d ' ')
    [ "$cm_hex" = "453dcd28" ] || { echo "FAIL"; exit 1; }
    echo "PASS"
}

case "${1:-}" in
    extract) cmd_extract ;;
    patch)   cmd_patch ;;
    repack)  cmd_repack ;;
    verify)  cmd_verify ;;
    all)     cmd_extract; cmd_patch; cmd_repack; cmd_verify ;;
    *)       echo "Usage: $0 {extract|patch|repack|verify|all}"; exit 1 ;;
esac
