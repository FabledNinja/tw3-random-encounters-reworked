
// this manager class doesn't do much actually, it's more of a namespace for functions
// about the ecosystem feature.
class RER_EcosystemManager {
  var master: CRandomEncounters;
  var ecosystem_analyser: RER_EcosystemAnalyzer;
  var ecosystem_modifier: RER_EcosystemModifier;

  public function init(master: CRandomEncounters) {
    this.master = master;
    
    this.ecosystem_analyser = new RER_EcosystemAnalyzer in this;
    this.ecosystem_analyser.init(this);

    this.ecosystem_modifier = new RER_EcosystemModifier in this;
    this.ecosystem_modifier.init(this);
  }

  // returns the EcosystemAreas the player is currently in.
  // EcosystemAreas can overlap and so it returns an array
  //
  // NOTE: it returns the indices of the EcosystemAreas because they're structs
  // and returning a struct makes a copy of it and not a reference. Which means
  // if you edit the returned struct the original isn't and you'd need to find it
  // with its index so it's better to just return an index.
  public function getCurrentEcosystemAreas(): array<int> {
    var player_position: Vector;
    var current_area: EcosystemArea;
    var output: array<int>;
    var i: int;

    LogChannel('RER', "getCurrentEcosystemAreas, current areas count: " + this.master.storages.ecosystem.ecosystem_areas.Size());

    player_position = thePlayer.GetWorldPosition();
    for (i = 0; i < this.master.storages.ecosystem.ecosystem_areas.Size(); i += 1) {
      current_area = this.master.storages.ecosystem.ecosystem_areas[i];

      // check if the player in is the radius
      if (VecDistanceSquared(player_position, current_area.position) < current_area.radius * current_area.radius) {
        output.PushBack(i);
      }
    }

    LogChannel('RER', "getCurrentEcosystemAreas, found " + output.Size() + " areas");

    return output;
  }

  public function getCreatureModifiersForEcosystemAreas(areas: array<int>): array<float> {
    var output: array<float>;
    var current_index: int;
    var current_area: EcosystemArea;
    var current_power: float;
    var current_impact: EcosystemCreatureImpact;
    var i, j, k: int;

    // first we fill the array with 0 for each creature type
    for (i = 0; i < CreatureMAX; i += 1) {
      output.PushBack(0);
    }

    // now for each area
    for (i = 0; i < areas.Size(); i += 1) {
      current_index = areas[i];
      current_area = this.master.storages.ecosystem.ecosystem_areas[current_index];

      for (j = 0; j < CreatureMAX; j += 1) {
        current_power = current_area.impacts_power_by_creature_type[j];

        // when power is at 0 we can skip it as it won't change anything
        if (current_power == 0) {
          continue;
        }

        LogChannel('RER', "current area, creature power = " + (CreatureType)j + " - " + current_power);

        // note that here, J is also an int that can be used as a CreatureType
        current_impact = this.master.bestiary.entries[j].ecosystem_impact;

        // now we loop through each influence and add them to the output
        // the influence is multiplied by the power of the current CreatureType
        for (k = 0; k < current_impact.influences.Size(); k += 1) {
          output[k] += current_power * current_impact.influences[k];
        }
      }
    }

    // here we now have a list of the influenced spawn rates for each CreatureType.
    // the influenced spawn rate is a float value that tells by how much the creature's
    // spawn rate should be multiplied. It can be positive or negative.
    return output;
  }

  public function udpateCountersWithCreatureModifiers(out counters: array<int>, modifiers: array<float>) {
    var i: int;

    if (counters.Size() != modifiers.Size()) {
      LogChannel('RER', "attempt at updating counters with creature modifiers, but counters and modifiers are not of the same size");

      return;
    }

    for (i = 0; i < counters.Size(); i += 1) {
      LogChannel('RER', "udpateCountersWithCreatureModifiers, before = " + counters[i]);
      LogChannel('RER', "udpateCountersWithCreatureModifiers, creature = " + (CreatureType)i + " modifier = " + modifiers[i]);

      // here, it's an added value `+=` and not a `=` so if the modifiers is at
      // 0 it won't change the value rather than setting it at 0.
      // See modifiers as an % increase/decrease.
      counters[i] += (int)((float)counters[i] * modifiers[i] * this.master.settings.ecosystem_community_power_effect);

      LogChannel('RER', "udpateCountersWithCreatureModifiers, after = " + counters[i]);
    }
  }

