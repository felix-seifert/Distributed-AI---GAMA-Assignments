# Assignment 1

## Basic Model

The model depicts a festival with its stalls and visitors. The stalls and visitors are implemented as species. Their instances, the agents, interact based on their nutrient demand and supply. 

The stalls of the festival are information centres, food stalls and drink stalls (species `InformationCentre`, `FoodStore` and `DrinksStore`). The different stalls inherent from the parent species `Stall` which provides them with boolean attributes which give information about what the store offers. The different sub-species 'override their attribute' and specifies an icon which should be used for displaying this stall. In the basic version, only the information centre(s) know the locations of the food and drinks stalls.

Over time, the visitors become more thirsty and hungry while they are randomly wandering around (species `Visitor`); each simulation cycle, their stored drinks and food decrease. When at least one nutrition storage reaches zero, the visitor has to approach an information centre if he/she does not know where to replenish his/her nutritional storage. After the visitor interacted with an information centre, it knows the location where it can replenish his/her storage, approaches this location, interacts with the stall and performs an associated action (e.g. replenish food storage). When both food and drinks storage are not zero, the visitor continues to randomly wander around.

The graphical user interface (GUI) of the experiment `Festival` displays all agents, their types and when they might interact. Commented lines in the source code allow to show the details of the interaction as console outputs.

### Parameters of Experiment

The parameters for the experiment `Festival` offer the basic options of specifying the size of the grid which forms the festival ground and the number of the different agents (number of information centres, stalls and visitors). When changing the number of agents, the requirements of the assignments are kept. The rquirements are that we have at least one information centre, at least four stalls which sell food and/or drinks and at least ten visitors.

We also added the option to change the size of the food and drinks storage. (The drinks and the food storage get reduced every simulation cycle. When both storages are empty when a visitor arrives at an information centre, the visitor first asks for the location of a drinks stall.)

When a visitor wants to retrieve the location of a stall, the visitor always takes the location with the lowest distance to its own location. This leads to a congregation of visitor agents around a few shops. (Information centres do not change their location and visitors would therefore always pick the same food and drinks stalls from an information centre). To change the behaviour of the visitor agents, a boolean parameter in the GUI of the `Festival` experiment triggers the change of the visitors behaviour to choose a target destination randomly out of the available destination.

## Improvement of Visitors' Exploring Performances

We added two functionalities which improve the visitors' performance in reducing the number of times he/she has to approach an information centre. At first, each visitor receives a brain where he/she can store places he/she visited. Secondly, he/she can also store locations which he/she received from other visitors.

By checking the amount of locations stored in the memory of a visitor over time, it is possible to understand the positive affect in terms of time and metres walked.

### Brain of Agents (Advanced Option)

As a first advanced option, we added a brain for the agents in form of a list of known stalls for each visitor (every agent has a memory). This option can be activated via the parameters of the experiment `Festival`.

Each visitor does not completely rely on its memory and sometime approaches the information centre to retrieve the location of a stall. If the memory of a visitor is not empty and he is in need of replenishing a nutritional value, `exploitingMemoryRate` defines the probability of the visitor looking up a location in his/her memory.

The probability for using his/her memory will not be a constant value all the time: The more a visitor uses his/her memory, the less he/she will use it later (and vice versa).

If a visitor receives the location of a new stand from an information centre, he/she can add this to his/her memory which extends the memorised locations. To improve the model, visitors should also forget the locations of stalls. With the implementation of this functionality, the model could run longer with actual state changes.

### Interaction With Other Visitors (Advanced Option)

Another way to extend the memory of known locations, the visitors can interact with each other. This function can also be activated via the parameters of the experiment `Festival`. 

If another visitor (a peer) is within `communicationDistance`, visitors can exchange information. The information echange happen also only with a probability, the rate defined in `interactionRate`, and if the content of the two memories has a difference. This interaction can be realised with color changes of the interacting visitors.

## Removal of Bad Behaving Agents (Advanced Option)

With a probability of `criminalRate`, each visitor can behave badly. Idea is to realise a bad beaviour and scole this bad behaviour.

When any visitor performs an interaction with a stall, it can become a criminal which then activates its variable `badBehaviour`.

Each visitor spies on al the other visitors within `guardRange` to check if any visitor has the active flag `badBehaviour`. In case a visitor realises such bad behaviour, the observing visitor approaches an information centre, reports his observation and finds a guard. The guard stores the witness and follows him/her. Once the guard is close enough to the criminal, he/she will delete the criminal (bad behaving visitor) from the simulation.

To activate the option of a guard who tries to remove bad behaving visitors, set the parameter for the number of guards greater than zero.
