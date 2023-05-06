# Defined in - @ line 1
function doc --wraps='go doc  | less -FX' --description 'alias doc=go doc  | less -FX'
  go doc  | less -FX $argv;
end
