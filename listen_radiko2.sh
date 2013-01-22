#!/bin/bash

############################
## area_id	area_name
## JP1	HOKKAIDO JAPAN
## JP2	AOMORI JAPAN
## JP3	IWATE JAPAN
## JP4	MIYAGI JAPAN
## JP5	AKITA JAPAN
## JP6	YAMAGATA JAPAN
## JP7	FUKUSHIMA JAPAN
## JP8	IBARAKI JAPAN
## JP9	TOCHIGI JAPAN
## JP10	GUNMA JAPAN
## JP11	SAITAMA JAPAN
## JP12	CHIBA JAPAN
## JP13	TOKYO JAPAN
## JP14	KANAGAWA JAPAN
## JP15	NIIGATA JAPAN
## JP16	TOYAMA JAPAN
## JP17	ISHIKAWA JAPAN
## JP18	FUKUI JAPAN
## JP19	YAMANASHI JAPAN
## JP20	NAGANO JAPAN
## JP21	GIFU JAPAN
## JP22	SHIZUOKA JAPAN
## JP23	AICHI JAPAN
## JP24	MIE JAPAN
## JP25	SHIGA JAPAN
## JP26	KYOTO JAPAN
## JP27	OSAKA JAPAN
## JP28	HYOGO JAPAN
## JP29	NARA JAPAN
## JP30	WAKAYAMA JAPAN
## JP31	TOTTORI JAPAN
## JP32	SHIMANE JAPAN
## JP33	OKAYAMA JAPAN
## JP34	HIROSHIMA JAPAN
## JP35	YAMAGUCHI JAPAN
## JP36	TOKUSHIMA JAPAN
## JP37	KAGAWA JAPAN
## JP38	EHIME JAPAN
## JP39	KOUCHI JAPAN
## JP40	FUKUOKA JAPAN
## JP41	SAGA JAPAN
## JP42	NAGASAKI JAPAN
## JP43	KUMAMOTO JAPAN
## JP44	OHITA JAPAN
## JP45	MIYAZAKI JAPAN
## JP46	KAGOSHIMA JAPAN
## JP47	OKINAWA JAPAN
############################

### 上記を参照して視聴しているエリアのアリアコードを設定してください
ARIA="JP13"  ## デフォルト 東京

## GET ARIA CHANNEL LIST
## CH_LIST=(`curl -s http://radiko.jp/v2/station/list/${ARIA}.xml | xmlstarlet sel -t -m /radiko/stations/station -v "concat(@id,':',name)" -n `)

CH_LIST=(`curl -s http://radiko.jp/v2/api/program/today\?area_id=${ARIA} | xmlstarlet sel -t -m /radiko/stations/station -v "@id" -n`)

### ## echo ${CH_LIST[@]} for Debug
### show_usage() {
	### echo "Usage: $COMMAND [-o output_path] [-t recording_seconds] station_ID" 1>&2
### }

### # オプション解析
### COMMAND=`basename $0`
### while getopts o:t: OPTION
### do
   ### case $OPTION in
     ### o ) OPTION_o="TRUE" ; VALUE_o="$OPTARG" ;;
     ### ### t ) OPTION_t="TRUE" ; VALUE_t="$OPTARG" ;;
     ### * ) show_usage ; exit 1 ;;
	### esac
### done

### shift $(($OPTIND - 1)) #残りの非オプションな引数のみが、$@に設定される

### if [ $# = 0 ]; then
  ### show_usage ; exit 1
### fi


## playerurl=http://radiko.jp/player/swf/player_2.0.1.00.swf
playerurl=http://radiko.jp/player/swf/player_3.0.0.01.swf
playerfile=./player.swf
keyfile=./authkey.png

MPLAYER=/usr/bin/mplayer


if [ $# -eq 1 ]; then
  channel=$1
  output=./$1.flv
elif [ $# -eq 2 ]; then
  channel=$1
  output=$2
else
  echo "usage : $0 channel_name[${CH_LIST[@]}] [outputfile]"
curl -s http://radiko.jp/v2/api/program/today\?area_id=${ARIA} | xmlstarlet sel -t -m /radiko/stations/station -v "concat(@id,':',name)" -n | while read line; do
 	echo $line
 done

  exit 1
fi

#
# get player
#
if [ ! -f $playerfile ]; then
  wget -q -O $playerfile $playerurl

  if [ $? -ne 0 ]; then
    echo "failed get player"
    exit 1
  fi
fi

#
# get keydata (need swftools)
#
if [ ! -f $keyfile ]; then
  swfextract -b 14 $playerfile -o $keyfile

  if [ ! -f $keyfile ]; then
    echo "failed get keydata"
    exit 1
  fi
fi

if [ -f auth1_fms ]; then
  rm -f auth1_fms
fi

#
# access auth1_fms
#
wget -q \
     --header="pragma: no-cache" \
     --header="X-Radiko-App: pc_1" \
     --header="X-Radiko-App-Version: 2.0.1" \
     --header="X-Radiko-User: test-stream" \
     --header="X-Radiko-Device: pc" \
     --post-data='\r\n' \
     --no-check-certificate \
     --save-headers \
     --user-agent="Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)" \
     https://radiko.jp/v2/api/auth1_fms

if [ $? -ne 0 ]; then
  echo "failed auth1 process"
  exit 1
fi

#
# get partial key
#
authtoken=`cat auth1_fms | perl -ne 'print $1 if(/x-radiko-authtoken: ([\w-]+)/i)'`
offset=`cat auth1_fms | perl -ne 'print $1 if(/x-radiko-keyoffset: (\d+)/i)'`
length=`cat auth1_fms | perl -ne 'print $1 if(/x-radiko-keylength: (\d+)/i)'`

partialkey=`dd if=$keyfile bs=1 skip=${offset} count=${length} 2> /dev/null | base64`

echo "authtoken: ${authtoken} \noffset: ${offset} length: ${length} \npartialkey: $partialkey"

rm -f auth1_fms

if [ -f auth2_fms ]; then
  rm -f auth2_fms
fi

#
# access auth2_fms
#
wget -q \
     --header="pragma: no-cache" \
     --header="X-Radiko-App: pc_1" \
     --header="X-Radiko-App-Version: 2.0.1" \
     --header="X-Radiko-User: test-stream" \
     --header="X-Radiko-Device: pc" \
     --header="X-Radiko-Authtoken: ${authtoken}" \
     --header="X-Radiko-Partialkey: ${partialkey}" \
     --post-data='\r\n' \
     --no-check-certificate \
     --user-agent="Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)" \
     https://radiko.jp/v2/api/auth2_fms

if [ $? -ne 0 -o ! -f auth2_fms ]; then
  echo "failed auth2 process"
  exit 1
fi

echo "authentication success"

areaid=`cat auth2_fms | perl -ne 'print $1 if(/^([^,]+),/i)'`
echo "areaid: $areaid"

rm -f auth2_fms

#
# rtmpdump
#
rtmpdump -v \
	 -r "rtmpe://w-radiko.smartstream.ne.jp" \
	 --playpath "simul-stream.stream" \
	 --app "${channel}/_definst_" \
         -W $playerurl \
         -C S:"" -C S:"" -C S:"" -C S:$authtoken \
         --live \
         --flv - | ${MPLAYER} -
