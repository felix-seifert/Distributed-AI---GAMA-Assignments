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

<img src="https://github.com/felix-seifert/Distributed-AI---GAMA-Assignments/blob/main/Assignment3/nQueen10.gif?raw=true">

High speed demonstration of the N=18 case (~ 500'000 cycles, ~1 minute and 20 seconds):

<img src="https://github.com/felix-seifert/Distributed-AI---GAMA-Assignments/blob/main/Assignment3/nQueen18.gif?raw=true">

Final result of the N=20 case (~ 2'227'000 cycles, ~7 minute and 20 seconds):

<img src="https://github.com/felix-seifert/Distributed-AI---GAMA-Assignments/blob/main/Assignment3/nQueen20.gif?raw=true">

## Task 2 - Decision-making Based on Individual Utility

The model `OptimiseIndividualUtility` includes two different agent species: `Guest` and `Stage`.

Instances of the species `Stage` have an adjacent floor for guests who want to see the act. Each stage shows sequentially randomised acts. The duration of an act is defined as a number of cycles which have to pass. After each act, a break follows which also has a duration defined in cycles. The different duration parameters can be modified in the experiment interface.

Each act has a set of attributes which have certain values from 0.2 to 1. The higher the value, the better the attribute. When an act at a stage is over, new values for the attributes are generated.

Instances of the species `Guest` want to attend acts. As there are multiple stages, they have a choice between different acts. Each visitor has a set of preferences with values from 0.2 to 1. These preferences can be used to calculate a utility for each act. The utility calculation works as follows:

```
utility = attribute1*preference1 + attribute2*preference2 ...
```

When a guest does not have any specific location, he/she asks all stages to transmit the attributes of their act. After the guest receives them, the guest uses these attributes and his/her own preferences to find the act with the highest utility. Afer the decision, the `targetStage` receives the question of the guest where exactly he/she should stand/sit on the guest floor. The guest then receives the exact location where he/she should go to.

## Task 3 - Improving Global Utility by Sacrificing Individual Utility

Building on the model of task 2, the model `ImproveGlobalUtility` assess the decision of each `Guest` after he/she decided. A central instance `Optimiser` helps with this.

The central part of this extended model is a new preference value for each `Guest`. Each guest either loves or hates crowded places. This preference affects the global utility either positively or negatively: If the guest likes the crowd, the proportion of the number of guests at the same act over the number of all guests is added to the global utility. If the guest does not like the crowd, this propotion gets subtracted from the global utility:

```
global_utility = utility_guest_1 + (guest_1_loves_crowd ? guests_at_same_event / all_guests : - guests_at_same_event / all_guests) + utility_guest_1 ...
```

Each `Stage` informs the `Optimiser` about the guests who attend each act. The optimiser then registers all empty acts and tries to find an act which has more than half of all guests. Also, it scans the guests of this crowded act to have a look if there is a guest who does not like crowds and is therefore sent to another empty act. The optimiser also checks the acts with exactly two attending guests. If these acts have one guest who does not like crowds while the other one loves them, the latter guest is moved to the crowded act.

The global utility is shown on the console before and after the movement of a few guests. Often, an improvement of the global utility can be observed. However, the movement decision is not based on the resulting utility and can therefore also result in a decrease of the global utility.

## Optimise Global Efficiency

To find the ideal distribution of guests, all guests and all stages have to send their preferences and attributes to the central optimiser where the optimisationg could be attempted. However, this optimisation is non-linear and an efficient solution not that obvious.

### Problem Definition

#### Parameters

{a, b, c, ..., j, ..., m} = Stages

{1, 2, 3, ..., i, ..., n} = Agents

m<sub>i</sub> = 1 if agent i enjoys crowds, -1 else

#### Variables

a<sub>i</sub>, b<sub>i</sub>, c<sub>i</sub>, ... = 1 if agent i select Stage a<sub>i</sub> (or b<sub>i</sub>, c<sub>i</sub>, ...), 0 else

n<sub>a</sub>, n<sub>b</sub>, n<sub>c</sub>, ... = number of agents visiting the a, b, c, ... Stage

**Constraints:**

a<sub>i</sub> + b<sub>i</sub> + c<sub>i</sub> + ... = 1 (each Agent can only choose one Stage)

n<sub>a</sub> + n<sub>b</sub> + n<sub>c</sub> + ... = n (the sum of all the agents in each Stage has to be equal to the total number of Agents in the Festival)

Σ<sub>i</sub> a<sub>i</sub> = n<sub>a</sub> (the number of Agents at the Stage a is equal to the number of Agents that selected that Stage)

Σ<sub>i</sub> b<sub>i</sub> = n<sub>b</sub> (the number of Agents at the Stage b is equal to the number of Agents that selected that Stage)

Σ<sub>i</sub> c<sub>i</sub> = n<sub>c</sub> (the number of Agents at the Stage c is equal to the number of Agents that selected that Stage)

...

#### Objective Function

max( Σ<sub>i</sub>  [(a<sub>i</sub>*n<sub>a</sub> + b<sub>i</sub>*n<sub>b</sub> + c<sub>i</sub>*n<sub>c</sub> + ...) * m<sub>i</sub>])

The Objective function is non-linear because each variable a<sub>i</sub>, b<sub>i</sub>, c<sub>i</sub>, ... is multiplied by the corresponding variable n<sub>a</sub>, n<sub>b</sub>, n<sub>c</sub>, ... .

The non-linearity of the problem implies that the search for a global maximum of the objective function is unoptimal due to the needed time (even though an optimal solution can be found, it is not ideal since it would take too much time to be adopted).

One solution is to perturbate the global utility value around the solution found by the base utility problem. On the basis of that, after each `Guest` selects his/her own favourite `Stage` (the one that maximises his/her utility), the `Optimiser` will try to change some guests' stage selection in order to evaluate if the global utility value can be increased.