  // this function fetches the current ecosystem areas the player is in, then
  // updates the power for the supplied creature by additioning the supplied
  // `power_change` value to the current `power` value of the creature in the
  // current areas.
  //
  // If there are no EcosystemArea around the player this function creates a new
  // one at the exact position of the player.
  //
  // If there are multiple EcosystemAreas around the player this function updates
  // the power values based on the distances.
  //
  // No matter the count of EcosystemAreas around the player it updates the power
  // value by calculating the % distance from the center of the area to its extremity.
  //
  // NOTE: the function saves the ecosystem storage after the operation.
  public function updatePowerForCreatureInCurrentEcosystemAreas(creature: CreatureType, power_change: float, position: Vector) {
    var ecosystem_areas: array<int>;
    var current_ecosystem_area: EcosystemArea;
    var current_index: int;
    var distance_from_center: float;
    var i: int;

    LogChannel('RER', "power change for " + creature + " = " + power_change);
    ecosystem_areas = this.getCurrentEcosystemAreas();

    if (ecosystem_areas.Size() == 0) {
      LogChannel('RER', "no ecosystem area found, creating one");
      current_ecosystem_area = getNewEcosystemArea(
        position,
        // this is the default radius, it uses the distance settings
        this.master.settings.minimum_spawn_distance + this.master.settings.spawn_diameter
      );

      this.master
        .storages
        .ecosystem
        .ecosystem_areas
        .PushBack(current_ecosystem_area);

      ecosystem_areas.PushBack(0);
    }

    for (i = 0; i < ecosystem_areas.Size(); i += 1) {
      current_index = ecosystem_areas[i];
      current_ecosystem_area = this.master.storages.ecosystem.ecosystem_areas[current_index];
      
      // at the moment it's just the raw squared distance
      distance_from_center = VecDistanceSquared(
        current_ecosystem_area.position,
        position
      );

      // now it's a percentage value going from 0 to 1
      distance_from_center = distance_from_center / (current_ecosystem_area.radius * current_ecosystem_area.radius);

      // minimum power change is 20%,
      distance_from_center = MinF(distance_from_center, 0.2);

      LogChannel('RER', "ecosystem power change for " + creature + " distance from center = " + distance_from_center);
      LogChannel('RER', "ecosystem power change for " + creature + " = " + power_change * (1 - distance_from_center));

      this.master
        .storages
        .ecosystem
        .ecosystem_areas[current_index]
        .impacts_power_by_creature_type[creature] += power_change
          * (1 - distance_from_center)

          // this is to make changes more impactful on minorities and large communities
          // the power change is multiplied by the power of the community.
          * (1 +
            AbsF(this.master
            .storages
            .ecosystem
            .ecosystem_areas[current_index]
            // 2.5% for every power
            // Let's imagine a case where 5 drowners spawn. 5 drowners mean +5 power
            // the next time drowners spawn instead of adding +5 it will be +6.5 or something
            .impacts_power_by_creature_type[creature] * 0.025)
          );
    }

    this.ecosystem_modifier
        .executePowerSpreadAndNaturalDeath(ecosystem_areas);

    // we now save the storage to store the power change.
    this.master
      .storages
      .ecosystem
      .save();
  }

  // returns a new empty ecosystem area with all default values initiliased
  public function getNewEcosystemArea(position: Vector, radius: float): EcosystemArea {
    var area: EcosystemArea;
    var i: int;

    for (i = 0; i < CreatureMAX; i += 1) {
      area.impacts_power_by_creature_type.PushBack(0);
    }

    area.position = position;
    area.radius = radius;

    return area;
  }

  // returns which other creatures influenced the surrounding ecosystem and helped
  // the community with the supplied type form.
  // 
  public function getCommunityReasonsToExist(creature_type: CreatureType): array<CreatureType> {
    var current_bestiary_entry: RER_BestiaryEntry;
    var influences: RER_ConstantInfluences;
    var output: array<CreatureType>;
    var i: int;

    influences = RER_ConstantInfluences();

    // we search for all creature who are either friend_with, low_indirect_influence
    // or high_indirect_influence towards wolves.
    // we do it in three steps to create a sorted array
    for (i = 0; i < CreatureMAX; i += 1) {
      current_bestiary_entry = this.master.bestiary.entries[i];

      if (current_bestiary_entry.ecosystem_impact.influences[creature_type] == influences.friend_with) {
        output.PushBack(i);
      }
    }

    for (i = 0; i < CreatureMAX; i += 1) {
      current_bestiary_entry = this.master.bestiary.entries[i];

      if (current_bestiary_entry.ecosystem_impact.influences[creature_type] == influences.high_indirect_influence) {
        output.PushBack(i);
      }
    }

    for (i = 0; i < CreatureMAX; i += 1) {
      current_bestiary_entry = this.master.bestiary.entries[i];

      if (current_bestiary_entry.ecosystem_impact.influences[creature_type] == influences.low_indirect_influence) {
        output.PushBack(i);
      }
    }

    return output;
  }

