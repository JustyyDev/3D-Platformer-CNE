#pragma header

uniform float curve; 
uniform float zoom;

void main() {
    vec2 uv = openfl_TextureCoordv;
    vec2 center = vec2(0.5, 0.5);
    
    vec2 offset = uv - center;
    float r = length(offset);
    
    // Spherical Lens / Globe effect
    // Bulges the center towards you, curves the edges away
    float bulge = 1.0 + r * r * curve;
    vec2 warpedUV = center + (offset * bulge) / zoom;
    
    if (warpedUV.x < 0.0 || warpedUV.x > 1.0 || warpedUV.y < 0.0 || warpedUV.y > 1.0) {
        gl_FragColor = vec4(0.0);
    } else {
        vec4 col = texture2D(bitmap, warpedUV);
        // Vignette shading: darkens the edges as they curve away
        col.rgb *= 1.0 - (r * r * (curve * 0.8));
        gl_FragColor = col;
    }
}