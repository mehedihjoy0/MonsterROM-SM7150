LOG_STEP_IN "- Increasing speaker volume values to 90"
EVAL "sed -i -E '/WSA_RX[01] Digital Volume/s/value=\"[^\"]*\"/value=\"90\"/' \
\"$WORK_DIR\"/vendor/etc/mixer_paths*.xml"
LOG_STEP_OUT

ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "etc/selinux/mapping/30.0.cil"
