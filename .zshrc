##################################################
# oh-my-zsh configuration
##################################################

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(
  macos
  git
  zsh-syntax-highlighting
  zsh-history-substring-search
  zsh-hangul
  )
ZSH_DISABLE_COMPFIX="true"
source $ZSH/oh-my-zsh.sh
PROMPT='%(?.%B%F{purple}▲%f%b.%B%F{red}x%f%b) '

##################################################
# My configuration
##################################################

# Korean
LANG=ko_KR.UTF-8

# Dotfiles
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# Alias
alias atop="sudo asitop"
alias bye="exit"
alias cask="brew install --cask"
alias cc="claude"
alias cl="clear"
alias code="zed-preview"
alias cdx="codex"
alias run="npm run"
alias dev="npm run dev"
alias dbgen="npm run db:gen"
alias dbpush="npm run db:push"
alias typegen="npm run typegen"
alias sb="supabase"
alias wg="wrangler"
alias ll="ls -lhG"
alias lll="ls -alhG"
alias ssh-homemini="ssh homemini@121.150.54.155"
alias youtube-download="yt-dlp"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# Node
export PATH="/opt/homebrew/opt/node@24/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/node@24/lib"
export CPPFLAGS="-I/opt/homebrew/opt/node@24/include"

# Added by Antigravity
export PATH="/Users/kyo/.antigravity/antigravity/bin:$PATH"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/kyo/.lmstudio/bin"
# End of LM Studio CLI section

# Obsidian CLI
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Claude Code - disable flickering
export CLAUDE_CODE_NO_FLICKER=1
