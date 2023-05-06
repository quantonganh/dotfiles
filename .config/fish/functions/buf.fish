function buf --description "Update brew formula"
  set -l inst (brew leaves | eval "fzf $FZF_DEFAULT_OPTS -m --header='[brew:update]'")

  if not test (count $inst) = 0
    for prog in $inst
      brew upgrade "$prog"
    end
  end
end
