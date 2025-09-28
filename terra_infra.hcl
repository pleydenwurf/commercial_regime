# inventory.yml
all:
  hosts:
    localhost:
      ansible_connection: local
  vars:
    # vSphere Configuration
    vcenter_host: "vcenter.example.com"
    vcenter_user: "administrator@vsphere.local"
    vcenter_pass: "{{ vault_vcenter_password }}"
    datacenter: "Datacenter1"
    cluster: "Cluster1"
    datastore_name: "datastore1"
    network_name: "VM Network"
    vm_folder: "Linux VMs"
    
    # VM Configuration
    vm_user: "root"
    ssh_key_file: "~/.ssh/id_rsa"
    
    # Domain and SSL Configuration
    domain: "example.com"
    acme_email: "admin@example.com"

---
# group_vars/all.yml
# vSphere Settings
vcenter_host: "{{ lookup('env', 'VCENTER_HOST') | default('vcenter.example.com') }}"
vcenter_user: "{{ lookup('env', 'VCENTER_USER') | default('administrator@vsphere.local') }}"
vcenter_pass: "{{ lookup('env', 'VCENTER_PASS') | default('changeme') }}"
datacenter: "{{ lookup('env', 'DATACENTER') | default('Datacenter1') }}"
cluster: "{{ lookup('env', 'CLUSTER') | default('Cluster1') }}"
datastore_name: "{{ lookup('env', 'DATASTORE') | default('datastore1') }}"
network_name: "{{ lookup('env', 'NETWORK') | default('VM Network') }}"

# SSL and Domain Settings
domain: "{{ lookup('env', 'DOMAIN') | default('example.com') }}"
acme_email: "{{ lookup('env', 'ACME_EMAIL') | default('admin@example.com') }}"

# VM Settings
vm_user: "{{ lookup('env', 'VM_USER') | default('root') }}"
ssh_key_file: "{{ lookup('env', 'SSH_KEY_FILE') | default('~/.ssh/id_rsa') }}"

---
# requirements.yml
collections:
  - name: community.vmware
    version: ">=3.0.0"
  - name: ansible.posix
    version: ">=1.0.0"
  - name: community.docker
    version: ">=3.0.0"

---
# ansible.cfg
[defaults]
host_key_checking = False
inventory = inventory.yml
remote_user = root
private_key_file = ~/.ssh/id_rsa
timeout = 30
gathering = smart
fact_caching = memory
stdout_callback = yaml
stderr_callback = yaml

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r