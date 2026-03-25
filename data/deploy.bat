@echo off
set VPS_IP=144.21.35.78
set KEY_PATH="C:\Users\jespe\OneDrive\Documenten\ssh-key-2026-03-25.key"

echo [1/4] Uploading server.js to Oracle VPS...
scp -i %KEY_PATH% server.js opc@%VPS_IP%:/home/opc/server.js

echo [2/4] Setting up Environment (Node.js 20)...
ssh -i %KEY_PATH% opc@%VPS_IP% "if ! command -v node &> /dev/null; then curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash - && sudo dnf install -y nodejs; fi"

echo [2.5/4] Opening Linux Internal Firewall...
:: This ensures port 8080 is open inside the Linux OS itself
ssh -i %KEY_PATH% opc@%VPS_IP% "sudo firewall-cmd --permanent --add-port=8080/tcp 2>/dev/null; sudo firewall-cmd --reload 2>/dev/null"

echo [3/4] Ensuring PM2 is installed...
ssh -i %KEY_PATH% opc@%VPS_IP% "if ! command -v pm2 &> /dev/null; then sudo npm install -g pm2; fi"

echo [4/4] Starting/Restarting the Flappy Server...
ssh -i %KEY_PATH% opc@%VPS_IP% "sudo /usr/bin/pm2 delete flappy 2>/dev/null; sudo /usr/bin/pm2 start /home/opc/server.js --name 'flappy' && sudo /usr/bin/pm2 save"

echo ----------------------------------------------------
echo ALL-IN-ONE DEPLOY SUCCESSFUL!
echo Your server is now live at %VPS_IP%
echo ----------------------------------------------------
pause