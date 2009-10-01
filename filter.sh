#!/usr/bin/bash
# Generates a filter list for a Juniper router based on an input AS-SET or ASN.

IS_SET=`echo $1 | cut -c3 | grep -`

if [[ "-" == "$IS_SET" ]]
then
	AS_LIST=`whois -h whois.radb.net \!i$1,1`
else
	AS_LIST=$1
fi

IP_LIST=""

for i in $AS_LIST
do
	IP_LIST+=`whois -h whois.radb.net -i origin $i | grep route: | cut -f 2 -d: | sed 's/ //g'`
	IP_LIST+=`echo " "`
done

echo $IP_LIST
