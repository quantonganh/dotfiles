set PATH ~/go/bin ~/.cargo/bin (go env GOROOT)/misc/wasm $PATH

alias b="brew"
alias bi="brew install"
alias bo="brew info"
alias bl="brew list"
alias br="brew uninstall"
alias bs="brew search"
alias bu="brew upgrade"
alias bud="brew update"

alias ch="cht.sh"
alias c99="clang"

alias d="docker"
alias dc="docker-compose $1"
alias de="docker exec -it $1 /bin/bash"
alias dl="docker logs $1"
alias dps="docker ps | grep $1"

function gdoc
	command go doc $argv | less -FX
end

alias gg="BROWSER=w3m googler -n 3"
alias h="howdoi"
alias h2="how2"
alias http="xh"

alias k="kubectl"
alias n="nb"

alias sc="supervisorctl"
alias sed="gsed"

alias t="tig"
alias tl="tig log"
alias tb="tig blame"
alias tg="tig grep"
alias ts="tig status"
alias tsh="tig stash"
alias tw="taskwarrior-tui"

alias ..="cd .."
# alias ag="rg -g '!vendor/*' $1"
alias c="bat"
alias lg="lazygit"
alias lad="lazydocker"
alias ls="exa"
alias o="open"
alias ss="salt-call -l debug state.sls"
alias v="hx"
alias wt="wezterm"

direnv hook fish | source

# The next line updates PATH for the Google Cloud SDK.
if [ -f '~/Downloads/google-cloud-sdk/path.fish.inc' ]; . '~/Downloads/google-cloud-sdk/path.fish.inc'; end
