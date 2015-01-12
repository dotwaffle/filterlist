# filterlist

filterlist is a shell script that generates filter lists for BGP peering
sessions. Information is gathered by either AS or AS-SET as returned from RADb.
You may select any whois server that you want, however AS-SET resolution is
always performed against *whois.radb.net*

**Features:**
* IPv4 and IPv6 Support
* AS-SET resolution
* De-duplication of prefixes
* Prefix aggregation if the [aggregate](http://freecode.com/projects/aggregate/) command is available
* Name your filter list
* Auto-generate part of the filter list name based on the ASN / AS-SET

**Supported filter types:**
* brocade
* cisco
* force10
* juniper
* quagga
* redback


## Usage

```bash
Usage: ./filter.sh [OPTS] AS-SET
    -t | --type [ juniper | cisco | brocade | force10 | redback | quagga ]
    -n | --name [ Filter Name ]
    -g | --gen
    -a | --aggregate [ Max Len ]
    -h | --host [ WHOIS server ]
         --ipv4
         --ipv6
```


### Examples

**Generate a Cisco IPv4 filter list for AS2**
```bash
$ ./filter.sh --type cisco --ipv4 2
ip prefix-list filter 10 permit 1.1.2.0/24
ip prefix-list filter 20 permit 2.0.0.0/16
ip prefix-list filter 30 permit 64.62.96.0/24
ip prefix-list filter 40 permit 201.62.50.0/24
ip prefix-list filter 50 permit 201.62.51.0/24
ip prefix-list filter 60 permit 201.71.32.0/24
ip prefix-list filter 70 permit 201.71.33.0/24
ip prefix-list filter 80 permit 201.71.34.0/24
ip prefix-list filter 90 permit 201.71.35.0/24
ip prefix-list filter 100 permit 205.143.159.0/24
```

**Generate an Aggregated IPv4 filter list for AS2**
```bash
$ ./filter.sh --type juniper -a 24 --ipv4 AS2
set policy-options policy-statement filter term auto-generated from protocol bgp
set policy-options policy-statement filter term auto-generated from route-filter 1.1.2.0/24 upto /24
set policy-options policy-statement filter term auto-generated from route-filter 2.0.0.0/16 upto /24
set policy-options policy-statement filter term auto-generated from route-filter 64.62.96.0/24 upto /24
set policy-options policy-statement filter term auto-generated from route-filter 201.62.50.0/23 upto /24
set policy-options policy-statement filter term auto-generated from route-filter 201.71.32.0/22 upto /24
set policy-options policy-statement filter term auto-generated from route-filter 205.143.159.0/24 upto /24
set policy-options policy-statement filter term auto-generated then accept
set policy-options policy-statement filter then reject
```

