# Enable RAW Support
# Before: [tbz w8, #0, 0x59fd3c]
# After: [nop]
HEX_PATCH "$WORK_DIR/vendor/lib64/libexynoscamera3.so" "88020036a10d0090" "1f2003d5a10d0090"
