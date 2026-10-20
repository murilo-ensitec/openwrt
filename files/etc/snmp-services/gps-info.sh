#!/bin/sh

ACTION="$1"
REQ_OID="$2"
BASE_OID=".1.3.6.1.4.1.48690.2"

# Helper to read single-line file contents safely
read_tmp() {
  FILE="$1"
  DEFAULT="$2"
  if [ -f "$FILE" ]; then
    VAL=$(cat "$FILE" 2>/dev/null | tr -d '\r\n')
    echo "${VAL:-$DEFAULT}"
  else
    echo "$DEFAULT"
  fi
}

# ==============================================================================
# DISTINCT HANDLER FUNCTIONS (READING FROM /tmp/)
# ==============================================================================

# .1.3.6.1.4.1.48690.2.1.0 -> modemNum
get_modemNum() {
  echo "$1"; echo "integer"; read_tmp "/tmp/modem_num" "1"
}

# .1.3.6.1.4.1.48690.2.1 -> mIndex
get_mIndex() {
  echo "$1"; echo "integer"; read_tmp "/tmp/modem_index" "1"
}

# .1.3.6.1.4.1.48690.2.1.2 -> mDescr
get_mDescr() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_descr" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.3 -> mImei
get_mImei() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_imei" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.4 -> mModel
get_mModel() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_model" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.5 -> mManufacturer
get_mManufacturer() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_manufacturer" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.6 -> mRevision
get_mRevision() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_revision" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.7 -> mSerial
get_mSerial() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_serial" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.8 -> mIMSI
get_mIMSI() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_imsi" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.9 -> mSimState
get_mSimState() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_sim_state" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.10 -> mPinState
get_mPinState() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_pin_state" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.11 -> mNetState
get_mNetState() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_net_state" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.12 -> mSignal
get_mSignal() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_signal" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.13 -> mOperator
get_mOperator() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_operator" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.14 -> mOperatorNumber
get_mOperatorNumber() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_operator_number" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.15 -> mConnectionState
get_mConnectionState() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_connection_state" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.16 -> mConnectionType
get_mConnectionType() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_connection_type" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.17 -> mTemperature
get_mTemperature() {
  echo "$1"; echo "integer"; read_tmp "/tmp/modem_temperature" "0"
}

# .1.3.6.1.4.1.48690.2.1.18 -> mCellID
get_mCellID() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_cell_id" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.19 -> mSINR
get_mSINR() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_sinr" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.20 -> mRSRP
get_mRSRP() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_rsrp" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.21 -> mRSRQ
get_mRSRQ() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_rsrq" "N/A"
}

# .1.3.6.1.4.1.48690.2.1.22 -> mSent
get_mSent() {
  echo "$1"; echo "counter64"; read_tmp "/tmp/modem_sent" "0"
}

# .1.3.6.1.4.1.48690.2.1.23 -> mReceived
get_mReceived() {
  echo "$1"; echo "counter64"; read_tmp "/tmp/modem_received" "0"
}

# .1.3.6.1.4.1.48690.2.1.24 -> mIP
get_mIP() {
  echo "$1"; echo "string"; read_tmp "/tmp/modem_ip" "0.0.0.0"
}

# .1.3.6.1.4.1.48690.2.1.25 -> mSentToday
get_mSentToday() {
  echo "$1"; echo "counter64"; read_tmp "/tmp/modem_sent_today" "0"
}

# .1.3.6.1.4.1.48690.2.1.26 -> mReceivedToday
get_mReceivedToday() {
  echo "$1"; echo "counter64"; read_tmp "/tmp/modem_received_today" "0"
}

