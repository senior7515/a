#!/bin/bash
/\\ 2>/dev/null
p=plugin-container

die(){
  echo -e "\e[1;31m$1\e[m"
  exit
}

warn(){
  echo -e "\e[1;35m$1\e[m"
  read
}

pidof(){
  ps -W | grep $1 | cut -c-9
}

killall(){
  pidof $1 | xargs /bin/kill -f
}

killall $p
echo ProtectedMode=0 >\\windows/system32/macromed/flash/mms.cfg
warn 'Killed flash player for clean dump.
Restart video then press enter here'
read < <(pidof $p) || die "$p not found!"
rm -f p.core
dumper p $REPLY &
until [ -s p.core ]; do sleep 1; done
mapfile vids < <(grep -aoz "<video [^>]*>" p.core | sort | uniq -w123)
declare -A attr

for i in "${!vids[@]}"; do
  IFS=\" read -a vid <<< "${vids[i]}"
  j=0
  while [[ "${vid[j]}" =~ \ ([^=]*) ]]; do
    attr[$i,${BASH_REMATCH[1]}]="${vid[j+1]}"
    ((j+=2))
  done
  printf "%2d\t%9s\t%s\n" "$i" "${attr[$i,file-type]}" "${attr[$i,cdn]}"
done

warn 'Make choice. Avoid level3.'
set -x
rtmpdump \
-W "http://download.hulu.com/huludesktop.swf" \
-a "${attr[$REPLY,server]#*//*/}?${attr[$REPLY,token]//amp;}" \
-o "out.flv" \
-r "${attr[$REPLY,server]}" \
-y "${attr[$REPLY,stream]}"
