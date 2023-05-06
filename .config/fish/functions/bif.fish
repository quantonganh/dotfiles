function bif --description "Install brew formula"
  set -l inst (http get https://formulae.brew.sh/api/formula.json | jq -r '.[].name' | eval "fzf $FZF_DEFAULT_OPTS -m --header='[brew:install]'")

  if not test (count $inst) = 0
    for prog in $inst
      brew install "$prog"
    end
  end
end
