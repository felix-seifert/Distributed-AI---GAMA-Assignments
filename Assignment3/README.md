# Assignment 3

## Task 1 - N Queens Problem

The N Queens problem requires to place N Queens on a NxN Chess Board. Each Queen has to be place on independent row, column and diagonals that are not share with any other Queen (each Queen can't have another queen on its available moving trajectory on the Chess Board). The base setting for this problem assign each Queen to each of the column of the Chess Board (as N is both the number of Queens and the size of the Chess Board). There's always at least one valid solution for this problem.

This problem can be solved with a centralized backtrack control system, for which each time one Queen can't be placed due to the position of the other Queens, it requires the previous Queen to change it position. This process can go back to the first Queen. Once the previous Queens changed their position, the new Queen can check if there's a valid posisition on it's column. If this isn't possible, the backtrack algorithm will try to fix the previous Queens' position again, until the new Chess Board setting is valid. Once this happen, the Queen of the next column will be allowed to try to find its own position. Once the N-th Queen is correctly placed, the algorithm stops.

It's possible to solve this problem also with a Multiagent approach, by allowing each Queen to talk with the Queens of the previous and the next column (except for the first one, that will be only able to talk with the next one - and the last one, that will only able to talk with the previous one).
The arrangement system is the same as the centralized control system: everytime the i-th Queen is not allowed to have a valid position along its column due to the incompatibility with the previous Queens' placement, it will talk with the previous one [(i-1)-th] to find a position that allows it (the i-th) to find a valid position.
In this way the problem can be solved by having each agent acting on its own and not by being placed by a centralized system.

**Code analysis:**

The Chess Board is created by alternating white and black cells based on the parity/disparity of the cell. If the sum of the cell's x and y is even, the cell will be white; otherwise it will be black. For example, the first cell is (0, 0), so the remainder of (0+0)/2 is 0, that makes the first cell white. The (0, 1) and (1, 0) will be black, because the remainder of the division (1+0)/2 (or (0+1)/2) is 1.

When a Queen is placed along its column, it checks if its position is compatible with the previous Queens' ones. This happen through the Queen's reflex validPositioning. If the new cell selected for the i-th Queen that is trying to be placed is compatible with the rest of the Queens, its boolean variable onPosition will be true. From this point the next Queen [(i+1)-th] will be able to start to position itself.

Each Queen has a boolean variable checkRowColumnDiagonalsCollision that is false if any of the previous Queens (1st, 2nd, ..., [(i-1)-th]) is occuping its row, column or diagonals cells (the definition of this variable is recursive, as in its definition there's a check on the previous Queen's checkRowColumnDiagonalsCollision [precedentQueen.checkRowColumnDiagonalsCollision(newPosition), on line 62]).
If this variable is false, the previous Queen's onPosition variable will be changed to false as there's no compatible setting for the new Queen on the Chess Board.

When the previous Queens establish a new setting for the Board (that means that all of them will have the onPosition value set on true again), the i-th Queen will try again to position itself. If this Queen will be able to find a valid position, the next Queen will try to position itself; otherwise the previous Queens will - again - find a new setting on the Chess Board.

This procedure will go on until all the Queens have a true value for the onPosition variable - then the process will stop.

**Examples:**

Slow speed demonstration of the N=10 case:

<img src="https://github.com/felix-seifert/Distributed-AI---GAMA-Assignments/blob/main/Assignment3/includes/data/nQueen10.gif?raw=true">

High speed demonstration of the N=18 case (~ 500'000 cycles, ~1 minute and 20 seconds):

<img src="https://github.com/felix-seifert/Distributed-AI---GAMA-Assignments/blob/main/Assignment3/includes/data/nQueen18.gif?raw=true">

Final result of the N=20 case (~ 2'227'000 cycles, ~7 minute and 20 seconds):

<img src="https://github.com/felix-seifert/Distributed-AI---GAMA-Assignments/blob/main/Assignment3/includes/data/nQueen20.gif?raw=true">

## Task 2 - Decision-making Based on Individual Utility

Report for task 2

## Challenge Task

The complexity of this task is based on the non-linearity of the problem.

**Definition of the problem:**

Parameters:

m<subscript>i</subscript> = 1 if agent i enjoys crowds, -1 else

Variables:

a<subscript>i</subscript>, b<subscript>i</subscript>, c<subscript>i</subscript>, ... = 1 if agent i select Stage a<subscript>i</subscript> (or b<subscript>i</subscript>, c<subscript>i</subscript>, ...), 0 else
