#!/bin/bash
# This scripts is to wrapper around getopts and to enable support for long names
#
# The help command is added automatically and if needed the "addusageheader" and "addusagefooter" functions
# can be used to add extra help information.
#
#
# addflag: is used to add a option that will automatically create a flag based on the flagname, if activated
# an readonly variable will be created with it's value set to "1"
#
# addoption: is used for adding options either without extra argument input or with. the callback function will be
# executed and $1 to that function is the extra argument if any.
#
#
# usage example
#
# addflag "long-name" "s" "flag description" "flagname"
#
# addoption "long1" "1" "first long option" "myfunc1"
# addoption "long2" "2" "second long option with argument" "myfunc2" 1
#
# parseoptions "$@"
#
# echo ${flagname}
#

usage(){
	local e
	local index=-1
	local i=0

	 printf "${usageheader}\n\n"

	length=$(getmaxlength)
	for e in "${optionarray[@]}";
	do
		longname=$(getoptionlongname $i)
		namesize="${#longname}"

		# get offset from longest name
		((namesize=$length-$namesize))

		# add some extra space for readability
		((namesize=namesize+5))

		line=$(printf "%${namesize}s")
		echo "-"$(getoptionshortname $i)", --"${longname}"${line}"$(getusage $i)
		let "i++"
	done

	printf "${usagefooter}\n"

	exit
}

getmaxlength(){
	size=0
	for i in $(seq 0 "${#optionarray[@]}");
	do

		longname=$(getoptionlongname $i)
		namesize="${#longname}"
		(( $size < $namesize )) && size=$namesize

	done

	echo ${size}
}

addusageheader(){
	readonly usageheader="$1"
}

addusagefooter(){
	readonly usagefooter="$1"
}

addflag(){
	# 1 long name
	# 2 short name
	# 3 usage
	# 4 flagname

	addoption "$1" "$2" "$3" "" "" "$4"

}

addoption(){
	# 1 long name
	# 2 short name
	# 3 usage
	# 4 callback function to execute
	# 5 callback requires arguments
	# 6 this is only used with addflag

	optionarray+=("$1:$2:$3:$4:$5:$6")
}

contains() {
	local e
	local index=-1
	local i=0
	for e in "${@:2}";
	do
		if [[ "$e" =~ $1 ]]
		then
			index=$i
			break
		else
			let "i++"
		fi
	done
	echo $index
}

containslongname(){
	# 1 long name to find e.g --my-cool-long-name

	name=`printf "%q" ${1:2}`
	retval=$(contains "^${name}:*" "${optionarray[@]}")

	echo $retval
}

containsshortname(){
	# 1 short name to find e.g -s

	name=`printf "%q" ${1}`
	retval=$(contains ":${name}:" "${optionarray[@]}")

	echo $retval
}

getoptionparameter(){
	# 1 index of optionarray
	# 2 index of parameter

	currrentIFS=$IFS

	IFS=':'

	#echo ${optionarray[@]}

	option=(${optionarray[${1}]})

	IFS=${currrentIFS}

	echo ${option[${2}]}
}

getoptionlongname(){
	# 1 index in optionarray
	echo $(getoptionparameter $1 0)
}

getoptionshortname(){
	# 1 index in optionarray
	echo $(getoptionparameter $1 1)
}

getusage(){
	# 1 index in optionarray
	echo $(getoptionparameter $1 2)
}

getcallback(){
	# 1 index in optionarray
	echo $(getoptionparameter $1 3)
}

requireargument(){
	# 1 index in optionarray
	echo $(getoptionparameter $1 4)
}

getflagname(){
	# 1 index in optionarray
	echo $(getoptionparameter $1 5)
}

create_flag(){
	# 1 index in optionarray

	flagname=$(getflagname $1)

	readonly ${flagname}="1"

}


create_optstring(){

	local optstring
	local e
	local index=-1
	local i=0
	for e in "${optionarray[@]}";
	do
		optstring+=$(getoptionshortname $i)

		if [[ $(requireargument $i) == "1" ]]
		then
			optstring+=":"
		fi

		let "i++"
	done

	echo "$optstring"
}

parseoptions(){
	arg=$@

	for arg
	do
		index=-1

		[[ $arg == "--help" || $arg == "-h" ]] && usage

		if [[ "${arg:0:2}" == "--" ]]
		then
			index=$(containslongname $arg)
		fi
		delim=""

		if [[ $index != "-1" ]]
		then
			 args=${args}"-"$(getoptionshortname $index)" "
		else
			[[ "${arg:0:1}" == "-" ]] || delim="\""

			args="${args}${delim}${arg}${delim} "
		fi

	done

	# reset to the converted args
	eval "set -- $args"

	while getopts ":"$(create_optstring) opt; do

		index=-1

		if [[ $opt != "?"  && $opt != ":" ]]
		then
			index=$(containsshortname $opt)
		fi

		if [[ $index != "-1" ]]
		then
			callback=$(getcallback $index)

			if [[ "${callback}" != "" ]]
			then
				#execute the callback
				eval ${callback} "\"${OPTARG}\""
			else
				create_flag $index
			fi

			continue
		else
			case $opt in

				:)
					echo "option -$OPTARG requires an argument"
					usage
					;;
				*)
					echo "option not found : -"$OPTARG
					usage
					;;
			esac

		fi

	done
}

# adding the help option with callback function
addoption "help" "h" "prints this help test" "usage"
