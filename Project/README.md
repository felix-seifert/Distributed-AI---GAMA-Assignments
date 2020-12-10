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