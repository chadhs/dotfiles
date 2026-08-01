-- Source for utils/Open in Neovim.app (rebuild: osacompile -o ...).
-- Opens files in Neovim inside Ghostty for Finder "Open With".

on open_paths(pathList)
	set opener to (system attribute "HOME") & "/dotfiles/utils/open-in-neovim.sh"
	repeat with posixPath in pathList
		try
			do shell script quoted form of opener & " " & quoted form of posixPath
		on error errMsg number errNum
			display alert "Open in Neovim failed" message errMsg & " (" & errNum & ")" as critical
		end try
	end repeat
end open_paths

on open theFiles
	set pathList to {}
	repeat with f in theFiles
		set end of pathList to POSIX path of f
	end repeat
	open_paths(pathList)
end open

on run
	try
		set theFile to choose file with prompt "Open in Neovim:"
		open_paths({POSIX path of theFile})
	on error number -128
		-- user cancelled
	end try
end run
