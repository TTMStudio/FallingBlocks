# -------------------------------------
# Imports
# -------------------------------------
$script = $myInvocation.MyCommand.Definition
$scriptPath = Split-Path -parent $script
. (Join-Path $scriptpath board.ps1)
. (Join-Path $scriptpath host.ps1)

#==============================
# CONSTANTS
#==============================

#Well we are not dealing with perfect squares when dealing with characters
[int]$global:SQUARE_WIDTH     = 4 
[int]$global:SQUARE_HEIGHT    = 3

[int]$global:BOARD_WIDTH_IN_SQUARES  = 10
[int]$global:BOARD_HEIGHT_IN_SQUARES = 18
[int]$global:BOARD_H_PADDING  = 5
[int]$global:BOARD_T_PADDING  = 1
[int]$global:BOARD_B_PADDING  = 13
[int]$global:BOARD_OFFSET_X   = $global:BOARD_H_PADDING
[int]$global:BOARD_OFFSET_Y   = $global:BOARD_T_PADDING
[int]$global:BOARD_WIDTH  	  = $global:BOARD_WIDTH_IN_SQUARES  * $global:SQUARE_WIDTH
[int]$global:BOARD_HEIGHT  	  = $global:BOARD_HEIGHT_IN_SQUARES * $global:SQUARE_HEIGHT
[int]$global:WINDOW_WIDTH     = $global:BOARD_WIDTH + 2*$global:BOARD_H_PADDING
[int]$global:WINDOW_HEIGHT    = $global:BOARD_HEIGHT + $global:BOARD_T_PADDING + $global:BOARD_B_PADDING 

#Default colors
$global:BG_COLOR = "Black"
$global:FG_COLOR = "Yellow"

#==============================
# VARIABLES
#==============================
$global:lastTimeToMove = $null

#==============================
# FUNCTIONS
#==============================

function Is-Time-To-Move( ) 
{
    [boolean]$isTime = $FALSE
    #time step will be a function of elapsed time
    $timeStep = 1000	
	
    $currentTime = $(Get-Date)
    if ($global:lastTimeToMove -eq $null) {
		$global:lastTimeToMove = $currentTime
	} else {
	
		$deltaTime = $(New-TimeSpan  $global:lastTimeToMove $currentTime)
      
		if ($deltaTime.TotalMilliseconds -gt $timeStep)  {
			$global:lastTimeToMove = $currentTime
			$isTime = $TRUE
		}
	}
    return $isTime
}

#Get hold of a random piece
function Next-Piece()
{
	return Get-Random -minimum 1 -maximum 8
}

#Simple mapping from piece type to color
function Get-Type-Color([int] $type)
{
	switch ($type) {
		1 { "Yellow"  }
		2 { "Red"     }
		3 { "Blue"    }
		4 { "White"   }
		5 { "Green"   }
		6 { "Magenta" }
		7 { "Cyan"    }
	}
}

# This function contains a lot of magic numbers
# But all it does is set the stage for the game
# drawing the labels and borders...
function Draw-Game-Area()
{
  #DRAW THE TOP
  Draw-String ($global:BOARD_H_PADDING - 1) ($global:BOARD_T_PADDING - 1) $global:FG_COLOR $global:BG_COLOR  ('#' * ($global:BOARD_WIDTH+2))
  
  #DRAW THE SIDES
  for ($y=$global:BOARD_T_PADDING; $y -lt ($global:BOARD_T_PADDING+$global:BOARD_HEIGHT); $y++) {
    #LEFT
	Draw-String ($global:BOARD_H_PADDING - 1) $y $global:FG_COLOR $global:BG_COLOR  "#"
	#RIGHT
	Draw-String ($global:BOARD_H_PADDING + $global:BOARD_WIDTH) $y $global:FG_COLOR $global:BG_COLOR  "#"	
  }
  #DRAW THE BOTTOM
  Draw-String 0 ($global:BOARD_HEIGHT + $global:BOARD_T_PADDING) $global:FG_COLOR $global:BG_COLOR  ('#' * $global:WINDOW_WIDTH)
  #DRAW POINT LABEL:
  Draw-String 1 ($global:BOARD_HEIGHT + $global:BOARD_T_PADDING+2) $global:FG_COLOR $global:BG_COLOR  "POINTS:"
  #NEXT PIECE LABEL
  Draw-String ($global:WINDOW_WIDTH/2) ($global:BOARD_HEIGHT + $global:BOARD_T_PADDING+2) $global:FG_COLOR $global:BG_COLOR  "NEXT:"
  #DRAW INSTRUCTIONS LABEL
  Draw-String 1 ($global:WINDOW_HEIGHT -8) $global:FG_COLOR $global:BG_COLOR  "INSTRUCTIONS:"
  #THE ACTUAL INSTRUCTIONS
  Draw-String 2 ($global:WINDOW_HEIGHT -7) $global:FG_COLOR $global:BG_COLOR  "q: quit"
  Draw-String 2 ($global:WINDOW_HEIGHT -6) $global:FG_COLOR $global:BG_COLOR  "i: rotate left"
  Draw-String 2 ($global:WINDOW_HEIGHT -5) $global:FG_COLOR $global:BG_COLOR  "k: rotate right"
  Draw-String 2 ($global:WINDOW_HEIGHT -4) $global:FG_COLOR $global:BG_COLOR  "j: move left"
  Draw-String 2 ($global:WINDOW_HEIGHT -3) $global:FG_COLOR $global:BG_COLOR  "l: move right"
  Draw-String 2 ($global:WINDOW_HEIGHT -2) $global:FG_COLOR $global:BG_COLOR  "space: drop"
  
}

