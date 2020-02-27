#!/bin/bash

IFS=$'\n'

declare -i NAME_CURSOR=0
declare -i PROCESS_CURSOR=-1
declare -i START_INDEX=0

NAME_SORT=''
PID_SORT='-'

function Show()
{
	declare -i INDEX

	# Check exceptions
	if [ ${#PID_LIST[@]} -le 20 ]; then
		if [ $PROCESS_CURSOR -ge ${#PID_LIST[@]} ]; then
			PROCESS_CURSOR=$((${#PID_LIST[@]} - 1))
		fi
	else
		if [ $START_INDEX -gt $((${#PID_LIST[@]} - 20)) ]; then
			START_INDEX=$((${#PID_LIST[@]} - 20))
		fi
	fi

	# Clear
	clear

	# Logo
	echo '______                     _    _             '
	echo '| ___ \                   | |  (_)            '
	echo '| |_/ / _ __   __ _   ___ | |_  _   ___   ___ '
	echo '|  __/ |  __| / _  | / __|| __|| | / __| / _ \'
	echo '| |    | |   | (_| || (__ | |_ | || (__ |  __/'
	echo '\_|    |_|    \__,_| \___| \__||_| \___| \___|'
	echo '                                              '
	echo '(_)       | |    (_)                          '
	echo ' _  _ __  | |     _  _ __   _   _ __  __      '
	echo '| ||  _ \ | |    | ||  _ \ | | | |\ \/ /      '
	echo '| || | | || |___ | || | | || |_| | >  <       '
	echo '|_||_| |_|\_____/|_||_| |_| \__,_|/_/\_\      '
	echo '                                              '

	# Header
	echo '-NAME-----------------CMD--------------------PID-----STIME-----'

	# Body
	for i in $(seq 0 19)
	do
		printf '|'

		if [ $i -eq $NAME_CURSOR ]; then
			printf '\e[41m'
		fi

		printf '%20s\e[0m|' ${NAME_LIST[$i]:0:20}

		if [ $i -eq $PROCESS_CURSOR ]; then
			printf '\e[42m'
		fi

		INDEX=$START_INDEX+$i
		STAT=' '
		
		if [ ${STAT_LIST[$INDEX]} ]; then
			[ "${STAT_LIST[$INDEX]}" = '+' ] && STAT='F' || STAT='B'
		fi

		printf '%s %-20s|' $STAT ${CMD_LIST[$INDEX]:0:20}
		printf '%7s|' ${PID_LIST[$INDEX]:0:7}
		printf '%9s\e[0m|\n' ${STIME_LIST[$INDEX]:0:9}
	done

	# Footer
	echo '---------------------------------------------------------------'
}

function NoPermission()
{
	# Clear
	clear
	
	# Print 'NO PERMISSION'
	echo ' _   _  ___                                            '
	echo '| \ | |/ _ \                                           '
	echo '|  \| | | | |                                          '
	echo '| |\  | |_| |                                          '
	echo '|_| \_|\___/                                           '
	echo ' ____  _____ ____  __  __ ___ ____ ____ ___ ___  _   _ '
	echo '|  _ \| ____|  _ \|  \/  |_ _/ ___/ ___|_ _/ _ \| \ | |'
	echo '| |_) |  _| | |_) | |\/| || |\___ \___ \| | | | |  \| |'
	echo '|  __/| |___|  _ <| |  | || | ___) |__) | | |_| | |\  |'
	echo '|_|   |_____|_| \_\_|  |_|___|____/____/___\___/|_| \_|'
	echo '                                                       '
                                                        
	# Press any key to continue
	read -n 1 -s
}

while [ true ]
do
	# Get result of 'ps' command
	PS_RESULT=`ps aux --sort=${PID_SORT}pid`

	# Get position of 'CMD'
	CMD_POSITION=`echo "$PS_RESULT" | head -1 | grep -bo COMMAND | cut -d ':' -f 1`

	# Delete header of PS_RESULT
	PS_RESULT=`sed '1d' <<< "$PS_RESULT"`

	# Get 'NAME' from PS_RESULT
	NAME_LIST=(`echo "$PS_RESULT" | awk '{print $1}' | sort -${NAME_SORT}u`)

	# Get process list by 'NAME'
	PROCESS_RESULT=`echo "$PS_RESULT" | grep ^${NAME_LIST[$NAME_CURSOR]} | grep -v 'ps aux'`

	# Get 'PID', 'STIME' from PROCESS_RESULT
	PID_LIST=(`awk '{print $2}' <<< "$PROCESS_RESULT"`)
	STIME_LIST=(`awk '{print $9}' <<< "$PROCESS_RESULT"`)

	# Get 'STAT' from PROCESS_RESULT (Only to check if it is 'Foreground' or 'Background')
	STAT_LIST=(`echo "$PROCESS_RESULT" | awk '{print $8}' | rev | cut -c 1`)
	
	# Get 'CMD' from PROCESS_RESULT
	CMD_LIST=(`echo "$PROCESS_RESULT"`)

	for i in $(seq 0 ${#CMD_LIST[@]})
	do
		CMD_LIST[$i]=${CMD_LIST[$i]:$CMD_POSITION}
	done

	# Show
	Show
	
	# Prompt
	echo "If you want to exit, please type 'q' or 'Q'"

	# Check enter key
	if read -n 3 -t 3 KEY; then
		if [ -z "$KEY" -a $PROCESS_CURSOR -gt -1 ]; then
			if [ "${NAME_LIST[$NAME_CURSOR]}" = `whoami` ]; then
				kill -9 ${PID_LIST[$START_INDEX+$PROCESS_CURSOR]}
			else
				NoPermission
			fi
		fi
	fi

	# Exit
	if [ "$KEY" = 'q' -o "$KEY" = 'Q' ]; then
		exit

	# Sort 'NAME' in ascending
	elif [ "$KEY" = '+n' ]; then
		NAME_SORT=''
		NAME_CURSOR=0
		PROCESS_CURSOR=-1
	
	# Sort 'NAME' in descending
	elif [ "$KEY" = '-n' ]; then
		NAME_SORT='r'
		NAME_CURSOR=0
		PROCESS_CURSOR=-1
	
	# Sort 'PID' in ascending
	elif [ "$KEY" = '+p' ]; then
		PID_SORT='+'
		NAME_CURSOR=0
		PROCESS_CURSOR=-1
	
	# Sort 'PID' in descending
	elif [ "$KEY" = '-p' ]; then
		PID_SORT='-'
		NAME_CURSOR=0
		PROCESS_CURSOR=-1

	# Up
	elif [ "$KEY" = $'\e[A' ]; then
		if [ $PROCESS_CURSOR -eq -1 ]; then
			if [ $NAME_CURSOR -gt 0 ]; then
				NAME_CURSOR=$NAME_CURSOR-1
				START_INDEX=0
			fi
		else
			if [ $PROCESS_CURSOR -gt 0 ]; then
				PROCESS_CURSOR=$PROCESS_CURSOR-1
			else
				if [ $START_INDEX -gt 0 ]; then
					START_INDEX=$START_INDEX-1
				fi
			fi
		fi

	# Down
	elif [ "$KEY" = $'\e[B' ]; then
		if [ $PROCESS_CURSOR -eq -1 ]; then
			if [ $NAME_CURSOR -lt $((${#NAME_LIST[@]} - 1)) -a $NAME_CURSOR -lt 19 ]; then
				NAME_CURSOR=$NAME_CURSOR+1
				START_INDEX=0
			fi
		else
			if [ $PROCESS_CURSOR -lt $((${#PID_LIST[@]} - 1)) -a $PROCESS_CURSOR -lt 19 ]; then
				PROCESS_CURSOR=$PROCESS_CURSOR+1
			else
				if [ $START_INDEX -lt $((${#PID_LIST[@]} - 20)) ]; then
					START_INDEX=$START_INDEX+1
				fi
			fi
		fi

	# Right
	elif [ "$KEY" = $'\e[C' ]; then
		if [ $PROCESS_CURSOR -eq -1 ]; then
			PROCESS_CURSOR=0
		fi

	# Left
	elif [ "$KEY" = $'\e[D' ]; then
		if [ $PROCESS_CURSOR -ge 0 ]; then
			PROCESS_CURSOR=-1
		fi
	fi
done
