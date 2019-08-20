VOLUMES=$@

for id in $VOLUMES; do grep -v meta.yml $id/checksum.md5 > $id/checksum.new; mv $id/checksum.new $id/checksum.md5; md5sum $id/meta.yml >> $id/checksum.md5; done

for id in $VOLUMES; do echo $id; zip $id.zip $id/meta.yml $id/checksum.md5; done