  // returns which other creatures influenced the surrounding ecosystem and stopped
  // the community with the supplied type from forming.
  // 
  public function getCommunityReasonsToNotExist(creature_type: CreatureType): array<CreatureType> {
    var current_bestiary_entry: RER_BestiaryEntry;
    var influences: RER_ConstantInfluences;
    var output: array<CreatureType>;
    var i: int;

    influences = RER_ConstantInfluences();

    // we search for all creature who are either kills_them, low_bad_influence
    // or high_bad_influence towards wolves.
    // we do it in three steps to create a sorted array
    for (i = 0; i < CreatureMAX; i += 1) {
      current_bestiary_entry = this.master.bestiary.entries[i];

      if (current_bestiary_entry.ecosystem_impact.influences[creature_type] == influences.friend_with) {
        output.PushBack(i);
      }
    }

    for (i = 0; i < CreatureMAX; i += 1) {
      current_bestiary_entry = this.master.bestiary.entries[i];

      if (current_bestiary_entry.ecosystem_impact.influences[creature_type] == influences.high_indirect_influence) {
        output.PushBack(i);
      }
    }

    for (i = 0; i < CreatureMAX; i += 1) {
      current_bestiary_entry = this.master.bestiary.entries[i];

      if (current_bestiary_entry.ecosystem_impact.influences[creature_type] == influences.low_indirect_influence) {
        output.PushBack(i);
      }
    }

    return output;
  }

  // returns communities who are influenced in a good way by the supplied creature type
  public function getCommunityGoodInfluences(creature_type: CreatureType): array<CreatureType> {
    var influences: RER_ConstantInfluences;
    var output: array<CreatureType>;
    var current_influence: float;
    var current_type: int;

    influences = RER_ConstantInfluences();

    // we search for all creatures whose wolves are either
    // friend_with, low_indirect_influence or high_indirect_influence towards them.
    // we do it in three steps to create a sorted array
    for (current_type = 0; current_type < CreatureMAX; current_type += 1) {
      current_influence = this.master.bestiary.entries[creature_type]
        .ecosystem_impact
        .influences[current_type];

      if (current_influence == influences.friend_with) {
        output.PushBack(current_type);
      }
    }

    for (current_type = 0; current_type < CreatureMAX; current_type += 1) {
      current_influence = this.master.bestiary.entries[creature_type]
        .ecosystem_impact
        .influences[current_type];

      if (current_influence == influences.high_indirect_influence) {
        output.PushBack(current_type);
      }
    }

    for (current_type = 0; current_type < CreatureMAX; current_type += 1) {
      current_influence = this.master.bestiary.entries[creature_type]
        .ecosystem_impact
        .influences[current_type];

      if (current_influence == influences.low_indirect_influence) {
        output.PushBack(current_type);
      }
    }

    return output;
  }

  // returns communities who are influenced in a bad way by the supplied creature type
  public function getCommunityBadInfluences(creature_type: CreatureType): array<CreatureType> {
    var influences: RER_ConstantInfluences;
    var output: array<CreatureType>;
    var current_influence: float;
    var current_type: int;

    influences = RER_ConstantInfluences();

    // we search for all creatures whose wolves are either
    // kills_them, low_bad_influence or high_bad_influence towards them.
    // we do it in three steps to create a sorted array
    for (current_type = 0; current_type < CreatureMAX; current_type += 1) {
      current_influence = this.master.bestiary.entries[creature_type]
        .ecosystem_impact
        .influences[current_type];

      if (current_influence == influences.kills_them) {
        output.PushBack(current_type);
      }
    }

    for (current_type = 0; current_type < CreatureMAX; current_type += 1) {
      current_influence = this.master.bestiary.entries[creature_type]
        .ecosystem_impact
        .influences[current_type];

      if (current_influence == influences.high_bad_influence) {
        output.PushBack(current_type);
      }
    }

    for (current_type = 0; current_type < CreatureMAX; current_type += 1) {
      current_influence = this.master.bestiary.entries[creature_type]
        .ecosystem_impact
        .influences[current_type];

      if (current_influence == influences.low_bad_influence) {
        output.PushBack(current_type);
      }
    }

    return output;
  }

}