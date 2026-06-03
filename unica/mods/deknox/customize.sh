SET_PROP_IF_DIFF "vendor" "ro.security.fips.ux" "Disabled"

_DELETE_FROM_WORK_DIR_IF_EXISTS()
{
    local PARTITION="$1"
    local FILE="$2"
    local FILE_PATH="$WORK_DIR/$PARTITION/$FILE"

    if [ -e "$FILE_PATH" ] || [ -L "$FILE_PATH" ]; then
        DELETE_FROM_WORK_DIR "$PARTITION" "$FILE"
    fi
}

# KnoxGuard
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/priv-app/KnoxGuard"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/permissions/privapp-permissions-com.samsung.android.kgclient.xml"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/aidl_comm_kg_client.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/vendor.samsung.hardware.tlc.kg-V2-ndk.so"

# DualDAR
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/bin/dualdard"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/init/dualdard.rc"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/libdualdar.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/hidl_comm_ddar_client.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/vendor.samsung.hardware.tlc.ddar@1.0.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/libdualdar.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/aidl_comm_ddar_client.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/vendor.samsung.hardware.tlc.ddar-V1-ndk.so"

# Blockchain
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/app/BlockchainBasicKit"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/framework/service-samsung-blockchain.jar"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/sysconfig/preinstalled-packages-com.samsung.android.coldwalletservice.xml"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/hidl_tlc_blockchain_comm_client.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/libtlc_blockchain_comm.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/libtlc_blockchain_keystore.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/libtlc_blockchain_direct_comm.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/vendor.samsung.hardware.tlc.blockchain@1.0.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/blockchain_aidl_comm_client.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/libtlc_blockchain_comm.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/libtlc_blockchain_keystore.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/libtlc_blockchain_direct_comm.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/vendor.samsung.hardware.tlc.blockchain-V1-ndk.so"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FRAMEWORK_SUPPORT_BLOCKCHAIN_SERVICE" --delete

# Payment
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/hidl_tlc_payment_comm_client.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/libtlc_payment_direct_comm.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/libtlc_payment_spay.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/libtlc_payment_comm.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/vendor.samsung.hardware.tlc.payment@1.0.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/payment_aidl_comm_client.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/libtlc_payment_direct_comm.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/libtlc_payment_spay.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/libtlc_payment_comm.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/vendor.samsung.hardware.tlc.payment-V1-ndk.so"

# MPOS
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/permissions/privapp-permissions-com.samsung.android.knox.mpos.xml"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/permissions/com.samsung.android.nfc.mpos.xml"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/framework/com.samsung.android.nfc.mpos.jar"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/libhidl_comm_mpos_tui_client.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/vendor.samsung.hardware.mpos-V1-ndk.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/vendor.samsung.hardware.tlc.mpos_tui@1.0.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/libhidl_comm_mpos_tui_client.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/vendor.samsung.hardware.mpos-V1-ndk.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/vendor.samsung.hardware.tlc.mpos_tui@1.0.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/priv-app/KnoxMposAgent"

# eSE COS
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/bin/sem_daemon"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/init/sem_early.rc"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/permissions/privapp-permissions-com.sem.factoryapp.xml"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/libsec_sem.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/libsec_semAidl.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/libsec_semRil.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/libsec_semTlc.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/libspictrl.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/libspictrl.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/vendor.samsung.hardware.security.sem-V1-ndk.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/priv-app/SEMFactoryApp"

# ICCC
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/hidl_comm_iccc_client.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/vendor.samsung.hardware.tlc.iccc@1.0.so"

# UCM
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/libucm_esecomm_adapter.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/libucm_tlc_hidl_api.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/vendor.samsung.hardware.tlc.ucm@2.0.so"

# Weaver
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib/android.hardware.weaver@1.0.so"

# HDM
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/priv-app/HdmApk"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/permissions/privapp-permissions-com.samsung.android.hdmapp.xml"

# WSM
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/public.libraries-wsm.samsung.txt"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/libhal.wsm.samsung.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/vendor.samsung.hardware.security.wsm.service-V1-ndk.so"

# Knox ZeroTrust
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/permissions/privapp-permissions-com.samsung.android.knox.zt.framework.xml"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/priv-app/KnoxZtFramework"

# Knox Matrix
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/bin/fabric_crypto"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/init/fabric_crypto.rc"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/permissions/FabricCryptoLib.xml"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/permissions/privapp-permissions-com.samsung.android.kmxservice.xml"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/vintf/manifest/fabric_crypto_manifest.xml"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/framework/FabricCryptoLib.jar"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/com.samsung.security.fabric.cryptod-V1-cpp.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/vendor.samsung.hardware.security.fkeymaster-V1-cpp.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/lib64/vendor.samsung.hardware.security.fkeymaster-V1-ndk.so"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/priv-app/KmxService"

# Other Knox APKs
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/priv-app/KPECore"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/priv-app/KnoxCore"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/priv-app/KnoxERAgent"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/priv-app/KnoxFrameBufferProvider"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/priv-app/KnoxNetworkFilter"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/priv-app/KnoxNeuralNetworkRuntime"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/priv-app/KnoxPushManager"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/priv-app/KnoxSandbox"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/priv-app/knoxanalyticsagent"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/priv-app/knoxvpnproxyhandler"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/permissions/privapp-permissions-com.knox.vpn.proxyhandler.xml"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/permissions/privapp-permissions-com.samsung.android.knox.analytics.uploader.xml"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/permissions/privapp-permissions-com.samsung.android.knox.app.networkfilter.xml"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/permissions/privapp-permissions-com.samsung.android.knox.er.xml"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/permissions/privapp-permissions-com.samsung.android.knox.kfbp.xml"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/permissions/privapp-permissions-com.samsung.android.knox.knnr.xml"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/permissions/privapp-permissions-com.samsung.android.knox.kpecore.xml"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/permissions/privapp-permissions-com.samsung.android.knox.pushmanager.xml"
_DELETE_FROM_WORK_DIR_IF_EXISTS "system" "system/etc/permissions/privapp-permissions-com.samsung.android.knox.sandbox.xml"

unset -f _DELETE_FROM_WORK_DIR_IF_EXISTS
