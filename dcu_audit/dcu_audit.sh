#!/bin/sh

# usage: dcu_audit.sh date

DATE=$1
DCU_AUDIT=~/dcu_audit
QUODPREP=/htprep/dcu
# QUODPREP=/l1/prep/d/dcu
QUODPREP_ARCHIVE=$QUODPREP/Archive/1_Waiting_for_Ingest
THIS_AUDIT=$DCU_AUDIT/$DATE
export HTFEED_CONFIG=/htapps/babel/feed/etc/config_ingest.yaml

cd $QUODPREP_ARCHIVE
mkdir -p $THIS_AUDIT

# find all zips waiting for ingest
find . -type f -name '*.zip' | tee $THIS_AUDIT/paths
# get status of each item
 perl -I /htapps/babel/feed/lib -w /htapps/babel/feed/bin/audit/dcu_item_state.pl < $THIS_AUDIT/paths | tee $THIS_AUDIT/status
# find correctly-ingested barcodes
grep MD5_CHECK_OK $THIS_AUDIT/status | cut -f 1 | perl -pe 's#.*\/##' | sort | uniq > $THIS_AUDIT/barcodes
# find correctly-ingested zips
cat $THIS_AUDIT/barcodes | xargs -n 1 -I % grep % $THIS_AUDIT/status | cut -f 1 | perl -w $DCU_AUDIT/move_good.pl ../2_Ingested > $THIS_AUDIT/ok_move.sh
# find items that need source changed to lit-dlps-dc
perl -I /htapps/babel/feed/lib -w /l/home/libadm/dcu_audit/check_source.pl $THIS_AUDIT/barcodes > $THIS_AUDIT/need_source_change

echo "CHECK FOR EMPTY DIRS!!"
