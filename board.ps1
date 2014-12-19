#==============================
# Variables
#==============================
$global:boardWidth = 0
$global:boardHeight = 0

#array[W][H] of shape numbers (see Initialize-Board)
$global:board = $null
#array of piece coordinates 
#((x1,y1),(x2,y2),(x3,y3),(x4,y4))
$global:pieceSegments = $null
#current shape number
$global:pieceType = $null
#The "moving part" of the piece
$global:pieceCenter = $null
#Game Over...
$global:boardPassive
#The Lines removed so far
$global:lineCount

#==============================
# Functions
#==============================
function Initialize-Board([int] $width=10, [int] $height=18) {
    $global:boardWidth = $width
    $global:boardHeight = $height
    #Note % is an alias for ForEach-Object
    $column = 1..$global:boardHeight | % { 0 }
    #The extra $ is there to make sure it is not a 
    #bunch of references to the same column
    $global:board  = 1..$global:boardWidth | % { ,$($column) }

    $global:lineCount = 0
}

function Get-Squares-For-Type([int] $type)
{
  $squares = $null
  switch($type) {
	 
        1 { #The Pyramid
          $squares = (0,0),(-1,0),(1,0),(0,1)
        }
        2 { # The Long One 
          $squares = (0,0),(-1,0),(1,0),(2,0)
        }
    	3 { # The Square 
          $squares = (0,0),(1,0),(1,1),(0,1)
        }
    	4 { # The 'L' Thingy
          $squares = (0,0),(1,0),(-1,0),(1,1)
        }
    	5 { # The Mirrored 'L' 
          $squares = (0,0),(1,0),(-1,0),(-1,1)
        }
    	6 { # The 'S'
          $squares = (0,0),(0,1),(-1,0),(1,1)
        }  
        7 { # A Mirrored 'S' 
          $squares = (0,0),(0,1),(-1,1),(1,0)
        } 
    }
	
	return $squares
}

function Set-Piece([int] $type)
{
    $global:pieceType = $type
    $global:pieceCenter = (4,0)
	$global:pieceSegments = $(Get-Squares-For-Type $type)
  
	return $(Is-Piece-Legal)
}

function Is-Piece-Legal() 
{
	$legal = $TRUE
	if ($global:pieceType -ne 0) {
		for ($seg = 0 ; $seg -lt 4 -and $piecePosition -ne $TRUE; $seg++)    {
			if ($global:board[$(Get-Piece-Segment-X $seg)][$(Get-Piece-Segment-Y $seg)] -ne 0) {
				$legal = $FALSE
				break
			} 
		}
	}
	return $legal
}

function Get-Squares()
{
	$squares = 0..3 | % {,($(Get-Piece-Segment-X $_), $(Get-Piece-Segment-Y $_))}
	return $squares
}

function Get-Line-Count()
{
	return $global:lineCount
}

function Get-Board()
{
	$copy  = 0..$global:boardWidth | % { ,($($global:board[$_])) }
	return $copy
}


function Get-Piece-Segment-X([int] $index) 
{
    $global:pieceCenter[0] + $global:pieceSegments[$index][0]
}

function Get-Piece-Segment-Y([int] $index) 
{
    $global:pieceCenter[1] + $global:pieceSegments[$index][1]
}

function Move-Piece([int] $dx, [int] $dy)
{
    $global:pieceCenter[0] = $global:pieceCenter[0] + $dx
    $global:pieceCenter[1] = $global:pieceCenter[1] + $dy
}

function Rotate-Piece([boolean] $isClockwise)
{    
	#run through the four possible squares
    #do a quad-to-quad rotation
    for ($seg = 0; $seg -lt 4; $seg++)  {	
	   [int] $tmpX = $global:pieceSegments[$seg][0]
	   if ($isClockwise) {
		  $global:pieceSegments[$seg][0] = $global:pieceSegments[$seg][1] #X=Y
		  $global:pieceSegments[$seg][1] = -$tmpX #Y=-X 
		} else {
		  $global:pieceSegments[$seg][0] = -$global:pieceSegments[$seg][1] #X=-Y
		  $global:pieceSegments[$seg][1] = $tmpX #Y=X
	    }
	}
}

function Is-Segment-Invalid([int] $x, [int] $y) 
{
    #Check X position 
    if( ($x -lt 0) -or ($x -ge $global:boardWidth) ) {
      return $TRUE 
    }
  
    #Check Y position 
    if( ($y -lt 0) -or ($y -ge $global:boardHeight) ) { 
      return $TRUE 
    }
    
    #Position already occupied?
    if ($global:board[$x][$y] -ne 0) { 
      return $TRUE
    }

    return $FALSE
}

function Is-Move-Legal([int] $dx, [int] $dy) 
{
	if ($global:pieceType -eq 0) {
        return $FALSE
    }

    #run through the four possible squares
    for ($seg = 0; $seg -lt 4; $seg++)  {
    	[int] $x = $(Get-Piece-Segment-X $seg) + $dx	
        [int] $y = $(Get-Piece-Segment-Y $seg) + $dy		
        if (Is-Segment-Invalid $x $y) {
            return $FALSE
        }
    }

    #I guess we are OK then
    return $TRUE;
}

