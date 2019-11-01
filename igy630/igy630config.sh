#!/bin/sh
#set -x

out=$(whence zoscloudfuncs >/dev/null)
if [ $? -eq 0 ]; then
	. zoscloudfuncs
else
	echo "zoscloud tools need to be in your PATH"
	exit 4
fi

runivp() {
	tempprefix="${IGYHLQ}T"
	tempds=`mvstmp ${tempprefix}`
	dtouch -tseq $tempds

	jobcard="//IGYWIVP1   JOB ${JOBOPTS},${JOBPARMS}"
	decho "$jobcard" ${tempds}
	decho -a "//*
//PROCLIB JCLLIB ORDER=${IGYHLQ}.SIGYPROC
//RUNIVP EXEC IGYWCLG,REGION=0M,
//  LNGPRFX=${IGYHLQ},
//  LIBPRFX=${CEEHLQ},
//  PARM.LKED='LIST.XREF,LET,MAP',
//  PARM.COBOL='RENT',
//  PARM.GO=''
//COBOL.SYSIN DD DISP=SHR,
//  DSN=${IGYHLQ}.SIGYSAMP(IGYIVP)
//GO.SYSOUT DD SYSOUT=*
" ${tempds}

	job=`jsub $tempds`
	running=1
	while [ ${running} -gt 0 ]; do
		status=`jls ${job} | awk '{ print $4; }'`
		if [ "${status}" != 'AC' ]; then
			running=0
		else 
			sleep 1
		fi
	done
	rc=`jls ${job} | awk '{ print $5; }'`
	if [ ${rc} != '0' ]; then
		echo "IVP failed with RC:${rc}"
		exit 16
	fi

	drm $tempds
	exit 0
}

props=$(callerdir "$0")"/igy630config.properties"
. zoscloudprops ${props}

out=`runivp`
rc=$?
if [ $rc -gt 0 ]; then
	echo "IVP failed. Installation aborted"
	echo "$out"
	exit $rc
fi

