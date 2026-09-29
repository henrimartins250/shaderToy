// Shadertoy GLSL Orbital Camera - Waterfall Lines Visualizer (Robust Thin Lines)

// Hash function for faint background stars
float Hash(vec3 p) {
    p = fract(p * vec3(443.897, 441.423, 437.195));
    p += dot(p, p.yxz + 19.19);
    return fract((p.x + p.y) * p.z);
}

// Faint background stars
vec3 BackgroundDots(vec3 ray) {
    vec3 p = floor(ray * 300.0);
    float h = Hash(p);
    if (h > 0.992) {
        return vec3(0.3 * smoothstep(0.992, 1.0, h));
    }
    return vec3(0.0);
}

// Robust Ray-Box intersection (guaranteed never to clip or drop out)
vec2 IntersectBox(in vec3 ro, in vec3 rd, in vec3 center, in vec3 rad, out vec3 oN) {
    vec3 p = ro - center;
    vec3 m = 1.0 / rd;
    vec3 n = m * p;
    vec3 k = abs(m) * rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
    if (tN > tF || tF < 0.0) return vec2(-1.0);
    oN = -sign(rd) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);
    return vec2(tN, tF);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Normalized pixel coordinates centered at screen middle
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // Mouse orbit control (defaults to a nice viewing angle if unclicked)
    vec2 mouse = iMouse.z > 0.0 ? iMouse.xy : iResolution.xy * vec2(0.5, 0.4);
    vec2 rot = (mouse / iResolution.xy) * vec2(6.28318, 3.14159) - vec2(3.14159, 1.57079);
    rot.y = clamp(rot.y, -1.49, 1.49); // Prevent flipping over poles
    
    // Calculate orbital camera position around world origin (0,0,0)
    float distance = 4.5;
    vec3 camPos = vec3(
        distance * cos(rot.y) * sin(rot.x),
        distance * sin(rot.y),
        distance * cos(rot.y) * cos(rot.x)
    );
    
    // Build camera basis vectors looking at the origin
    vec3 target = vec3(0.0);
    vec3 forward = normalize(target - camPos);
    vec3 worldUp = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(forward, worldUp));
    vec3 up = cross(right, forward);
    
    // Construct primary ray direction
    float zoom = 1.5;
    vec3 ray = normalize(forward * zoom + right * uv.x + up * uv.y);
    
    // Start with background faint starfield
    vec3 col = BackgroundDots(ray);
    
    // Loop through a dense sequence of lines stacked along the Z-axis
    float tClosest = 1e20;
    vec3 hitNormal = vec3(0.0);
    int hitIndex = 0;
    
    for (int i = -10; i <= 10; i++) {
        // Stacked along Z-axis
        vec3 center = vec3(0.0, 0.0, float(i) * 0.3);
        
        // Dimensions: Wide along X (1.5), but very thin along Y and Z (0.015) 
        // making them actual fine lines/wires instead of flat boards.
        vec3 boxRad = vec3(1.5, 0.015, 0.015);
        
        vec3 normal;
        vec2 tBox = IntersectBox(camPos, ray, center, boxRad, normal);
        if (tBox.x > 0.0 && tBox.x < tClosest) {
            tClosest = tBox.x;
            hitNormal = normal;
            hitIndex = i;
        }
    }
    
    // If we hit any of the lines, shade it with a vibrant audio-visualizer glow
    if (tClosest < 1e19) {
        float tColor = (float(hitIndex) + 10.0) / 20.0;
        
        // Beautiful audio visualizer color gradient along the waterfall depth
        vec3 lineColor = mix(vec3(0.2, 0.6, 1.0), vec3(0.9, 0.3, 0.8), tColor);
        
        // Simple directional lighting for 3D depth perception
        vec3 lightDir = normalize(vec3(1.0, 2.0, 3.0));
        float diff = max(dot(hitNormal, lightDir), 0.4);
        
        col = lineColor * diff;
    }
    
    fragColor = vec4(col, 1.0);
}
