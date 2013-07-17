vcd-cpi-cli
===========

This is a CLI tool which invokes `ruby_vcloud_sdk` and `bosh_vcloud_cpi` directly, for debugging and testing.

How to use
----------

It depends on how you want to use:

1. You already installed `ruby_vcloud_sdk` and `bosh_vcloud_cpi` through `gem install ...`

   Then, you don't need special operations, just do `bundle install` and you can invoke `bin/vcd-cli ...`

2. You are modifying `ruby_vcloud_sdk` or `bosh_vcloud_cpi`, and you hate building and installing gem very time

   The dynamic loading feature will help you a lot. 
   Set two envionrment variables:
   
   - SDK_PATH: pointing to `ruby_vcloud_sdk` folder;
   - CPI_PATH: pointing to `bosh_vcloud_cpi` folder;
   - BOSH_PATH: pointing to bosh source tree, required by cpi.
   
   Then do `bundle install` once, from now on, keep the above environment variables, you can do `bin/vcd-cli ...`

Commands
--------

Refer to internal design doc. Will be updated here later.

Example
-------

Here's a simple example:

1. Clone source code
```bash
git clone https://github.com/vchs/bosh -b vcloud_cpi_changes
git clone https://github.com/vchs/vcd-cpi-cli
```

2. Setup environment variables and do bundle install
```bash
export BOSH_PATH=`pwd`/bosh
export SDK_PATH=$BOSH_PATH/ruby_vcloud_sdk
export CPI_PATH=$BOSH_PATH/bosh_vcloud_cpi
cd vcd-cpi-cli
bundle install
```

3. Create a configuration file
```bash
cp sample-config.yml _my_config.yml
# update _my_config.yml with your vCloud settings
bin/vcd-cli target ./_my_config.yml
```

4. Start working with cli
```bash
bin/vcd-cli cpi create-stemcell ~/Downloads/vsphere-stemcell-0.8.1.tar.gz
```
