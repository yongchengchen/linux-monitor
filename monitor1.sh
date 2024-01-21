#!/bin/bash
# system info
unique_name=$1
host_name="$(hostname)"
os_version=$(cat /etc/*-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '"' | head -n 1)
code_version="$(uname -r)"
currtime="$(date +'%Y-%m-%dT%H:%M:%S.%3N')"
os_start_time="$(who -b | awk '{print $3" "$4 }')"
os_running_day="$(uptime | awk '{print $3}')"

# cpu
cpu_number="$(lscpu |awk 'NR==4{print $2}')"
cpu_process_top10="$(ps aux --sort=-%cpu|head -n 10 |awk '{print substr($0,0,120)}'|sed 's/$/<br>/')"

storage="$(df -Ph | \
  jq -R -s '
    [
      split("\n") |
      .[] |
      if test("^/") then
        gsub(" +"; " ") | split(" ") | {disk: .[0], total: .[1], used: .[2], avail: .[3], used_percent: .[4], mount: .[5] }
      else
        empty
      end
      ]' )"

mem="$(free -m | \
  jq -R -s '
    [
      split("\n") |
      .[] |
      if test("^[MmSs]") then
        gsub(" +"; " ") | split(" ") | {type: .[0], total: .[1], used: .[2], free: .[3], buff: .[5] }
      else
        empty
      end
      ]')"

vmstatus="$(vmstat | grep -v "memory" | grep -v "free" | \
  jq -R -s '
      split("\n") |
      .[] |
      if test("^ ") then
        gsub(" +"; " ") | split(" ") | {running_proc: .[1], block_proc: .[2], swpd: .[3], free: .[4], buff: .[5], cache: .[6], si: .[7], so: .[8], bi: .[9], bo: .[10], cpu_int:.[11], context_switch:.[12], cpu_user:.[13], cpu_sys: .[14], cpu_idel:.[15], cpu_wait:.[16]}
      else
        empty
      end
      ')"

if [ "$vmstatus" = "" ]; then
        read -r vmstatus < /tmp/vmstat.txt
else
        echo $vmstatus > /tmp/vmstat.txt
fi

slavedbstat="$(/usr/local/bin/dbslavemonitor.sh)"
dbproclist="$(/usr/local/bin/dbproclist.sh)"

data=$( jq -n \
                  --arg currtime "$currtime" \
                  --arg unique_name "$unique_name" \
                  --arg host_name "$host_name" \
                  --arg os_version "$os_version" \
                  --arg run_days  "$os_running_day" \
                  --arg start_time  "$os_start_time" \
                  --arg kernel_version "$code_version" \
                  --arg slavedbstat "$slavedbstat" \
		  --arg dbproclist "$dbproclist" \
                  --argjson storage "$storage" \
                  --argjson memory "$mem" \
                  --argjson vmstatus "$vmstatus" \
                  --arg top10 "$cpu_process_top10" \
                  '{ unique_name: $unique_name, host_name: $host_name, "@timestamp": $currtime, os_version: $os_version, kernel_version: $kernel_version, slavedbstat: $slavedbstat, dbproclist: $dbproclist, run_days: $run_days, start_time: $start_time, storage: $storage, memory: $memory, vmstatus: $vmstatus, top10: $top10}' )
#echo $data

hsetData=$(jq -n \
                  --arg key "server-monitor-set" \
                  --arg unique_name "$unique_name" \
                  --argjson data "$data" \
		  '{key: $key, field: $unique_name, data: $data }')

listData=$(jq -n \
                  --arg key "server-monitor-list" \
                  --argjson data "$data" \
                  '{key: $key, data: $data }')


JREDIS_SERVER=
JREDIS_TOKEN=

curl -sS --header "Content-Type: application/json" \
  -H "Authorization: $JREDIS_TOKEN" \
  --request POST \
  --data "$hsetData" \
  $JREDIS_SERVER/jredis/hset  >  /dev/null

curl -sS --header "Content-Type: application/json" \
  -H "Authorization: $JREDIS_TOKEN" \
  --request POST \
  --data "$listData" \
  $JREDIS_SERVER/jredis/maxlpush/1000  >  /dev/null
