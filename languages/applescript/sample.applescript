#!/usr/bin/osascript
-- AppleScript 2.8 (macOS 26) — syntax showcase
-- Warehouse inventory helper: reads a stock list, reports low items and
-- talks to Finder, Mail and System Events.
# A hash comment is also a line comment.
(* A block comment, which
   (* may nest *)
   across lines. TODO: tidy the handler names. *)

use AppleScript version "2.8"
use framework "Foundation"
use framework "AppKit"
-- use application "System Events" -- imports that app's terminology into the whole script
use scripting additions

-- ── Properties and globals ─────────────────────────────────────────
property warehouseName : "Acme Central"
property reorderPoint : 25
property taxRate : 0.2
property sampleSKUs : {"A-100", "B-200", "C-300"}
property settings : {verbose:true, retries:3, label:"stock"}
global gTotal, gReport
set gTotal to 0
set gReport to ""

-- ── Literals ───────────────────────────────────────────────────────
set anInteger to 42
set aReal to 3.14159
set anExponent to 1.5E-3
set aBoolean to true
set aString to "Tab\there, newline\nhere, quote \" and backslash \\ and unicode é"
set aList to {1, 2, 3, "four", 5.5, true, missing value}
set aRecord to {name:"Widget", qty:12, price:4.5}
set aDate to date "Monday, 1 January 2024 at 09:00:00"
set aFile to POSIX file "/Users/Shared/stock.csv"
set aAlias to alias "Macintosh HD:Users:Shared:"
set aClass to class of anInteger
set aChar to character id 65
set pi_ to «constant ****pi  »
set rawData to «data TEXT616263»
set emptyList to {}
set nothingHere to missing value

-- ── Operators ──────────────────────────────────────────────────────
set arithmetic to (1 + 2) * 3 - 4 / 5 div 2 mod 3 ^ 2
set comparison to (1 < 2) and (2 ≤ 3) and (3 ≥ 2) and (2 ≠ 3) or not (1 = 2)
set wordy to (1 is less than 2) and (2 is greater than 1) and (3 is equal to 3)
set stringy to "abc" & "def" & return & linefeed & tab & space & quote
set contained to ("b" is in "abc") and ("abc" contains "b") and ("abc" begins with "a") and ("abc" ends with "c")
set refs to a reference to aList
set coerced to (anInteger as text) & (aReal as string) & (aBoolean as integer)
set listItems to item 1 of aList & first item of aList & last item of aList & items 2 thru 3 of aList
set randomOne to some item of aList
set theLength to length of aList + (count aList) + number of items in aList
set midChars to text 2 thru 3 of "abcdef"
set wordsOf to words of "the quick brown fox"
set paras to paragraphs of "one" & return & "two"

-- ── Handlers ───────────────────────────────────────────────────────
on greet(personName)
	return "Hello, " & personName
end greet

to double(n)
	return n * 2
end double

on withLabels given label:theLabel, amount:theCount
	return theLabel & theCount
end withLabels

on isLow(qty, threshold)
	if qty < threshold then return true
	return false
end isLow

on process(sku, isVerbose)
	if isVerbose then log "processing " & sku
	return sku
end process

on handleArgs(argv)
	set argCount to count argv
	return argCount
end handleArgs

on open theFiles
	repeat with f in theFiles
		log (POSIX path of f)
	end repeat
end open

on idle
	return 30
end idle

on quit
	continue quit
end quit

-- ── Script objects and inheritance ─────────────────────────────────
script Counter
	property ticks : 0
	on increment()
		set my ticks to (my ticks) + 1
		return ticks
	end increment
end script

script SubCounter
	property parent : Counter
	on increment()
		continue increment()
	end increment
end script

tell Counter to increment()

-- ── Control flow ───────────────────────────────────────────────────
if gTotal = 0 then
	set gReport to "empty"
else if gTotal < reorderPoint then
	set gReport to "low"
else
	set gReport to "ok"
end if

if gTotal > 0 then display notification "Stock ok" with title warehouseName subtitle "Check" sound name "Glass"

repeat 3 times
	set gTotal to gTotal + 1
end repeat

repeat with i from 1 to 10 by 2
	if i = 5 then exit repeat
end repeat

repeat with anItem in aList
	log anItem
end repeat

set counter to 0
repeat while counter < 3
	set counter to counter + 1
end repeat

repeat until counter = 0
	set counter to counter - 1
end repeat

repeat
	exit repeat
end repeat

-- ── Error handling ─────────────────────────────────────────────────
try
	error "Out of stock" number 1001 partial result {0} from "A-100" to integer
	set x to 1 / 0
on error errMsg number errNum from badObj partial result partialList to expectedType
	log errMsg & " (" & errNum & ")"
end try

try
	set y to missing value
on error
	log "caught"
end try

