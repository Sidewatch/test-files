-- Count the words in every open TextEdit document and speak the total.
use AppleScript version "2.4"
use scripting additions

property greeting : "Word count"
set wordTotal to 0

tell application "TextEdit"
	repeat with doc in documents
		set wordTotal to wordTotal + (count words of (text of doc))
	end repeat
end tell

if wordTotal > 1000 then
	display dialog greeting & ": " & wordTotal & " — long read" buttons {"OK"} default button 1
else
	say "Only " & (wordTotal as text) & " words"
end if

on describe(n)
	return "n is " & n
end describe

log describe(wordTotal)
