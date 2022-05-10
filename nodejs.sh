#!/bin/bash
sudo apt update -y
sudo apt install git -y
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 16.15.0
nvm use 16.15.0
git clone https://github.com/FestineOnGCP/react-nodejs.git
cd /home/ubuntu/react-nodejs/my-app
npm install
npm audit fix
npm run build
sudo mkdir -p /var/www/html/my-app
sudo mv ./build/ /var/www/html/my-app/build
sudo mv ../api /var/www/html/api
cd /var/www/html/api
npm install
npm install pm2 -g
npm audit fix
pm2 --name test-app start node -- ./server.js
source ~/.bashrc
exit
exit

