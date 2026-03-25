function new() {
    // Set the default value if the player hasn't touched the options yet
    if(FlxG.save.data.flappyFont == null) {
        FlxG.save.data.flappyFont = "vcr.ttf";
    }
}