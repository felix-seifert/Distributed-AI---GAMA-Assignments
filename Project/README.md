# Project

Task of the project is to develop an interaction of several humanoid entities. The project report gets finished when the implementation is completed.

The project describes a simulated experiment of different agents spending their free time. There are different stalls which the humanoid agents will visit every now and then. These stalls are `Pub` and `ConcertHall`. There are also different classes of humanoid agents who behave differently. These different agent classes are `PartyLover`, `ChillPerson` and `Criminal`.

The humanoid agents roam around randomly. With a given chance, an agents want to go to a stall. The stall is decided randomly and the agent asks the stall for a specific place. This agent then approaches the stall. Upon entering the stall (if the agent is close enough), the time for it starts to count: Each agent has a minimum number of cycles it would stay in the stall. When an agent stayed in a stall long enough, it leaves the stall only with a given chance and start to randomly rome around again. The guest notifies the place about both its entrence and its departure. Therefore, the places have a list about all the guests.