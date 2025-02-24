
// return true in cases where the player is busy in a cutscene or in the boat.
// When a spawn should be cancelled.
function isPlayerBusy(): bool {
  return thePlayer.IsInInterior()
      || thePlayer.IsInCombat()
      || thePlayer.IsUsingBoat()
      || thePlayer.IsSwimming()
      || !thePlayer.IsActionAllowed(EIAB_DrawWeapon)
      || isPlayerInScene();
}

function isPlayerInScene(): bool {
  return thePlayer.IsInNonGameplayCutscene()
      || thePlayer.IsInGameplayScene()
      || thePlayer.IsCiri()
      || theGame.IsDialogOrCutscenePlaying()
      || theGame.IsCurrentlyPlayingNonGameplayScene()
      || theGame.IsFading()
      || theGame.IsBlackscreen()
      || thePlayer.IsInFistFightMiniGame();
}