# Short Script to generate my necessary tasks for business travels
# Every journey obviously has a date, is assigned a project and a description
# I need to 
# 1. Apply for travel funding
# 2. Book the journey and hotels
# 3. Travel at the appointed date
# 4. Formally account the costs

function print_usage ()
{
	echo "USAGE:"
	echo "`basename ${0}` <project> <date> <description>"
}


if [[ $# < 1 ]] ; then 
	print_usage
	exit 1
fi

project=${1:?Please give Project as first parameter}
traveldate=${2:?Please give date of travel as second parameter}
description=${3:?Please give description of travel as third parameter}
shift 3


function traveladder ()
{
  local project=$1
  local date=$2
  local description=$3
  shift 3
  local taskid=`task add project:${project} due:${date} "${description}" +reise $@ 2>/dev/null | sed 's/^Created\stask\s\([0-9][0-9]*\)\..*$/\1/'`
  echo ${taskid}
}


function include_in_cv ()
{
for  VAR in "$@" ; do 
	if [[ "$VAR" == "+cv" ]] ; then  
		return 0;  
	fi ;  
done; 
return 1
}


traveltaskid=`traveladder ${project} ${traveldate} "Reise: ${description}" \
	priority:A +reisend $@`
echo "Traveltask ID:${traveltaskid}"


bookingid=`traveladder ${project} ${traveltaskid}.due-1d "Buchung: ${description}" \
	scheduled:${traveltaskid}.due-1wk +buchung $@`
echo "Booking ID:${bookingid}"

antragid=`traveladder  ${project} ${traveltaskid}.due-1wk "Dienstreiseantrag: ${description}" \
	+antrag scheduled:${traveltaskid}.due-2wk $@`
echo "Antrag ID: ${antragid}"

berichtid=`traveladder ${project} ${traveltaskid}.due+1wk "Bericht: ${description}" \
	+report wait:${traveltaskid}.due $@`
echo "Bericht I: ${berichtid}"

abrechnungid=`traveladder ${project} ${traveltaskid}.due+6month "Abrechnung Dienstreise: ${description}"\
       	+abrechnung wait:${traveltaskid}.due scheduled:${traveltaskid}.due+1wk $@` 
echo "Abrechnung ID: ${abrechnungid}"

if include_in_cv ${@} ; then
	cvid=`traveladder me ${abrechnungid}.due "Reise ${description} in CV eintragen" priority:B $@`
	echo "CV-Eintrag ID: ${cvid}"
	task ${cvid} modify depends:${traveltaskid} 2>/dev/null 1>/dev/nul
fi



task ${traveltaskid} modify depends:${bookingid} 2>/dev/null 1>/dev/null
task ${traveltaskid} modify depends:${antragid} 2>/dev/null 1>/dev/null
task ${berichtid} modify depends:${traveltaskid} 2>/dev/null 1>/dev/null
task ${abrechnungid} modify depends:${antragid} 2>/dev/null 1>/dev/null
