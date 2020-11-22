# Assignment 3

## Task 1 - N Queens Problem

The N Queens problem requires to place N Queens on a NxN Chess Board. Each Queen has to be place on an independent row, column and diagonals that are not share with any other Queen (each Queen can't have another queen on their available moving trajectory on the Chess Board). The base setting for this problem assign each Queen to each of the column of the Chess Board. There's always at least one valid solution for this problem.

This problem can be solved with a centralized backtrack control system, for which each time one Queen can't be placed due to the position of the other Queens, it requires the previous Queen to change it position. This process can go back to the first Queen. Once the previous Queens changed their position, the new Queen can check if there's a valid posisition on it's column. If this isn't possible, the backtrack algorithm will try to fix the previous Queens' position again, until the new Chess Board setting is valid. Once this happen, the Queen of the next column will be allowed to try to find its own position. Once the N-th Queen is correctly placed, the algorithm stops.

It's possible to solve this problem also with a Multiagent approach, by allowing each Queen to talk with the Queens of the previous and the next column (except for the first one, that will be only able to talk with the next one - and the last one, that will only able to talk with the previous one).
The arrangement system is the same as the centralized control system: everytime the i-th Queen is not allowed to have a valid position along its column due to the incompatibility with the previous Queens' placement, it will talk with the previous one [(i-1)-th] to find a position that allows it (the i-th) to find a valid position.
In this way the problem can be solved by having each agent acting on its own and not by being placed by a centralized system.

## Task 2 - Decision-making Based on Individual Utility

Report for task 2