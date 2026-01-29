////////////////////////////////////////////////////////
//  TV-OUT pixel perfect horizontal smoothing
//  Author: manekinekodesu - github.com/manekinekodesu
//  License: GPLv3
////////////////////////////////////////////////////////

////////////////////////////////////////////////////////
// this shader is meant to be used when running
// an emulator on a real CRT-TV with 
// custom_viewport_width set to 640
////////////////////////////////////////////////////////


#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#define COMPAT_TEXTURE texture
#else
#define COMPAT_VARYING varying
#define COMPAT_ATTRIBUTE attribute
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

COMPAT_ATTRIBUTE vec2 VertexCoord;
COMPAT_ATTRIBUTE vec2 TexCoord;
COMPAT_VARYING vec4 TEX0;

//flat COMPAT_VARYING float vTriID;
COMPAT_VARYING vec2 vPos;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 OutputSize;

void main()
{
	gl_Position = MVPMatrix * vec4(VertexCoord, 0.0, 1.0);
	TEX0.xy = TexCoord.xy;
	
	// Calculate a unique value for the triangle based on the vertex position.
    // In a standard quad strip:
    // Triangle 1 usually has a vertex with positive product (1,1 or -1,-1).
    // Triangle 2 usually has a vertex with negative product (-1,1 or 1,-1).
    // Multiplying x*y gives us a way to separate them.
    // vTriID = VertexCoord.x * VertexCoord.y;
	
	// Pass the position coordinates (-1.0 to 1.0) to the fragment shader
    vPos = VertexCoord; 
}
#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

// Parameter format: "Internal_Name" "Display Name" Default Min Max Step
#pragma parameter BRIGHTNESS "Shader Brightness" 0.85 0.0 2.0 0.05

#ifdef PARAMETER_UNIFORM
    uniform COMPAT_PRECISION float BRIGHTNESS;
#else
    #define BRIGHTNESS 0.85
#endif

#define SCALE 2.5

uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

//flat COMPAT_VARYING float vTriID;
COMPAT_VARYING vec2 vPos;

uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 OutputSize;

void main()
{
	// Blend every 2nd column of pixels (0,1,blend,3,4)
	bool blend = ( mod( floor( TEX0.x * (TextureSize.x*SCALE)) ,5.0) == 2.0);
	
	// FIX: Diagonal line artefact caused by float rounding error, otherwice offset = 1.0
	// Top-Left side will sum to negative numbers (approx -2 to 0) -> Result 0.0
    // Bottom-Right side will sum to positive numbers (approx 0 to 2) -> Result 1.0
	// float offset = step(0.0, vTriID) * 2.0 - 1.0;
	float offset = step(0.0, vPos.x - vPos.y) * 2.0 - 1.0;
	
	vec3 tmp;
	tmp.xy = TEX0.xy;
	tmp.z = TEX0.x+offset/(TextureSize.x * SCALE);
	
	// Sample neighboring colors
	vec4 col1 = COMPAT_TEXTURE(Texture, tmp.xy);
	vec4 col2 = COMPAT_TEXTURE(Texture, tmp.zy);
	
	// Mix based on the step result (0.0 = col1, 1.0 = 50/50 blend)
	vec4 _color = mix(col1, mix(col1,col2,0.5), float(blend));

	FragColor = _color * BRIGHTNESS;
	return;
}

#endif
