#!/bin/sh
### BEGIN INIT INFO
# Provides:          wide-dhcpv6-server
# Required-Start:    $syslog $network $remote_fs
# Required-Stop:     $syslog $remote_fs
# Should-Start:      $local_fs
# Should-Stop:       $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start/Stop WIDE DHCPv6 server
# Description:       (empty)
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin
DHCP6SBIN=/usr/sbin/dhcp6s
DHCP6SPIDBASE=/var/run/dhcp6s
NAME="dhcp6s"
DESC="WIDE DHCPv6 server"

STOP_RETRY_SCHEDULE='TERM/20/forever/KILL/1'

. /lib/lsb/init-functions

test -x $DHCP6SBIN || exit 0

if [ ! -f /etc/default/wide-dhcpv6-server ]; then
	exit 0
else
	. /etc/default/wide-dhcpv6-server
fi


[ "X$INTERFACES" != "X" ] || exit 0

case "$VERBOSE" in
    1)  DEBUG="-d"
        ;;
    2)  DEBUG="-D"
        ;;
    *)  DEBUG=""
esac

# single arg is -v for messages, -q for none
check_status()
{
    for INT in $INTERFACES; do
        if [ ! -r "${DHCP6SPIDBASE}.${INT}.pid" ]; then
            test "$1" != -v || echo "$NAME is not running on ${INT}."
            return 3
        fi
        if read pid < "${DHCP6SPIDBASE}.${INT}.pid" && ps -p "$pid" > /dev/null 2>&1; then
            test "$1" != -v || echo "$NAME is running on ${INT}."
            return 0
        else
            test "$1" != -v || echo "$NAME is not running on ${INT} but ${DHCP6SPIDBASE}.${INT}.pid exists."
            return 1
        fi
    done
}

case "$1" in
	start)
                for INT in $INTERFACES; do
                    log_daemon_msg "Starting $DESC on $INT" "$NAME"
		    start-stop-daemon --start --quiet --pidfile ${DHCP6SPIDBASE}.${INT}.pid \
			--exec $DHCP6SBIN --oknodo -- $DEBUG -k /dev/null -P ${DHCP6SPIDBASE}.${INT}.pid $INT
		    sleep 2
		    if check_status -q; then
                        log_end_msg 0
                    else
                        log_end_msg 1
                        exit 1
                    fi
                done
		;;
	stop)
                for INT in $INTERFACES; do
                    log_daemon_msg "Stopping $DESC on $INT" "$NAME"
                    start-stop-daemon --stop --quiet --retry $STOP_RETRY_SCHEDULE \
                        --pidfile ${DHCP6SPIDBASE}.${INT}.pid --oknodo
                    log_end_msg $?
                    rm -f $DHCP6SPID
                done
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