with timeout of 30 seconds
	delay 1
end timeout

with transaction
	log "inside transaction"
end transaction

considering case and punctuation
	set sameText to ("A" is "a")
end considering

ignoring white space and hyphens
	set sameText2 to ("a-b" is "ab")
end ignoring

using terms from application "Finder"
	set dummy to 1
end using terms from

-- ── Application scripting ──────────────────────────────────────────
tell application "Finder"
	set homeFolder to home
	set fileCount to count of (every file of folder "Documents" of homeFolder whose name extension is "csv")
	set bigFiles to every file of desktop whose size > 1000000
	set theName to name of front window
	activate
	open POSIX file "/Users/Shared"
	make new folder at desktop with properties {name:"Stock Reports"}
	duplicate file "stock.csv" of desktop to folder "Stock Reports" of desktop with replacing
	move file "old.csv" of desktop to trash
	reveal selection
end tell

tell application "System Events"
	tell process "Finder"
		set frontmost to true
		click menu item "New Finder Window" of menu "File" of menu bar 1
		keystroke "n" using {command down, shift down}
		key code 36
	end tell
	set appList to name of every process whose background only is false
	set fileExists to exists file "/etc/hosts"
	set uiEnabled to UI elements enabled
end tell

tell application "Mail"
	set newMessage to make new outgoing message with properties {subject:"Low stock", content:"See attached." & return, visible:false}
	tell newMessage
		make new to recipient at end of to recipients with properties {address:"buyer@example.com"}
		make new attachment with properties {file name:aFile} at after the last paragraph
	end tell
	send newMessage
end tell

tell application "TextEdit"
	if not (exists document 1) then make new document
	set text of document 1 to "Report generated"
	save document 1 in file "report.txt" of desktop
	close every document saving no
end tell

-- ── Shell, dialogs, Foundation ─────────────────────────────────────
set shellOut to do shell script "ls -1 /tmp | head -3"
set shellAdmin to do shell script "echo ok" with administrator privileges
set quotedPath to quoted form of "/tmp/dir with spaces"
set theDate to current date
set theTime to time string of theDate
set theHome to path to home folder
set docsFolder to path to documents folder as text
set clip to the clipboard
set the clipboard to "copied"
set frontApp to (path to frontmost application as text)
set sysInfo to system info
set vol to output volume of (get volume settings)
set volume output volume 50

display dialog "Reorder now?" default answer "25" with title warehouseName with icon caution buttons {"Cancel", "Reorder", "Later"} default button "Reorder" cancel button "Cancel" giving up after 10
set theResult to button returned of result
set chosen to choose from list sampleSKUs with prompt "Pick a SKU" with multiple selections allowed
set pickedFile to choose file with prompt "Stock file" of type {"csv", "public.text"}
set pickedFolder to choose folder
display alert "Done" message "Finished" as informational giving up after 5
say "Inventory check complete" using "Samantha" speaking rate 180
beep 2
log "debug output"

