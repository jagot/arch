arch
====

A small script to prepare new installations of Arch Linux.

Run the following at the initial prompt, after having booted the
install medium:

    export BASE_URL="url"
    curl -sSL "${BASE_URL}/arch-install.sh" | zsh

Ideas
-----

* [ ] Automatically install console keyboard layout, patched to use
  CAPS LOCK as an additional Ctrl key.
* [X] Rank mirrors using Reflector.
* [X] Change `SigLevel` in `pacman.conf` to `PackageRequired`
* [ ] Edit `/etc/makepkg.conf` to optimize compiler flags and not
  compress packages (`PKGEXT='.pkg.tar'`).
* [X] Install
  [Powerpill](http://xyne.archlinux.ca/projects/powerpill/) and set it
  up to use Rsync. Must edit `/etc/powerpill/powerpill.json` to
  include Rsync mirrors ranked in the previous step.
* Install Pacaur and configure it to use Powerpill.
* [X] Transfer config files to the new installation.
* [ ] Install some key packages into the new install:
    * Zsh
    * Emacs
* [ ] Add user.
* [ ] Clone configuration files.
