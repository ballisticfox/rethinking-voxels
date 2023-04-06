#include "/lib/common.glsl"

uniform float viewWidth;
uniform float viewHeight;
ivec2 view = ivec2(viewWidth + 0.1, viewHeight + 0.1);
ivec2 lowResView = view / 8;
uniform vec3 fogColor;
uniform vec3 cameraPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform sampler2D colortex0;
uniform sampler2D colortex15;

#include "/lib/vx/raytrace.glsl"

void main() {
	ivec2 coords = ivec2(gl_FragCoord.xy);
	ivec2 tileCoords = coords / lowResView;
	float visibility = 0.0;
	vec4 debug = vec4(0);
	if (all(lessThan(tileCoords, ivec2(8)))) {
		int lightNum = tileCoords.x + 8 * tileCoords.y;
		ivec2 localCoords = coords % lowResView * 8;
		if (all(lessThan(localCoords, view))) {
			vec4 normalDepthData = texelFetch(colortex0, localCoords, 0);
			if (length(normalDepthData.xyz) > 0.5) {
				vec4 pos = vec4(localCoords, 1 - normalDepthData.w, 1);
				pos.xy = (pos.xy + 0.5) / view;
				pos.xyz = 2 * pos.xyz - 1;
				pos = gbufferModelViewInverse * (gbufferProjectionInverse * pos);
				pos.xyz = pos.xyz / pos.w + fract(cameraPosition);
				debug.xyz = (pos.xyz + floor(cameraPosition) - vec3(50, 65, 0)) * 0.1;
				pos.xyz += 0.05 * normalDepthData.xyz;
				if (clamp(pos.xyz, -pointerGridSize / POINTER_VOLUME_RES, pointerGridSize / POINTER_VOLUME_RES) == pos.xyz) {
					ivec3 pgc = ivec3(pos.xyz + pointerGridSize / POINTER_VOLUME_RES);
					int lightCount = PointerVolume[4][pgc.x][pgc.y][pgc.z];
					if (lightCount > lightNum) {
						light_t thisLight = lights[PointerVolume[5 + lightNum][pgc.x][pgc.y][pgc.z]];
						vec3 dir = thisLight.pos - pos.xyz;
						if (dot(dir, normalDepthData.xyz) > 0) {
							#ifdef ACCURATE_RT
								ray_hit_t rayHit = betterRayTrace(pos.xyz, dir, colortex15);
							#else
								ray_hit_t rayHit = raytrace(pos.xyz, dir, colortex15);
							#endif
							if (rayHit.rayColor.a < 0.1) {
								visibility = 1.0;
							} else if (rayHit.rayColor.a < 0.9) {
								visibility = 0.5;
							} else {
								vec3 dist = abs(rayHit.pos - thisLight.pos) / (max(thisLight.size, vec3(0.5)) + 0.01);
								if (max(max(dist.x, dist.y), dist.z) > 1.0) visibility = 0.0;
								else if (rayHit.transColor.a > 0.1) visibility = 0.5;
								else visibility = 1.0;
							}
						}
					}
				}
			}
		}
	}
	/*RENDERTARGETS:12*/
	gl_FragData[0] = vec4(visibility, 0, 0, 1);
}