# dotfiles

configs and systems preferences for all the machines i frequent now and in the future.

obviously you **want to read** the best part... [emacs-config.org](editors/emacs-config.org)

## deployment

`sh deploy.sh` is idempotent and safe to run on every login.

## more info

for now check out the deploy.sh script and the various files; i promise it's not too exciting. ^_^

### lang version philosophy

where possible run the lastest stable version via homebrew as a base version.  if you need a specific version for development use a version manager or docker.

#### current exceptions

- node@22
- corretto21 (amazon jdk)
- postgresql@17

### fun options

create a `~/.box-name` to override the host name that is used for display purposes in zsh