# ==============================================================================
# GET REQUEST DISPATCHER
# ==============================================================================
get_info() {
  case "$1" in
    "${BASE_OID}"|"${BASE_OID}.1.0")                 get_modemNum "$1" ;;
    "${BASE_OID}.2.1"|"${BASE_OID}.2.1.1")           get_mIndex "$1" ;;
    "${BASE_OID}.2.1.2"|"${BASE_OID}.2.1.2")         get_mDescr "$1" ;;
    "${BASE_OID}.2.1.3"|"${BASE_OID}.2.1.3")         get_mImei "$1" ;;
    "${BASE_OID}.2.1.4"|"${BASE_OID}.2.1.4")         get_mModel "$1" ;;
    "${BASE_OID}.2.1.5"|"${BASE_OID}.2.1.5")         get_mManufacturer "$1" ;;
    "${BASE_OID}.2.1.6"|"${BASE_OID}.2.1.6")         get_mRevision "$1" ;;
    "${BASE_OID}.2.1.7"|"${BASE_OID}.2.1.7")         get_mSerial "$1" ;;
    "${BASE_OID}.2.1.8"|"${BASE_OID}.2.1.8")         get_mIMSI "$1" ;;
    "${BASE_OID}.2.1.9"|"${BASE_OID}.2.1.9")         get_mSimState "$1" ;;
    "${BASE_OID}.2.1.10"|"${BASE_OID}.2.1.10")       get_mPinState "$1" ;;
    "${BASE_OID}.2.1.11"|"${BASE_OID}.2.1.11")       get_mNetState "$1" ;;
    "${BASE_OID}.2.1.12"|"${BASE_OID}.2.1.12")       get_mSignal "$1" ;;
    "${BASE_OID}.2.1.13"|"${BASE_OID}.2.1.13")       get_mOperator "$1" ;;
    "${BASE_OID}.2.1.14"|"${BASE_OID}.2.1.14")       get_mOperatorNumber "$1" ;;
    "${BASE_OID}.2.1.15"|"${BASE_OID}.2.1.15")       get_mConnectionState "$1" ;;
    "${BASE_OID}.2.1.16"|"${BASE_OID}.2.1.16")       get_mConnectionType "$1" ;;
    "${BASE_OID}.2.1.17"|"${BASE_OID}.2.1.17")       get_mTemperature "$1" ;;
    "${BASE_OID}.2.1.18"|"${BASE_OID}.2.1.18")       get_mCellID "$1" ;;
    "${BASE_OID}.2.1.19"|"${BASE_OID}.2.1.19")       get_mSINR "$1" ;;
    "${BASE_OID}.2.1.20"|"${BASE_OID}.2.1.20")       get_mRSRP "$1" ;;
    "${BASE_OID}.2.1.21"|"${BASE_OID}.2.1.21")       get_mRSRQ "$1" ;;
    "${BASE_OID}.2.1.22"|"${BASE_OID}.2.1.22")       get_mSent "$1" ;;
    "${BASE_OID}.2.1.23"|"${BASE_OID}.2.1.23")       get_mReceived "$1" ;;
    "${BASE_OID}.2.1.24"|"${BASE_OID}.2.1.24")       get_mIP "$1" ;;
    "${BASE_OID}.2.1.25"|"${BASE_OID}.2.1.25")       get_mSentToday "$1" ;;
    "${BASE_OID}.2.1.26"|"${BASE_OID}.2.1.26")       get_mReceivedToday "$1" ;;
    *) return 1 ;;
  esac
}