function Is-Rotation-Legal([boolean] $isClockwise) 
{
	if ($global:pieceType -eq 0) {
        return $FALSE
    }
    
    #run through the four possible squares
    #do a quad-to-quad rotation
    for ($seg = 0; $seg -lt 4; $seg++)  {

        if ($isClockwise) {
    		$dx = $global:pieceSegments[$seg][1] #X= Y
    		$dy =-$global:pieceSegments[$seg][0] #Y=-X
        }
        else {
    		$dx =-$global:pieceSegments[$seg][1] #X=-Y
    		$dy = $global:pieceSegments[$seg][0] #Y= X 
        }

        [int]$x = $global:pieceCenter[0] + $dx
        [int]$y = $global:pieceCenter[1] + $dy
        if (Is-Segment-Invalid $x $y) {
            return $FALSE
        }
    }

    #I guess we are OK then
    return $TRUE
}

function Do-Move([int] $dx, [int] $dy)
{
	if ($global:boardPassive) {
        return $FALSE;
    }
    
	[boolean] $success = Is-Move-Legal $dx $dy

	if ($success) {
	  Move-Piece $dx $dy
	}

	return $success
}

function Do-Rotate([boolean] $isClockwise) 
{
	if ($global:boardPassive) {
        return $FALSE;
    }
    
	[boolean] $success = Is-Rotation-Legal $isClockwise

	if ($success) {
	  Rotate-Piece $isClockwise
	}

	return $success
}

function Move-Down()
{
	return $(Do-Move 0 1)
}

function Move-Left()
{
	return $(Do-Move -1 0)
}

function Move-Right()
{
	return $(Do-Move 1 0)
}

function Rotate-Left()
{
	#Y axis is pointing down so left is our clockwise
    return $(Do-Rotate $TRUE)
}

function Rotate-Right()
{
	#Y axis is pointing down so right is our counter clockwise
    return $(Do-Rotate $FALSE)
}

function Drop()
{
	if ($global:boardPassive) {
        return $FALSE;
    }

	while ($(Is-Move-Legal 0 1)) {
	  $success = Do-Move 0 1
	}

	return $TRUE
}

#Move the piece to the board,
#validate the board and finally
#clear the current piece
function Lock()
{
    #transfer the piece onto the board 
    for ($seg = 0; $seg -lt 4; $seg++) {
        $global:board[$(Get-Piece-Segment-X $seg)][$(Get-Piece-Segment-Y $seg)] = $global:pieceType
    }
    #clear the current piece
    $global:pieceType = 0
    
    Validate-Board
}

#Pre Condition: The piece coordinates are 
#still where they where locked and we only 
#have to look if they generated any lines
function Validate-Board()
{
    $fullLine  = 1..$global:boardHeight | % { $FALSE }
    
	for ($seg = 0; $seg -lt 4; $seg++) {
		[int] $y = $(Get-Piece-Segment-Y $seg)
		if (-not $fullLine[$y] ) {
            #Full line unless we detect otherwise
			$fullLine[$y] = $TRUE  
            #Run over the line looking for holes
			for ($x=0; $x -lt $global:boardWidth; $x++) {
				if ($global:board[$x][$y] -eq 0) {
                    #Not a full line after all
					$fullLine[$y] = $FALSE
					break
				}
			}
		}
	}
    
    for ($y=0; $y -lt $global:boardHeight; $y++) {
		if ($fullLine[$y]) {
			$global:lineCount++
			#Move lines down
			for ($yAbove=$y; $yAbove -gt 0; $yAbove-- ) {
				for ($x=0; $x -lt $global:boardWidth; $x++) {
					$global:board[$x][$yAbove] = $global:board[$x][$yAbove-1];
				}
			}
			#finally delete the last line
			for($x=0; $x -lt $global:boardWidth; $x++) {
				$global:board[$x][0] = 0;
			}
		}
	}
}

#==============================
# Test 
#==============================

function Test()
{
    Initialize-Board 10 18	
    $success = Set-Piece 6
	Show-Board
	$success = Move-Down
	Show-Board
	$success = Drop
	Show-Board
}

function Show-Board()
{
    Write-Host "__BOARD__"
    for ($y = 0; $y -lt $global:boardHeight; $y++)    { 
        for ($x = 0; $x -lt $global:boardWidth; $x++)    {
            #look at the falling piece?
            [boolean] $piecePosition = $FALSE
            if ($global:pieceType -ne 0) {
                for ($seg = 0 ; $seg -lt 4 -and $piecePosition -ne $TRUE; $seg++)    {
                    if (($(Get-Piece-Segment-X($seg)) -eq $x) -and ($(Get-Piece-Segment-Y($seg)) -eq $y)) {
                        Write-Host -NoNewLine $global:pieceType
                        $piecePosition = $TRUE
                    } 
                }
            }
            if ($piecePosition -ne $TRUE) {
                Write-Host -NoNewLine $global:board[$x][$y]
            }
        }
        Write-Host
     }
}

#Uncomment the line below to run test script
#Run as .\board.ps1 from the PS command line

#. Test
