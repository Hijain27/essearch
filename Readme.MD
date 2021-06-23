http://download.sonatype.com/nexus/3/nexus-3.22.0-02-unix.tar.gz

sudo vim /etc/systemd/system/nexus.service

[Unit]
Description=nexus service
After=network.target
[Service]
Type=forking
LimitNOFILE=65536
User=nexus
Group=nexus
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-abort
[Install]
WantedBy=multi-user.target


sudo systemctl enable nexus
sudo systemctl start nexus
sudo systemctl status nexus
