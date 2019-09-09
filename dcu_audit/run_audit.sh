#!/bin/bash
# fully automated auditing for DCU items - 2014-10-27 aelkiss

AUDIT_HOME=/l/home/libadm/dcu_audit
TODAY=$(date +"%Y%m%d")
DCU_ARCHIVE=/quod-prep/prep/d/dcu/Archive
THIS_AUDIT=$AUDIT_HOME/$TODAY

mkdir -p $THIS_AUDIT
cd $DCU_ARCHIVE/1_Waiting_for_Ingest

# find all zips waiting for ingest
find . -type f -name '*.zip' | tee $THIS_AUDIT/paths
# get status of each item
 perl -I /htapps/babel/feed/lib -w /htapps/babel/feed/bin/audit/dcu_item_state.pl < $THIS_AUDIT/paths | tee $THIS_AUDIT/status
# find correctly-ingested zips
cat $THIS_AUDIT/barcodes | xargs -n 1 -I % grep % $THIS_AUDIT/status | cut -f 1 | perl -w $AUDIT_HOME/move_good.pl ../2_Ingested > $THIS_AUDIT/ok_move.sh

 /bin/bash $THIS_AUDIT/ok_move.sh > $THIS_AUDIT/ok_move.out 2> $THIS_AUDIT/ok_move.err
find . -type d -empty > $THIS_AUDIT/empty_dirs 
cat $THIS_AUDIT/empty_dirs | xargs rmdir

# find & send correctly-ingested barcodes
grep MD5_CHECK_OK $THIS_AUDIT/status | cut -f 1 | sed 's/^\.\///' | sort > $THIS_AUDIT/digifeeds_ingested_$TODAY.txt

( echo "$(wc -l $THIS_AUDIT/digifeeds_ingested_$TODAY.txt | cut -f 1 -d ' ') digifeeds ingested; list is attached."; 
  echo;
  if [ -s $THIS_AUDIT/empty_dirs ];
  then echo "Empty folders removed:"
  sed 's/^\.\///' < $THIS_AUDIT/empty_dirs;
  else echo "No empty folders removed.";
  fi ) | heirloom-mailx -s "Digifeeds ingested $(date +"%Y-%m-%d")" -a $THIS_AUDIT/digifeeds_ingested_$TODAY.txt dcu-ht-ingest@umich.edu

# find & send items that need source changed to lit-dlps-dc
perl -I /htapps/babel/feed/lib -w /l/home/libadm/dcu_audit/check_source.pl $THIS_AUDIT/barcodes > $THIS_AUDIT/need_source_change
grep "bib google" $THIS_AUDIT/need_source_change | grep -v 69015 > $THIS_AUDIT/digifeeds_needing_source_change_$TODAY.txt
if [ -s $THIS_AUDIT/digifeeds_needing_source_change_$TODAY.txt ];
then echo "Digifeeds needing source change to lit-dlps-dc are attached" | heirloom-mailx -s "Digifeeds needing source change $(date +"%Y-%m-%d")" -a $THIS_AUDIT/digifeeds_needing_source_change_$TODAY.txt lit-cs-ingest@umich.edu timothy@umich.edu khage@umich.edu;
fi

if [ -e $THIS_AUDIT/digifeeds_non_bib_$TODAY.txt ]
then rm $THIS_AUDIT/digifeeds_non_bib_$TODAY.txt;
fi

grep "google" $THIS_AUDIT/need_source_change | grep -v 'bib ' >> $THIS_AUDIT/digifeeds_non_bib_$TODAY.txt
grep "69015" $THIS_AUDIT/need_source_change >> $THIS_AUDIT/digifeeds_non_bib_$TODAY.txt
if [ -s $THIS_AUDIT/digifeeds_non_bib_$TODAY.txt ]
then echo "Digifeeds needing source change to lit-dlps-dc that are not bib-determined are attached; Core Services will update the rights." | heirloom-mailx -s "Digifeeds needing source change (non-bib) $(date +"%Y-%m-%d")" -a $THIS_AUDIT/digifeeds_non_bib_$TODAY.txt lit-cs-ingest@umich.edu khage@umich.edu timothy@umich.edu;
fi
