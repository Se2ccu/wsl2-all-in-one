# FOR WSL2 based on ubuntu22.04
sudo apt update && sudo apt upgrade -y
sudo apt install -y net-tools dnsutils iputils-ping git curl zsh build-essential ca-certificates

# 网络代理
export http_proxy="http://x.x.x.x:3128"
export https_proxy=${http_proxy}

# apt代理
sudo vim /etc/apt/apt.conf
Acquire::https::proxy "http://x.x.x.x:3128/";
Acquire::http::proxy "http://x.x.x.x:3128/";
Acquire::http::Verify-Peer "false";
Acquire::https::Verify-Peer "false";

# git配置
ssh-keygen -t ed25519 -C "your_email@example.com"
# add to github.com ssh key
git config --global http.sslVerify "false"
git config --global user.name "ccu"
git config --global user.email "ccu@example.com"
git init
git add .
git commit -m "first commit"
git push 
git pull

#增加CA证书
sudo cp mycert.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# 用户切换终端为zsh
chsh -s /bin/zsh

# install oh-my-zsh  查看DNS配置是否正确：nslookup raw.githubusercontent.com
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# zsh自动补全和高亮插件
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 修改zsh配置文件（主题和插件）
# sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="ys"/' ~/.zshrc
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting z extract web-search)/' ~/.zshrc

# 重新加载zsh配置文件
source ~/.zshrc

# uv + python包
wget -qO- https://astral.sh/uv/install.sh | sh
# 自动补全
echo 'eval "$(uv generate-shell-completion zsh)"' >> ~/.zshrc

# semgrep代码静态扫描工具环境
mkdir semgrep
cd semgrep
uv init python-venv
uv add semgrep
#uv run semgrep --severity ERROR --severity WARNING --config /mnt/d/CodeKing/Choul /mnt/d/code --sarif --sarif-output scan_results.sarif

# python科学计算+编程环境
uv init python-base
uv add numpy scipy cryptography

# gdb + gef
sudo apt-get install gdb
git clone https://github.com/hugsy/gef.git ~/.gef
echo "source ~/.gef/gef.py" >> ~/.gdbinit

# 网络协议测试
sudo apt install wireshark -y
sudo dpkg-reconfigure wireshark-common
sudo usermod -aG wireshark $USER
newgrp wireshark

# rust工具链安装
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup default stable
#cargo install asnfuzzgen


# srsran-4G
sudo apt-get install libuhd-dev uhd-host
sudo -E uhd_images_downloader --verbose  # 需要单独继承代理环境变量

# usb无法直接识别usrp b210需要绑定并映射usb，参考https://learn.microsoft.com/zh-cn/windows/wsl/enterprise

sudo apt-get install build-essential cmake libfftw3-dev libmbedtls-dev libboost-program-options-dev libconfig++-dev libsctp-dev libnuma-dev libpcap-dev -y
git clone https://github.com/srsRAN/srsRAN_4G.git
cd srsRAN_4G
mkdir build
cd build
cmake ../
make -j $(nproc)
sudo make install
sudo ldconfig
sudo srsran_4g_install_configs.sh user
# 将基站或者ue的配置example文件同步到./root/.config/srsran/ue.conf or enb.conf
sudo srsue
sudo srsenb

# open5gs.mongodb
sudo apt update
sudo apt install gnupg
curl -fsSL https://pgp.mongodb.com/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
#open5gs
sudo -E add-apt-repository ppa:open5gs/latest # must add -E，否则代理环境变量无法获取
sudo apt update
sudo apt install open5gs


