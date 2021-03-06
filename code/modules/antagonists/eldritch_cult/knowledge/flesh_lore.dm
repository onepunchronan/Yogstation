/datum/eldritch_knowledge/base_flesh
	name = "Principle of Hunger"
	desc = "Opens up the path of flesh to you. Allows you to transmute a pool of blood with a knife into a Flesh Blade"
	gain_text = "Hundreds of us starved, but I.. I found the strength in my greed."
	banned_knowledge = list(/datum/eldritch_knowledge/base_ash,/datum/eldritch_knowledge/base_rust,/datum/eldritch_knowledge/final/ash_final,/datum/eldritch_knowledge/final/rust_final)
	next_knowledge = list(/datum/eldritch_knowledge/flesh_grasp)
	required_atoms = list(/obj/item/kitchen/knife,/obj/effect/decal/cleanable/blood)
	result_atoms = list(/obj/item/melee/sickly_blade/flesh)
	cost = 1
	route = PATH_FLESH

/datum/eldritch_knowledge/flesh_ghoul
	name = "Imperfect Ritual"
	desc = "Allows you to resurrect the dead as voiceless dead by sacrificing them on the transmutation rune with a poppy. Voiceless dead are mute and have 50 HP. You can only have 2 at a time."
	gain_text = "I found notes.. notes of a ritual, it was unfinished and yet I still did it."
	cost = 1
	required_atoms = list(/mob/living/carbon/human,/obj/item/reagent_containers/food/snacks/grown/poppy)
	next_knowledge = list(/datum/eldritch_knowledge/flesh_mark,/datum/eldritch_knowledge/armor,/datum/eldritch_knowledge/ashen_eyes)
	route = PATH_FLESH
	var/max_amt = 2
	var/current_amt = 0
	var/list/ghouls = list()

/datum/eldritch_knowledge/flesh_ghoul/on_finished_recipe(mob/living/user,list/atoms,loc)
	var/mob/living/carbon/human/humie = locate() in atoms
	if(QDELETED(humie) || humie.stat != DEAD)
		return

	if(length(ghouls) >= max_amt)
		return

	if(HAS_TRAIT(humie,TRAIT_HUSK))
		return

	if(HAS_TRAIT(humie, TRAIT_MINDSHIELD))
		return

	humie.grab_ghost()

	if(!humie.mind || !humie.client)
		var/list/mob/dead/observer/candidates = pollCandidatesForMob("Do you want to play as a [humie.real_name], a voiceless dead", ROLE_HERETIC, null, ROLE_HERETIC, 50,humie)
		if(!LAZYLEN(candidates))
			return
		var/mob/dead/observer/C = pick(candidates)
		message_admins("[key_name_admin(C)] has taken control of ([key_name_admin(humie)]) to replace an AFK player.")
		humie.ghostize(0)
		humie.key = C.key

	ADD_TRAIT(humie,TRAIT_MUTE,MAGIC_TRAIT)
	log_game("[key_name_admin(humie)] has become a voiceless dead, their master is [user.real_name]")
	humie.revive(full_heal = TRUE, admin_revive = TRUE)
	humie.setMaxHealth(50)
	humie.health = 50 // Voiceless dead are much tougher than ghouls
	humie.become_husk()
	humie.faction |= "heretics"

	var/datum/antagonist/heretic_monster/heretic_monster = humie.mind.add_antag_datum(/datum/antagonist/heretic_monster)
	var/datum/antagonist/heretic/master = user.mind.has_antag_datum(/datum/antagonist/heretic)
	heretic_monster.set_owner(master)
	atoms -= humie
	RegisterSignal(humie,COMSIG_MOB_DEATH,.proc/remove_ghoul)
	ghouls += humie

/datum/eldritch_knowledge/flesh_ghoul/proc/remove_ghoul(datum/source)
	var/mob/living/carbon/human/humie = source
	ghouls -= humie
	humie.mind.remove_antag_datum(/datum/antagonist/heretic_monster)
	UnregisterSignal(source,COMSIG_MOB_DEATH)

