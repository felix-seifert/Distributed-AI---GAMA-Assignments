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