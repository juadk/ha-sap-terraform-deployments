#!/bin/bash -xe

exec > /tmp/init_server.log 2>&1

# Wait for the provisioner file step in Terraform
while [[ ! -d "/root/salt/" ]];do
  echo "Waiting for Salt directory..."
  sleep 5
done

# Salt minion installation
if [[ ${qa_reg_code} != "empty" ]]; then
  if grep -q 'role: "iscsi_srv"' /tmp/grains; then
    sh /root/salt/install-salt-minion.sh -r ${qa_reg_code}
  else
    sh /root/salt/install-salt-minion.sh -d -r ${qa_reg_code}
  fi
  mv /tmp/grains /etc/salt/
fi

# Server configuration
sh /root/salt/deployment.sh

# Salt formulas execution
[[ -d /srv/salt ]] && sh /root/salt/formula.sh
