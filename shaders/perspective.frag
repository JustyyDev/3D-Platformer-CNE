#pragma header

uniform float skew;
uniform float depth;
uniform float tilt;

void main() {
    vec2 uv = openfl_TextureCoordv;

    float pY = uv.y - 0.5;
    float perspective = 1.0 + pY * tilt;
    
    vec2 pUv = uv;
    pUv.x = 0.5 + (pUv.x - 0.5) / perspective;

    float skewFactor = 1.0 - uv.y * skew;
    pUv.x = (pUv.x - 0.5) / skewFactor + 0.5;

    if (pUv.x < 0.0 || pUv.x > 1.0 || pUv.y < 0.0 || pUv.y > 1.0) {
        discard;
    }

    vec4 color = flixel_texture2D(bitmap, pUv);

    float shade = 1.0 - uv.y * depth * 0.3;
    color.rgb *= shade;

    float fogAmount = smoothstep(0.0, 1.0, uv.y) * depth * 0.15;
    vec3 fogColor = vec3(0.02, 0.01, 0.06);
    color.rgb = mix(color.rgb, fogColor, fogAmount);

    gl_FragColor = color;
}