# Project

The project describes a simulated experiment of agents spending their free time while interacting with each other. The model [FreeTime](models/FreeTime.gaml) describes the basic functionality of different people visiting oubs and concert halls. The model [FreeTimeBDIRL](models/FreeTimeBDIRL.gaml) shows the extension of the basic model with `Belief, Desire, Intention` (BDI) agents and a simple reinforcement learning implementation.

## Agents

There are different stalls which humanoid agents will visit every now and then. These stalls are of the classes `Pub` and `ConcertHall`. There are also different classes of humanoid agents with distinctive behaviour. These different agent classes are `PartyLover`, `ChillPerson` and `Criminal`.

### Stalls

Each stall has a counter of cycles which is increased every cycle. At certain events, this counter is reset. This leads to the possibility to count certain durations.

The two different classes of stalls `Pub` and `ConcertHall` change their status based on this time. Each `Pub` has a kitchen to sell food. This kitchen though is not always open: When the amount of passed cycle reaches a given threshold, the kitchen is closed/opened. Similarly, each `ConcertHall` runs different concerts. These concerts run all around the clock. A new concert starts when the number of cycles it lasts is reached. Each new concert selects a random music genre from a globally given set of music genres.

### Mover

The humanoid agents, which are of the parent class `Mover`, roam around randomly. With a given chance, an agent wants to go to a stall. The stall is decided randomly from a list of all stall and the agent asks the stall for a specific place within the stall. This agent then approaches the place in the stall. Upon entering the stall (if the agent is close enough), its time starts to count: Each agent has a minimum number of cycles it would stay in the stall. When an agent stayed in a stall long enough, it leaves the stall with a given chance and starts to randomly rome around again. The guest notifies the place about both its entrence and its departure. Therefore, the places have a list about all the present guests.

Every `Mover` has the attributes `generous`, `noisy` and `hungry`. To keep it simpler, their values usually do not change over time (see the change of `generous` later). The value of each attribute is filled with a random number out of the given range. 0.0 represents a lowest value for an attribute and 1.0 is the highest. The different subtypes of the `Mover` class have stronger forms of specific attributes and have a behaviour which is based on them.

All the movers also have one common action: they try to invite someone else for a drink. Each time a `Mover` enters a stall and its `generous` value is high enough, it tries to invite someone else for a drink. However, this invitation happens only with a given chance. In case of an invitation, the `Mover` asks the stall to invite one random guest. Then, the `generous` value of the guest who received a free drink increases.

#### PartyLover

Each `PartyLover` is shown as an orange point. Their `noisy` value is higher than the ones of the other movers. 

In addition to the normal attributes, every `PartyLover` has a list of preferred music genres which is picked randomly from the global list of available music genres. If a `PartyLover` enters a `ConcertHall`, it asks this `ConcertHall` for the music genre of the current concert. If the music genre is none of the ones which are preffered by the `PartyLover` and its generosity is not high enough, it will leave the `ConcertHall` immediately. This reaction will also be printed on the console.

#### ChillPerson

Every `ChillPerson` is represented with a grey point. They have higher values of the attribute `generous`.

Besides their increased generosity, chill people can be affected by noisy guests. When a `ChillPerson` enters a stall, it asks for a list of all present guests. It then loops through all the guests to calculate the average value of their attribute `noisy`. If this average value is too high, the `ChillPerson` leaves the stall immediately and this reaction is printed on the console.

#### Criminal

Agents of the class `Criminal` are shown as blue points.

Criminals do not have a higher value for a specific characteristic. However, their actions are based on the value `hungry`. When they are in a `Pub`, they inquire the information whether the kitchen is opened. If the kitchen is open and `Criminal` hungry enough, it steals some food and leaves the `Pub`. This action will also be printed on the console.

## Drink Invitation

Besides the map where the actions and interaction of the agents can be orserverd, two other views show diagrams of the interaction. 

One diagram shows the average of the `generous` value of all the action over time (red curve). 