function Draw-Points([int] $lines )
{
	[string] $points = $lines * 100
	Draw-String 9 ($global:BOARD_HEIGHT + $global:BOARD_T_PADDING+2) $global:FG_COLOR $global:BG_COLOR  $points	
}

function Draw-Square-With-Offset([int]$offsetX, [int]$offsetY, [int]$hIndex, [int]$vIndex, [string]$fgColor, [string]$bgColor)
{   
    $x = $offsetX + $hIndex*$global:SQUARE_WIDTH
    $y = $offsetY + $vIndex*$global:SQUARE_HEIGHT

    #Draw the three lines
    Draw-String $x $y $fgColor $bgColor "┌──┐"
    Draw-String $x ($y+1) $fgColor $bgColor "│  │"
    Draw-String $x ($y+2) $fgColor $bgColor "└──┘"
}

function Draw-Next([int] $prevType, [int] $nextType )
{
	#Define the offset where the next piece is drawn
	$offsetX = ($global:WINDOW_WIDTH/2) + 9
	$offsetY =	($global:BOARD_HEIGHT + $global:BOARD_T_PADDING+2) + 2 
	
	if ($prevType -ne $null) {
		#Erase the squares belonging to the previous piece
		$squares = $(Get-Squares-For-Type $prevType)
		for ($seg = 0; $seg -lt 4; $seg++)    {
			Draw-Square-With-Offset $offsetX $offsetY $squares[$seg][0] $squares[$seg][1]  $global:BG_COLOR $global:BG_COLOR
		} 
	}
	
	$squares = $(Get-Squares-For-Type $nextType)
	#Draw the segments  
	for ($seg = 0; $seg -lt 4; $seg++)    {
		Draw-Square-With-Offset $offsetX $offsetY $squares[$seg][0] $squares[$seg][1]  $global:BG_COLOR $(Get-Type-Color $nextType)
	} 
}

function Draw-Square-On-Board([int] $hIndex, [int] $vIndex, [string]$foreground, [string] $background)
{
	Draw-Square-With-Offset $global:BOARD_OFFSET_X $global:BOARD_OFFSET_Y $hIndex $vIndex $foreground $background
}

function Erase-Square([int] $x, [int] $y)
{
	Draw-Square-On-Board $x $y $global:BG_COLOR $global:BG_COLOR
} 

function Draw-Piece-Square([int] $x, [int] $y, [int] $type)
{
    #Use the background as foreground 
	Draw-Square-On-Board $x $y $global:BG_COLOR $(Get-Type-Color $type)
}

function Draw-Piece ([array] $squares, [int]$pieceType)
{
	#Draw the current segments
    if ($global:pieceType -ne 0) {
		for ($seg = 0 ; $seg -lt 4; $seg++)    {
			Draw-Piece-Square $squares[$seg][0] $squares[$seg][1] $pieceType
        } 
    }
}

