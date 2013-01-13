#!/bin/bash

quote ()
{
  [[ ${!1} =~ [\ \&] ]] && read $1 <<< \"${!1}\"
}

warn ()
{
  printf "\e[36m%s\e[m\n" "$*"
}

pgrep ()
{
  ps -W | awk /$1/'{print$4;exit}'
}

pkill ()
{
  pgrep $1 | xargs kill -f
}

log ()
{
  local pp
  for oo
  do
    quote oo
    pp+=("$oo")
  done
  warn "${pp[@]}"
  eval "${pp[@]}"
}

qsplit ()
{
  IFS=\" read -a $1 <<< "${!2}"
}

usage ()
{
  echo "usage: $0 DELAY CDN FILETYPE TITLE"
  echo
  echo "To see available CDNs and filetypes run script with just DELAY."
  exit
}

clean ()
{
  rm -f a.flv pg.core
  exit
}

serialize ()
{
  xs=${REPLY}
  xs=${xs#* }
  xs=${xs%/>}
  qsplit xa xs
  aa=0
  while [ ${xa[aa]} ]
  do
    read ${xa[aa]//[-:=]} <<< ${xa[aa+1]}
    (( aa += 2 ))
  done
}

[ $1 ] || usage
pc=plugin-container
pkill $pc
echo ProtectedMode=0 2>/dev/null >$WINDIR/system32/macromed/flash/mms.cfg
warn 'Killed flash player for clean dump.
Script will automatically continue after video is restarted.'

until read < <(pgrep $pc)
do
  sleep 1
done

sleep $1
shift
rm -f pg.core
dumper pg $REPLY &

until [ -s pg.core ]
do
  sleep 1
done

kill -13 %%

while read
do
  serialize
  if ! [ $1 ]
  then
    printf "%-9s  %9s\n" "$cdn" "$filetype"
  elif [ $cdn$filetype = $1$2 ]
  then
    break
  fi
done < <(grep -aoz "<video [^>]*>" pg.core | sort | uniq -w123)

[ $1 ] || clean

log rtmpdump \
  -o a.flv \
  -W http://download.hulu.com/huludesktop.swf \
  -r "$server" \
  -y "$stream" \
  -a "${server#*//*/}?${token//amp;}"

shift 2
log ffmpeg -i a.flv -c copy -v warning "$*.mp4"
clean
