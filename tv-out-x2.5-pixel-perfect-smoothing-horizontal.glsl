////////////////////////////////////////////////////////
//	TV-OUT pixel perfect horizontal smoothing
//	Author: manekinekodesu - github.com/manekinekodesu
//	License: GPLv3
////////////////////////////////////////////////////////

////////////////////////////////////////////////////////
// this shader is meant to be used when running
// an emulator on a real CRT-TV with custom_viewport_width set to 640
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

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION vec2 TextureSize;
void main()
{
	gl_Position = MVPMatrix * vec4(VertexCoord, 0.0, 1.0);
	TEX0.xy = TexCoord.xy;
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

vec4 _color;

#define brightness 0.85
#define scaling 2.5

uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

uniform COMPAT_PRECISION vec2 TextureSize;
void main()
{
	bool result = (mod( floor(TEX0.x * (TextureSize.x*scaling/1.0)) ,5.0)==2.0);
	
	vec4 tmp;
	tmp.xy = TEX0.xy;
	tmp.z = TEX0.x+1.0/(TextureSize.x * scaling);

	vec4 col1 = COMPAT_TEXTURE(Texture, tmp.xy);
	vec4 col2 = COMPAT_TEXTURE(Texture, tmp.zy);
	
	_color = result?mix(col1,col2,0.5):col1;

	FragColor = _color * brightness;
	return;
}
#endif
