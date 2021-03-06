#!/usr/bin/env bash

function usage {
    echo "Usage: $0 command [options]"
    echo -e "\ncommands are:"
    echo -e "\tinit         \tInitializes the VMs"
    echo -e "\tclean        \tRemoves allocated resources"
    echo -e "\tsync         \tCopies relevant files to the VMs"
    echo -e "\tprovision    \tConfigures the infracstructure"
    echo -e "\tprepare      \tPrepares the virtual image to boot from"

    echo -e "\nSupply --help (or -h) to see the options for each command"

    echo -e "\nThe typical order to set up MicroMosler is to call:"
    echo -e "\t$0 init --all   # --all to create networks too"
    echo -e "\t$0 sync"
    echo -e "\t$0 provision"
    echo ""
}

case "$1" in
    init|clean|sync|provision|prepare)
	_CMD=$1
	shift # Remove the command name from $@
	export MM_CMD="$0 ${_CMD}"
	$(dirname ${BASH_SOURCE[0]})/lib/${_CMD}.sh $@ # pass the remaining arguments
	;;
    all)
	echo "Not implemented yet";
	set -e # exit on error
	# $0 clean -q
	# $0 init -i CentOS6-mm-extended -q
	# $0 sync -q
	# $0 provision --cheat -q
	exit 2;;
    *) echo "$0: error - unrecognized command $1" 1>&2; usage; exit 1;;
esac

