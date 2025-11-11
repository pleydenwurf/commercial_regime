ini   [Unit]
   Description=KPX Proxy Service
   After=network.target

   [Service]
   Type=simple
   ExecStart=/usr/local/bin/kpx -c /etc/kpx.yaml
   Restart=on-failure

   [Install]
   WantedBy=multi-user.target
