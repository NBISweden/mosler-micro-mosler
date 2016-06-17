#!/usr/bin/env bash

# Get credentials and machines settings
HERE=$(dirname ${BASH_SOURCE[0]})
source $HERE/settings.sh

export TL_HOME MOSLER_IMAGES
export LIB=${MM_HOME}/lib

export VAULT=vault
CONNECTION_TIMEOUT=1 #seconds

function usage {
    echo "Usage: $0 [options]"
    echo -e "\noptions are"
    echo -e "\t--machines <list>,"
    echo -e "\t        -m <list>      \tA comma-separated list of machines"
    echo -e "\t                       \tDefaults to: \"${MACHINES[@]// /,}\"."
    echo -e "\t                       \tWe filter out machines that don't appear in the default list."
    echo -e "\t--vault <name>         \tName of the drop folder in the servers"
    echo -e "\t                       \tDefaults to '${VAULT}'"
    echo -e "\t--mail-to <email>      \tContact email for the cron jobs"
    echo -e "\t                       \tDefaults to '${MAILTO}'"
    echo -e "\t--timeout <seconds>,   \tSkips the steps of syncing files to the servers"
    echo -e "\t       -t <seconds>    \tSkips the steps of syncing files to the servers"
    echo -e "\t--cheat                \tUses tricks to provision machines faster (like mysql pre-dumps)"
    echo -e "\t--quiet,-q             \tRemoves the verbose output"
    echo -e "\t--help,-h              \tOutputs this message and exits"
    echo -e "\t-- ...                 \tAny other options appearing after the -- will be ignored"
}

# While there are arguments or '--' is reached
while [ $# -gt 0 ]; do
    case "$1" in
        --quiet|-q) VERBOSE=no;;
        --help|-h) usage; exit 0;;
        --machines|-m) CUSTOM_MACHINES=$2; shift;;
        --cheat) DO_CHEAT=yes;;
        --vault) VAULT=$2; shift;;
        --mail-to) MAILTO=$2; shift;;
        --timeout|-t) CONNECTION_TIMEOUT=$2; shift;;
        --) shift; break;;
        *) echo "$0: error - unrecognized option $1" 1>&2; usage; exit 1;;
    esac
    shift
done

#######################################################################
# Logic to allow the user to specify some machines
if [ -n ${CUSTOM_MACHINES:-''} ]; then
    CUSTOM_MACHINES_TMP=${CUSTOM_MACHINES//,/ } # replace all commas with space
    CUSTOM_MACHINES="" # Filtering the ones which don't exist in settings.sh
    for cm in $CUSTOM_MACHINES_TMP; do
	if [[ "${MACHINES[@]}" =~ "$cm" ]]; then
	    CUSTOM_MACHINES+="$cm "
	else
	    echo "Unknown machine: $cm"
	fi
	# for m in ${MACHINES[@]}; do
	#     [ "$cm" = "$m" ] && CUSTOM_MACHINES+=" $cm" && break
	# done
    done
    MACHINES=(${CUSTOM_MACHINES})

    if [ ${#MACHINES[@]} -eq 0 ]; then
	oups "Nothing to be done. Exiting..."
	exit 2
    else
	[ "$VERBOSE" = "yes" ] && echo "Using these machines: ${CUSTOM_MACHINES// /,}"
    fi
fi

mkdir -p ${PROVISION_TMP}

#######################################################################
# Logic to print progress and start/pause
source $LIB/utils.sh

#######################################################################
# Checking if machines are available. Filtering them out otherwise
source $LIB/ssh_connections.sh

#######################################################################
# Aaaaannnnnddd...... cue music!
########################################################################
[ "$VERBOSE" = "yes" ] && echo -e "\nConfiguring servers:"
FAIL=0
reset_progress
print_progress
export DB_SERVER=${MACHINE_IPs[openstack-controller]} # Used in the templates

for machine in ${MACHINES[@]}
do
    # Selecting the template
    _TEMPLATE=${LIB}/${PROVISION[$machine]}/provision.jn2
    if [ ! -f ${_TEMPLATE} ]; then
	oups "\tProvisioning script unknown for $machine"
	filter_out_machine $machine
    else

	_SCRIPT=${PROVISION_TMP}/run.$machine
	_LOG=${PROVISION_TMP}/log.$machine
	# Rendering the template
	# It will use the (exported) environment variables
	render_template $machine ${_TEMPLATE} ${_SCRIPT}

	{ # Scoping, in that current shell
	    ssh -F ${SSH_CONFIG} ${FLOATING_IPs[$machine]} 'sudo bash -e -x -v 2>&1' <${_SCRIPT} &>${_LOG}
	    RET=$?
	    if [ $RET -eq 0 ]; then report_ok $machine; else report_fail $machine; fi
	    print_progress
	    exit $RET
	} &
	JOB_PIDS[$machine]=$!
    fi
done
    
for job in ${JOB_PIDS[@]}; do wait $job || ((FAIL++)); done
print_progress

if (( FAIL > 0 )); then
    oups "\a\n${FAIL} servers failed to be configured"
else
    [ "$VERBOSE" = "yes" ] && thumb_up "\nServers configured"
fi

#kill_notifications # already trapped