set nsString to current application's NSString's stringWithString:"hello"
set upper to (nsString's uppercaseString()) as text
set theDict to current application's NSDictionary's dictionaryWithObjects:{1, 2} forKeys:{"a", "b"}

-- ── Special forms ──────────────────────────────────────────────────
get the name of the first item of aList
set (item 1 of aList) to "changed"
copy "x" to the end of aList
set end of aList to "y"
set beginning of aList to "z"
set {firstItem, secondItem} to {1, 2}
return it

-- ── Further constructs ─────────────────────────────────────────────
-- Application-specific terms, 'of' chains and possessives
tell application "Finder"
	set theWindow to Finder window 1
	set windowBounds to bounds of theWindow
	set itemNames to name of every item of (startup disk)
	set firstFolder to first folder of desktop
	set sizeOfFile to size of (info for (POSIX file "/etc/hosts" as alias))
	set theSelection to selection
	set newName to (name of firstFolder) & "_copy"
	set name of firstFolder to newName
	set label index of firstFolder to 2
	set comment of firstFolder to "Warehouse"
	select firstFolder
	eject disk "Backup"
	empty trash
	update firstFolder
	print firstFolder
	delete every file of trash
end tell

tell application "Safari"
	set theURL to URL of current tab of window 1
	do JavaScript "document.title" in current tab of window 1
	open location "https://example.com"
end tell

tell application "Terminal"
	do script "echo hello" in window 1
end tell

tell application "System Events" to keystroke "v" using command down
tell application "System Events" to tell process "Dock" to set visible to true

tell application id "com.apple.finder" to activate

tell application "Calendar"
	tell calendar "Work"
		make new event with properties {summary:"Reorder review", start date:(current date) + 1 * days, end date:(current date) + 1 * days + 1 * hours}
	end tell
end tell

-- Date and unit arithmetic
set nextWeek to (current date) + 1 * weeks
set minutesLeft to 90 * minutes
set seconds_ to 2 * hours + 30 * minutes + 15 * seconds
set conversions to (5 as kilometers as miles)
set unitText to (12 as inches) as feet

-- Text item delimiters and coercions
set AppleScript's text item delimiters to {", ", "; "}
set parts to text items of "a, b; c"
set AppleScript's text item delimiters to ""
set joined to parts as text
set asciiCode to ASCII number "A"
set asciiChar to ASCII character 66
set asListOfRecords to every record of {{a:1}, {a:2}}
set recordCombo to {a:1} & {b:2}
set listCombo to {1} & {2} & 3
set theClass to class of {1} as text
set isMissing to (missing value is missing value)
set theContents to contents of aRecord
set recordItem to name of aRecord
set aRecord's qty to 13
set second item of aList to "two"
set the first character of "abc" to "X"
set theRef to a reference to (item 1 of aList)
set contents of theRef to "via reference"
set theIdentity to (get id of 1) as list

-- Named parameters, labelled handlers and prepositions
on rectangle given width:w, height:h
	return w * h
end rectangle

on compliment for someone from sender with feeling
	return "Hi " & someone & " from " & sender
end greet

on moveItem from fromRef into toRef
	return {fromRef, toRef}
end moveItem

on handlerWithAt at pos by delta against thing
	return pos + delta
end handlerWithAt

compliment for "Ann" from "Bob" with feeling
rectangle given width:3, height:4
moveItem from 1 into 2

-- Boolean words, spelled-out comparisons, ranges
set checks to {(1 is not equal to 2), (1 does not equal 2), (3 comes after 2), (2 comes before 3), (1 is not less than 2), ("a" is not in "b"), ("x" does not contain "y"), ("a" starts with "a"), (3 is greater than or equal to 3), (2 is less than or equal to 2)}
set thing to some item of {1, 2, 3}
set rangeEnds to items 1 thru -1 of {1, 2, 3}
set midItem to middle item of {1, 2, 3}
set rev to reverse of {1, 2, 3}
set pos to offset of "b" in "abc"

-- Special constants and Unicode
set spaceChar to space
set tabChar to tab
set lf to linefeed
set cr to return
set quoteChar to quote
set pathSep to "/"
set nul to missing value
set unicode to "résumé — naïve 世界 🚀"
set numericConstants to {pi, e}
set emptyString to ""
set booleanNot to not true
set bigExp to 1.0E+10
set negExp to -2.5E-3
set intDiv to 7 div 2
set intMod to 7 mod 2
set caretPower to 2 ^ 10
set rangeEnd to -1
set ordinal to third item of {1, 2, 3}
set lastOfTen to 10th item of {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
set absoluteId to id of front window

-- Return statements and tell-return forms
on compute()
	tell me to set x to 3
	return x
end compute

on returnsFromTell()
	tell application "Finder" to return name of startup disk
end returnsFromTell

-- Error numbers and error handling variants
try
	error number -128
on error number -128
	log "cancelled"
end try

try
	error "custom" number 2000
on error the errorMessage number the errorNumber
	log errorMessage & errorNumber
end try

try
	do shell script "false"
on error errStr number errNum from obj partial result res to cls
	log {errStr, errNum, res, obj, cls}
end try

-- TODO: split into libraries with `load script`.
set lib to load script alias "Macintosh HD:Users:Shared:lib.scpt"
tell lib to run
run script "return 1 + 1"
run script file "Macintosh HD:Users:Shared:other.scpt" with parameters {"a", "b"}
store script Counter in file "Macintosh HD:Users:Shared:counter.scpt" replacing yes

-- ── The run handler, locals and pipe identifiers ───────────────────
script RunDemo -- an explicit run handler is only legal inside a script object here
	on run argv
		local scratch, marker
		set scratch to 1
		set |reserved word variable| to "pipes allow spaces and keywords"
		set |end| to 2
		return |end| + scratch
	end run
end script

-- ── Filtering references: whose, where, its, whose-by-index ────────
tell application "Finder"
	set bigFiles to every file of desktop whose size > 1000000 and name extension is "csv"
	set firstBig to first file of desktop whose size > 1000000
	set odd to (every item of desktop where its name begins with "a")
	set notes to every file of desktop whose name contains "note" or name ends with ".txt"
	set emptyOnes to every folder of desktop whose (count of items) = 0
	set kinds to name of every item of desktop whose kind is not "Folder"
	set lastThree to items -3 thru -1 of (get name of every item of desktop)
	set middleOne to middle item of (get name of every item of desktop)
	set anyOne to some item of (get name of every item of desktop)
	set byId to item id 5 of desktop
	set byName to folder named "Stock Reports" of desktop
end tell

-- ── considering / ignoring: every attribute ────────────────────────
considering numeric strings
	set naturalOrder to ("item 10" > "item 9")
end considering
considering diacriticals and punctuation
	set accentSensitive to ("é" is "e")
end considering
ignoring application responses
	tell application "Finder" to activate
end ignoring
considering hyphens, punctuation and white space but ignoring case
	set mixed to ("A-b" is "a-b")
end considering

-- ── Result, get, and implicit it ───────────────────────────────────
get (1 + 2)
set threeResult to result
tell application "Finder" to get name of startup disk
set diskName to result

-- ── Property access via possessive, my, its, of ────────────────────
script Config
	property depth : 1
	on bump()
		set my depth to my depth + 1
		set its depth to depth + 1
		set depth of me to 5
		return Config's depth
	end bump
end script
set cfgDepth to Config's depth
set cfgDepth2 to depth of Config

-- ── Script objects: parent chains, run handler, nested handlers ────
script Outer
	property label : "outer"
	on run
		return label
	end run
	script Inner
		property parent : AppleScript
		on describe()
			return label & "/inner"
		end describe
	end script
end script
set innerText to Outer's Inner's describe()

-- ── Handlers: positional, labelled, with default-looking patterns ──
on addNumbers(a, b)
	return a + b
end addNumbers
on listLength about theList
	return count theList
end listLength
on repeatThing for thing given amount:n
	return n
end repeatThing
on firstWordOf(theText)
	return word 1 of theText
end firstWordOf
on pourInto into theItems
	return theItems
end pourInto
on advance from s by step
	return s + step
end advance
on ending(beforeEnd)
	return beforeEnd
end ending
on makeWith given name:theName, age:theAge, active:isActive
	return {name:theName, age:theAge, active:isActive}
end makeWith
set made to makeWith given name:"Ann", age:30, active:true
set ln to listLength about {1, 2, 3}

-- ── Coercions and class names ──────────────────────────────────────
set asNumber to "42" as integer
set asReal to "3.5" as real
set asBool to "true" as boolean
set asList to "abc" as list
set asRecord to {1, 2} as record
set asDate to "1 January 2025" as date
set asAlias to (path to desktop) as alias
set asPOSIX to POSIX path of (path to desktop)
set asHFS to (POSIX file "/tmp") as text
set asUnicode to "é" as Unicode text
set asData to "abc" as data
set classNames to {class of 1, class of 1.5, class of "s", class of {}, class of {a:1}, class of true, class of (current date), class of missing value, class of me, class of (path to desktop)}
set hasAClass to (class of 1 is integer) and (class of "s" is text) and (class of 1.5 is real)

-- ── Chevron (raw) terms and event codes ────────────────────────────
tell application "Finder"
	«event aevtodoc» (POSIX file "/tmp")
	set rawProp to «property pnam» of startup disk
end tell
set rawClass to «class long»

-- ── AppleScriptObjC ────────────────────────────────────────────────
set aString to current application's NSString's stringWithString:"objc"
set aList2 to current application's NSArray's arrayWithArray:{"a", "b"}
set aMutable to current application's NSMutableDictionary's new()
aMutable's setObject:"v" forKey:"k"
set aValue to (aMutable's objectForKey:"k") as text
set aBlockSafe to current application's NSProcessInfo's processInfo()'s processName() as text
set theRegex to current application's NSRegularExpression's regularExpressionWithPattern:"[0-9]+" options:0 |error|:(missing value)
set rangeValue to current application's NSMakeRange(0, 3)

-- ── Dialog and system helpers not yet shown ────────────────────────
display dialog "Name?" default answer "" with hidden answer
set sel to choose application with prompt "Pick"
set theURL to choose URL
set newFile to choose file name with prompt "Save as" default name "report.txt"
set theColour to choose color default color {65535, 0, 0}
set theLoc to localized string "Hello" in bundle (path to me)
set appPath to path to application "Finder"
set resPath to path to resource "icon.icns"
set tempPath to path to temporary items from user domain
set theInfo to info for (path to me)
set versionText to version
set osVersion to system attribute "sys2"
set myName to name of me
set isRunning to application "Finder" is running
set thePath to POSIX path of (path to me)
set tickCount to (do shell script "date +%s") as integer
set theLine to read file (POSIX file "/etc/hosts") before linefeed
set eof to get eof of (POSIX file "/etc/hosts")
open for access file "Macintosh HD:tmp:out.txt" with write permission
write "data" to file "Macintosh HD:tmp:out.txt" starting at eof
close access file "Macintosh HD:tmp:out.txt"
launch application "Finder"
delay 0.5
random number from 1 to 10 with seed 3
round 2.5 rounding up
round 2.5 rounding down
round 2.5 rounding toward zero
round 2.5 rounding to nearest
get ASCII number "a"
offset of "b" in "abc"
