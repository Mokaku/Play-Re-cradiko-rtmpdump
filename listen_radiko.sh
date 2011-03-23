#!/bin/bash

## #!/bin/sh

RTMPDUMP=/usr/local/bin/rtmpdump
MPLAYER=/usr/bin/mplayer

case "$1" in
  TBS|QRR|LFR|NSB|INT|FMT|FMJ)
    [ -f "${RTMPDUMP}" ] || exit 1
##    "${RTMPDUMP}" -vr rtmp://radiko.smartstream.ne.jp/"$1"/_defInst_/simul-stream | "${MPLAYER}" -
    "${RTMPDUMP}"  -vr rtmpe://radiko.smartstream.ne.jp/INT/_defInst_/simul-stream --flashVer "10.0" --app "${1}/_defInst_" -o - | ${MPLAYER} -
    echo "Connected Radiko channel $1"
    ;;
  *)
    echo $"Usage: $0 {TBS|QRR|LFR|NSB|INT|FMT|FMJ}"
    exit 2
esac
