# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

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
# I'm not a fan of rvm's install, but rbenv doesn't support 2.6.5 (yet?) (on Debian 10?)
sudo apt install gnupg2
gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvm install 3.0.1
gem install bundler
bundle install
```
