#!/bin/zsh

autoload colors
colors

function logged_run()
{
    echo "==> ${fg[red]}$1${reset_color}"
    result=$(eval "$2" 2>&1)
    if (( $? != 0 )); then
        echo $result | less
    fi
}

function config_pacman()
{
    pacman -Sy
    cp /etc/pacman.conf /etc/pacman.conf.orig
    cat /etc/pacman.conf.orig | sed 's/^SigLevel\(.*\)/SigLevel = PackageRequired/' > /etc/pacman.conf
    pacman-key --init
    pacman-key --populate archlinux
}

function install_package()
{
    pacman -Sy --noconfirm $1
}

function rank_mirrors()
{
    read -q "REPLY?Rank mirrors? y/[n] "
    echo -e "\n"
    if [[ "${REPLY}" != "y" ]] ; then
        return
    fi
    logged_run "Installing reflector" "install_package reflector"

    cp -vf /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig
    logged_run "Ranking..." "reflector --verbose -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist"
}

function install_base_devel()
{
    logged_run "Installing base-devel" "install_package base-devel"
}

function install_ruby()
{
    logged_run "Installing Ruby" "install_package ruby"
    logged_run "Installing gems" "gem install parseconfig json"
}

function get_file()
{
    curl -O "${BASE_URL}/$1"
}

function config_makepkg()
{
    cp /etc/makepkg.conf /etc/makepkg.conf.orig
    get_file "config_makepkg.rb"
    logged_run "Configure Makepkg" "ruby config_makepkg.rb"
}

function build_aur_package()
{
    opwd=$(pwd)
    cd /tmp
    
    a=("${(s:/:)1}")
    arc_name=$a[-1]
    a=("${(s/./)arc_name}")
    dir_name=$a[1]

    curl -sSLO $1
    su pkg_build -c "tar xzpf $arc_name"
    cd $dir_name
    su pkg_build -c makepkg
    pkg_file=$(ls *.pkg.tar.xz)
    pacman -U --noconfirm "$pkg_file"
    cd /tmp
    rm -rf $dir_name
    cd $opwd
}

function install_powerpill()
{
    echo "Installing Powerpill"
    deps="python-xdg aria2 pyalpm rsync"
    python3_aur_url="https://aur.archlinux.org/cgit/aur.git/snapshot/python3-aur.tar.gz"
    pm2ml_url="https://aur.archlinux.org/cgit/aur.git/snapshot/pm2ml.tar.gz"
    powerpill_url="https://aur.archlinux.org/cgit/aur.git/snapshot/powerpill.tar.gz"

    # Install deps from official repos
    for p in "${(s/ /)deps}"; do
        logged_run "Installing $p" "install_package $p"
    done

    # Build Powerpill and deps from Aur
    useradd pkg_build
    mkdir -p /home/pkg_build/.gnupg/
    echo "keyring /etc/pacman.d/gnupg/pubring.gpg" > /home/pkg_build/.gnupg/gpg.conf
    chown -R pkg_build /home/pkg_build
    
    logged_run "Installing python3-aur" "build_aur_package ${python3_aur_url}"
    logged_run "Installing pm2ml" "build_aur_package ${pm2ml_url}"
    logged_run "Installing powerpill" "build_aur_package ${powerpill_url}"
    
    userdel pkg_build
    rm -rf /home/pkg_build

    # Config Powerpill    
    # Rank rsync mirrors and paste them into Powerpills config file
    logged_run "Ranking rsync mirrors" "reflector --verbose -l 200 -p rsync --sort rate --save /tmp/mirrorlist.rsync"
    cat /tmp/mirrorlist.rsync | grep "Server =" | sed 's/Server = //g' > /tmp/mirrorlist.rsync.filtered
    get_file "config_powerpill.rb"
    cp /etc/powerpill/powerpill.json /etc/powerpill/powerpill.json.orig
    logged_run "Configure Powerpill" "ruby config_powerpill.rb"
}

function copy_config_files()
{
    read "prefix?Enter prefix [/mnt/]: "
    if [[ "$prefix" == "" ]]; then
        prefix="/mnt/"
    fi
    if [[ ! -d $prefix ]]; then
        echo "No such directory: $prefix"
        return
    fi

    local -a config_files
    config_files=(
        "/etc/pacman.conf"
        "/etc/pacman.d/mirrorlist"
        "/etc/powerpill/powerpill.json"
        #"/etc/makepkg.conf"
    )

    for file in $config_files; do
        dest="${prefix}/${file}"
        if [[ -f $dest ]]; then
            mv "$dest" "${dest}.orig"
        fi
        cp $file $dest
    done
}

typeset -A menu_done

function menu()
{
    c=-1
    while (( c != 0 )); do
        local -a menu_items
        menu_items=(
            "Configure Pacman:config_pacman"
            "Rank mirrors using reflector:rank_mirrors"
            "Install base-devel:install_base_devel"
            "Install Ruby:install_ruby"
            "Configure Makepkg (broken!):config_makepkg"
            "Install Powerpill+deps:install_powerpill"
            "Copy config files to install prefix:copy_config_files"
        )

        for i in $(seq 1 ${#menu_items}); do
            d=("${(s/:/)menu_items[$i]}")
            if [[ "${menu_done[$i]}" == "1" ]]; then
                done="$fg[green]x${reset_color}"
            else
                done=" "
            fi
            echo "${fg[red]}$i${reset_color}) $done ${d[1]}"
        done
        echo -e "${fg[red]}0${reset_color})   Exit\n"
        read "c?Choice: "

        if (( c>0 && c<=${#menu_items} )); then
            d=("${(s/:/)menu_items[$c]}")
            eval "${d[2]}"
            menu_done[$c]="1"
        fi
        
        echo
        echo "------------------------------------"
    done
}

menu
