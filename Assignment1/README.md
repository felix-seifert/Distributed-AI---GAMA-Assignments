# Assignment 1

## Basic Model

The model depicts a festival with its stalls and visitors. The stalls and visitors are implemented as species. Their instances, the agents, interact based on their nutrient demand and supply. 

The stalls of the festival are information centres, food stalls and drink stalls (species `InformationCentre`, `FoodStore` and `DrinksStore`). The different stalls inherent from the parent species `Stall` which provides them with boolean attributes which give information about what the store offers. The different sub-species 'override their attribute' and specifies an icon which should be used for displaying this stall. In the basic version, only the information centre(s) know the locations of the food and drinks stalls.

Over time, the visitors become more thirsty and hungry while they are randomly wandering around (species `Visitor`); each simulation cycle, their stored drinks and food decrease. When at least one nutrition storage reaches zero, the visitor has to approach an information centre if he/she does not know where to replenish his/her nutritional storage. After the visitor interacted with an information centre, it knows the location where it can replenish his/her storage, approaches this location, interacts with the stall and performs an associated action (e.g. replenish food storage). When both food and drinks storage are not zero, the visitor continues to randomly wander around.

The graphical user interface (GUI) of the experiment `Festival` displays all agents, their types and when they might interact. The console outputs show the details of the interaction.

### Parameters of Experiment

The parameters for the experiment `Festival` offer the basic options of specifying the size of the grid which forms the festival ground and the number of the different agents (number of information centres, stalls and visitors). When changing the number of agents, the requirements of the assignments are kept. The rquirements are that we have at least one information centre, at least four stalls which sell food and/or drinks and at least ten visitors.

We also added the option to change the size of the food and drinks storage. (The drink storage is reduced by 0.02 per simulation cycle, the food storage by 0.01 per simulation cycle. When both storages are emoty when a visitor arrives at an information centre, the visitor first asks for the location of a drinks stall.)

When a visitor wants to retrieve the location of a stall, the visitor always takes the location with the lowest distance to its own location. This leads to a congregation of visitor agents around a few shops. (Information centres do not change their location and visitors would therefore always pick the same food and drinks stalls from an information centre). To change the behaviour of the visitor agents, a boolean parameter in the GUI of the `Festival` experiment triggers the change of the visitors behaviour to choose a target destination randomly out of the available destination.
