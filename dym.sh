#!/bin/bash

# Ana Başlık
function show_title {
    echo -e "\n\e[1;33m=============================================\e[0m"
    echo -e "\e[1;33m\t\tMolla202 - Dymension Floopyland Kurulum Scripti\e[0m"
    echo -e "\e[1;33m=============================================\e[0m"
    echo -e "\n"
}

show_title

read -p "Düğüm adını girin (moniker): " MONIKER

{
# Güncelleme ve kütüphane kurulumu
echo -e "\e[1;34mGüncelleme ve kütüphane kurulumu...\e[0m"
sudo apt -q update
sudo apt -qy install curl git jq lz4 build-essential
sudo apt -qy upgrade

# Go Kurulumu
echo -e "\e[1;34mGo kurulumu...\e[0m"
ver="1.20.3"
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> \$HOME/.bash_profile
source \$HOME/.bash_profile
go version

# Dymension Klonlama ve Derleme
echo -e "\e[1;34mDymension klonlama ve derleme...\e[0m"
cd \$HOME
rm -rf dymension
git clone https://github.com/dymensionxyz/dymension.git
cd dymension
git checkout v1.0.2-beta
make build
mkdir -p \$HOME/.dymension/cosmovisor/genesis/bin
mv build/dymd \$HOME/.dymension/cosmovisor/genesis/bin/
rm -rf build
sudo ln -s \$HOME/.dymension/cosmovisor/genesis \$HOME/.dymension/cosmovisor/current -f
sudo ln -s \$HOME/.dymension/cosmovisor/current/bin/dymd /usr/local/bin/dymd -f

# Cosmovisor ve Servis Kurulumu
echo -e "\e[1;34mCosmovisor ve servis kurulumu...\e[0m"
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.4.0
sudo tee /etc/systemd/system/dymd.service > /dev/null << EOF
[Unit]
Description=dymension node service
After=network-online.target

[Service]
User=\$USER
ExecStart=\$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=\$HOME/.dymension"
Environment="DAEMON_NAME=dymd"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:\$HOME/.dymension/cosmovisor/current/bin"

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable dymd

# Dymd Yapılandırması
echo -e "\e[1;34mDymd yapılandırması...\e[0m"
dymd config chain-id froopyland_100-1
dymd config keyring-backend test
dymd config node tcp://localhost:14657
dymd init \$MONIKER --chain-id froopyland_100-1

# Diğer Yapılandırmalar
echo -e "\e[1;34mDiğer yapılandırmalar...\e[0m"
curl -Ls https://raw.githubusercontent.com/molla202/Dymension-Froopyland/main/genesis.json
curl -Ls https://raw.githubusercontent.com/molla202/Dymension-Froopyland/main/addrbook.json
sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@dymension-testnet.rpc.kjnodes.com:14659\"|" \$HOME/.dymension/config/config.toml
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.025udym,0.025uatom\"|" \$HOME/.dymension/config/app.toml
sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  \$HOME/.dymension/config/app.toml
sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:14658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:14657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:14660\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:14656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":14666\"%" \$HOME/.dymension/config/config.toml
sed -i -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:14617\"%; s%^address = \":8080\"%address = \":14680\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:14690\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:14691\"%; s%:8545%:14645%; s%:8546%:14646%; s%:6065%:14665%" \$HOME/.dymension/config/app.toml

# Servisi Başlat ve Logları İzle
echo -e "\e[1;34mServisi başlatma ve logları izleme...\e[0m"
sudo systemctl start dymd
echo -e "\e[1;34mServis başlatıldı. Logları kontrol etmek için aşağıdaki komutu kullanabilirsiniz:\e[0m"
echo -e "\e[1;36msudo journalctl -u dymd -f --no-hostname -o cat\e[0m"
} &> /dev/null

echo -e "\e[1;32mKurulum tamamlandı.\e[0m"
