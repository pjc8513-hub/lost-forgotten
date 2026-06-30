shader_type sky;

uniform vec3 zenith_color : source_color = vec3(0.2, 0.45, 0.85);   // Deep sky blue
uniform vec3 horizon_color : source_color = vec3(0.55, 0.75, 0.9); // Pale horizon blue
uniform float horizon_blur : hint_range(0.0, 1.0) = 0.3;



uniform vec3 sun_color : source_color = vec3(1.0, 0.95, 0.8);
uniform float sun_size : hint_range(0.01, 0.5) = 0.05;
uniform float sun_blur : hint_range(0.0, 0.1) = 0.01; // Low blur creates great retro pixel artifacts

void sky() {
    // 1. Base Sky Gradient
    // SKY_COORDS.y goes from 1.0 (zenith) to 0.0 (horizon)
    float v = clamp(SKY_COORDS.y, 0.0, 1.0);
    float gradient_t = smoothstep(0.0, horizon_blur, v);
    vec3 sky_gradient = mix(horizon_color, zenith_color, gradient_t);
    
    // 2. The Sun Disk
    // LIGHT0_DIRECTION is automatically provided by Godot's primary DirectionalLight3D
    float sun_dot = dot(EYEDIR, LIGHT0_DIRECTION);
    
    // Calculate the sun shape based on the angle to the light source
    float sun_factor = smoothstep(1.0 - sun_size - sun_blur, 1.0 - sun_size, sun_dot);
    vec3 sun_disk = sun_color * sun_factor;
    
    // 3. Combine them
    // We use a screen-style blend or simple addition so the sun sits "on top" of the gradient
    vec3 final_color = mix(sky_gradient, sun_color, sun_factor);
    
    COLOR = final_color;
}