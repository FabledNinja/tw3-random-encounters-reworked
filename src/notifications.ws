
function displayRandomEncounterEnabledNotification() {
  theGame
  .GetGuiManager()
  .ShowNotification(
    GetLocStringByKey("option_rer_enabled")
  );
}

function displayRandomEncounterDisabledNotification() {
  theGame
  .GetGuiManager()
  .ShowNotification(
    GetLocStringByKey("option_rer_disabled")
  );
}

function NDEBUG(message: string, optional duration: float) {
  theGame
  .GetGuiManager()
  .ShowNotification(message, duration);
}

function NLOG(message: string) {
  LogChannel('RER', message);
}