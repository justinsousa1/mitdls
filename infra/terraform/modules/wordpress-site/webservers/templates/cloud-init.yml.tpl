#cloud-config
write_files:
  - path: /etc/profile.d/automation-vars.sh
    owner: root:root
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      export ENVIRONMENT_NAME=${environment_name}
      export INSTANCE_ID="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
      export INSTANCE_ID_TRIMMED="$(echo $INSTANCE_ID | cut -d '-' -f 2)"
      export AWS_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
      export LOCAL_IP="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"

      aws configure set region $AWS_REGION

  - path: /root/mount-efs-drive.sh
    owner: root:root
    permissions: "0755"
    content: |
      #!/usr/bin/env bash

      static_files_efs_id=$(aws efs describe-file-systems  --creation-token ${static_files_efs_id} | jq -r .FileSystems[].FileSystemId)

      # let's imagine we're using nginx in front of wordpress, you can mount the files into
      # the webroot from the EFS drive
      if ! mountpoint -q /usr/share/; then
        mount -t efs -o tls $static_files_efs_id:/ /usr/share/nginx/html
      fi

      nginx -t
      systemctl enable nginx
      systemctl restart nginx


  - path: /etc/wordpress/bootstrap-db-cnx.sh
    owner: root:root
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      AWS_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
      aws configure set region $AWS_REGION

      DB_CONNECTION=$(aws secretsmanager get-secret-value --secret-id  /wordpress/${environment_name}/db-connection-info | jq -r .SecretString)
      DB_HOST=$(echo $DB_CONNECTION | jq -r .host)
      DB_PORT=5432
      DB_USERNAME=$(echo $DB_CONNECTION | jq -r .username)
      DB_PASSWORD=$(echo $DB_CONNECTION | jq -r .password)

      # Use these variables somewhere like store them in a flat file or however wordpress is configured
      cat > /etc/wordpress/db-connection.yml <<DBAUTH

      address: $DB_HOST
      username: $DB_USERNAME
      password: $DB_PASSWORD
      port: $DB_PORT
      DBAUTH

      chown wordpress:wordpress /etc/wordpress/db-connection.yml

runcmd:
  - source /etc/profile.d/automation-vars.sh
  - sleep 1
  - /bin/bash /root/mount-efs-drive.sh
  - /bin/bash /etc/wordpress/bootstrap-db-cnx.sh
  - systemctl enable wordpress
  - systemctl restart wordpress

# this is just an example cloud-init script that would be put into user_data for the launch template
# in general you want to separate build time from runtime bootstrapping. build time that is part of building the app itself
# should go into the packer / AMI build process whereas runtime information can go into user data.
# other things you could do here
# if not using a load balancer you could point the DNS w/ aws route53 cli commands and the IP address retrieved from
# the local metadata endpoint. you can also install a tls cert with certbot/letsencrypt.
# take care to not grant more route53 IAM permissions than are necessary.
# run test scripts to validate the bootstrapping is successful and alert if not.