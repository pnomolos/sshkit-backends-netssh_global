# SSHKit Global As

**SSHKit Global As** is a backend to be used in conjunction with Capistrano 3
and SSHKit to allow deployment on setups where users login as one identity and
then need to sudo to a different identity for each command.

This works globally so that default tasks will automatically `sudo` without
modification. This allows the default tasks to be used in this kind of setup
without them being altered.

`as` blocks are still possible and will override this global setting.

In some setups the ssh agent also needs to be forwarded (such as git clone).
Here the setting `ssh_commands` can be set to automatically forward the ssh
agent to the sudo user for certain commands.

### To run tests

To setup an OSX machine to run the tests, install Homebrew then:

```
brew tap Homebrew/bundle
brew bundle
vagrant up --provision
bundle
rake
```

### Usage

```ruby
require 'sshkit/backends/netssh_global_as'

set :user, 'bob'   # (Capistrano default) the user we will login as
set :owner, 'app1' # (New setting) the user we will globally sudo as
set :ssh_commands, [:git, :bundle] # (New setting) the commands which require
                                   # access to bob's ssh agent

set :sshkit_backend, Sshkit::Backends::NetsshGlobalAs
```

### Credits

The code and test suite are built on top of [SSHKit](http://github.com/capistrano/sshkit).