function Clear-Piece([array] $squares) {
	#Erase the old segments...
	for ($seg = 0 ; $seg -lt 4; $seg++)    {
			Erase-Square $squares[$seg][0] $squares[$seg][1] 
    } 
}

function Update-Board([array] $oldBoard, [array] $newBoard) 
{
	#Check for differences - line by line
	for ($y = 0; $y -lt $global:BOARD_HEIGHT_IN_SQUARES; $y++) {
		for ($x = 0; $x -lt $global:BOARD_WIDTH_IN_SQUARES; $x++) {
			#If the values are different we need to take action
		
			if ($oldBoard[$x][$y] -ne $newBoard[$x][$y]) { 
				if ($newBoard[$x][$y] -eq 0) {
					Erase-Square $x $y
				} else { 
					Draw-Piece-Square $x $y $newBoard[$x][$y]
				}
			}
		}
	}
}

function Main {

	#Store the current state of the PS Window 
	Record-Host-State
    
    try {
     	Configure-Host "PowerShell Tetris" $global:WINDOW_WIDTH $global:WINDOW_HEIGHT $global:FG_COLOR $global:BG_COLOR 
	         
        [boolean]$quit    		    = $FALSE
		[boolean]$isGameOver 		= $FALSE
		[boolean]$isGameInitialized = $FALSE
        [boolean]$repaint 		    = $TRUE
	
		#
        # Go into the control loop
        #
		do {
			if (-not $isGameInitialized) {
				Clear-Host
				Initialize-Board $global:BOARD_WIDTH_IN_SQUARES $global:BOARD_HEIGHT_IN_SQUARES
				$success = Set-Piece $(Next-Piece)
	
				$lastSquares = Get-Squares
				$lastBoard = Get-Board
				$nextPiece = Next-Piece
				
				Draw-Game-Area 
				Draw-Points 0
				Draw-Next $null $nextPiece
				
				$isGameInitialized   = $TRUE				
				$isGameOver          = $FALSE
				$repaint	 		 = $TRUE
			}
			
			if ($isGameOver) {	
				[string]$gameOverStr = "Game Over (press n to play again)"
				$x = ($global:WINDOW_WIDTH/2) - ($gameOverStr.Length/2)
				$y = ($global:WINDOW_HEIGHT/2)
				Draw-String  $x $y   "red" "yellow" $gameOverStr
					
			} else {
		
				#Do any repaints if needed
				if ($repaint) {
					$currentSquares = Get-Squares
					if ($lastSquares -ne $null) {
						Clear-Piece $lastSquares
					}
					Draw-Piece $currentSquares $global:pieceType
					$lastSquares = $currentSquares
					$repaint = $FALSE
				}
				
				#
				if (Is-Time-To-Move) {
					if (-not $(Move-Down)) { #If we cannot move down take needed action
						Lock
						if ($lastSquares -ne $null) {
							Clear-Piece $lastSquares
							$lastSquares = $null
						}
						$currentBoard = Get-Board
						Update-Board $lastBoard $currentBoard
						$lastBoard = $currentBoard
						
						$isGameOver = -not $(Set-Piece $nextPiece)
						$lastPiece = $nextPiece
						$nextPiece = Next-Piece
						Draw-Points $(Get-Line-Count)
						Draw-Next $lastPiece $nextPiece
					}				
					$repaint = $TRUE
				}
			}
		
			#We allways read input (the moves are ignored by the board)
            $character = Read-Character
            # make sure we have a character 
            # so it is not just a meta key
            if ($character -ne 0) {
                
                switch -regex ($character) {
					#UP = rotate left
                    "i" {
						$repaint = $(Rotate-Left)
                    } 
					
					#DOWN = rotate right
					"k" {
						$repaint = $(Rotate-Right)
					}
					
					#LEFT 
					"j" {
						$repaint = $(Move-Left)
					}
					
					#RIGHT
					"l" {
						$repaint = $(Move-Right)
					}
					
					#SPACE
					" " {
						$repaint = $(Drop)
					}
					
                    # Quit 
                    "q" {
                        $quit = $TRUE
                    }
					
					# New Game
					"n" {
						if ($isGameOver) {
							$isGameInitialized = $FALSE
						}
					}
                }
            }
        } while (-not $quit)
         
    } finally {
		#When done we make sure to return the shell
		#to the same state we started in
		Restore-Host-State
    }
}    


#Run the main function 
. Main
