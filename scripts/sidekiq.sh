#! /bin/sh

DISCOURSE_HOME="/opt/bitnami/apps/discourse/htdocs"
SIDEKIQ_PIDFILE=$DISCOURSE_HOME/log/sidekiq.pid
SIDEKIQ_LOGFILE="$DISCOURSE_HOME/log/sidekiq.log"
SIDEKIQ_START="/opt/bitnami/ruby/bin/ruby $DISCOURSE_HOME/bin/sidekiq -P $SIDEKIQ_PIDFILE -e production -L $SIDEKIQ_LOGFILE"
SIDEKIQ_STATUS=""
SIDEKIQ_PID=""
SIDEKIQ_STATUS=""
PID=""
ERROR=0
 
get_pid() {
    PID=""
    PIDFILE=$1
    # check for pidfile                                                                                          
    if [ -f $PIDFILE ] ; then
        PID=`cat $PIDFILE`
    fi
}

get_sidekiq_pid() {
    get_pid $SIDEKIQ_PIDFILE
    if [ ! $PID ]; then
        return
    fi
    if [ $PID -gt 0 ]; then
        SIDEKIQ_PID=$PID
    fi
}

is_service_running() {
    PID=$1
    if [ "x$PID" != "x" ] && kill -0 $PID 2>/dev/null ; then
        RUNNING=1
    else
        RUNNING=0
    fi
    return $RUNNING
}

is_sidekiq_running() {
    get_sidekiq_pid
    is_service_running $SIDEKIQ_PID
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        SIDEKIQ_STATUS="discourse_sidekiq not running"
    else
        SIDEKIQ_STATUS="discourse_sidekiq already running"
    fi
    return $RUNNING
}

start_sidekiq() {
    is_sidekiq_running
    RUNNING=$?
    if [ $RUNNING -eq 1 ]; then
        echo "$0 $ARG: discourse_sidekiq  (pid $SIDEKIQ_PID) already running"
        exit
    fi
    if [ `id -u` != 0 ]; then
        ((cd $DISCOURSE_HOME && $SIDEKIQ_START 2>&1) >/dev/null) &
    else
        su - daemon -s /bin/sh -c "((cd $DISCOURSE_HOME && $SIDEKIQ_START 2>&1) >/dev/null) &"
    fi
    COUNTER=10
    while [ $RUNNING -eq 0 ] && [ $COUNTER -ne 0 ]; do
        COUNTER=`expr $COUNTER - 1`
        sleep 3
        is_sidekiq_running
        RUNNING=$?
    done
    if [ $RUNNING -eq 0 ]; then
        ERROR=1
    fi

    if [ $ERROR -eq 0 ]; then
        echo "$0 $ARG: discourse_sidekiq started"
        sleep 2
    else
        echo "$0 $ARG: discourse_sidekiq could not be started"
        ERROR=3
    fi
}

stop_sidekiq() {
    NO_EXIT_ON_ERROR=$1
    is_sidekiq_running
    RUNNING=$?
    if [ $RUNNING -eq 0 ]; then
        echo "$0 $ARG: $SIDEKIQ_STATUS"
        if [ "x$NO_EXIT_ON_ERROR" != "xno_exit" ]; then
            exit
        else
            return
        fi
    fi

    kill $SIDEKIQ_PID
    COUNTER=10
    while [ $RUNNING -eq 1 ] && [ $COUNTER -ne 0 ]; do
        COUNTER=`expr $COUNTER - 1`
        sleep 3
        is_sidekiq_running
        RUNNING=$?
    done
    rm $SIDEKIQ_PIDFILE

    if [ $RUNNING -eq 0 ]; then
            echo "$0 $ARG: discourse_sidekiq stopped"
        else
            echo "$0 $ARG: discourse_sidekiq could not be stopped"
            ERROR=4
    fi
}

cleanpid() {
    rm -f $SIDEKIQ_PIDFILE
}

if [ "x$1" = "xstart" ]; then
    start_sidekiq
elif [ "x$1" = "xstop" ]; then
    stop_sidekiq
elif [ "x$1" = "xstatus" ]; then
    is_sidekiq_running
    echo "$SIDEKIQ_STATUS"
elif [ "x$1" = "xcleanpid" ]; then
    cleanpid
fi

exit $ERROR
