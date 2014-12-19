
function Record-Host-State()
{
    $global:hostWindowSize      = $Host.UI.RawUI.WindowSize
    $global:hostWindowPosition  = $Host.UI.RawUI.WindowPosition 
    $global:hostBufferSize      = $Host.UI.RawUI.BufferSize    
    $global:hostTitle           = $Host.UI.RawUI.WindowTitle    
    $global:hostBackground      = $Host.UI.RawUI.BackgroundColor    
    $global:hostForeground      = $Host.UI.RawUI.ForegroundColor
    $global:hostCursorSize      = $Host.UI.RawUI.CursorSize
    $global:hostCursorPosition  = $Host.UI.RawUI.CursorPosition
    
    #Store the full buffer
    $rectClass = "System.Management.Automation.Host.Rectangle" 
    $bufferRect = new-object $rectClass 0, 0, $global:hostBufferSize.width, $global:hostBufferSize.height
    $global:hostBuffer = $Host.UI.RawUI.GetBufferContents($bufferRect)
}

function Restore-Host-State()
{
    $Host.UI.RawUI.CursorSize       = $global:hostCursorSize
    $Host.UI.RawUI.BufferSize       = $global:hostBufferSize
    $Host.UI.RawUI.WindowSize       = $global:hostWindowSize
    $Host.UI.RawUI.WindowTitle      = $global:hostTitle
    $Host.UI.RawUI.BackgroundColor  = $global:hostBackground
    $Host.UI.RawUI.ForegroundColor  = $global:hostForeground
    
    $pos = $Host.UI.RawUI.WindowPosition
    $pos.x = 0
    $pos.y = 0
    #First restore the contents of the buffer and then reposition the cursor
    $Host.UI.RawUI.SetBufferContents($pos, $global:hostBuffer)
    $Host.UI.RawUI.CursorPosition = $global:hostCursorPosition
}

function Configure-Host([string] $title, [int] $width, [int] $height, [string] $fgColor, [string] $bgColor)
{
	# Set the new window and buffer sizes to be the same so        
	# there are no scroll bars.        
	$gameWindowSize = $Host.UI.RawUI.WindowSize
	$gameWindowSize.Width = $width
	$gameWindowSize.Height = $height
	$gameBufferSize = $gameWindowSize     
	$Host.UI.RawUI.WindowSize = $gameWindowSize
	$Host.UI.RawUI.BufferSize = $gameBufferSize		
	
	#Set a new title on the window
	$Host.UI.RawUI.WindowTitle = $title
	#Hide the cursor
	$Host.UI.RawUI.CursorSize = 0 
	#Define new colors for the buffer before clearing
	$Host.UI.RawUI.BackgroundColor = $bgColor
	$Host.UI.RawUI.ForegroundColor = $fgColor
	
	#Let us try and clear the screen
	Clear-Host
}

function Read-Character()
{
    if ($host.ui.RawUI.KeyAvailable) {
        return $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp").Character
    }
   
    return 0
}

#Draws a string to a specific cursor position
function Draw-String([int] $x, [int] $y, [string] $fgColor, [string] $bgColor, [string] $str)
{
#  
#	These lines would do the same thing if you 
#	prefer the Write-Host style...
#
#	$cursor = $Host.UI.RawUI.CursorPosition
#	$cursor.x = $x
#	$cursor.y = $y
#	$Host.UI.RawUI.CursorPosition = $cursor #reposition cursor
#   Write-Host -NoNewline -BackgroundColor $bgColor -ForegroundColor $fgColor $str
#	
	$pos = $Host.UI.RawUI.WindowPosition
	$pos.x = $x
	$pos.y = $y
	$row = $Host.UI.RawUI.NewBufferCellArray($str, $fgColor, $bgColor) 
	$Host.UI.RawUI.SetBufferContents($pos,$row) 
}
	