/datum/eldritch_knowledge/flesh_grasp
	name = "Grasp of Flesh"
	gain_text = "My newfound desire, it drove me to do great things! To revoke the grasp of death! The Priest said."
	desc = "Empowers your mansus grasp to be able to create a single ghoul out of a dead person. Ghouls have only 25 HP and become husked."
	cost = 1
	next_knowledge = list(/datum/eldritch_knowledge/flesh_ghoul)
	var/ghoul_amt = 1
	var/list/spooky_scaries
	route = PATH_FLESH

/datum/eldritch_knowledge/flesh_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!ishuman(target) || target == user)
		return
	var/mob/living/carbon/human/human_target = target
	var/datum/status_effect/eldritch/eldritch_effect = human_target.has_status_effect(/datum/status_effect/eldritch/rust) || human_target.has_status_effect(/datum/status_effect/eldritch/ash) || human_target.has_status_effect(/datum/status_effect/eldritch/flesh)
	if(eldritch_effect)
		. = TRUE
		eldritch_effect.on_effect()
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			H.bleed_rate += 7

	if(QDELETED(human_target) || human_target.stat != DEAD)
		return

	human_target.grab_ghost()

	if(!human_target.mind || !human_target.client)
		to_chat(user, "<span class='warning'>There is no soul connected to this body...</span>")
		return

	if(HAS_TRAIT(human_target, TRAIT_HUSK))
		to_chat(user, "<span class='warning'>The body is too damaged to be revived this way!</span>")
		return

	if(HAS_TRAIT(human_target, TRAIT_MINDSHIELD))
		to_chat(user, "<span class='warning'>Their connection to this realm is too strong!</span>")
		return

	if(LAZYLEN(spooky_scaries) >= ghoul_amt)
		to_chat(user, "<span class='warning'>Your Patron cannot support more ghouls on this plane!</span>")
		return

	LAZYADD(spooky_scaries, human_target)
	log_game("[key_name_admin(human_target)] has become a ghoul, their master is [user.real_name]")
	//we change it to true only after we know they passed all the checks
	. = TRUE
	RegisterSignal(human_target,COMSIG_MOB_DEATH,.proc/remove_ghoul)
	human_target.revive(full_heal = TRUE, admin_revive = TRUE)
	human_target.setMaxHealth(25)
	human_target.health = 25
	human_target.become_husk()
	human_target.faction |= "heretics"
	var/datum/antagonist/heretic_monster/heretic_monster = human_target.mind.add_antag_datum(/datum/antagonist/heretic_monster)
	var/datum/antagonist/heretic/master = user.mind.has_antag_datum(/datum/antagonist/heretic)
	heretic_monster.set_owner(master)
	return


/datum/eldritch_knowledge/flesh_grasp/proc/remove_ghoul(datum/source)
	var/mob/living/carbon/human/humie = source
	spooky_scaries -= humie
	humie.mind.remove_antag_datum(/datum/antagonist/heretic_monster)
	UnregisterSignal(source, COMSIG_MOB_DEATH)

/datum/eldritch_knowledge/flesh_mark
	name = "Mark of flesh"
	gain_text = "I saw them, the Marked ones. The screams.. the silence."
	desc = "Your sickly blade now applies mark of flesh status effect. To activate the mark, use your mansus grasp on the marked. Mark of flesh when procced causeds additional bleeding."
	cost = 2
	next_knowledge = list(/datum/eldritch_knowledge/summon/raw_prophet)
	banned_knowledge = list(/datum/eldritch_knowledge/rust_mark,/datum/eldritch_knowledge/ash_mark)
	route = PATH_FLESH

/datum/eldritch_knowledge/flesh_mark/on_eldritch_blade(target,user,proximity_flag,click_parameters)
	. = ..()
	if(isliving(target))
		var/mob/living/living_target = target
		living_target.apply_status_effect(/datum/status_effect/eldritch/flesh)

