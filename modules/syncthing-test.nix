_:

{
  # Test folder for Silverlining app development. Synced only between
  # saffron (laptop) and the test Android phone. Not shared with main
  # devices or the 0everything sync.
  services.syncthing.settings.folders."~/0workspace/silverbullet_app/0testsilverlining" = {
    id = "0testsilverlining";
    devices = [
      "test-phone"
    ];
  };
}
