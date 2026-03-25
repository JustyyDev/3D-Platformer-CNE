import funkin.backend.shaders.CustomShader;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

var transitionShader:CustomShader;
var transitionSprite:FlxSprite;

function create(event) {
    var isOut:Bool = event.transOut;
    event.cancel();

    var maxRadius:Float = Math.sqrt(FlxG.width * FlxG.width + FlxG.height * FlxG.height);

    transitionShader = new CustomShader("circular");
    transitionShader.screenCenter = [FlxG.width / 2, FlxG.height / 2];

    var startRad:Float = isOut ? maxRadius : 0;
    var endRad:Float = isOut ? 0 : maxRadius;
    transitionShader.radius = startRad;

    transitionSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
    transitionSprite.shader = transitionShader;
    transitionSprite.scrollFactor.set();
    
    if (event.camera != null) {
        transitionSprite.cameras = [event.camera];
    } else {
        transitionSprite.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    }
    
    add(transitionSprite);

    FlxTween.num(startRad, endRad, 0.6, {
        ease: FlxEase.quadInOut,
        onUpdate: function(twn) {
            transitionShader.radius = twn.value;
        },
        onComplete: function(_) {
            finish();
        }
    });
}