/datum/eldritch_knowledge/flesh_blade_upgrade
	name = "Bleeding Steel"
	gain_text = "It rained blood, that's when I understood The Gravekeeper's advice."
	desc = "Your blade will now cause additional bleeding."
	cost = 2
	next_knowledge = list(/datum/eldritch_knowledge/summon/stalker)
	banned_knowledge = list(/datum/eldritch_knowledge/ash_blade_upgrade,/datum/eldritch_knowledge/rust_blade_upgrade)
	route = PATH_FLESH

/datum/eldritch_knowledge/flesh_blade_upgrade/on_eldritch_blade(target,user,proximity_flag,click_parameters)
	. = ..()
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		H.bleed_rate += 3

/datum/eldritch_knowledge/summon/raw_prophet
	name = "Raw Ritual"
	gain_text = "I saw the mirror-sheen in their dead eyes. It could be put to use."
	desc = "You can now summon a Raw Prophet by transmuting eyes, a left arm and a right arm. Raw prophets have a massive sight range, X-ray, and can sustain a telepathic network, but are very fragile and weak."
	cost = 1
	required_atoms = list(/obj/item/organ/eyes,/obj/item/bodypart/l_arm,/obj/item/bodypart/r_arm)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/raw_prophet
	next_knowledge = list(/datum/eldritch_knowledge/flesh_blade_upgrade,/datum/eldritch_knowledge/spell/blood_siphon,/datum/eldritch_knowledge/curse/paralysis)
	route = PATH_FLESH

/datum/eldritch_knowledge/summon/stalker
	name = "Lonely Ritual"
	gain_text = " The Uncanny Man walks lonely in the Valley, I called for his aid."
	desc = "You can now summon a Stalker by transmuting a knife, a candle, a pen and a piece of paper. Stalkers can shapeshift into harmeless animals and have access to an EMP."
	cost = 1
	required_atoms = list(/obj/item/kitchen/knife,/obj/item/candle,/obj/item/pen,/obj/item/paper)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/stalker
	next_knowledge = list(/datum/eldritch_knowledge/summon/ashy,/datum/eldritch_knowledge/summon/rusty,/datum/eldritch_knowledge/final/flesh_final)
	route = PATH_FLESH

/datum/eldritch_knowledge/summon/ashy
	name = "Ashen Ritual"
	gain_text = "I combined the principle of Hunger with a desire for Destruction. The Eyeful Lords took notice."
	desc = "You can now summon an Ash Man by transmutating a pile of ash, a head and a book. Ash Men have powerful offensive abilities and access to the Ash Passage spell."
	cost = 1
	required_atoms = list(/obj/effect/decal/cleanable/ash,/obj/item/bodypart/head,/obj/item/book)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/ash_spirit
	next_knowledge = list(/datum/eldritch_knowledge/summon/stalker,/datum/eldritch_knowledge/spell/flame_birth)

/datum/eldritch_knowledge/summon/rusty
	name = "Rusted Ritual"
	gain_text = "I combined the principle of Hunger with a desire of Corruption. The Rusted Hills call my name."
	desc = "You can now summon a Rust Walker transmutating vomit pool and a book. Rust Walkers are capable of spreading rust and have a decent but short ranged projectile attack."
	cost = 1
	required_atoms = list(/obj/effect/decal/cleanable/vomit,,/obj/item/book)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/rust_spirit
	next_knowledge = list(/datum/eldritch_knowledge/summon/stalker,/datum/eldritch_knowledge/spell/entropic_plume)

/datum/eldritch_knowledge/spell/blood_siphon
	name = "Blood Siphon"
	gain_text = "Our blood is one in the same, after all. The Owl told me."
	desc = "You gain a spell that drains enemies health and restores yours."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/targeted/touch/blood_siphon
	next_knowledge = list(/datum/eldritch_knowledge/summon/raw_prophet,/datum/eldritch_knowledge/spell/area_conversion)

