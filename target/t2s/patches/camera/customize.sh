# Clamp voice-command TFLite CPU topology lookups to the first record when the
# source runtime requests a core index that is not exposed by Exynos2100.
HEX_PATCH "$WORK_DIR/system/system/lib64/libtensorflowlite_jni_voicecommand.so" \
    "080140f9290140b90851208b1f00096b00319f9ac0035fd6" \
    "080140f9290140b91f00096b00309f1a0051208bc0035fd6"

# Fall back to the first CPU topology record when the donor TFLite runtime requests
# an index that is not exposed by the target Exynos2100 cpuinfo implementation.
HEX_PATCH "$WORK_DIR/system/system/lib64/libtensorflowlite_c.2.16.1.camera.samsung.so" \
    "080140f9290140b91f2003d50820aa9b3f01006b00819f9ac0035fd6" \
    "080140f9290140b9eb0308aa0820aa9b3f01006b00818b9ac0035fd6"
