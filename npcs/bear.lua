npc_types['bear'] = {
			name="Bear",
			color={108,40,90},
			hostile=true,
			move='attack',
			vocal=true,
			max_health=20,
                        armour={
                                        {
                                                type="flesh",
                                                natural=true,                   -- means cannot be lost/destroyed
                                                value=2                         -- defensively quite ok
                                        }
                        },
                        weapons={
                                        {
                                                name='teeth',
                                                natural=true,
						likelihood=2,
                                                attacks={
                                                        {
                                                                verbs={'bites','gnaws','seizes','chomps on','takes a chunk out of','sinks in to'},
                                                                damage={dice_qty=2,dice_sides=6,plus=2},
                                                                critical_chance_multiplier=3
                                                        }
                                                }
                                        },
                                        {
                                                name='claws',
                                                natural=true,
                                                likelihood=8,
                                                attacks={
                                                        {
                                                                verbs={'whacks','scrapes','scratches','mauls','rips','vicerates','tears'},
                                                                damage={dice_qty=2,dice_sides=4,plus=3},
                                                                critical_chance_multiplier=1.5
                                                        }
                                                }
                                        }
                        },
			sounds={
				attack=love.audio.newSource({
								"npcs/bear/bear-growl-1.mp3",
								"npcs/bear/bear-growl-2.mp3",
								"npcs/bear/bear-growl-3.mp3",
								"npcs/bear/bear-growl-4.mp3",
								"npcs/bear/bear-growl-5.mp3",
								"npcs/bear/bear-growl-6.mp3",
								"npcs/bear/bear-growl-7.mp3",
								"npcs/bear/bear-growl-8.mp3",
								"npcs/bear/bear-growl-9.mp3",
								"npcs/bear/bear-growl-10.mp3",
								"npcs/bear/bear-growl-11.mp3",
								"npcs/bear/bear-growl-12.mp3",
								"npcs/bear/bear-growl-13.mp3",
								"npcs/bear/bear-growl-14.mp3",
								"npcs/bear/bear-growl-15.mp3",
								"npcs/bear/bear-growl-16.mp3",
								"npcs/bear/bear-growl-17.mp3",
								"npcs/bear/bear-growl-18.mp3",
								"npcs/bear/bear-growl-19.mp3",
								"npcs/bear/bear-growl-20.mp3",
								"npcs/bear/bear-growl-21.mp3",
								"npcs/bear/bear-growl-22.mp3",
								"npcs/bear/bear-growl-23.mp3",
								"npcs/bear/bear-growl-24.mp3",
								"npcs/bear/bear-growl-25.mp3",
								"npcs/bear/bear-growl-26.mp3",
								"npcs/bear/bear-growl-27.mp3"
							     }),
				target=love.audio.newSource({
								"npcs/bear/bear-growl-1.mp3",
								"npcs/bear/bear-growl-2.mp3",
								"npcs/bear/bear-growl-3.mp3",
								"npcs/bear/bear-growl-4.mp3",
								"npcs/bear/bear-growl-5.mp3",
								"npcs/bear/bear-growl-6.mp3",
								"npcs/bear/bear-growl-7.mp3",
								"npcs/bear/bear-growl-8.mp3",
								"npcs/bear/bear-growl-9.mp3",
								"npcs/bear/bear-growl-10.mp3",
								"npcs/bear/bear-growl-11.mp3",
								"npcs/bear/bear-growl-12.mp3",
								"npcs/bear/bear-growl-13.mp3",
								"npcs/bear/bear-growl-14.mp3",
								"npcs/bear/bear-growl-15.mp3",
								"npcs/bear/bear-growl-16.mp3",
								"npcs/bear/bear-growl-17.mp3",
								"npcs/bear/bear-growl-18.mp3",
								"npcs/bear/bear-growl-19.mp3",
								"npcs/bear/bear-growl-20.mp3",
								"npcs/bear/bear-growl-21.mp3",
								"npcs/bear/bear-growl-22.mp3",
								"npcs/bear/bear-growl-23.mp3",
								"npcs/bear/bear-growl-24.mp3",
								"npcs/bear/bear-growl-25.mp3",
								"npcs/bear/bear-growl-26.mp3",
								"npcs/bear/bear-growl-27.mp3"
							     }),
				distance=love.audio.newSource({
								"npcs/bear/bear-noise-1.mp3",
								"npcs/bear/bear-noise-2.mp3",
								"npcs/bear/bear-noise-3.mp3",
								"npcs/bear/bear-noise-4.mp3",
								"npcs/bear/bear-noise-5.mp3",
								"npcs/bear/bear-noise-6.mp3",
								"npcs/bear/bear-noise-7.mp3",
								"npcs/bear/bear-noise-8.mp3",
								"npcs/bear/bear-noise-9.mp3",
								"npcs/bear/bear-noise-10.mp3",
								"npcs/bear/bear-noise-11.mp3",
								"npcs/bear/bear-noise-12.mp3",
								"npcs/bear/bear-noise-13.mp3",
								"npcs/bear/bear-noise-14.mp3",
								"npcs/bear/bear-noise-15.mp3",
								"npcs/bear/bear-noise-16.mp3",
								"npcs/bear/bear-noise-17.mp3",
								"npcs/bear/bear-noise-18.mp3",
								"npcs/bear/bear-noise-19.mp3",
								"npcs/bear/bear-noise-20.mp3",
								"npcs/bear/bear-noise-21.mp3",
								"npcs/bear/bear-noise-22.mp3",
								"npcs/bear/bear-noise-23.mp3",
								"npcs/bear/bear-noise-24.mp3",
								"npcs/bear/bear-noise-25.mp3",
								"npcs/bear/bear-noise-26.mp3",
								"npcs/bear/bear-noise-27.mp3",
								"npcs/bear/bear-noise-28.mp3",
								"npcs/bear/bear-noise-29.mp3"
							     }),
				die=love.audio.newSource({
								"npcs/bear/bear-death-1.mp3",
								"npcs/bear/bear-death-2.mp3",
								"npcs/bear/bear-death-3.mp3",
								"npcs/bear/bear-death-4.mp3",
								"npcs/bear/bear-death-5.mp3",
								"npcs/bear/bear-death-6.mp3",
								"npcs/bear/bear-death-7.mp3",
								"npcs/bear/bear-death-8.mp3",
								"npcs/bear/bear-death-9.mp3",
								"npcs/bear/bear-death-10.mp3",
								"npcs/bear/bear-death-11.mp3",
								"npcs/bear/bear-death-12.mp3"
				})
			}
		}
