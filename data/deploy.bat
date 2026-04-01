@echo off
set VPS_IP=144.21.35.78
set KEY_PATH="C:\Users\jespe\OneDrive\Documenten\ssh-key-2026-03-25.key"
set KOFI_TOKEN=e2e34b8d-e0e4-4b1d-a706-adb06c74f3ed

echo [1/4] Uploading server.js to Oracle VPS...
scp -i %KEY_PATH% server.js opc@%VPS_IP%:/home/opc/server.js

echo [2/4] Setting up Environment (Node.js 20)...
ssh -i %KEY_PATH% opc@%VPS_IP% "if ! command -v node &> /dev/null; then curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash - && sudo dnf install -y nodejs; fi"

echo [2.5/4] Opening Linux Internal Firewall...
ssh -i %KEY_PATH% opc@%VPS_IP% "sudo firewall-cmd --permanent --add-port=8080/tcp 2>/dev/null; sudo firewall-cmd --permanent --add-port=8081/tcp 2>/dev/null; sudo firewall-cmd --reload 2>/dev/null; sudo iptables -I INPUT -p tcp -m tcp --dport 8080 -j ACCEPT; sudo iptables -I INPUT -p tcp -m tcp --dport 8081 -j ACCEPT; sudo iptables -I INPUT -p tcp -m tcp --dport 22 -j ACCEPT; sudo iptables -I INPUT -p icmp -j ACCEPT; sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null 2>&1; sudo netfilter-persistent save 2>/dev/null"

echo [3/4] Ensuring PM2 is installed...
ssh -i %KEY_PATH% opc@%VPS_IP% "if ! command -v pm2 &> /dev/null; then sudo npm install -g pm2; fi"

echo [4/4] NUKING OLD PROCESSES AND RESTARTING...
ssh -i %KEY_PATH% opc@%VPS_IP% "sudo pm2 kill; sudo fuser -k 8080/tcp 2>/dev/null; sudo fuser -k 8081/tcp 2>/dev/null; sudo rm -rf /root/.pm2/dump.pm2; sudo ADMIN_KEY=flappyAdmin2026 KOFI_TOKEN=%KOFI_TOKEN% pm2 start /home/opc/server.js --name 'flockfall'; sudo pm2 save"

echo ----------------------------------------------------
echo DEPLOY SUCCESSFUL! PORTS 8080/8081 ARE NOW CLEAN.
echo Opening Live Logs... (Press Ctrl+C to stop logging)
echo ----------------------------------------------------

ssh -i %KEY_PATH% opc@%VPS_IP% "sudo pm2 logs flockfall"
pause