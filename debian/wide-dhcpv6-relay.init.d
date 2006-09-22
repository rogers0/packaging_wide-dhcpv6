#!/bin/sh
#
# Start/stop the wide-dhcpv6 relay
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin
DHCP6RBIN=/usr/sbin/dhcp6relay
DHCP6RPID=/var/run/dhcp6relay.pid
NAME="dhcp6relay"
DESC="WIDE DHCPv6 relay"

test -x $DHCP6RBIN || exit 0

if [ ! -f /etc/default/wide-dhcpv6-relay ]; then
	echo "/etc/default/wide-dhcpv6-relay does not exist! - Aborting..."
	echo "Run 'dpkg-reconfigure wide-dhcpv6-relay' to solve the problem."
	exit 1
fi

. /etc/default/wide-dhcpv6-relay

[ "X$INTERFACES" != "X" ] || exit 0

# single arg is -v for messages, -q for none
check_status()
{
    if [ ! -r "$DHCP6RPID" ]; then
        test "$1" != -v || echo "$NAME is not running."
        return 3
    fi
    if read pid < "$DHCP6RPID" && ps -p "$pid" > /dev/null 2>&1; then
        test "$1" != -v || echo "$NAME is running."
        return 0
    else
        test "$1" != -v || echo "$NAME is not running but $DHCP6RPID exists."
        return 1
    fi
}

case "$1" in
	start)
		echo -n "Starting $DESC: "
		start-stop-daemon --start --quiet --pidfile $DHCP6RPID \
			--exec $DHCP6RBIN -- $INTERFACES
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
		start-stop-daemon --stop --quiet --pidfile $DHCP6RPID
		rm -f $DHCP6RPID
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
