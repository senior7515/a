#!/bin/bash
# FIXME check for RtmpSrv RtmpDumpHelper on PATH

warn ()
{
  echo -e "\e[1;35m$@\e[m"
}

pgrep ()
{
  ps -W | awk /$1/'{print$4;exit}'
}

pkill ()
{
  pgrep $1 | xargs kill -f
}

try ()
{
  warn "$@"
  eval "$@"
}

pc=plugin-container
pkill $pc
pkill rtmpdumphelper
echo ProtectedMode=0 2>/dev/null >$WINDIR/system32/macromed/flash/mms.cfg
warn 'This script requires RtmpSrv v2.4-46 or higher.
Killed flash player for clean dump.
Restart video then press enter here.'
read

until read < <(pgrep $pc)
  do
    warn "$pc not found!"
    read
  done

rm -f pg.core
dumper pg $REPLY &

until [ -s pg.core ]
  do
    sleep 1
  done

warn 'Press enter to start RtmpDumpHelper, then restart video.'
read

LANG= grep -Eaom1 '(RTMP|rtmp).{0,2}://[-.0-z]+' pg.core |
  cut -d: -f3 > tp

read < tp
echo "[general]
autorunproxyserver=0
captureportslist=1935 $REPLY
usecaptureportslist=1" > /usr/local/bin/rtmpdumphelper.cfg
rtmpdumphelper &
read < <(rtmpsrv -i)
pkill rtmpdumphelper
declare -a aa="($REPLY)"
declare -A ab

while getopts "C:W:a:f:o:p:r:y:" opt "${aa[@]:1}"
  do
    ab[$opt]="$OPTARG"
  done

tr "[:cntrl:]" "\n" < pg.core |
  grep -1m1 secureTokenResponse |
  tac > tp

read ab[T] < tp
rm pg.core tp

try rtmpdump -o a.flv -r "${ab[r]}" ||
try rtmpdump -o a.flv -r "${ab[r]}" -y "${ab[y]}" ||
try rtmpdump -o a.flv -r "${ab[r]}" -y "${ab[y]}" -v ||
try rtmpdump -o a.flv -r "${ab[r]}" -y "${ab[y]}" -a "${ab[a]}" ||
try rtmpdump -o a.flv -r "${ab[r]}" -y "${ab[y]}" -T "${ab[T]}" -W "${ab[W]}" ||
try rtmpdump -o a.flv -r "${ab[r]}" -y "${ab[y]}" -T "${ab[T]}" -p "${ab[p]}"
