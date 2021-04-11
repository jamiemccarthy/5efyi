# README

```
gem install bundler
bundle install
bin/emit-srd.rb
```

On production server:

```
sudo apt update
sudo apt install -y git screen
ssh-keygen -C deploy_fivee_app -f ~/.ssh/id_rsa_deploy_fivee_app
vi ~/.ssh/config # Host github.com, User git, IdentityFile ~/.ssh/id_rsa_deploy_fivee_app
mkdir ~/p
cd ~/p
git clone git@github.com:jamiemccarthy/fiveefyi.git
sudo apt install gnupg2
gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
cd fiveefyi
rvm install ruby-3.0.1 --default
rvm cleanup all
gem install bundler
bundle install
```

The "deploy" runs in a screen:

```
git pull --ff-only && bundle install --quiet && rails assets:precompile && git log -1 && date && rails s
```
