/**
* Name: FreeTime
* Model which simulates different humanoid entities who spend their free time and interact with each other 
* Author: Marco Molinari <molinarimarco8@gmail.com>, Felix Seifert <mail@felix-seifert.com>
*/


model FreeTime

global {
	
	int gridWidth <- 10;
	int gridHeight <- 10;
	bool displayEntityName <- false;
}

species Stall skills: [fipa] {}

species Pub parent: Stall {}

species ConcertHall parent: Stall {}

species Mover skills: [moving, fipa] {
	
	Stall targetStall <- nil;
	
	reflex randomMove when: targetStall = nil {
		do wander;
	}
}

species PartyLover parent: Mover {}

species ChillPerson parent: Mover {}

species Criminal parent: Mover {}

species Journalist parent: Mover {}

species Scientist parent: Mover {}
