#!/bin/bash

CFG_LIST_FILE=$1
ACTION=$2

NUM_CFG=$(wc -l $CFG_LIST_FILE | awk '{ print $1 }')
CURR_CFG_FILE=/var/run/xrandr_config

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

cmd=$(sed -n $(($cfg+1))p $CFG_LIST_FILE)
xrandr $cmd

echo "Current config ($cfg): "
xrandr

exit 0
