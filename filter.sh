#!/bin/bash
# Generates a filter list for a router based on an input AS-SET or ASN.

# Define a usage statement
usage()
{
	echo "$0: A filterlist generator"
	echo "Usage: $0 [OPTS] AS-SET"
	echo "    -t | --type [juniper | cisco | brocade | force10]"
	echo "    -n | --name [Filter Name]"
}

# Initialise some variables, to make it safe to use
FILTERNAME="filter"
INC=10
IP_LIST=""

# Parse the command line options
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
		-h|--help)
			usage
			exit 1
			;;
		*)
			echo "Error: Unknown option: $1" >&2
			usage
			exit 1
			;;
	esac
done

if [ $# -lt 1 ]
	then usage
	exit 1
fi

# Do we have an AS-SET or an ASN?
IS_SET=$(echo $1 | cut -c3 | grep -)

# If we've got an AS-SET, use the handy !i and ,1 commands on RADB
if [[ "-" == "$IS_SET" ]]
then
	AS_LIST=$(whois -h whois.radb.net \!i$1,1 | sed 2\!d)
else
	AS_LIST=$1
fi

# Find out which prefixes are contained within that AS number, from RADB
for i in $AS_LIST
do
	IP_LIST+=$(whois -h whois.radb.net \!g$i | sed 2\!d)
	IP_LIST+=$(echo " ")
done

# If we're on Force10, create the prefix-list
if [ "$TYPE" == "force10" ]
then
	echo "ip prefix-list $FILTERNAME"
fi

# Format the output nicely
for i in $IP_LIST
do
	if [ "$TYPE" == "juniper" ]
	then
		echo "set policy-options policy-statement $FILTERNAME term auto-generated from route-filter $i exact"
	elif [ "$TYPE" == "cisco" ]
	then
		echo "ip prefix-list $FILTERNAME $INC permit $i"
		let INC=INC+10
	elif [ "$TYPE" == "brocade" ]
	then
		echo "ip prefix-list $FILTERNAME permit $i"
	elif [ "$TYPE" == "force10" ]
	then
		echo " seq $INC permit $i"
	else
		echo $i
	fi
done

# Tell the Juniper router to accept those prefixes
if [ "$TYPE" == "juniper" ]
then
	echo "set policy-options policy-statement $FILTERNAME term auto-generated then accept"
fi

