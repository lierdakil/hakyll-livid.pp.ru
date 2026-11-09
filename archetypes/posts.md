---
title: {{ .Name | replaceRE "^[0-9]{4}-[0-9]{2}-[0-9]{2}-" "" | replaceRE "-" " " | title }}
date: {{ time.AsTime .Date | time.In "UTC" | time.Format "2006-01-02T15:04:05Z07:00" }}
year-month: "{{ time.Format "2006-01" .Date }}"
tags: []
---
