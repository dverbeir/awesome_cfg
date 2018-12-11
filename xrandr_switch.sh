#!/bin/bash

CFG_LIST_FILE=$1
ACTION=${2:-0}
CURR_CFG_FILE=/var/run/xrandr_config

display=( $(xrandr | grep " connected" | awk '{ print $1 }') )

cfg_load()
{
	local tmp
	#IFS=$'\r\n' GLOBIGNORE='*' command eval  'CFGS=($(cat ${CFG_FILE_LIST}))'
	readarray tmp < "${CFG_LIST_FILE}"
	for l in "${tmp[@]}"; do
		if [[ ! $l =~ ^# ]]; then
			CFGS+=("$l")
		fi
	done
}

cfg_get()
{
	echo "${CFGS[$1]}"
}

cfg_num()
{
	echo "${#CFGS[@]}"
}


cfg_load

NUM_CFG=$(cfg_num)
echo "ACTION=$ACTION CFG_LIST_FILE=$CFG_LIST_FILE NUM_CFG=$NUM_CFG" > /tmp/xr

cfg=0
[ -f $CURR_CFG_FILE ] && cfg=$(cat $CURR_CFG_FILE)

if [ "x$ACTION" = "x0" ]; then
  cfg=0
elif [ "x$ACTION" = "x1" ]; then
  [ $cfg -le 0 ] && cfg=$((NUM_CFG-1)) || cfg=$((cfg-1))
else
  [ $cfg -ge $((NUM_CFG-1)) ] && cfg=0 || cfg=$((cfg+1))
fi

echo $cfg > $CURR_CFG_FILE

cfg_cmd=$(cfg_get $cfg)
echo "$cfg: $cfg_cmd" >> /tmp/xr
cmd=$(eval "echo ${cfg_cmd}")

echo $cmd >> /tmp/xr
xrandr $cmd

echo "Current config ($cfg): " >> /tmp/xr
xrandr >> /tmp/xr

exit 0
