#!/bin/bash

######################
# ssh-tunnelr v1.0.4 #
######################

DST_FIRST_PORT=40000
QUIET=0

show_help () {
  echo "Usage: ssh-tunnelr [OPTIONS]"
  echo ""
  echo "Options :"
  echo "  -u, --user           User to authenticate to servers"
  echo "  -h, --hosts          Single host or hosts list separate by ','"
  echo "  -L, --forward-range  Port range to forward to endpoint"
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
	-L|--forward-range)
	  PORTS_RANGE=${2}
	  shift
	  ;;
	--help)
	  show_help
  	  exit
	  ;;
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
IFS=':' read -r -a PR   <<< "$PORTS_RANGE"

# checks
if [ "$USERNAME" = "" ]; then
  throw_error "Please specify username"
fi
if [ "$HOSTS" = "" ]; then
  throw_error "Please specify one host or more"
fi
if [ "$PORTS_RANGE" = "" ]; then
  throw_error "Please specify port range"
fi
if (( "${PR[0]}" > "${PR[1]}" )); then
  throw_error "Source port must be less than end port"
fi
if (( "${PR[0]}" < 1 )) || (( "${PR[1]}" < 1 )); then
  throw_error "Port must be greater than 1"
fi
if (( "${PR[0]}" > 65535 )) || (( "${PR[1]}" > 65535 )); then
  throw_error "Port must be less than 65535"
fi

CMD=""
# for each host
for ((i=0; i<${#HSTS[@]}; ++i)); do
  CMD="$CMD\nssh -t $USERNAME@${HSTS[$i]}\n"
  if (( $i == 0 )); then
	PORT="${PR[0]}"
  fi
  # for each port in range
  for ((j=${PR[0]}; j<=${PR[1]}; ++j)); do
	CMD="$CMD-L $PORT:localhost:$PORT\n"
	((PORT++))
  done
done

echo -e $CMD
CMD="$(echo -e $CMD)"
$CMD

#TODO:
#- Corriger Port[s] must be greater than ...
#- Prendre en charge des options ssh (-X, -t)
