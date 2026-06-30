shader_type sky;

uniform vec3 zenith_color : source_color = vec3(0.1, 0.1, 0.2);
uniform vec3 horizon_color : source_color = vec3(0.5, 0.3, 0.2);
uniform float horizon_blur : hint_range(0.0, 1.0) = 0.5;

void sky() {
    // SKY_COORDS.y is 1.0 at zenith, 0.0 at horizon, -1.0 at nadir
    float v = SKY_COORDS.y;
    
    // Create a smooth gradient
    float t = smoothstep(0.0, horizon_blur, v);
    
    // Mix the horizon color and zenith color
    vec3 final_color = mix(horizon_color, zenith_color, t);
    
    // Output directly
    COLOR = final_color;
}