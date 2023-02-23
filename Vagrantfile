# -*- mode: ruby -*-

# vi: set ft=ruby :

git_key = ENV["GIT_KEY"] || ""
dns1 = ENV["DNS1"] || "1.1.1.1"
dns2 = ENV["DNS2"] || "1.0.0.1"
cpu = ENV["CPU"] || 8
ram = ENV["RAM"] || 45056

Vagrant.configure(2) do |config|

  config.vm.box = "generic/ubuntu2004"
  config.vm.hostname = "openstack"
  config.vm.network :private_network, ip: "10.1.2.10"
  config.vm.network :private_network, ip: "10.1.2.11", auto_config: false
  config.vm.provider :libvirt do |libvirt|
    libvirt.cpus = cpu
    libvirt.memory = ram
    libvirt.nested = true
    libvirt.machine_virtual_size = 250
  end
  config.vm.provision "file", source: "ansible.cfg", destination: "/tmp/ansible.cfg"
  config.vm.synced_folder ".", "/vagrant", type: "nfs", mount_options: ["vers=3,tcp"]
  config.vm.provision "shell", env: {"DNS1"=>dns1,"DNS2"=>dns2,"GIT_KEY"=>git_key,"RAM"=>ram}, inline: <<-SHELL
    growpart /dev/vda 3
    resize2fs /dev/vda3
    sed -i "s/4.2.2.1/$DNS1/g" /etc/netplan/01-netcfg.yaml
    sed -i "s/4.2.2.2/$DNS2/g" /etc/netplan/01-netcfg.yaml
    sed -i "s/4.2.2.1/$DNS1/g" /etc/systemd/resolved.conf
    sed -i "s/4.2.2.2/$DNS2/g" /etc/systemd/resolved.conf
    systemctl restart systemd-resolved
    netplan apply
    snap install core snapd
    snap install terraform --classic
    snap install kubectl --classic
    snap install helm --classic
    apt update
    apt install -y python3-dev libffi-dev gcc libssl-dev python3-venv python3-docker pipenv jq
    apt install --reinstall ca-certificates
    python3 -m venv /root/kolla-ansible-venv
    source /root/kolla-ansible-venv/bin/activate
    pip3 install 'ansible>=4,<6'
    pip3 install git+https://opendev.org/openstack/kolla-ansible@stable/yoga
    mkdir -p {/etc/kolla,/etc/ansible}
    mv /tmp/ansible.cfg /etc/ansible/ansible.cfg
    cp -r /root/kolla-ansible-venv/share/kolla-ansible/etc_examples/kolla/* /etc/kolla
    cp  /root/kolla-ansible-venv/share/kolla-ansible/ansible/inventory/* /root/
    sed -i -e '/\#kolla_base_distro/c\\kolla_base_distro: "ubuntu"' -e '/\#kolla_install_type/c\\kolla_install_type: "source"'\
           -e '/\#kolla_internal_vip_address/c\\kolla_internal_vip_address: "10.1.2.9"' -e '/\#network_interface/c\\network_interface: "eth1"'\
           -e '/\#neutron_external_interface/c\\neutron_external_interface: "eth2"'\
           -e '/\#nova_console/c\\nova_console: "spice"' /etc/kolla/globals.yml
    sed -i -e '/127.0.2.1/d' /etc/hosts

    kolla-ansible install-deps
    kolla-genpwd
    kolla-ansible -i /root/all-in-one bootstrap-servers
    kolla-ansible -i /root/all-in-one prechecks
    kolla-ansible -i /root/all-in-one deploy || kolla-ansible -i /root/all-in-one deploy
    kolla-ansible -i /root/all-in-one post-deploy

    deactivate
    echo "source /etc/kolla/admin-openrc.sh" >> /root/.bashrc
    pip3 install python-openstackclient
    source /etc/kolla/admin-openrc.sh
    sed -i 's/10.0/10.1/g' /root/kolla-ansible-venv/share/kolla-ansible/init-runonce
    /root/kolla-ansible-venv/share/kolla-ansible/init-runonce
    echo "    eth2: {}" >> /etc/netplan/50-vagrant.yaml
    ip link set eth2 up

    if openstack application credential show demo > /dev/null 2> /dev/null; then
      export OS_APPLICATION_CREDENTIAL_ID=`openstack application credential show demo -f json | jq '.id' | tr -d '"'`
    else
      export OS_APPLICATION_CREDENTIAL_ID=`openstack application credential create --unrestricted --role admin --role heat_stack_owner --secret password demo -f json | jq '.id' | tr -d '"'`
    fi
    export OS_AUTH_TYPE=v3applicationcredential
    export OS_INTERFACE=public
    export OS_APPLICATION_CREDENTIAL_SECRET=password
    unset OS_AUTH_PLUGIN OS_ENDPOINT_TYPE OS_PASSWORD OS_PROJECT_DOMAIN_NAME\
     OS_PROJECT_NAME OS_TENANT_NAME OS_USERNAME OS_USER_DOMAIN_NAME

    cd /root
    echo $GIT_KEY | base64 -d > /root/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa
    rm /root/.ssh/id_rsa.pub
    echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > /root/.ssh/config
    git clone -b v1.1.5 https://gitlab.ics.muni.cz/muni-kypo-crp/devops/kypo-crp-tf-deployment.git
    cd /root/kypo-crp-tf-deployment/tf-openstack-base
    terraform init
    export TF_VAR_external_network_name=public1
    export TF_VAR_dns_nameservers='["'$DNS1'","'$DNS2'"]'
    export TF_VAR_standard_small_disk="10"
    export TF_VAR_standard_medium_disk="10"
    if (( $RAM < 45056 )); then
      export TF_VAR_csirtmu_tiny_ram="1024"
      export TF_VAR_standard_small_ram="1024"
      export TF_VAR_standard_medium_ram="1024"
      export TF_VAR_standard_large_ram="8196"
    fi
    terraform apply -auto-approve -var-file tfvars/vars-all.tfvars
    mkdir -p /root/.kube
    cp /root/kypo-crp-tf-deployment/tf-openstack-base/config /root/.kube/config
    export TF_VAR_acme_contact="demo@kypo.cz"
    export TF_VAR_application_credential_id=$OS_APPLICATION_CREDENTIAL_ID
    export TF_VAR_application_credential_secret=$OS_APPLICATION_CREDENTIAL_SECRET
    export TF_VAR_gen_user_count=10
    export TF_VAR_guacamole_admin_password=password
    export TF_VAR_guacamole_user_password=password
    export TF_VAR_head_host=`terraform output -raw cluster_ip`
    export TF_VAR_head_ip=`terraform output -raw cluster_ip`
    export TF_VAR_kubernetes_host=`terraform output -raw cluster_ip`
    export TF_VAR_kubernetes_client_certificate=`terraform output -raw kubernetes_client_certificate`
    export TF_VAR_kubernetes_client_key=`terraform output -raw kubernetes_client_key`
    export TF_VAR_kypo_crp_head_version="1.1.9"
    export TF_VAR_kypo_postgres_version="2.1.0"
    export TF_VAR_os_auth_url=$OS_AUTH_URL
    export TF_VAR_proxy_host=`terraform output -raw proxy_host`
    export TF_VAR_proxy_key=`terraform output -raw proxy_key`
    export TF_VAR_git_config='{type="INTERNAL",server="git-internal.kypo",sshPort="22",restServerUrl="http://git-internal.kypo:5000/",user="git",privateKey="",accessToken="no-gitlab-token",ansibleNetworkingUrl="git@git-internal.kypo:/repos/backend-python/ansible-networking-stage/kypo-ansible-stage-one.git",ansibleNetworkingRev="v1.0.11"}'
    export TF_VAR_oidc_providers='[{url="https://'$TF_VAR_head_host':443/csirtmu-dummy-issuer-server/",logoutUrl="https://'$TF_VAR_head_host':443/csirtmu-dummy-issuer-server/endsession",clientId="'`head -n 300 /dev/urandom | tr -dc 'A-Za-z' | fold -w 36 | head -n 1`'",label = "Login with local issuer",issuerIdentifier="", userInfoUrl="", responseType=""}]'
    export TF_VAR_users='{"kypo-admin"={iss="https://'$TF_VAR_head_host':443/csirtmu-dummy-issuer-server/",password="password",email="kypo-admin@example.com",fullName="Demo Admin",givenName="Demo",familyName="Admin",admin=true}}'
    cd /root/kypo-crp-tf-deployment/tf-head-services
    sed -i -e "s/1.1.1.1/$DNS1/" -e "s/1.0.0.1/$DNS2/" values.yaml
    terraform init
    terraform apply -auto-approve
    echo "ALL DONE. Open https://$TF_VAR_head_host/"
    echo "Login: kypo-admin"
    echo "Password: password"
    echo "Import demo training with URL git@git-internal.kypo:/repos/prototypes-and-examples/sandbox-definitions/kypo-crp-demo-training.git"
    echo "Import adaptive demo training with URL git@git-internal.kypo:/repos/prototypes-and-examples/sandbox-definitions/kypo-crp-demo-training-adaptive.git"
  SHELL
end
