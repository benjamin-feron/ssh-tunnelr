#!/bin/bash

####################
# ssh-tunnelr v1.2 #
####################

DST_FIRST_PORT=40000
DRY_MODE=0

show_help () {
  echo "Usage: ssh-tunnelr [OPTIONS]"
  echo ""
  echo "Options :"
  echo "  -u, --user           User to authenticate to servers"
  echo "  -h, --hosts          Single host or hosts list separate by ','"
  echo "  -f, --forward        Single port or range to forward to endpoint. You can specify simple port range e.g. 80:82."
  echo "                       You also can specify output port range with a third port number e.g. 7000:7002:80."
  echo "                       So port 7000 will be forwarded on port 80 of the endpoint, 7001 on 81 and 7002 on 82."
  echo "  -d, --dry            Dry mode, for test. With this option, ssh command is not launched, it's only shown."
  echo "  --help               Show help"
  echo ""
  echo "Example:               ssh-ranger -u username -h host.domain.com,172.16.1.11,10.5.1.10 -p 20000:20004"
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
	-f|--forward)
	  PORTS_RANGE=${2}
	  shift
	  ;;
	-d|--dry)
	  DRY_MODE=1
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

MAX_PORT_NUMBER=65535

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

# if single port specify
if (( "${#PR[@]}" == 1 )); then
  PR[1]=PR[0]
fi

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
if (( "${PR[0]}" < 1 )) || (( "${PR[1]}" < 1 )) || (( "${#PR[@]}" == 3 )) && (( "${PR[2]}" < 1)); then
#if (( "${PR[0]}" < 1 )) || (( "${PR[1]}" < 1 )); then
  throw_error "Ports numbers  must be greater than 1"
fi
if (( "${PR[0]}" > $MAX_PORT_NUMBER )) || \
   (( "${#PR[@]}" > 1 )) && (( "${PR[1]}" > $MAX_PORT_NUMBER )) || \
   (( "${#PR[@]}" > 2 )) && (( "${PR[2]}" > $MAX_PORT_NUMBER )); then
  throw_error "Ports numbers must be less than $MAX_PORT_NUMBER"
fi

CMD=""
# for each host
for ((i=0; i<${#HSTS[@]}; ++i)); do
  CMD="$CMD\nssh -t $USERNAME@${HSTS[$i]}\n"
  SRC_PORT="${PR[0]}"
  DST_PORT="${PR[0]}"
  CNT=0
  # for each port in range
  for ((j=${PR[0]}; j<=${PR[1]}; ++j)); do
  	# if output port is specified
    if [[ "$(( i + 1 ))" -eq "${#HSTS[@]}" && "${#PR[@]}" -eq "3" ]]; then
	  DST_PORT="$(( ${PR[2]} + $CNT ))"
	fi
	CMD="$CMD-L $SRC_PORT:localhost:$DST_PORT\n"
	(( SRC_PORT++ ))
	(( DST_PORT++ ))
	(( CNT++ ))
  done
done

echo -e $CMD
CMD="$(echo -e $CMD)"
if [ "$DRY_MODE" -eq "0" ]; then
  $CMD
fi

#TODO:
#- Prendre en charge des options ssh (-X, -t)
