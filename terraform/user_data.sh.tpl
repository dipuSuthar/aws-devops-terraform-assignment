#!/bin/bash
set -euxo pipefail
dnf install -y nodejs20 nodejs20-npm unzip
mkdir -p /opt/app && cd /opt/app
aws s3 cp s3://${bucket}/${key} app.zip
unzip -o app.zip
npm install --omit=dev

cat > /etc/systemd/system/app.service <<UNIT
[Unit]
Description=DevOps task app
After=network-online.target

[Service]
WorkingDirectory=/opt/app
Environment=PORT=3000
Environment=AWS_REGION=${region}
Environment=DB_SECRET_ARN=${secret_arn}
Environment=APP_BUCKET=${bucket}
ExecStart=/usr/bin/node server.js
Restart=always
User=nobody

[Install]
WantedBy=multi-user.target
UNIT

chown -R nobody:nobody /opt/app
systemctl daemon-reload
systemctl enable --now app
