#pragma header

uniform float amount;

void main() {
    vec2 uv = openfl_TextureCoordv;
    vec2 res = 1.0 / openfl_TextureSize;
    float spread = amount;

    vec4 col = texture2D(bitmap, uv);
    col += texture2D(bitmap, uv + vec2(spread, 0.0) * res);
    col += texture2D(bitmap, uv + vec2(-spread, 0.0) * res);
    col += texture2D(bitmap, uv + vec2(0.0, spread) * res);
    col += texture2D(bitmap, uv + vec2(0.0, -spread) * res);
    col += texture2D(bitmap, uv + vec2(spread, spread) * res);
    col += texture2D(bitmap, uv + vec2(-spread, -spread) * res);
    col += texture2D(bitmap, uv + vec2(spread, -spread) * res);
    col += texture2D(bitmap, uv + vec2(-spread, spread) * res);

    gl_FragColor = col / 9.0;
}