DELETE_FROM_WORK_DIR "vendor" "tee"
mkdir -p "$WORK_DIR/vendor/tee"
SET_METADATA "vendor" "tee" 0 2000 755 "u:object_r:tee_file:s0"

if ! grep -q "tee_file (dir (mounton" "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"; then
    echo "(allow init_202404 tee_file (dir (mounton)))" >> "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"
    echo "(allow priv_app_202404 tee_file (dir (getattr)))" >> "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"
fi

SET_PROP "vendor" "ro.vendor.multitee.supported_bootloaders" "$(cat "$(dirname ${BASH_SOURCE[0]})/supported_bootloaders" | tr '\n' ',' | sed 's/,$//')"
SET_PROP "vendor" "ro.vendor.multitee.version" "$(cat "$(dirname ${BASH_SOURCE[0]})/module.prop" | grep 'version=' | sed 's/version=//')"
if git -C "$(dirname ${BASH_SOURCE[0]})" rev-parse --is-inside-work-tree &>/dev/null; then
    SET_PROP "vendor" "ro.vendor.multitee.revision" "$(git -C "$(dirname ${BASH_SOURCE[0]})" rev-parse --short=8 HEAD)"
fi
