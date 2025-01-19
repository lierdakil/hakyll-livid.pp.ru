---
title: Как получить CIDR префиксы для ASN
published: 2025-01-19T15:20:23Z
tags: asn, cidr, bgp
---

На правах памятки, получить все префиксы для ASN можно используя `bgpq4`:

```bash
bgpq4 -4 as12345 # для ipv4
bgpq4 -6 as12345 # для ipv6
```
По умолчанию вывод в формате Cisco, но умеет много разных, в т.ч. кастомный.

Плюс, умеет объединять префиксы (флаг `-A`).
Если зачем-нибудь нужно просто список подсетей, без наворотов, то можно сделать так:

```bash
bgpq4 -A4F '%n/%l\n' as12345
```

<!-- more -->

Скажем, если хочется забить в address list на микротике, можно набросать какой-то такой скрипт:

```bash
#!/usr/bin/env bash

ASN="$1"
name="$2"
version="${3:-46}"

go() {
  local v=$1
  local ip=$2
  echo "/$ip/firewall/address-list remove numbers=[find list=$name]"
  bgpq4 -A"${v}"F "/$ip/firewall/address-list/add list=$name address=%n/%l comment=$ASN\n" "$ASN"
}

[[ "$version" =~ "4" ]] && go 4 ip
[[ "$version" =~ "6" ]] && go 6 ipv6
```
