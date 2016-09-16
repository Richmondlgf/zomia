npc_types['goblin'] = {
			name="Goblin",
			color={30,138,30},
			hostile=true,
			move='attack',
			vocal=true,
			sounds={
				attack=love.audio.newSource({
					"sounds/impact/punch-1.mp3",
					"sounds/impact/punch-2.mp3",
					"sounds/impact/punch-3.mp3",
					"sounds/impact/punch-4.mp3",
					"sounds/impact/punch-5.mp3",
					"sounds/impact/punch-6.mp3",
					"sounds/impact/punch-7.mp3",
					"sounds/impact/punch-8.mp3",
					"sounds/impact/punch-9.mp3",
					"sounds/impact/punch-10.mp3",
				}),
				distance=love.audio.newSource({
					"npcs/goblin/goblin-1.mp3",
					"npcs/goblin/goblin-2.mp3",
					"npcs/goblin/goblin-3.mp3",
					"npcs/goblin/goblin-4.mp3",
					"npcs/goblin/goblin-5.mp3",
					"npcs/goblin/goblin-6.mp3",
					"npcs/goblin/goblin-7.mp3"
				}),
				target=love.audio.newSource({
					"npcs/goblin/goblin-1.mp3",
					"npcs/goblin/goblin-2.mp3",
					"npcs/goblin/goblin-3.mp3",
					"npcs/goblin/goblin-4.mp3",
					"npcs/goblin/goblin-5.mp3",
					"npcs/goblin/goblin-6.mp3",
					"npcs/goblin/goblin-7.mp3"
				}),
				win=love.audio.newSource({
					"npcs/goblin/goblin-laugh.mp3"
				})
			}
		}