/datum/eldritch_knowledge/final/flesh_final
	name = "Priest's Final Hymn"
	gain_text = "Men of the world; Hear me! For the time of the Lord of Arms has come!"
	desc = "Bring 3 bodies onto a transmutation rune to either ascend as the King of the Night or summon a Terror of the Night and triple your ghoul maximum."
	required_atoms = list(/mob/living/carbon/human)
	cost = 3
	route = PATH_FLESH

/datum/eldritch_knowledge/final/flesh_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	var/alert_ = alert(user,"Do you want to ascend as the Lord of the Night or empower yourself and summon a Terror of the Night?","...","Yes","No")
	user.SetImmobilized(10 HOURS) // no way someone will stand 10 hours in a spot, just so he can move while the alert is still showing.
	switch(alert_)
		if("No")
			var/mob/living/summoned = new /mob/living/simple_animal/hostile/eldritch/armsy(loc)
			message_admins("[summoned.name] is being summoned by [user.real_name] in [loc]")
			var/list/mob/dead/observer/candidates = pollCandidatesForMob("Do you want to play as a [summoned.real_name]", ROLE_HERETIC, null, ROLE_HERETIC, 100,summoned)
			user.SetImmobilized(0)
			if(LAZYLEN(candidates) == 0)
				to_chat(user,"<span class='warning'>No ghost could be found...</span>")
				qdel(summoned)
				return FALSE
			var/mob/living/carbon/human/H = user
			H.physiology.brute_mod *= 0.5
			H.physiology.burn_mod *= 0.5
			var/datum/antagonist/heretic/heretic = user.mind.has_antag_datum(/datum/antagonist/heretic)
			var/datum/eldritch_knowledge/flesh_grasp/ghoul1 = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
			ghoul1.ghoul_amt *= 3
			var/datum/eldritch_knowledge/flesh_ghoul/ghoul2 = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_ghoul)
			ghoul2.max_amt *= 3
			var/mob/dead/observer/ghost_candidate = pick(candidates)
			priority_announce("$^@&#*$^@(#&$(@&#^$&#^@# Fear the dark, for Vassal of Arms has ascended! The Terror of the Night has come! $^@&#*$^@(#&$(@&#^$&#^@#","#$^@&#*$^@(#&$(@&#^$&#^@#", 'sound/ai/spanomalies.ogg')
			log_game("[key_name_admin(ghost_candidate)] has taken control of ([key_name_admin(summoned)]).")
			summoned.ghostize(FALSE)
			summoned.key = ghost_candidate.key
			summoned.mind.add_antag_datum(/datum/antagonist/heretic_monster)
			var/datum/antagonist/heretic_monster/monster = summoned.mind.has_antag_datum(/datum/antagonist/heretic_monster)
			var/datum/antagonist/heretic/master = user.mind.has_antag_datum(/datum/antagonist/heretic)
			monster.set_owner(master)
			master.ascended = TRUE
		if("Yes")
			var/mob/living/summoned = new /mob/living/simple_animal/hostile/eldritch/armsy/prime(loc,TRUE,10)
			summoned.ghostize(0)
			user.SetImmobilized(0)
			for(var/obj/effect/proc_holder/spell/S in user.mind.spell_list)
				if(istype(S, /obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash)) //vitally important since ashen passage breaks the shit out of armsy
					user.mind.spell_list.Remove(S)
					qdel(S)
			priority_announce("$^@&#*$^@(#&$(@&#^$&#^@# Fear the dark, for King of Arms has ascended! Our Lord of the Night has come! $^@&#*$^@(#&$(@&#^$&#^@#","#$^@&#*$^@(#&$(@&#^$&#^@#", 'sound/ai/spanomalies.ogg')
			log_game("[user.real_name] ascended as [summoned.real_name]")
			var/mob/living/carbon/carbon_user = user
			var/datum/antagonist/heretic/ascension = carbon_user.mind.has_antag_datum(/datum/antagonist/heretic)
			ascension.ascended = TRUE
			carbon_user.mind.transfer_to(summoned, TRUE)
			carbon_user.gib()

	return ..()
