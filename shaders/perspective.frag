#pragma header

uniform float skew; // How much it tilts
uniform float depth; // Perspective depth

void main() {
    vec2 uv = openfl_TextureCoordv;
    
    // Warp the coordinates to create a 3D perspective tilt
    uv.x = (uv.x - 0.5) / (1.0 - uv.y * skew) + 0.5;
    
    vec4 color = texture2D(bitmap, uv);
    
    // Optional: Slight darkening as things get "further away" (higher Y)
    color.rgb *= (1.0 - uv.y * 0.2);
    
    // Ensure we don't draw outside the warped UVs
    if (uv.x < 0.0 || uv.x > 1.0) discard;
    
    gl_FragColor = color;
}