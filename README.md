## Table of contents
* [General info](#general-info)
* [Technologies](#technologies)
* [Setup](#setup)
* [Config](#config)

## General info
With this project, you will be able to create a clustershell with hosts listed in foreman for states warning and error.
It excludes Windows, currently

## Technologies
Project is created with:
* Ruby (https://www.ruby-lang.org/de/)
* Puppet (https://www.puppet.com/)
* Foreman (https://www.theforeman.org/)
	
## Setup
```
$ mkdir -p $HOME/puppetclustershell
$ cd $HOME/puppetclustershell
$ git clone
$ bundle install
$ ruby $HOME/puppetclustershell/get_hosts.rb
```

## Config
In the config file you can define your Foreman URL with "path_common" and your username with "user".
You password you will have to enter in the prompt after running the get_hosts.rb


