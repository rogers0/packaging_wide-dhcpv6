#!/bin/sh
#
# Start/stop the wide-dhcpv6 client
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin
DHCP6CBIN=/usr/sbin/dhcp6c
DHCP6CPID=/var/run/dhcp6c.pid
NAME="dhcp6c"
DESC="WIDE DHCPv6 client"

test -x $DHCP6CBIN || exit 0

if [ ! -f /etc/default/wide-dhcpv6-client ]; then
	echo "/etc/default/wide-dhcpv6-client does not exist! - Aborting..."
	echo "Run 'dpkg-reconfigure wide-dhcpv6-client' to solve the problem."
	exit 1
fi

. /etc/default/wide-dhcpv6-client

[ "X$INTERFACES" != "X" ] || exit 0

# single arg is -v for messages, -q for none
check_status()
{
    if [ ! -r "$DHCP6CPID" ]; then
        test "$1" != -v || echo "$NAME is not running."
        return 3
    fi
    if read pid < "$DHCP6CPID" && ps -p "$pid" > /dev/null 2>&1; then
        test "$1" != -v || echo "$NAME is running."
        return 0
    else
        test "$1" != -v || echo "$NAME is not running but $DHCP6CPID exists."
        return 1
    fi
}

case "$1" in
	start)
		echo -n "Starting $DESC: "
		start-stop-daemon --start --quiet --pidfile $DHCP6CPID \
			--exec $DHCP6CBIN -- $INTERFACES
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
		start-stop-daemon --stop --quiet --pidfile $DHCP6CPID
		rm -f $DHCP6CPID
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
