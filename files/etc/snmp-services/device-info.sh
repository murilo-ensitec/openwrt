#!/bin/sh

ACTION="$1"
REQ_OID="$2"
BASE_OID=".1.3.6.1.4.1.48690.1"

get_info() {
    case "$1" in
        "${BASE_OID}.0") 
            echo "device";;              # 1. serial
        "${BASE_OID}.1.0") 
            echo "${BASE_OID}.1.0"; echo "string"; echo "SN12345678" ;;              # 1. serial
        "${BASE_OID}.2.0") 
            echo "${BASE_OID}.2.0"; echo "string"; echo "Mxx" ;; # 2. deviceName
        "${BASE_OID}.3.0") 
            echo "${BASE_OID}.3.0"; echo "string"; echo "TEC-4G-Mxx" ;;              # 3. productCode
        "${BASE_OID}.4.0") 
            echo "${BASE_OID}.4.0"; echo "string"; echo "BATCH-2026-01" ;;          # 4. batchNumber
        "${BASE_OID}.5.0") 
            echo "${BASE_OID}.5.0"; echo "string"; echo "v1.2" ;;                   # 5. hardwareRevision
        "${BASE_OID}.6.0") 
            echo "${BASE_OID}.6.0"; echo "string"; echo "0.1" ;; # 6. fwVersion
        *) return 1 ;;
    esac
}

get_next() {
    case "$1" in
        "${BASE_OID}")                       get_info "${BASE_OID}.1.0" ;;
        "${BASE_OID}.1.0")   get_info "${BASE_OID}.2.0" ;;
        "${BASE_OID}.2.0")   get_info "${BASE_OID}.3.0" ;;
        "${BASE_OID}.3.0")   get_info "${BASE_OID}.4.0" ;;
        "${BASE_OID}.4.0")   get_info "${BASE_OID}.5.0" ;;
        "${BASE_OID}.5.0")   get_info "${BASE_OID}.6.0" ;;
        *) return 1 ;;
    esac
}

if [ "$ACTION" = "-g" ]; then
    get_info "$REQ_OID"
elif [ "$ACTION" = "-n" ]; then
    get_next "$REQ_OID"
fi