# ==============================================================================
# GETNEXT REQUEST DISPATCHER (SNMPWALK)
# ==============================================================================
get_next() {
  case "$1" in
    "${BASE_OID}")                                   get_modemNum "${BASE_OID}.1.0" ;;
    "${BASE_OID}"|"${BASE_OID}.1.0")                 get_mIndex "${BASE_OID}.2.1.1" ;;
    "${BASE_OID}.2.1"|"${BASE_OID}.2.1.1")           get_mDescr "${BASE_OID}.2.1.2" ;;
    "${BASE_OID}.2.1.2"|"${BASE_OID}.2.1.2")         get_mImei "${BASE_OID}.2.1.3" ;;
    "${BASE_OID}.2.1.3"|"${BASE_OID}.2.1.3")         get_mModel "${BASE_OID}.2.1.4" ;;
    "${BASE_OID}.2.1.4"|"${BASE_OID}.2.1.4")         get_mManufacturer "${BASE_OID}.2.1.5" ;;
    "${BASE_OID}.2.1.5"|"${BASE_OID}.2.1.5")         get_mRevision "${BASE_OID}.2.1.6" ;;
    "${BASE_OID}.2.1.6"|"${BASE_OID}.2.1.6")         get_mSerial "${BASE_OID}.2.1.7" ;;
    "${BASE_OID}.2.1.7"|"${BASE_OID}.2.1.7")         get_mIMSI "${BASE_OID}.2.1.8" ;;
    "${BASE_OID}.2.1.8"|"${BASE_OID}.2.1.8")         get_mSimState "${BASE_OID}.2.1.9" ;;
    "${BASE_OID}.2.1.9"|"${BASE_OID}.2.1.9")         get_mPinState "${BASE_OID}.2.1.10" ;;
    "${BASE_OID}.2.1.10"|"${BASE_OID}.2.1.10")       get_mNetState "${BASE_OID}.2.1.11" ;;
    "${BASE_OID}.2.1.11"|"${BASE_OID}.2.1.11")       get_mSignal "${BASE_OID}.2.1.12" ;;
    "${BASE_OID}.2.1.12"|"${BASE_OID}.2.1.12")       get_mOperator "${BASE_OID}.2.1.13" ;;
    "${BASE_OID}.2.1.13"|"${BASE_OID}.2.1.13")       get_mOperatorNumber "${BASE_OID}.2.1.14" ;;
    "${BASE_OID}.2.1.14"|"${BASE_OID}.2.1.14")       get_mConnectionState "${BASE_OID}.2.1.15" ;;
    "${BASE_OID}.2.1.15"|"${BASE_OID}.2.1.15")       get_mConnectionType "${BASE_OID}.2.1.16" ;;
    "${BASE_OID}.2.1.16"|"${BASE_OID}.2.1.16")       get_mTemperature "${BASE_OID}.2.1.17" ;;
    "${BASE_OID}.2.1.17"|"${BASE_OID}.2.1.17")       get_mCellID "${BASE_OID}.2.1.18" ;;
    "${BASE_OID}.2.1.18"|"${BASE_OID}.2.1.18")       get_mSINR "${BASE_OID}.2.1.19" ;;
    "${BASE_OID}.2.1.19"|"${BASE_OID}.2.1.19")       get_mRSRP "${BASE_OID}.2.1.20" ;;
    "${BASE_OID}.2.1.20"|"${BASE_OID}.2.1.20")       get_mRSRQ "${BASE_OID}.2.1.21" ;;
    "${BASE_OID}.2.1.21"|"${BASE_OID}.2.1.21")       get_mSent "${BASE_OID}.2.1.22" ;;
    "${BASE_OID}.2.1.22"|"${BASE_OID}.2.1.22")       get_mReceived "${BASE_OID}.2.1.23" ;;
    "${BASE_OID}.2.1.23"|"${BASE_OID}.2.1.23")       get_mIP "${BASE_OID}.2.1.24" ;;
    "${BASE_OID}.2.1.24"|"${BASE_OID}.2.1.24")       get_mSentToday "${BASE_OID}.2.1.25" ;;
    "${BASE_OID}.2.1.25"|"${BASE_OID}.2.1.25")       get_mReceivedToday "${BASE_OID}.2.1.26" ;;
    *) return 1 ;;
  esac
}

# Execute action
if [ "$ACTION" = "-g" ]; then
  get_info "$REQ_OID"
elif [ "$ACTION" = "-n" ]; then
  get_next "$REQ_OID"
fi
