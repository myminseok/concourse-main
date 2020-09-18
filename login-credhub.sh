unset CREDHUB_CA_CERT
unset CREDHUB_CLIENT
unset CREDHUB_PROXY
unset CREDHUB_SECRET
unset CREDHUB_SERVER

credhub api --server=https://concourse.pcfdemo.net:8844 --ca-cert <(bosh int ./credhub-vars-store.yml --path=/credhub-ca/ca)
credhub login  --client-name=concourse_client --client-secret=$(bosh int ./credhub-vars-store.yml --path=/concourse_credhub_client_secret)
