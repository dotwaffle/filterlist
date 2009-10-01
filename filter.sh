#!/usr/bin/bash
# Generates a filter list for a router based on an input AS-SET or ASN.

FILTERNAME="filter"
INC=10
IP_LIST=""

while [[ $1 = -* ]]; do
	case "$1" in
		-t|--type)
			TYPE="$2"
			shift 2
			;;
		-n|--name)
			FILTERNAME="$2"
			shift 2
			;;
		*)
			echo "Error: Unknown option: $1" >&2
			exit 1
			;;
	esac
done

IS_SET=`echo $1 | cut -c3 | grep -`

if [[ "-" == "$IS_SET" ]]
then
	AS_LIST=`whois -h whois.radb.net \!i$1,1`
else
	AS_LIST=$1
fi

for i in $AS_LIST
do
	IP_LIST+=`whois -h whois.radb.net -i origin $i | grep route: | cut -f 2 -d: | sed 's/ //g'`
	IP_LIST+=`echo " "`
done

for i in $IP_LIST
do
	if [ "$TYPE" == "juniper" ]
	then
		echo "set policy-options policy-statement $FILTERNAME from route-filter $i exact"
	elif [ "$TYPE" == "cisco" ]
	then
		echo "ip prefix-list $FILTERNAME $INC permit $i"
		let INC=INC+10
	else
		echo $i
	fi
done
