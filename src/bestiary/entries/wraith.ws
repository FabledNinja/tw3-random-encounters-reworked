
class RER_BestiaryWraith extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();

    this.type = CreatureWRAITH;
    this.menu_name = 'Wraiths';
    this.localized_name = 'option_rer_wraith';

    

  this.template_list.templates.PushBack(
    makeEnemyTemplate(
      "characters\npc_entities\monsters\wraith_lvl1.w2ent",,,
      "gameplay\journal\bestiary\wraith.journal"
    )
  );
  this.template_list.templates.PushBack(
    makeEnemyTemplate(
      "characters\npc_entities\monsters\wraith_lvl2.w2ent",,,
      "gameplay\journal\bestiary\wraith.journal"
    )
  );
  this.template_list.templates.PushBack(
    makeEnemyTemplate(
      "characters\npc_entities\monsters\wraith_lvl2_customize.w2ent",,,
      "gameplay\journal\bestiary\wraith.journal"
    )
  );
  this.template_list.templates.PushBack(
    makeEnemyTemplate(
      "characters\npc_entities\monsters\wraith_lvl3.w2ent",,,
      "gameplay\journal\bestiary\wraith.journal"
    )
  );
  this.template_list.templates.PushBack(
    makeEnemyTemplate(
      "characters\npc_entities\monsters\wraith_lvl4.w2ent", 2,,
      "gameplay\journal\bestiary\wraith.journal"
    )
  );

    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 2;
    this.template_list.difficulty_factor.minimum_count_medium = 2;
    this.template_list.difficulty_factor.maximum_count_medium = 3;
    this.template_list.difficulty_factor.minimum_count_hard = 3;
    this.template_list.difficulty_factor.maximum_count_hard = 4;

  

    this.trophy_names.PushBack('modrer_wraith_trophy_low');
    this.trophy_names.PushBack('modrer_wraith_trophy_medium');
    this.trophy_names.PushBack('modrer_wraith_trophy_high');

    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer)
      .influence(influences.kills_them) //CreatureHUMAN
      .influence(influences.no_influence) //CreatureARACHAS
      .influence(influences.no_influence) //CreatureENDREGA
      .influence(influences.no_influence) //CreatureGHOUL
      .influence(influences.no_influence) //CreatureALGHOUL
      .influence(influences.no_influence) //CreatureNEKKER
      .influence(influences.no_influence) //CreatureDROWNER
      .influence(influences.no_influence) //CreatureROTFIEND
      .influence(influences.no_influence) //CreatureWOLF
      .influence(influences.self_influence) //CreatureWRAITH
      .influence(influences.no_influence) //CreatureHARPY
      .influence(influences.no_influence) //CreatureSPIDER
      .influence(influences.no_influence) //CreatureCENTIPEDE
      .influence(influences.no_influence) //CreatureDROWNERDLC
      .influence(influences.no_influence) //CreatureBOAR
      .influence(influences.no_influence) //CreatureBEAR
      .influence(influences.no_influence) //CreaturePANTHER
      .influence(influences.friend_with) //CreatureSKELETON
      .influence(influences.no_influence) //CreatureECHINOPS
      .influence(influences.no_influence) //CreatureKIKIMORE
      .influence(influences.friend_with) //CreatureBARGHEST
      .influence(influences.no_influence) //CreatureSKELWOLF
      .influence(influences.no_influence) //CreatureSKELBEAR
      .influence(influences.friend_with) //CreatureWILDHUNT
      .influence(influences.no_influence) //CreatureBERSERKER
      .influence(influences.no_influence) //CreatureSIREN

      // large creatures below
      .influence(influences.no_influence) //CreatureDRACOLIZARD
      .influence(influences.no_influence) //CreatureGARGOYLE
      .influence(influences.no_influence) //CreatureLESHEN
      .influence(influences.no_influence) //CreatureWEREWOLF
      .influence(influences.no_influence) //CreatureFIEND
      .influence(influences.no_influence) //CreatureEKIMMARA
      .influence(influences.no_influence) //CreatureKATAKAN
      .influence(influences.no_influence) //CreatureGOLEM
      .influence(influences.no_influence) //CreatureELEMENTAL
      .influence(influences.friend_with) //CreatureNIGHTWRAITH
      .influence(influences.friend_with) //CreatureNOONWRAITH
      .influence(influences.no_influence) //CreatureCHORT
      .influence(influences.no_influence) //CreatureCYCLOP
      .influence(influences.no_influence) //CreatureTROLL
      .influence(influences.no_influence) //CreatureHAG
      .influence(influences.no_influence) //CreatureFOGLET
      .influence(influences.no_influence) //CreatureBRUXA
      .influence(influences.no_influence) //CreatureFLEDER
      .influence(influences.no_influence) //CreatureGARKAIN
      .influence(influences.no_influence) //CreatureDETLAFF
      .influence(influences.no_influence) //CreatureGIANT
      .influence(influences.no_influence) //CreatureSHARLEY
      .influence(influences.no_influence) //CreatureWIGHT
      .influence(influences.no_influence) //CreatureGRYPHON
      .influence(influences.no_influence) //CreatureCOCKATRICE
      .influence(influences.no_influence) //CreatureBASILISK
      .influence(influences.no_influence) //CreatureWYVERN
      .influence(influences.no_influence) //CreatureFORKTAIL
      .influence(influences.no_influence) //CreatureSKELTROLL
      .build();
  }

  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences{
    return super.setCreaturePreferences(preferences, encounter_type);
  }
}
