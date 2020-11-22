/**
* Name: NQueensModel
* Model where N queens find a position on a squared NxN chessboard while adhering the following rules:
* 	* One queen per row
* 	* One queen per column
* 	* One queen per diagonal line 
* Author: Marco Molinari <molinarimarco8@gmail.com>, Felix Seifert <mail@felix-seifert.com> 
*/

model nQueen

global {
	
	int boardSize <- 10;
	//bool activateDebugTexts <- false;
	float size <- 4.0;
	
	init {
		
		Queen currentPrecedentQueen <- nil;
		
		loop currentColumn from: 0 to: (boardSize - 1) {
			create Queen returns: currentQueen {
				precedentQueen <- currentPrecedentQueen;
				//write string(precedentQueen) + " in loop";
				column <- currentColumn;
				location <- {-5, -5};
			}
			
			currentPrecedentQueen <- currentQueen[0];
			//write string(column_queen[0]) + " out loop";
		}
	}
}

species Queen skills:[moving] {
	
	rgb color <- #green;
	point targetCell <- nil;
	bool onPosition <- false;
	int row <- -1;
	int column;
	Queen precedentQueen;
	image_file icon <- image_file("../includes/data/queen.png");
	
	reflex moveToTarget when: targetCell != nil {
		
		if(targetCell = location) {
			targetCell <- nil;
		}
		
		do goto target: targetCell;
	}
	
	
	bool checkRowColumnDiagonalsCollision(chessBoard newPosition) {

		if (precedentQueen = nil) {
			return true;
		}
		
		return precedentQueen.row != newPosition.grid_y and abs(precedentQueen.row - newPosition.grid_y) != abs(precedentQueen.column - newPosition.grid_x) and precedentQueen.checkRowColumnDiagonalsCollision(newPosition);	
	}
	
	
	reflex validPositioning when: (precedentQueen = nil or precedentQueen.onPosition = true) and !onPosition and targetCell = nil {
		
		if (row < boardSize - 1) {
			loop currentRow from: (row + 1) to: (boardSize - 1) {
				chessBoard currentCell <- chessBoard grid_at {column, currentRow};
				if (checkRowColumnDiagonalsCollision(currentCell)) {
					targetCell <- currentCell.location;
					row <- currentRow;
					onPosition <- true;
					return;
				}
			}
		}

		row <- -1;
		precedentQueen.onPosition <- false;
	}
	
	aspect default {
		
		draw icon size: size;
		draw ('      ' + name) color: color;
	}
}

grid chessBoard width: boardSize height: boardSize {
	
    rgb color <- mod((grid_x + grid_y), 2) = 0 ? #white : #black;
}


experiment nQueen type: gui {
 
	parameter "Board size and Queens number: " var: boardSize min: 4 max: 100 category: "Problem dimension";
	//parameter "Display debug texts: " var: activateDebugTexts category: "Debug text";
 
	output {
		
		display chessBoard {
			
			grid chessBoard lines: #black;
			species Queen aspect: default;
		}
	}
}
