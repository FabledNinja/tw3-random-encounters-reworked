
state Combat in RandomEncountersReworkedHuntEntity {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);

    LogChannel('modRandomEncounters', "Hunt - State Combat");

    this.Combat_Main();
  }

  entry function Combat_Main() {
    // to know if it's an ambush
    // if true, will play a oneliner and a camera scene
    // the camera scene plays only if player is not busy and doesn't have camera scenes disabled from menu
    if (parent.bait_moves_towards_player) {
      RER_tutorialTryShowAmbushed();
      this.startAmbushCutscene();
    }

    this.resetEntitiesAttitudes();
    this.makeEntitiesTargetPlayer();
    this.waitUntilPlayerFinishesCombat();

    if (parent.entity_settings.allow_trophy_pickup_scene) {
      parent
        .master
        .requestOutOfCombatAction(OutOfCombatRequest_TROPHY_CUTSCENE);
    }

    this.Combat_goToNextState();
  }

  private latent function startAmbushCutscene() {
    if (isPlayerBusy()) {
      return;
    }

    if (parent.master.settings.geralt_comments_enabled) {
      thePlayer.PlayVoiceset( 90, "BattleCryBadSituation" );
    }

    if(!parent.master.settings.disable_camera_scenes
    && parent.master.settings.enable_action_camera_scenes) {
      playAmbushCameraScene();
    }
  }

  private latent function playAmbushCameraScene() {
    var scene: RER_CameraScene;
    var camera: RER_StaticCamera;
    var look_at_position: Vector;

    // where the camera is placed
    scene.position_type = RER_CameraPositionType_ABSOLUTE;
    scene.position = theCamera.GetCameraPosition() + Vector(0, 0, 1);

    // where the camera is looking
    scene.look_at_target_type = RER_CameraTargetType_STATIC;
    look_at_position = parent.getRandomEntity().GetWorldPosition();
    scene.look_at_target_static = look_at_position + Vector(0, 0, 0);

    scene.velocity_type = RER_CameraVelocityType_FORWARD;
    scene.velocity = Vector(0.001, 0.001, 0);

    scene.duration = 0.2;
    scene.position_blending_ratio = 0.05;
    scene.rotation_blending_ratio = 0.05;

    camera = RER_getStaticCamera();

    camera.playCameraScene(scene, true);
  }

  private latent function resetEntitiesAttitudes() {
    var i: int;

    for (i = 0; i < parent.entities.Size(); i += 1) {
      ((CActor)parent.entities[i])
        .ResetTemporaryAttitudeGroup(AGP_Default);
    }
  }

  private latent function makeEntitiesTargetPlayer() {
    var i: int;

    for (i = 0; i < parent.entities.Size(); i += 1) {
      // ((CActor)parent.entities[i]).SetTemporaryAttitudeGroup(
      //   'monsters',
      //   AGP_Default
      // );

      if (((CActor)parent.entities[i]).GetTarget() != thePlayer && !((CActor)parent.entities[i]).HasAttitudeTowards(thePlayer)) {
        ((CNewNPC)parent.entities[i]).NoticeActor(thePlayer);
        ((CActor)parent.entities[i]).SetAttitude(thePlayer, AIA_Hostile);
      }
    }
  }

  latent function waitUntilPlayerFinishesCombat() {
    // sleep a bit before entering the loop, to avoid a really fast loop if the
    // player runs away from the monster
    Sleep(3);

    while (!parent.areAllEntitiesDead() && !SUH_areAllEntitiesFarFromPlayer(parent.entities)) {
      this.makeEntitiesTargetPlayer();
      parent.removeDeadEntities();
      RER_moveCreaturesAwayIfPlayerIsInCutscene(parent.entities, 20);

      Sleep(1);
    }
  }

  latent function Combat_goToNextState() {
    if (parent.areAllEntitiesDead()) {
      parent.GotoState('Ending');
    }
    else {
      parent.GotoState('Wandering');
    }
  }
}
