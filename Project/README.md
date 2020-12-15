# Project

The project describes a simulated experiment of agents spending their free time while interacting with each other.

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

## Challenges
We made an integration for both of the challenges.



## Belief, Desire, Intention
For the BDI integration, we have the DustBots as a group of Agents able to interact with Pubs to collect trash. Once the trash is collected, it is brought to the Festival Recylce Center.

The DustBot are provided with the skill 'simple_bdì', that allow them to use Beliefs, Desires and Intentions.

The initialization of each of these DustBots begins with adding the desire to find Trash ('findTrash').

They are able to perceive two targets: other DustBots and Pubs. When another DustBot is perceived, the desire to share information ('shareInformation') is set with a strenght of 5.0. Otherwise when a Pub is perceived and if it's not empty ('each.trashAccumulated > 0') and inside the sight distance ('sightDistance'), the joy emotion will be triggered. Once a DustBot is joyous, the desire to share information ('shareInformation') is set with a strenght of 5.0. The plan 'shareInformation' will be explained after.

In this case, since trash has been found, the intention to find it is removed ('remove_intention(findTrash, false)').

In order to establish a hierarchy in the possible actions, we set two rules:
'rule belief: pubLocation new_desire: hasTrash strength: 2.0;'
'rule belief: hasTrash new_desire: bringTrashToRecycle strength: 3.0;'
The first rule explain that if there's a belief about a Pub location (not empty of trash), then trash can be found there; the second one allows the DustBot to bring Trash to recycle after Trash has been collected.

Since the communication among these agents can be faulty, they are provided with a simple individual memory of the known Pub locations. When a DustBot is in 'wander' state, he will then reach one of the known Pubs to check what's its Trash status.

The plan 'chooseClosestPub' evaluate which Pub is not empty and select the closest one as target. In this process, the memory will be updated with the knowledge of the closest Pub identified.

The plan 'getTrash' set the subintention to 'choosePub' in case a target it's missing, forcing the DustBot to operate. Else, if a target Pub is selected, the 'do goto target:target' moves the DustBot to the target location. Once there, it can either pick an amount of Trash equal to it's capacity ('trashCapacity') or the residual Trash if the Trash in the Pub ('trashAccumulated') is smaller then the DustBot capacity (e.g.: 13->8->3->0).

Once the maximum Trash capacity of the DustBot ('trashCapacity') is achieved, the DustBot enter the plan 'goToRecycleStation', as the 'rule belief: hasTrash new_desire: bringTrashToRecycle strength: 3.0;' commands.

One RecycleCenter ('festivalRecycleCenter') is located in the center of the map to optimize the average distance for any random disposition of the Stalls.
After imposing the 'goto target:' to 'festivalRecycleCenter', once the location is reached, the DustBot lose the belief of 'hasTrash' and the intention 'bringTrashToRecycle'. The amount of total Trash collected ('festivalRecycleCenter.totalTrashCollected' and 'self.totalTrashCollected') are updated with the amount brought by the DustBot.
The Trash currently held ('trashCurrentlyHeld') is set to 0. The bot is now going to collect more Thrash.

DustBots have a simple communication plan ('shareInformation'), that let them exchange information about Pubs. More precisely, known Pubs with Trash and known Pubs without Trash. This operation is done by adding a belief ('add_belief') of the specific Pubs ('knownPub' and 'knownEmptyPub').

In order to let the DustBot work, an increasing amount of Trash ('trashAccumulated') is implemented in the Pub specie.
Everytime a client of the Pub leaves, a random amount of Trash ('rnd(1,5)') is allocated into the Pub.
This let the mechanics of the Party to interact with the BDI interface: everytime the DustBot identify Trash in a Pub, they take it to the Festival Recycle Center.

A balancing in the number of Guests and DustBots is required in order to keep the Festival empty of Trash.

Here is a simulation of the experiment:

<img src="https://user-images.githubusercontent.com/36768662/102253483-a9249500-3f07-11eb-96bb-4aaf0faac92d.png">

The first image represents the map of the simulation with the different species and processes already explained previously.
The white agents are the DustBots: the bigger the DustBot, the more the quantity of Trash currently held ('trashCurrentlyHeld').

This is a balanced setting, as there are no overlapping of Stalls or isolated Stalls. It may happen that the DustBots won't be able to see a Pub far away if the sight distance ('sightDistance') isn't set properly high enough.

If a Pub is unseen, Trash will be accumulated.

<img src="https://user-images.githubusercontent.com/36768662/102253487-a9bd2b80-3f07-11eb-8898-2e2417fc87e3.png">

The second image shows how much Trash is accumulated in each Pub (Red and Blue lines) through the time. After the 1200th cycle of execution, the DustBots discovers the Trash in the Pub and start to clean it. Once the Pub is empty of Trash, the DustBots can keep the whole Festival Trash value under control.

The Blue line represent the second Pub accumulated Trash: it's possible to see that now and then Trash appears, but it is instantly collected by the DustBot. The same behavior will follow after the 5000th cycle for the first Pub (Red line).

Even though in this image is not noticeable, in this graph is also represented the general Communication Index ('communicationIndex') as a Green line. It is increased by 1 everytime a communication among the DustBots happens, but it is represented divided by 1000 as it explodes in the value through time.

In the following image a different behavior from another execution of the same experiment can be seen:

<img src="https://user-images.githubusercontent.com/36768662/102253479-a75ad180-3f07-11eb-8bcf-41ffd5f0a75f.png">

Here the Red Pub got discovered after 1400 cycles, and as soon as it happens the Communication Index (Green line) increases. The same process happens goes for the Blue Pub at 3000 cycles. After being discovered, they are constantly checked for Trash.

From the same simulation of the first two images:

<img src="https://user-images.githubusercontent.com/36768662/102253489-aa55c200-3f07-11eb-8fc5-7bfc1a3b112d.png">

This graph represents the Trash currently held by each DustBot through time. As their maximum capacity is 5 in this simulation, they can't hold more Trash, as shown in the graph.
The DustBot0 (Red line) wasn't active for the first 1500 cycles, but as soon as the second Pub is discovered, he starts to clean it from the Trash (as noticeable in the first figure).

As regards how each DustBot performed:

<img src="https://user-images.githubusercontent.com/36768662/102253484-a9249500-3f07-11eb-8fd7-84778188e0b1.png>

With the same color are represented the total Trash collected by one DustBot and its individual Communication Index ('personalCommunicationIndex'). To be more precise, the 3 higher lines represents the total Trash collected by the DustBots, while the lower ones the corresponding Communication Index.

Here (DustBot2 PCI, Grey line), in comparison with the previous graph (DustBot2 Trash currently held, Green line), confirm that the first Trash collection for DustBot2 happened around the 1000th cycle. This happened because it wasn't able to communicate with the other DustBots, as it's shown in its low PCI ('personalCommunicationIndex').

## Reinforcement Learning
