
statemachine class RER_MonsterNest extends CMonsterNestEntity {
  var master: CRandomEncounters;
  var entities: array<CEntity>;

  var entity_settings: ContractEntitySettings;

  var is_destroyed: bool;

  var bestiary_entry: RER_BestiaryEntry;

  /**
   * counts how many monsters were spawned by this nest
   */
  var monsters_spawned_count: int;

  /**
   * defines when newly spawned monsters should no longer drop loot.
   * The number set corresponds to the number of monsters that were spawned
   * before.
   */
  var disable_monsters_loot_threshold: int;
  default disable_monsters_loot_threshold = 10;

  /**
   * controls how many monsters the nest can spawn in total.
   */
  var monsters_spawned_limit: int;
  default monsters_spawned_limit = 15;

  var pin_position: Vector;

  function startEncounter(master: CRandomEncounters) {
    this.master = master;
    this.loadSettings(master);

    this.GotoState('Loading');

    this.AddTimer('intervalLifeCheck', 10.0, true);
  }

  private function loadSettings(master: CRandomEncounters) {
    this.entity_settings.kill_threshold_distance = master.settings.kill_threshold_distance;
    this.entity_settings.allow_trophy_pickup_scene = master.settings.trophy_pickup_scene;
    
    this.entity_settings.allow_trophies = master
      .settings
      .trophies_enabled_by_encounter[EncounterType_CONTRACT];
    
    this.entity_settings.enable_loot = master
      .settings
      .enable_encounters_loot;

    this.disable_monsters_loot_threshold = 5;

    if (master.settings.selectedDifficulty == RER_Difficulty_RANDOM) {
      this.monsters_spawned_limit = RandRange(
        ((int)RER_Difficulty_HARD + 1) * 4,
        ((int)RER_Difficulty_EASY + 1) * 4
      );
    }
    else {
      this.monsters_spawned_limit = RandRange(
        ((int)master.settings.selectedDifficulty + 1) * 4,
        ((int)master.settings.selectedDifficulty + 1) * 3,
      );
    }
  }

  event OnSpawned(spawnData: SEntitySpawnData) {}

  event OnAreaEnter(area: CTriggerAreaComponent, activator: CComponent) {
    if (area != (CTriggerAreaComponent)this.GetComponent("VoiceSetTrigger")
     || !this.CanPlayVoiceSet()
     || this.voicesetPlayed) {
       return false;
    }

    this.l_enginetime = theGame.GetEngineTimeAsSeconds();

    // the player did not talk in the last 60 seconds
    if (l_enginetime > this.voicesetTime + 60.0f) {
      this.voicesetTime = this.l_enginetime;
      this.voicesetPlayed = true;
      this.GotoState('Talking');
    }
    // he did, so we directly go to the spawning state
    else if (GetCurrentStateName() != 'Spawning') {
      this.GotoState('Spawning');
    }

    SUH_makeEntitiesTargetPlayer(this.entities);
  }

  event OnFireHit(source: CGameplayEntity) {
    if (source != thePlayer || wasExploded) {
      return false;
    }

    if (this.monsters_spawned_count > this.monsters_spawned_limit * 0.75) {
      GetEncounter();

      wasExploded = true;
      airDmg = false;

      this.GotoState('Explosion');
    }
  }
  event OnAardHit(sign: W3AardProjectile) {}
	
  event OnInteraction(actionName: string, activator: CEntity) {
    if (activator != thePlayer || !thePlayer.CanPerformPlayerAction()) {
			return false;
		}
	
		if(interactionComponent && wasExploded && interactionComponent.IsEnabled()) {
			interactionComponent.SetEnabled(false);
		}

    if (!PlayerHasBombActivator()) {
      GetWitcherPlayer().DisplayHudMessage( GetLocStringByKeyExt( "panel_hud_message_destroy_nest_bomb_lacking" ) );
			messageTimestamp = theGame.GetEngineTimeAsSeconds();

      return false;
    }

    if(interactionComponent && interactionComponent.IsEnabled()) {
      wasExploded = true;
      GetEncounter();
      interactionComponent.SetEnabled(false);
      
      GotoState('SettingExplosives');
    }

    return true;
  }

  latent function getRandomNestCreatureType(master: CRandomEncounters): RER_BestiaryEntry {
    var bentry: RER_BestiaryEntry;

    bentry = master.bestiary.getRandomEntryFromBestiary(
      master,
      EncounterType_CONTRACT,
      RER_BREF_IGNORE_SETTLEMENT,
      (new RER_SpawnRollerFilter in this)
        .init()
        .removeEveryone()
        .allowCreature(CreatureARACHAS)
        .allowCreature(CreatureENDREGA)
        .allowCreature(CreatureGHOUL)
        .allowCreature(CreatureALGHOUL)
        .allowCreature(CreatureNEKKER)
        .allowCreature(CreatureDROWNER)
        .allowCreature(CreatureROTFIEND)
        .allowCreature(CreatureWOLF)
        .allowCreature(CreatureHARPY)
        .allowCreature(CreatureSPIDER)
        .allowCreature(CreatureCENTIPEDE)
        .allowCreature(CreatureDROWNERDLC)
        .allowCreature(CreatureBOAR)
        .allowCreature(CreatureECHINOPS)
        .allowCreature(CreatureKIKIMORE)
        .allowCreature(CreatureSKELWOLF)
        .allowCreature(CreatureSIREN)
        .allowCreature(CreatureWRAITH)
    );

    return bentry;
  }

  timer function intervalLifeCheck(optional dt : float, optional id : Int32) {
    var distance_from_player: float;

    if (this.GetCurrentStateName() == 'Ending') {
      return;
    }

    distance_from_player = VecDistance(
      this.GetWorldPosition(),
      thePlayer.GetWorldPosition()
    );

    if (distance_from_player > this.entity_settings.kill_threshold_distance) {
      LogChannel('modRandomEncounters', "killing entity - threshold distance reached: " + this.entity_settings.kill_threshold_distance);
      this.endEncounter();

      return;
    }
  }

  public function endEncounter() {
    if (this.GetCurrentStateName() != 'Ending') {
      this.GotoState('Ending');
    }
  }

  public latent function clean() {
    var i: int;

    NLOG("RER_MonsterNest destroyed");

    this.RemoveTimer('intervalLifeCheck');

    for (i = 0; i < this.entities.Size(); i += 1) {
      ((CActor)this.entities[i])
        .Kill('RandomEncountersReworkedContractEntity', true);
    }

    this.Destroy();
  }
}
