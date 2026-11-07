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

# install_hint <tool>   e.g. vim, vim-clipboard, git, curl, clipboard-tool, zellij,
#                      neovim, c-compiler, ripgrep, fd, node, go, lazygit, deno
# Prints a suggested command for the current platform.
install_hint() {
    local what="$1" family
    family="$(detect_pkg_family)"
    case "$family:$what" in
        brew:vim|brew:vim-clipboard) echo "brew install vim" ;;
        brew:git)                    echo "xcode-select --install   (or: brew install git)" ;;
        brew:curl)                   echo "brew install curl" ;;
        brew:clipboard-tool)         echo "pbcopy ships with macOS; check that /usr/bin is on PATH" ;;
        brew:zellij)                 echo "brew install zellij" ;;
        brew:c-compiler)             echo "xcode-select --install" ;;
        brew:tar|brew:unzip)         echo "both ship with macOS; check that /usr/bin is on PATH" ;;

        # Neovim: distro packages are often older than the 0.11 AstroNvim needs.
        apt:neovim)    echo "sudo snap install nvim --classic   (apt's neovim is usually too old; or use the AppImage from https://github.com/neovim/neovim/releases)" ;;
        dnf:neovim)    echo "sudo dnf install neovim" ;;
        pacman:neovim) echo "sudo pacman -S neovim" ;;
        apk:neovim)    echo "sudo apk add neovim" ;;
        *:nvim)        install_hint neovim ;;

        apt:c-compiler)    echo "sudo apt install build-essential" ;;
        dnf:c-compiler)    echo "sudo dnf install gcc make" ;;
        pacman:c-compiler) echo "sudo pacman -S base-devel" ;;
        zypper:c-compiler) echo "sudo zypper install gcc make" ;;
        apk:c-compiler)    echo "sudo apk add build-base" ;;

        apt:fd)      echo "sudo apt install fd-find" ;;
        dnf:fd)      echo "sudo dnf install fd-find" ;;
        apt:node)    echo "sudo apt install nodejs npm" ;;
        dnf:node|zypper:node) echo "sudo $([ "$family" = dnf ] && echo dnf || echo zypper) install nodejs npm" ;;
        pacman:node) echo "sudo pacman -S nodejs npm" ;;
        apk:node)    echo "sudo apk add nodejs npm" ;;
        apt:go)      echo "sudo apt install golang-go" ;;
        dnf:go)      echo "sudo dnf install golang" ;;
        *:lazygit)   [ "$family" = brew ] && echo "brew install lazygit" || echo "see https://github.com/jesseduffield/lazygit#installation" ;;
        *:deno)      [ "$family" = brew ] && echo "brew install deno" || echo "curl -fsSL https://deno.land/install.sh | sh" ;;

        brew:*)   echo "brew install $what" ;;

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

        # Not packaged everywhere (e.g. Debian/Ubuntu); cargo works on any Linux.
        pacman:zellij) echo "sudo pacman -S zellij" ;;
        apk:zellij)    echo "sudo apk add zellij" ;;
        *:zellij)      echo "cargo install --locked zellij   (or a release binary: https://github.com/zellij-org/zellij/releases)" ;;

        apt:*)    echo "sudo apt install $what" ;;
        dnf:*)    echo "sudo dnf install $what" ;;
        pacman:*) echo "sudo pacman -S $what" ;;
        zypper:*) echo "sudo zypper install $what" ;;
        apk:*)    echo "sudo apk add $what" ;;
        *)        echo "install '$what' with your system package manager" ;;
    esac
}
