#!/bin/sh

A=""
B=""
C=""
D=N

OPTS='{
	"options": [
		{
			"short_opt": "a",
			"long_opt": "long-a",
			"description": "Option A",
			"arg_type": "directory",
			"default": "default A"
		},
		{
			"short_opt": "b",
			"long_opt": "long-b",
			"description": "Option B",
			"arg_type": "file",
			"default": "default B"
		},
		{
			"short_opt": "c",
			"long_opt": "long-c",
			"description": "Option C"
		},
		{
			"short_opt": "d",
			"long_opt": "long-d",
			"description": "Option D"
		},
		{
			"long_opt": "bash-completion",
			"description": "Generate bash completion"
		},
		{
			"short_opt": "h",
			"long_opt": "help",
			"description": "Print this message and exit"
		}
	]
}'

build_opt() {
	short_opt="$(echo $1 | jq -r '.short_opt')"
	long_opt="$(echo $1 | jq -r '.long_opt')"
	description="$(echo $1 | jq -r '.description')"
	arg_type="$(echo $1 | jq -r '.arg_type')"
	default="$(echo $1 | jq -r '.default')"
}

build_opts() {
	local parse_opts cb cb_args

	parse_opts="$(echo "$1" | jq -c '.options[]')"
	cb=$2
	shift 2
	cb_args=$@

	echo "${parse_opts}" | \
	while IFS='' read -r opt; do
		build_opt "${opt}"
		${cb} ${cb_args}
	done
}

gen_usage() {
	if [ "${short_opt}" = "" ] || [ "${short_opt}" = "null" ]; then
		short_opt=" "
	else
		short_opt="-${short_opt}"
	fi

	long_opt="--${long_opt}"

	if [ "${arg_type}" = "" ] || [ "${arg_type}" = "null" ]; then
		arg_type=" "
	else
		arg_type="<${arg_type}>"
	fi

	if [ "${default}" = "" ] || [ "${default}" = "null" ]; then
		default=" "
	else
		default="(default: '${default}')"
	fi

	printf "%${1}s%2s|%-20s %-12s %s %s\n" " " "${short_opt}" "${long_opt}" "${arg_type}" "${description}" "${default}"
}

gen_compgen() {
	echo -n "--${long_opt} "
}

gen_compreply() {
	long_opt="--${long_opt}"

	case "${arg_type}" in
		"directory")
			printf "%${1}s%s)\n" " " "${long_opt}"
			printf "%${2}sCOMPREPLY=( \$(compgen -d -- \${cur}) )\n" " "
			printf "%${2}s;;\n" " "
			;;
		"file")
			printf "%${1}s%s)\n" " " "${long_opt}"
			printf "%${2}sCOMPREPLY=( \$(compgen -f -- \${cur}) )\n" " "
			printf "%${2}s;;\n" " "
			;;
	esac
}

gen_getopts() {
	if [ "${short_opt}" != "" ] && [ "${short_opt}" != "null" ]; then
		echo -n "-${short_opt}"
		if [ "${arg_type}" != "" ] && [ "${arg_type}" != "null" ]; then
			echo -n ":"
		fi
	fi
}

usage() {
	echo "Usage:"
	echo "    $1 [options]"
	echo "Options:"
	build_opts "${OPTS}" gen_usage 4
}

do_bash_completion() {
	compgen_arg="$(build_opts "${OPTS}" gen_compgen)"
	echo "#!/bin/bash"
	echo ""
	echo "_$1 () {"
	echo "    local cur prev words cword"
	echo "    _init_completion || return"
	echo ""
	echo "    case \${prev} in"
	build_opts "${OPTS}" gen_compreply 8 12
	echo "        *)"
	echo "            COMPREPLY=( \$(compgen -W '${compgen_arg}' -- \${cur}) )"
	echo "            ;;"
	echo "    esac"
	echo "} &&"
	echo "    complete -F _$1 $1"
	echo ""
	echo "# ex: ts=4 sw=4 et filetype=sh"
}

read_first_arg() {
	echo $1
}

read_first_char() {
	echo $1 | awk '{ print substr($1, 0, 1) }'
}

full_name() {
	echo "${1##*/}"
}

file_name() {
	echo "${1%.*}"
}

while getopts "-:$(build_opts "${OPTS}" gen_getopts)" OPT; do
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
		-bash-completion)
			do_bash_completion $(file_name $(full_name $0))
			exit
			;;
		h|-help)
			usage $0
			exit
			;;
		*)
			echo "Invalid option: -${OPT}. Use -h or --help for help" >&2
			exit
			;;
	esac
done
shift $((OPTIND-1)) # Remove parsed options and arguments from $@ list

echo "A=$A"
echo "B=$B"
echo "C=$C"
echo "D=$D"

