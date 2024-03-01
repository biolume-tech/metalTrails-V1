#include <metal_stdlib>
using namespace metal;

// TrailPoint structure from the trail project
struct TrailPoint {
    float4 position; // x, y, z, and w
    float4 color;    // r, g, b, and a
};

// VertexOut structure adapted to include point size and index
struct VertexOut {
    float4 position [[position]];
    float pointSize [[point_size]]; // Control the size of the point
    uint index; // Pass the index to the fragment shader
};

// Vertex shader from the trail project, adapted for the TrailPoint structure
vertex VertexOut vertex_main(uint vertexID [[vertex_id]],
                             constant TrailPoint* trailPoints [[buffer(0)]],
                             constant uint &frameCount [[buffer(1)]]) {
    VertexOut vertexOut;
    
    // Determine the index of the point in the trail
    uint index = vertexID % 15; // Match with the trail length
    
    // Use the trail point data to position the points
    vertexOut.position = trailPoints[index].position;
    vertexOut.pointSize = max(1.0, 9.0 - (index * 1.0)); // Size decreases with the index
    vertexOut.index = index;
    
    return vertexOut;
}

// Fragment shader from the trail project
fragment float4 fragment_main(VertexOut vertex_out [[stage_in]],
                              constant TrailPoint* trailPoints [[buffer(0)]]) {
    // Use the index from the vertex shader to get the color
    float4 color = trailPoints[vertex_out.index].color;
    return color; // Return the color with applied opacity
}


// Hash function for pseudo-random number generation
uint hash(uint x) {
    x += (x << 10u);
    x ^= (x >> 6u);
    x += (x << 3u);
    x ^= (x >> 11u);
    x += (x << 15u);
    return x;
}

// Compute shader to randomly move points
kernel void compute_main(device TrailPoint* trailPoints [[buffer(0)]],
                         constant uint &frameCount [[buffer(1)]],
                         uint id [[thread_position_in_grid]]) {
    // Update only the leading point with random movement
    if (id == 0) {
        float movementSpeed = 0.01; // Adjust this value to control movement speed
        float movementScale = 0.2;  // Adjust this value to control movement scale
        float spacingFactor = 0.5;  // Adjust this value to control spacing
        
        // Smooth movement using sine and cosine functions
        float deltaX = movementSpeed * sin(float(frameCount) * movementScale) * spacingFactor;
        float deltaY = movementSpeed * cos(float(frameCount) * movementScale) * spacingFactor;
        
        // Update position of the leading point
        trailPoints[id].position.x += deltaX;
        trailPoints[id].position.y += deltaY;
    }
    // Update the trailing points
    else if (id < 15) { // Replace 10 with your actual trail length
        trailPoints[id].position = trailPoints[id - 1].position;
    }
}







