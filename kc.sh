#!/bin/bash

for i in docker curl jq; do
    which $i > /dev/null
done

KCCONTAINER=$CONTAINER
if [ -z $CONTAINER ]; then
    KCCONTAINER=`docker ps | grep cp-kafka | head -1 | awk '{print $1}'`
fi

KCHOST=`docker inspect $KCCONTAINER | jq -r '.[].Config.Hostname'`
KCPORT=`docker inspect $KCCONTAINER | jq -r '.[].Config.Env' | grep REST_PORT | grep -Po "\d+"`
KCMETHOD="GET"
KCHEADERS=""
KCPROTOCOL="http"
KCPAYLOAD=""
KCCONNECTOR=${1-"?expand=status"}
KCAPIPATH="/connectors/$KCCONNECTOR"
command="$2"

exec()
{
    if [ ! -z $KCPAYLOAD ]; then
            echo "curl -X $KCMETHOD $KCHEADERS $KCPROTOCOL://$KCHOST:$KCPORT$KCAPIPATH -d $KCPAYLOAD"
            output=`curl -sS -X $KCMETHOD $KCHEADERS "$KCPROTOCOL://$KCHOST:$KCPORT$KCAPIPATH" -d $KCPAYLOAD 2>&1`
    else
            echo "curl -X $KCMETHOD $KCHEADERS $KCPROTOCOL://$KCHOST:$KCPORT$KCAPIPATH"
            output=`curl -sS -X $KCMETHOD $KCHEADERS "$KCPROTOCOL://$KCHOST:$KCPORT$KCAPIPATH" 2>&1`
    fi

    if [ $? -gt 0 ]; then
            echo $output
    else
            echo $output | jq
    fi
}

config()
{
    KCAPIPATH=$KCAPIPATH"/config"
    file=${1-}

    if [ -n "$file" ]; then
            KCPAYLOAD="-d @$file"
            KCMETHOD="POST"
            KCHEADERS="-H Content-Type:application/json"
    fi
}

delete()
{
    KCMETHOD="DELETE"
}

pause()
{
    KCAPIPATH=$KCAPIPATH"/pause"
    KCMETHOD="PUT"
}

resume()
{
    KCAPIPATH=$KCAPIPATH"/resume"
    KCMETHOD="PUT"
}

restart()
{
    KCAPIPATH=$KCAPIPATH"/restart"
    KCMETHOD="POST"
}

tasks()
{
    KCAPIPATH=$KCAPIPATH"/tasks"
    task=${1-}
    action=${2-status}

    if [ -n "$task" ]; then
            KCAPIPATH=$KCAPIPATH"/$task/$action"
            if [ "$action" = "restart" ]; then
                    KCMETHOD="POST"
            fi
    fi
}

topics()
{
    KCAPIPATH=$KCAPIPATH"/topics"
    action=${1-}

    if [ -n "$action" ]; then
            KCAPIPATH=$KCAPIPATH"/$action"
            if [ "$action" = "reset" ]; then
                    KCMETHOD="PUT"
            fi
    fi
}

connectors()
{
    KCAPIPATH="/connectors"
}

plugins()
{
    KCAPIPATH="/connector-plugins"
    plugin=${2-}
    action=${3-validate}
    file=${4-}

    if [ -n "$plugin" ]; then
            KCAPIPATH=$KCAPIPATH"/$plugin"
            if [ "$action" = "validate" ]; then
                    KCAPIPATH=$KCAPIPATH"/config/$action"
                    if [ -n "$file" ]; then
                            KCPAYLOAD="@$file"
                            KCMETHOD="PUT"
                            KCHEADERS="-H Content-Type:application/json"
                    fi

            fi
    fi
}

logging()
{
    KCAPIPATH="/admin/loggers"
    logger=${2-root}
    level=${3-INFO}

    if [ -n "$3" ]; then
            KCAPIPATH=$KCAPIPATH"/$logger"

            case "$level" in
                "ERROR" | "WARN" | "INFO" | "DEBUG" | "TRACE" )
                KCPAYLOAD='{"level":"'$level'"}'
                ;;
              *)
            esac

            KCMETHOD="PUT"
            KCHEADERS="-H Content-Type:application/json"
    fi
}

help()
{
	echo "usage:    $0
        $0 connectors | logging | help
        $0 plugins { <plugin> validate plugin-config.json }
        $0 <connector> { delete
                         pause
                         resume
                         restart
                         topics
                         topics reset
                         tasks
                         tasks <num>
                         tasks <num> status | restart
                         config
                         config config-file.json }
        $0 logging { ERROR | WARN | INFO | DEBUG | TRACE }
"
   KCAPIPATH="/"
}

# generic actions
case "$KCCONNECTOR" in
  "connectors" | "plugins" | "logging" | "help" )
        "$KCCONNECTOR" "$@"
        exec
        exit
        ;;
  *)
        ;;
esac

shift 2

# connector actions
case "$command" in
  "delete" | "pause" | "resume" | "restart" | "tasks" | "topics" | "config" | "help" )
        "$command" "$@"
        ;;
  *)
        ;;
esac

exec
