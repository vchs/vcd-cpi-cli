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
   - CPI_PATH: pointing to `bosh_vcloud_cpi` folder.
   
   Then do `bundle install` once, from now on, keep the above environment variables, you can do `bin/vcd-cli ...`

Commands
--------

Refer to internal design doc. Will be updated here later.
