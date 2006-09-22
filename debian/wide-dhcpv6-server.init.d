#!/bin/sh
#
# Start/stop the wide-dhcpv6 server
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin
DHCP6SBIN=/usr/sbin/dhcp6s
DHCP6SPID=/var/run/dhcp6s.pid
NAME="dhcp6s"
DESC="WIDE DHCPv6 server"

test -x $DHCP6SBIN || exit 0

if [ ! -f /etc/default/wide-dhcpv6-server ]; then
	echo "/etc/default/wide-dhcpv6-server does not exist! - Aborting..."
	echo "Run 'dpkg-reconfigure wide-dhcpv6-server' to solve the problem."
	exit 1
fi

. /etc/default/wide-dhcpv6-server

[ "X$INTERFACES" != "X" ] || exit 0

# single arg is -v for messages, -q for none
check_status()
{
    if [ ! -r "$DHCP6SPID" ]; then
        test "$1" != -v || echo "$NAME is not running."
        return 3
    fi
    if read pid < "$DHCP6SPID" && ps -p "$pid" > /dev/null 2>&1; then
        test "$1" != -v || echo "$NAME is running."
        return 0
    else
        test "$1" != -v || echo "$NAME is not running but $DHCP6SPID exists."
        return 1
    fi
}

case "$1" in
	start)
		echo -n "Starting $DESC: "
		start-stop-daemon --start --quiet --pidfile $DHCP6SPID \
			--exec $DHCP6SBIN -- $INTERFACES
		sleep 2
		if check_status -q; then
			echo "$NAME."
		else
			echo "$NAME failed to start."
			exit 1
		fi
		;;
	stop)
		echo -n "Stopping $DESC: $NAME"
		start-stop-daemon --stop --quiet --pidfile $DHCP6SPID
		rm -f $DHCP6SPID
		echo "."
		;;
	restart|force-reload)
		$0 stop
		sleep 2
		$0 start
		if [ "$?" != "0" ]; then
			exit 1
		fi
		;;
	status)
		echo "Status of $NAME: "
		check_status -v
		exit "$?"
		;;
	*)
		echo "Usage: $0 (start|stop|restart|force-reload|status)"
		exit 1
esac

exit 0
