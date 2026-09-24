#!/usr/bin/env fish
# Rotate old log files and report what was removed.

set -l log_dir ~/logs
set -l keep_days 14
set -l removed 0

function human -a bytes
    if test $bytes -gt 1048576
        printf "%.1f MB" (math $bytes / 1048576)
    else
        printf "%d KB" (math --scale=0 $bytes / 1024)
    end
end

for file in $log_dir/*.log
    set -l age (math (date +%s) - (stat -f %m $file))
    if test $age -gt (math $keep_days \* 86400)
        set -l size (stat -f %z $file)
        echo "removing $file ("(human $size)")"
        rm -- $file; and set removed (math $removed + 1)
    end
end

switch $removed
    case 0
        echo "nothing older than $keep_days days"
    case '*'
        echo "$removed file(s) removed"
end
