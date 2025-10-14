# FOR WSL2 based on ubuntu22.04
sudo apt update && sudo apt upgrade -y
sudo apt install -y net-tools dnsutils iputils-ping git curl zsh

git config --global http.sslVerify "false"

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


# srsran-4G
sudo apt-get install libuhd-dev uhd-host

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
srsran_4g_install_configs.sh user
