#!/bin/bash

####################
# ssh-tunnelr v1.3 #
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
  echo "                       This option can be repeated multiples times e.g -f 110:118 -f 7000:7002:80 -f 3306."
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
	  PORTS_RANGE="$PORTS_RANGE ${2}"
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
IFS=' ' read -r -a PRS  <<< "$PORTS_RANGE"

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

# construct ssh command
CMD=""
# for each host
for ((i=0; i<${#HSTS[@]}; ++i)); do
  CMD="$CMD\nssh $USERNAME@${HSTS[$i]}\n"

  # for each range in ports ranges
  for ((j=0; j<${#PRS[@]}; ++j)); do
    # unserialize range
    IFS=':' read -r -a PR <<< "${PRS[$j]}"

    # if single port specified
    if (( "${#PR[@]}" == 1 )); then
      PR[1]=${PR[0]}
      PR[2]=${PR[0]}
    # if simple range port specified
    #elif (( "${#PR[@]}" == 2 )); then
      #PR[2]=${PR[1]}
    fi

    SRC_PORT=${PR[0]}
    DST_PORT=${PR[0]}
  
  	# if last host AND out ports range specified
    if [[ "$(( i + 1 ))" -eq "${#HSTS[@]}" && "${#PR[@]}" -eq "3" ]]; then
	  DST_PORT=${PR[2]}
	fi

	# checks
	if (( $SRC_PORT < 1 )) || (( $DST_PORT < 1 )); then
	  throw_error "Ports numbers  must be greater than 1"
	fi
	if (( ${PR[0]} > ${PR[1]} )); then
	  throw_error "First port in range must be less than last port"
	fi

	# for each port in range
	for ((k=${PR[0]}; k<=${PR[1]}; ++k)); do
	  if (( $SRC_PORT > $MAX_PORT_NUMBER )) || (( $DST_PORT > $MAX_PORT_NUMBER )); then
		throw_error "Ports numbers  must be less than $MAX_PORT_NUMBER - $DST_PORT"
	  fi
	  CMD="$CMD-L $SRC_PORT:localhost:$DST_PORT\n"
	  (( SRC_PORT++ ))
	  (( DST_PORT++ ))
    done
  done
done

echo -e $CMD
CMD="$(echo -e $CMD)"
if [ "$DRY_MODE" -eq "0" ]; then
  $CMD
fi

#TODO:
#- Prendre en charge des options ssh (-X, -t)
