#!/bin/bash
set +x

print_trace() {
    echo "$(date +%y-%m-%d" "%H:%M:%S) : $1" 
}

print_usage() {
    print_trace "Usage: `basename $0` --logfile file.txt --who Nath"
    exit
}

declare nums
nums["XXX"]="YYY"

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -f|--logfile)
    LOGFILE="$2"
    shift # past argument
    ;;
    -w|--who)
    WHO="$2"
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value

done

if [ -z ${LOGFILE} ]
then
  print_trace "Parameter logfile is missing"
  print_usage
fi

if [ -z ${WHO} ]
then
  WHO="Nath"
  print_trace "Parameter who is missing, use default : ${WHO}"
fi

if [ ! -f ${LOGFILE} ]
then
  print_trace "File ${LOGFILE} doesn't exist"
  exit 1
fi

i=0
print_trace "Parsing of logfile..."
while IFS='' read -r line || [[ -n "$line" ]]; do
    # Read log by log
    secondpart=$(echo $line | sed 's/.*Tel://')
    tel=$(echo $secondpart | cut -d' ' -f1)
    if [ "$tel" == "${nums[${WHO}]}" ]
    then
      date_tmp=$(echo $line | cut -d' ' -f1)
      dates[$i]=$(echo $date_tmp | cut -d'.' -f1)
      servers[$i]=$(echo $line | cut -d' ' -f2)
      msg[$i]=$(echo $line | sed 's/.*message://' | sed 's/\\n//g')
      tel[$i]=$tel
      i=$(($i + 1))
    fi
done < ${LOGFILE}
print_trace "Parsing of logfile...done."

lastweek="$(date "+%Y-%m-%d" -d "7 days ago")"
morning="8"
evening="20"
lastdayofweek=""

echo
echo "Messages reçus pour ${WHO} entre ${evening}H et ${morning}H depuis le ${lastweek} :"
echo

for i in `seq 1 $(expr ${i} - 1)`
do
  thisweek=$(echo ${dates[$i]} | cut -d'T' -f1)
  thistime=$(echo ${dates[$i]} | cut -d'T' -f2)
  thishour=$( echo $thistime | cut -d':' -f1)
  dayofweek=$(date --date=${thisweek} "+%A")  
  daymonthtitle=$(date --date=${thisweek} "+%d %B")  
  if [[ "$thisweek" > "$lastweek" ]]
  then
      if [ "$thishour" -lt "$morning" ] || [ "$thishour" -ge "$evening" ]
      then
        if [ ! "$lastdayofweek" == "$dayofweek" ]
        then
           daytitle="$(tr '[:lower:]' '[:upper:]' <<< ${dayofweek:0:1})${dayofweek:1}"
           echo 
           echo ===========================
           echo "  " $daytitle $daymonthtitle
           echo ===========================
           echo 
           lastdayofweek=$dayofweek
        fi
        echo "Message reçu à $thistime depuis ${servers[$i]} :"
        echo ${msg[$i]%% - *}"  "${msg[$i]: -8}
        echo
    fi
  fi
done
exit
