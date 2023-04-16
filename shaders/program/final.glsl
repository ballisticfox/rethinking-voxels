////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER
#ifndef IS_IRIS
#include "/lib/misc/irisRequired.glsl"
#else
noperspective in vec2 texCoord;

//Uniforms//
uniform float viewWidth, viewHeight;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform sampler2D colortex3;

#ifdef UNDERWATER_DISTORTION
	uniform int isEyeInWater;

	uniform float frameTimeCounter;
#endif

//SSBOs//
#define WRITE_TO_SSBOS
#include "/lib/vx/SSBOs.glsl"

//Pipeline Constants//
#include "/lib/misc/pipelineSettings.glsl"

//Common Variables//

//Common Functions//
#if IMAGE_SHARPENING > 0
	vec2 viewD = 1.0 / vec2(viewWidth, viewHeight);

	vec2 sharpenOffsets[4] = vec2[4](
		vec2( viewD.x,  0.0),
		vec2( 0.0,  viewD.x),
		vec2(-viewD.x,  0.0),
		vec2( 0.0, -viewD.x)
	);

	void SharpenImage(inout vec3 color, vec2 texCoordM) {
		float mult = 0.0125 * IMAGE_SHARPENING;
		color *= 1.0 + 0.05 * IMAGE_SHARPENING;

		for (int i = 0; i < 4; i++) {
			color -= texture2D(colortex3, texCoordM + sharpenOffsets[i]).rgb * mult;
		}
	}
#endif

//Includes//

//Program//
uniform sampler2D colortex12;
void main() {
	vec2 texCoordM = texCoord;

	#ifdef UNDERWATER_DISTORTION
		if (isEyeInWater == 1) texCoordM += 0.0007 * sin((texCoord.x + texCoord.y) * 25.0 + frameTimeCounter * 3.0);
	#endif

	vec3 color = texture2D(colortex3, texCoordM).rgb;

	#if IMAGE_SHARPENING > 0
		SharpenImage(color, texCoordM);
	#endif

	//clear SSBOs
	if (gl_FragCoord.x + gl_FragCoord.y < 1.5) {
		#ifdef ACCURATE_RT
			numFaces = 0;
		#endif
		numLights = 0;
		gbufferPreviousModelViewInverse = gbufferModelViewInverse;
		gbufferPreviousProjectionInverse = gbufferProjectionInverse;
	}
	// just for testing, triPointerStrip doesn't need to be cleared
	int pixelNum = int(gl_FragCoord.x) + int(viewWidth + 0.1) * int(gl_FragCoord.y);
	if (pixelNum < MAX_TRIS) {
		triPointerStrip[pixelNum] = 0;
	}
	if (all(lessThan(gl_FragCoord.xy, pointerGridSize.xz))) {
		ivec2 coords = ivec2(gl_FragCoord.xy);
		for (int i = 0; i < pointerGridSize.y; i++) {
			PointerVolume[0][coords.x][i][coords.y] = 0;
			PointerVolume[4][coords.x][i][coords.y] = 0;
		}
	}
	//color = mix(color, texelFetch(colortex12, ivec2(gl_FragCoord.xy), 0).rgb, 0.7);
	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
}

#endif
#endif
//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

noperspective out vec2 texCoord;

//Uniforms//

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
	gl_Position = ftransform();
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif
