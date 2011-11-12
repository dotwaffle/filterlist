#!/bin/bash
# filter.sh: Generates a filter list for a router based on an input AS-SET or ASN.

# Copyright 2009-2011 Matthew Walster
# Distributed under the terms of the GNU General Public Licence

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Define a usage statement
usage()
{
	echo "$0: A filterlist generator"
	echo "Usage: $0 [OPTS] AS-SET"
	echo "    -t | --type [juniper | cisco | brocade | force10]"
	echo "    -n | --name [Filter Name]"
	echo "    -h | --host [WHOIS server]"
	echo "         --ipv4"
	echo "         --ipv6"
}

# Initialise some variables, to make it safe to use
FILTERNAME="filter"
INC=10
IP_LIST=""
WHOISSERVER="whois.radb.net"
IP_VERSION="4"

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
		-h|--host)
			WHOISSERVER="$2"
			shift 2
			;;
		--help)
			usage
			exit 1
			;;
		--ipv4)
			IP_VERSION="4"
			shift
			;;
		--ipv6)
			IP_VERSION="6"
			shift
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
	AS_LIST=$(whois -h whois.radb.net \!i$1,1 | sed '/^\[/d' | sed 2\!d)
else
	AS_LIST=$1
fi

# Find out which prefixes are contained within that AS number
for i in $AS_LIST
do
	if [ "$IP_VERSION" == "4" ]
	then
		IP_LIST+=$(whois -h $WHOISSERVER -- "-i origin $i" | grep ^route: | cut -f 2 -d: | sed 's/ //g')
	elif [ "$IP_VERSION" == "6" ]
	then
		IP_LIST+=$(whois -h $WHOISSERVER -- "-i origin $i" | grep ^route6: | cut -f 2- -d: | sed 's/ //g')
	fi
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
		let INC=INC+10
	else
		echo $i
	fi
done

# Tell the Juniper router to accept those prefixes
if [ "$TYPE" == "juniper" ]
then
	echo "set policy-options policy-statement $FILTERNAME term auto-generated then accept"
fi

