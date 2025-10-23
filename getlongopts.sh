A=""
B=""
C=""
D=N

usage() {
	echo "Usage: $1"
	echo "   -a|--long-a <arg>"
	echo "   -b|--long-b <arg>"
	echo "   -c|--long-c <arg>"
	echo "   -d|--long-d"
}

read_first_arg() {
	echo $1
}

read_first_char() {
	echo $1 | awk '{ print substr($1, 0, 1) }'
}

while getopts "-:a:b:c:d" OPT; do
	# Original post: https://stackoverflow.com/a/28466267/519360
	# Long option: reformulate OPT and OPTARG
	if [ "$OPT" = "-" ]; then
		OPT=-$OPTARG                   # Extract long option name
		shift $((OPTIND-1))            # Remove parsed option from $@ list
		OPTARG=$(read_first_arg $@)    # Extract long option argument (may be empty)
		FIRST_CHAR=$(read_first_char $OPTARG)
		# Remove parsed argument from $@ list if OPTARG is not NULL
		# and the first character of OPTARG is not "-"
		if [ "$FIRST_CHAR" != "" ]; then
			if [ "$FIRST_CHAR" != "-"  ]; then
				shift 1
			fi
		fi
	fi
	case "$OPT" in
		a|-long-a)
			A=$OPTARG
			;;
		b|-long-b)
			B=$OPTARG
			;;
		c|-long-c)
			C=$OPTARG
			;;
		d|-long-d)
			D=Y
			;;
		*)
			usage $0
			exit
			;;
	esac
done
shift $((OPTIND-1)) # Remove parsed options and arguments from $@ list

echo "A=$A"
echo "B=$B"
echo "C=$C"
echo "D=$D"

