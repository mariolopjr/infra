#!/usr/bin/env bash
# List files on the tmpfs root that a reboot will erase as a nushell table, newest last.
set -euo pipefail

# shellcheck disable=SC2016 # $in is nushell's
{
  printf 'modified\tsize\tpath\n'
  sudo find / -xdev -type f -not -path '/tmp/*' -not -path '/etc/static/*' -printf '%TY-%Tm-%Td %TH:%TM\t%s\t%p\n' |
    grep -vP '\t/etc/(passwd|group|shadow|subuid|subgid|sudoers|resolv.conf|\.clean|NIXOS)$'
} | nu --stdin -c '$in | from tsv | into int size | into filesize size | into datetime modified | sort-by modified'
