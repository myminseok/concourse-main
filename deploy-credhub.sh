source ./set-boshenv.sh

bosh deploy -d credhub-uaa credhub-uaa-manifest.yml \
  --vars-file credhub-vars.yml \
  --vars-store credhub-vars-store.yml
