# terraform/inventory.tpl
all:
  children:
    traefik:
      hosts:
        traefik-server:
          ansible_host: ${traefik_ip}
          ansible_user: root
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
    nginx:
      hosts:
        nginx-proxy:
          ansible_host: ${nginx_ip}
          ansible_user: root
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
    stepca:
      hosts:
        stepca-server:
          ansible_host: ${stepca_ip}
          ansible_user: root
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
  vars:
    domain: ${domain}
    artifactory_url: ${artifactory_url}
    traefik_ip: ${traefik_ip}
    nginx_ip: ${nginx_ip}
    stepca_ip: ${stepca_ip}
