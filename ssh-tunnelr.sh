#!/bin/bash

######################
# ssh-tunnelr v1.0.1 #
######################

DST_FIRST_PORT=40000
QUIET=0

show_help () {
  echo "Usage: ssh-ranger [OPTIONS]"
  echo ""
  echo "Options :"
  echo "  -u, --user           User to authenticate to servers"
  echo "  -h, --hosts          Single host or hosts list separate by ','"
  echo "  -p, --port-range     Port range to dig. In other words, port range to tunnel to end point."
  echo "  -b, --bounce-port    First port number of internal bounces port ranges. Default value: 40000."
  echo "  --help               Show help"
  echo ""
  echo "example:               ssh-ranger -u username -h host.domain.com,172.16.1.11,10.5.1.10 -p 20000:20004 -b 17000"
  echo ""
}

while :; do
  case $1 in
	-u|--user)
	  USERNAME=${2}
	  shift
	  ;;
	-h|--host)
	  HOSTS=${2}
	  shift
	  ;;
	-p|--port-range)
	  SRC_PORTS_RANGE=${2}
	  shift
	  ;;
	-b|--bounce-port)
	  DST_FIRST_PORT=${2}
	  shift
	  ;;
	--help)
	  show_help
  	  exit
	  ;;
#	-v|--verbose)
#	  VERBOSE=$((verbose + 1))
#	  ;;
#	-q|--quiet)
#	  QUIET=1
#	  ;;
#	--)
#	  shift
#	  break
#	  ;;
	-?*)
	  printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
	  ;;
	*)
	  break
  esac
  shift
done

throw_error () {
  MSG=$1
  EXIT=$2

  STD_MSG="Command stopped"

  printf "\033[0;31m$MSG\033[0m\n"
  echo "$STD_MSG"
  if $EXIT ; then
  	exit 1
  fi
}

# unserialize data
IFS=',' read -r -a HSTS <<< "$HOSTS"
IFS=':' read -r -a SPR  <<< "$SRC_PORTS_RANGE"

# checks
if [ "$USERNAME" = "" ]; then
  throw_error "Please specify username"
fi
if [ "$HOSTS" = "" ]; then
  throw_error "Please specify one host or more"
fi
if [ "$SRC_PORTS_RANGE" = "" ]; then
  throw_error "Please specify port range"
fi
if (( "${SPR[0]}" > "${SPR[1]}" )); then
  throw_error "Source port must be less than end port"
fi
if (( "${SPR[0]}" < 1 )) || (( "${SPR[1]}" < 1 )) || (( "$DST_FIRST_PORT" < 1 )); then
  throw_error "Port must be greater than 1"
fi
if (( "${SPR[0]}" > 65535 )) || (( "${SPR[1]}" > 65535 )) || (( "$DST_FIRST_PORT > 65535 ")); then
  throw_error "Port must be less than 65535"
fi

CMD=""
# for each host
for ((i=0; i<${#HSTS[@]}; ++i)); do
  CMD="$CMD\nssh -t $USERNAME@${HSTS[$i]}\n"
  if (( $i == 0 )); then
	SRC_PORT="${SPR[0]}"
	DST_PORT=$DST_FIRST_PORT
  elif [[ "$(( i + 1 ))" -lt "${#HSTS[@]}" ]]; then
	SRC_PORT=$DST_FIRST_PORT
	DST_PORT=$DST_FIRST_PORT
  else
	SRC_PORT=$DST_FIRST_PORT
	DST_PORT="${SPR[0]}"
  fi
  for ((j=${SPR[0]}; j<=${SPR[1]}; ++j)); do
	CMD="$CMD-L $SRC_PORT:localhost:$DST_PORT\n"
	((SRC_PORT++))
	((DST_PORT++))
  done
done

echo -e $CMD
CMD="$(echo -e $CMD)"
$CMD

TODO:
- Corriger Port[s] must be greater than ...
- Prendre en charge des options ssh (-X, -t)
