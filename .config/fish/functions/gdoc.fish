# Defined in /Users/quanta/.config/fish/config.fish @ line 18
function gdoc --wraps='go doc  | less -FX' --wraps='command go doc  | less -FX'
	go doc $1 | less -FX
end
