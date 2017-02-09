if [ "$1x" == "x" ]; then
	xrandr --output DP2 --auto --primary --output eDP1 --auto --same-as DP2 --output DP1 --auto --right-of DP2
else
	xrandr --output DP2 --auto --primary --output DP1 --auto --right-of DP2 --output eDP1 --off
fi
exit 0
