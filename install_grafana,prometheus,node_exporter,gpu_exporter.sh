PROMETHEUS_VERSION="3.1.0"
PROMETHEUS_ARCHIVE="prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
PROMETHEUS_DIR="prometheus-${PROMETHEUS_VERSION}.linux-amd64"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/prometheus"
DATA_DIR="/var/lib/prometheus"
SERVICE_FILE="/etc/systemd/system/prometheus.service"

sudo wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/${PROMETHEUS_ARCHIVE}
sudo tar vxf ${PROMETHEUS_ARCHIVE}
sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus
sudo mkdir -p ${CONFIG_DIR} ${DATA_DIR}
sudo cd ${PROMETHEUS_DIR}
sudo mv prometheus promtool ${INSTALL_DIR}
sudo mv console* ${CONFIG_DIR}
sudo mv prometheus.yml ${CONFIG_DIR}
sudo chown prometheus:prometheus ${INSTALL_DIR}/prometheus
sudo chown prometheus:prometheus ${INSTALL_DIR}/promtool
sudo chown prometheus:prometheus ${CONFIG_DIR}
sudo chown -R prometheus:prometheus ${CONFIG_DIR}/consoles
sudo chown -R prometheus:prometheus ${CONFIG_DIR}/console_libraries
sudo chown -R prometheus:prometheus ${DATA_DIR}


sudo cat <<EOF | sudo tee ${CONFIG_DIR}/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'gpu'
     static_configs:
      - targets: ['localhost:9835']
EOF

cat <<EOF | sudo tee ${SERVICE_FILE}
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=${INSTALL_DIR}/prometheus \
 --config.file ${CONFIG_DIR}/prometheus.yml \
 --storage.tsdb.path ${DATA_DIR}/ \
 --web.console.templates=${CONFIG_DIR}/consoles \
 --web.console.libraries=${CONFIG_DIR}/console_libraries

[Install]
WantedBy=multi-user.target
EOF


sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus



NODE_EXPORTER_VERSION="1.8.2"
NODE_EXPORTER_ARCHIVE="node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
NODE_EXPORTER_DIR="node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"
INSTALL_DIR="/etc/node_exporter"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"

sudo wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${NODE_EXPORTER_ARCHIVE}
sudo tar xzf ${NODE_EXPORTER_ARCHIVE}
sudo rm -rf ${NODE_EXPORTER_ARCHIVE}
sudo mv ${NODE_EXPORTER_DIR} ${INSTALL_DIR}

cat <<EOF | sudo tee ${SERVICE_FILE}
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=${INSTALL_DIR}/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl restart node_exporter


sudo apt-get install -y apt-transport-https software-properties-common wget
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com beta main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install grafana -y
sudo apt-get install grafana-enterprise -y
sudo systemctl daemon-reload
sudo systemctl start grafana-server


VERSION="1.1.0"
ARCHIVE="nvidia_gpu_exporter_${VERSION}_linux_x86_64.tar.gz"
INSTALL_DIR="/usr/bin"
SERVICE_FILE="/etc/systemd/system/nvidia_gpu_exporter.service"

wget https://github.com/utkuozdemir/nvidia_gpu_exporter/releases/download/v${VERSION}/${ARCHIVE}
tar -xvzf ${ARCHIVE}
sudo mv nvidia_gpu_exporter ${INSTALL_DIR}
nvidia_gpu_exporter --help
sudo useradd --system --no-create-home --shell /usr/sbin/nologin nvidia_gpu_exporter

cat <<EOF | sudo tee ${SERVICE_FILE}
[Unit]
Description=Nvidia GPU Exporter
After=network-online.target

[Service]
Type=simple
User=nvidia_gpu_exporter
Group=nvidia_gpu_exporter
ExecStart=${INSTALL_DIR}/nvidia_gpu_exporter
SyslogIdentifier=nvidia_gpu_exporter
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now nvidia_gpu_exporter
sudo systemctl start nvidia_gpu_exporter

sudo systemctl status prometheus
sudo systemctl status grafana-server
sudo systemctl status node_exporter
sudo systemctl status nvidia_gpu_exporter

sudo ufw allow 3000
sudo ufw allow 9100
sudo ufw allow 9090
sudo ufw allow 9835

sudo rm -rf nvidia_gpu_exporter_1.1.0_linux_x86_64.tar.gz prometheus-3.1.0.linux-amd64.tar.gz 