![FreeTime_model_display_generous_chart_size_663x853_cycle_13354_time_1607624249114](https://user-images.githubusercontent.com/41639203/101814412-17a8d200-3b59-11eb-9513-378556c65a48.png)

The other diagram shows the number of all drink invitations which happened during the experiment (blue curve).

![FreeTime_model_display_drink_invitations_size_663x853_cycle_13354_time_1607624252255](https://user-images.githubusercontent.com/41639203/101814446-23949400-3b59-11eb-98e2-da8243c9ff5d.png)

At the beginning, only the chill people can have a `generous` value which is high enough to invite someone else for a drink. As the generosity of people who are invited for a drink increases, after a while, more people become generous enough to invite someone for a drink. This can be seen in the increasing gradient. The average generosity can however not be higher than `1.0`. Therefore, the graph with the average `generous` value (red graph) does not surpass this level. Even though the drink invitations do not affect the generosity later on, drink invitations still happen and the blue graph still rises.

## Experiment Parameters

The parameters of the experiment offer the options to adjust the size of the grid and the number of agents of all five agent classes. Besides these options, you also get the option to edit the options for the part of the experiment which is shown in the diagrams: you can edit values relevant to the drink invitation. It is possible to change the minimum value of `generous` which is needed to invite someone for a drink. Also, the drink invitation does not always happen if the generosity is big enough; besides the minimum value of `generous`, a drink invitation has a certain chance which can also be editet in the parameters. As a last paremeter, you can change the amount by which the `generous` value is increasedd in case of a drink invitation.

## Belief, Desire, Intention (BDI)

In general, agents of the class `DustBot` try to approach pubs to collect trash which they then bring to the `RecycleStation`.

### DustBot

For the BDI integration, we have the agent class `DustBot`. The `DustBot` instances are able to interact with every `Pub` to collect trash. Once the trash is collected, it is brought to the `RecycleStation`.

Each `DustBot` has a given `sightDistance`. Within this distance, it is able to comunicate with other dust bots and pubs (the lower the `sightDistance`, the lower the amount of interactions).

The dust bots also have a maximum amount of trash which they could collect. As the currently carried trash of each `DustBot` is stored as an instance variable, it is checked that a `DustBot` does not carry more trash than the maximum amount.

To realise the BDI functionality, the dust bots are provided with the skill `simple_bdi`.

To express the desire of a `DustBot` to find trash, the initialisation begins with adding the desire `findTrash`. It then wanders around randomly.

Dust bots are able to perceive two different target classes: `DustBot` and `Pub`. The perception of agents of different classes results in setting the same desire in different ways:
* If a `DustBot` is perceived within the `sightDistance`, the desire `shareInformation` will be set with a strength of `5.0`.
* If a `Pub` with accumulated trash is perceived within the `sightDistance`, it receives the emotion `joy`. Once a DustBot is joyous, the desire `shareInformation` will be set with a strength of `5.0`. In this case, a `Pub` with trash is found and the intention to find trash is removed.

In order to establish a hierarchy in the possible actions, we set two rules:
* `rule belief: pubLocation new_desire: hasTrash strength: 2.0;`
* `rule belief: hasTrash new_desire: bringTrashToRecycle strength: 3.0;`
The former rule explains that if there is a belief about the location of a `Pub` which has trash, trash can be found there. The letter rule allows the `DustBot` to bring the trash to a `RecycleStation` after the trash has been collected.

According to the former rule, a `DustBot` moves to a `Pub` which has some trash. Once it reaches the target, it picks up the minimum of the `Pub`'s trash and the trash it can carry. In case the target `Pub` of a `DustBot` is missing, the plan `getTrash` will set the subintention to `choosePub`, forcing the DustBot to operate. Once the maximum trash capacity of a `DustBot` is reached, the letter rule applies and it enters the plan `goToRecycleStation`.

When a `DustBot` has the target `RecycleStation` and reaches its target, it loses the belief `hasTrash` and the intention `bringTrashToRecycle`. The trash collected by the `RecycleStation` and the trash collected by this `DustBot` is then increased by the amount of trash this bot recycled. The trash which is currently held by the `DustBot` is set to zero and it continues to collect more trash.

#### DustBots' Communication

Dust bots have a simple communication plan (`shareInformation`) that lets them exchange information about pubs. More precisely, known pubs with trash and known pubs without trash. This communication is achieved by adding a belief of the specific pubs (`knownPub` and `knownEmptyPub`).

Since the communication between the dust bots can be faulty, each `DustBot` is provided with a simple individual memory of known `Pub` locations. When a `DustBot` is in `wander` state, it will approach one of the known pubs to check the trash status of this `Pub`.

### RecycleStation

One `RecycleStation` is located in the center of the map to optimize the average distance for any random disposition of the Stalls. Dust bots approach it to recycle the rubbish they collected.

### Trash Creation

In order to provide the dust bots with work, each `Pub` has an accumulated amount of trash. Everytime a guest of a `Pub` leaves, the guets leaves a random amount of trash in the `Pub`. Everytime a `DustBot` identifies trash in a `Pub`, a `DustBot` approaches this `Pub` and brings it to the `RecycleStation`.

To keep the observed area free of trash, the instances of the class `Mover` and `DustBot` have to be balanced.

## Simulation

The first image represents the map of the previously described simulation. The white agents are the dust bots: the bigger the `DustBot`, the more the quantity of trash it currently holds.

<img src="https://user-images.githubusercontent.com/36768662/102253483-a9249500-3f07-11eb-96bb-4aaf0faac92d.png">

This picture shows a balanced setting, as there are no overlapping stalls or isolated stalls. It may happen that the dust bots will not be able to see a `Pub` far away if the sight distance is not high enough. If a `Pub` is unseen, its trash will be accumulated.

### Global Trash Chart

The second image shows how much trash is accumulated in each `Pub` (red and blue graphs) over time. After cycle 1200 of the execution, the dust bots discover the trash in the `Pub` and start to clean it. Once this `Pub0` is empty of trash, the dust bots can keep the whole simulation's trash under control.

<img src="https://user-images.githubusercontent.com/36768662/102253487-a9bd2b80-3f07-11eb-8898-2e2417fc87e3.png">

The blue line represents the accumulated trash of `Pub1`. Every now and then, some trash appears for this pub. However, the trash will be instantly collected by a `DustBot`. Once the huge trash amount of `Pub0` is cleared (around cycle 4600), it has the same status as its trash is removed quite soon.

Even though it is not noticeable that strongly in this image, the chart also includes the general `Communication Index` as a green graph. Every communication between different dust bots increases this index by 1. As this index explodes over time, its value is divided by 1000.

The following image shows the chart of a simulation where the increase of the `Communication Index` can be seen. After the discovery of `Pub0` (red graph), the communication between dust bots and therefore, the `Communication Index` (green graph) increases. Once `Pub1` is discovered by the dust bots, they also communicate about `Pub1`.

<img src="https://user-images.githubusercontent.com/36768662/102253479-a75ad180-3f07-11eb-8bcf-41ffd5f0a75f.png">

### Trash Currently Held Chart

The following image shows a chart shows the trash which is held by each `DustBot` over time. The graph shows that the maximum capacity of each `DustBot` is five. A few cycles after collecting the trash, the trash value becomes zero again. This is when a `DustBot` unloads its trash at the `RecycleStation`.

<img src="https://user-images.githubusercontent.com/36768662/102253489-aa55c200-3f07-11eb-8fc5-7bfc1a3b112d.png">

`DustBot0` (red graph) was not active for nearly 1500 cycles. As soon as the second Pub is discovered, it starts to free it from trash (compare first image of BDI section).

### Total Trash Chart

The following chart shows how the different dust bots performed individually. The performance of each `DustBot` is shown with one unique colour. Each colour shows two graphs: the trash which got collected by this bot and the personal communication index (PCI) of this bot. The three higher graphs in this image depict the total trash collected by each `DustBot` and the lower ones show the PCI.

<img src="https://user-images.githubusercontent.com/36768662/102253484-a9249500-3f07-11eb-8fd7-84778188e0b1.png">

This chart confirms an observation from the previous chart (Trash Currently Held): `DustBot2` (green graph) started to perform only around cycle 1000. As this later activity of dust bots happen because they do not discover a near `Pub` and also do not interact with other dust bots, a `sightDistance` which is too low can lead to an accumulation of trash. To decrease an accumulation of trash, the `sightDistance` can be increased.

## Reinforcement Learning

In the extended model [FreeTimeBDIRL](models/FreeTimeBDIRL.gaml), each `PartyLover` changes its music taste randomly through `reflex considerNewMusicGenre`. Each `ConcertHall` is implemented with a trend following algorithm. Over time, both party lovers and concert halls will alter their preference to different music genres.

### Agent

These are the new variables introduced for the `species ConcertHall`:

`int changeMusicTasteThreshold <- 92` Represent the probability, for every PartyLover, not to change its music tastes at every step. This parameters can be changed during execution.

`list<PartyLover> knownPartyLovers <- [];` Contains the PartyLovers that have interacted with the ConcertHall

`list<string> musicTasteDistribution <- [];`Contains strings as 'Rock', 'Funk', ... that are taken as single vote in the preference evaluation

`list<int> musicTasteCount <- [0,0,0,0,0];`Contains the number of person that enjoy the corresponding index (0 = 'Rock', 1 = ...)

`int totalCount <- 0;` Equivalent to the number of preferences taken into consideration (from musicTasteDistribution)

`list<float>probabilities <- [0.0,0.0,0.0,0.0,0.0];` Current probabilities prediction based on known PartyLovers

`list<float>probabilityPerturbations <- [0.0,0.0,0.0,0.0,0.0];` Stored Perturbation to avoid fashions: musicGenres decay through time by assigning a temporary negative/positive compensation

`list<float>probabilitiesAfterPerturbation <- [0.0,0.0,0.0,0.0,0.0];` Sum of `probabilities` and `probabilityPerturbations`

`string electedConcertGenre <- "";` New proposed musicGenre for the next concert cycle

`string choosenConcertGenre <- "";` If the electedConcertGenre is different from previousMusicGenre, this is equivalent to the new music genre decided

`string previousMusicGenre <- "";` Used to evaluate possible fashions situations

`float maxFashionDecay <- rnd(-0.5,0.0);` To limit Fasion decay

## System

Only one action (`updateMusicPlanning`) has been added to the base code.

The `knownPartyLovers` are checked for their music tastes: these are added as tokens into `musicTasteDistribution`.

The `musicTasteCount` is of the same length of the musicGenres. For each musicGenre the number of token is calculated.
The total number of token `totalCount` is calculated by summing all the tokens counted.

`probabilities` contains a vector with the same number of elements, but each of the value is the probability of choosing the corresponding musicGenre for the next concert.

`probabilityPerturbations` is the perturbation vector we apply to the `probabilities` one. It's used in the code to avoid fashions that might break the algorithm. The value of a musicGenre on fashion exceed is lowered, while a rising musicGenre is encouraged. 

`probabilitiesAfterPerturbation` is the sum of the two vectors before. From this vector, the maximum value (probability+perturbation) is choosen as elected musicGenre.

If the elected musicGenre proposed `electedConcertGenre` is a new one, the perturbation is cancelled on that musicGenre. Otherwhise, it will increase the negative perturbation.

Even though this Reinforcement Learning module is a simple process, the choice of the maximum value of `probabilitiesAfterPerturbation` grants to ConcertHalls the capability to follow the best music trends. For example, if a money value is introduced in the system with a continuous and equal distribution among the agents, this algorithm will be able to maximize the revenues.

The ConcertHall start without knownledge of its environment. It interacts throgh time with PartyLovers while they ask for information about the concert. Everytime there's an interaction, the ConcertHall formulate a new probability distribution of what's the best choice for the next concert based on its knowledge of the environment. Then, it applies the action of starting the concert with the selected musicGenre. The increase in number of people satisfied with this choice is technically the reward we can convert into revenue.

Even tough movement is not included in the RL implementation, it's possible to imagine the trend as a point that has to be followed by the ConcertHall. This algorithm allows the ConcertHalls to continuously follow the music tastes through the random variation of the PartyLovers tastes.

## Simulation

<img src="https://user-images.githubusercontent.com/36768662/102285280-4ac2db00-3f36-11eb-9fcf-31d15cc2a628.gif">

In this chart is shown the starting point of the ConcertHall knowledge. Each new musicGenre is added to the chart. The section with higher area will be the choice for the next concert. Few seconds before the ending of the GIF it's possible to see a variation of speed, due to the higher number of tokens taken into consideration for the choice.
          
<img src="https://user-images.githubusercontent.com/36768662/102285283-4b5b7180-3f36-11eb-9458-2ef8e1d5b77b.gif">
The variation of `changeMusicTasteThreshold` can perturbate the randomness of music tastes of the PartyLovers. Even at the fastest speed of variation (`changeMusicTasteThreshold = 0`), the algorithm is able to perform a good choice in terms of reward.
If the value of `changeMusicTasteThreshold` is set to 100, the variation of music tastes from PartyLover will stop, and so will the ConcertHall choices.

<img src="https://user-images.githubusercontent.com/36768662/102291012-70ee7800-3f42-11eb-943e-1e0b52210889.gif">
In this chart is represented that the choice of the ConcertHall corresponds with the most requested musicGenre (there's some latency, fast simulation can be approximative).

<img src="https://user-images.githubusercontent.com/36768662/102291014-721fa500-3f42-11eb-9de2-afda2e3895d3.gif">
As last, it's possible to disable a type of music, through e.g. `disableRock`. In the GIF above is represented what happens if a musicGenre can't be selected as new favourite music Genre by PartyLovers. The result shows robustness for the algorithm, that's capable to follow the change.

