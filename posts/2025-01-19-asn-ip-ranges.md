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
