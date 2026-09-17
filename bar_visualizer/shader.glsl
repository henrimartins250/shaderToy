

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord / iResolution.xy;

    // Grid pixelation for 32 audio-style visualizer bars
    float numBars = 32.0;
    
    // Snap x to discrete bar steps (0.0 to 1.0)
    float barIndex = (floor(uv.x * numBars) + 0.5) / numBars;
    
    // Sample frequency data from iChannel0
    // Y = 0.25 samples FFT frequency spectrum (0.0 = Bass, 1.0 = Treble)
    float waveHeight = texture(iChannel0, vec2(barIndex, 0.25)).r;
    
    // Default background color (dark blue/purple)
    vec3 col = vec3(0.05, 0.05, 0.15);
    
    // Render the visualizer bars if pixel Y position is below the audio amplitude
    if (uv.y < waveHeight) {
        // Dynamic gradient color from blue (bottom/lows) to pink/red (top/highs)
        col = mix(vec3(0.2, 0.6, 1.0), vec3(1.0, 0.2, 0.5), uv.y);
        
        // Add a vertical gap between bars
        float barSubCoord = fract(uv.x * numBars);
        if (barSubCoord < 0.1) {
            col *= 0.2; // Dim color at the edge of each bar
        }
    }

    // Output to screen
    fragColor = vec4(col, 1.0);
}
