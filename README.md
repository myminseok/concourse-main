

# deploying concourse on AWS

## prepare target cloud env
- run bbl: https://github.com/myminseok/bbl-template.git


## set lb on bosh cloud-config

```
bosh cloud-config > cloud-config.yml
cp cloud-config.yml cloud-config.yml.orig

edit cloud-config.yml

bosh update-cloud-config ./cloud-config.yml

```

cloud-config.yml

```

vm_extensions:
- cloud_properties:
    ephemeral_disk:
      size: 1024
      type: gp2
  name: 1GB_ephemeral_disk
  ...

- cloud_properties:
    lb_target_groups:
    - aws-cp-mkim-concourse80
    - aws-cp-mkim-concourse443
    - aws-cp-mkim-concourse2222
    security_groups:
    - aws-cp-mkim-concourse-lb-internal-security-group
    - sg-018eb5eefab290083
  name: lb
- cloud_properties:
    lb_target_groups:
    - aws-cp-mkim-concourse8443
    - aws-cp-mkim-concourse8844
    security_groups:
    - aws-cp-mkim-concourse-lb-internal-security-group
    - sg-018eb5eefab290083
  name: credhublb
vm_types:

```


## vi credhub-uaa-manifest.yml

``` 
---
name: credhub-uaa
instance_groups:
- name: credhub-uaa
  azs:
  - z1
  instances: 1
  vm_type: t2.small
  persistent_disk_type: 1GB
  stemcell: xenial
  vm_extensions:          <-- add credhub lb extenstion . from bosh cloud-config
  - credhublb
  networks:
  - name: ((deployment-network))
#    static_ips:
#    - ((internal-ip-address))  <--- remove all 'internal-ip-address'


releases:
- name: uaa
  version: "74.25.0"
  url: "https://bosh.io/d/github.com/cloudfoundry/uaa-release?v=74.25.0"  <--- update release
  sha1: "7eb46ce8d64d11e3bcfb52fc7c26c1e72085fd69"

- name: "credhub"
  version: "2.9.0"
  url: "https://bosh.io/d/github.com/pivotal-cf/credhub-release?v=2.9.0" <--- update release
  sha1: "36d3a92588c33bc3a7ce54cd4714c96cc7d1bee2"

- name: postgres
  version: "((postgres_version))"

- name: bpm
  version: "((bpm_version))"


```



```
---
deployment-network: private 
external-ip-address: "concourse.pcfdemo.net"
#internal-ip-address: "concourse.pcfdemo.net"
db_host: localhost
db_port: 5432
uaa_external_url: "https://concourse.pcfdemo.net:8443"
uaa_internal_url: "https://concourse.pcfdemo.net:8443"
#uaa_version: "74.9.0"
#credhub_version: "2.5.7"
postgres_version: "42"
bpm_version: "1.1.8"

```


## upload release



## deploy-credhub.sh

```
source ../bbl-aws/bosh-env.sh

bosh deploy -d credhub-uaa credhub-uaa-manifest.yml \
  --vars-file credhub-vars.yml \
  --vars-store credhub-vars-store.yml

 ```

##  concourse variables.yml with credhub vars

variables.yml

```
---
local_user:
  username: admin
  password: secrets
deployment_name: concourse
db_persistent_disk_type: 5GB
db_vm_type: t2.small 
external_url: https://concourse.pcfdemo.net 
external_host: concourse.pcfdemo.net
network_name: private 
postgres_password: secrets
#web_ip: 
web_vm_type: t2.small 
web_network_name: private
web_network_vm_extension: lb
web_instances: 1
worker_vm_type: t2.small
worker_ephemeral_disk: 50GB_ephemeral_disk
worker_instances: 1
azs: [z1]


credhub_url: "https://concourse.pcfdemo.net:8844"
credhub_client_id: "concourse_client"

## bosh int credhub-vars-store.yml --path=/concourse_credhub_client_secret
credhub_client_secret: "yo2j2ztxicr3d0ifgckv"

## bosh int credhub-vars-store.yml --path=/credhub-ca/ca
credhub_ca_cert: |
  -----BEGIN CERTIFICATE-----
  ... eh7CHP5CSnlpxrQgsn5tET0K2IYylZ
  jJY97pb2y8MaGP+y5mKBrFMpAAgzBiom
  -----END CERTIFICATE-----
```



## deploy-concourse.sh

```
source ../bbl-aws/bosh-env.sh

bosh deploy \
-d concourse ./concourse-bosh-deployment/cluster/concourse.yml \
-l ./concourse-bosh-deployment/versions.yml \
-l variables.yml \
--vars-store cluster-creds.yml \
-o ./concourse-bosh-deployment/cluster/operations/backup-atc.yml \
-o ./concourse-bosh-deployment/cluster/operations/basic-auth.yml \
-o ./concourse-bosh-deployment/cluster/operations/privileged-http.yml \
-o ./concourse-bosh-deployment/cluster/operations/privileged-https.yml \
-o ./concourse-bosh-deployment/cluster/operations/tls.yml \
-o ./concourse-bosh-deployment/cluster/operations/tls-vars.yml  \
-o ./concourse-bosh-deployment/cluster/operations/web-network-extension.yml  \
-o ./concourse-bosh-deployment/cluster/operations/worker-ephemeral-disk.yml \
-o ./concourse-bosh-deployment/cluster/operations/scale.yml \
-o ./concourse-bosh-deployment/cluster/operations/credhub.yml

```
