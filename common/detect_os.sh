#!/usr/bin/env bash
# OS detection and package-install hints.
# We never install system packages ourselves; we only tell the user how.

[ -n "${_DOTFILES_DETECT_OS_LOADED:-}" ] && return 0
_DOTFILES_DETECT_OS_LOADED=1

# Prints: macos | linux | unsupported
detect_os() {
    case "$(uname -s)" in
        Darwin) echo macos ;;
        Linux)  echo linux ;;
        *)      echo unsupported ;;
    esac
}

# Prints a coarse package-manager family: brew | apt | dnf | pacman | zypper | apk | unknown
detect_pkg_family() {
    if [ "$(detect_os)" = macos ]; then
        echo brew
        return
    fi
    local ids=''
    if [ -r /etc/os-release ]; then
        # Subshell so os-release variables don't leak into the caller.
        # shellcheck disable=SC1091
        ids="$(. /etc/os-release && printf '%s %s' "${ID:-}" "${ID_LIKE:-}")"
    fi
    case " $ids " in
        *" debian "*|*" ubuntu "*) echo apt ;;
        *" fedora "*|*" rhel "*|*" centos "*) echo dnf ;;
        *" arch "*) echo pacman ;;
        *" suse "*|*" opensuse "*) echo zypper ;;
        *" alpine "*) echo apk ;;
        *) echo unknown ;;
    esac
}

# install_hint <vim|vim-clipboard|git|curl|clipboard-tool>
# Prints a suggested command for the current platform.
install_hint() {
    local what="$1" family
    family="$(detect_pkg_family)"
    case "$family:$what" in
        brew:vim|brew:vim-clipboard) echo "brew install vim" ;;
        brew:git)                    echo "xcode-select --install   (or: brew install git)" ;;
        brew:curl)                   echo "brew install curl" ;;
        brew:clipboard-tool)         echo "pbcopy ships with macOS; check that /usr/bin is on PATH" ;;

        apt:vim)            echo "sudo apt install vim" ;;
        apt:vim-clipboard)  echo "sudo apt install vim-gtk3   (full Vim with +clipboard; terminal 'vim' still works)" ;;
        apt:clipboard-tool) echo "sudo apt install wl-clipboard   (Wayland)   or   sudo apt install xclip   (X11)" ;;

        dnf:vim)            echo "sudo dnf install vim-enhanced" ;;
        dnf:vim-clipboard)  echo "sudo dnf install vim-X11   (provides 'vimx' with +clipboard)" ;;
        dnf:clipboard-tool) echo "sudo dnf install wl-clipboard   or   sudo dnf install xclip" ;;

        pacman:vim)            echo "sudo pacman -S vim" ;;
        pacman:vim-clipboard)  echo "sudo pacman -S gvim   (replaces vim; terminal 'vim' gains +clipboard)" ;;
        pacman:clipboard-tool) echo "sudo pacman -S wl-clipboard   or   sudo pacman -S xclip" ;;

        zypper:vim)            echo "sudo zypper install vim" ;;
        zypper:vim-clipboard)  echo "sudo zypper install gvim" ;;
        zypper:clipboard-tool) echo "sudo zypper install wl-clipboard   or   sudo zypper install xclip" ;;

        apk:vim)            echo "sudo apk add vim" ;;
        apk:clipboard-tool) echo "sudo apk add wl-clipboard   or   sudo apk add xclip" ;;

        apt:*)    echo "sudo apt install $what" ;;
        dnf:*)    echo "sudo dnf install $what" ;;
        pacman:*) echo "sudo pacman -S $what" ;;
        zypper:*) echo "sudo zypper install $what" ;;
        apk:*)    echo "sudo apk add $what" ;;
        *)        echo "install '$what' with your system package manager" ;;
    esac
}
