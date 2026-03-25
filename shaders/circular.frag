#pragma header

uniform float radius;
uniform vec2 screenCenter;

void main() {
    vec2 uv = openfl_TextureCoordv;
    vec2 fragCoord = uv * openfl_TextureSize;
    
    if (distance(fragCoord, screenCenter) < radius) {
        discard;
    }

    gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
}