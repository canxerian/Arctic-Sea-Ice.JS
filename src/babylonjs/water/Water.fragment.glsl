precision highp float;

uniform sampler2D _NormalMap;
uniform sampler2D _DepthTex;

uniform float _Time;
uniform float _NormalMapSpeed;
uniform float _NormalMapSize;
uniform vec3 _SunPosition;
uniform vec3 _CamPosition;
uniform float _Shininess;
uniform float _Specular;
uniform vec3 _SpecularColour;
uniform float _MaxDepth;
uniform vec3 _ColourDeep;
uniform vec3 _ColourShallow;
uniform vec2 _CamNearFar;
uniform float _FogDensity;
uniform vec3 _FogColour;

// Varying (vert to frag parameters)
varying vec2 vUV;
varying vec3 vPosition;
varying vec4 vWorldPosition;
varying vec4 vClipSpace;

float saturate(float val) {
    return clamp(val, 0.0, 1.0);
}

float getWaterDepth() {
    float camNear = _CamNearFar[0];
    float camFar = _CamNearFar[1];

    // Normalised device coords (i.e the fragment, in screen-space)
    vec2 ndc = (vClipSpace.xy / vClipSpace.w) / 2.0 + 0.5;
    
    // grab depth value (0 to 1) at ndc for object behind water
    float depthOfObjectBehindWater = texture2D(_DepthTex, ndc).r;
    
    // get depth of water plane
    float linearWaterDepth = (vClipSpace.z + camNear) / (camFar + camNear);
    
    // calculate water depth scaled to camFar since camFar > camNear
    float waterDepth = camFar * (depthOfObjectBehindWater - linearWaterDepth);
    
    // get water depth as a ratio of _MaxDepth
    float wdepth = clamp((waterDepth / _MaxDepth), 0.0, 1.0);

    return wdepth;
}

// https://github.com/mrdoob/three.js/blob/dev/examples/jsm/objects/Water.js
vec3 getNormal( vec2 uv ) {
    float time = _Time * _NormalMapSpeed;
    uv *= _NormalMapSize;

    vec2 uv0 = ( uv / 103.0 ) + vec2(time / 17.0, time / 29.0);
    vec2 uv1 = uv / 107.0-vec2( time / -19.0, time / 31.0 );
    vec2 uv2 = uv / vec2( 8907.0, 9803.0 ) + vec2( time / 101.0, time / 97.0 );
    vec2 uv3 = uv / vec2( 1091.0, 1027.0 ) - vec2( time / 109.0, time / -113.0 );
    vec3 noise = texture2D( _NormalMap, uv0 ).xyz +
        texture2D( _NormalMap, uv1 ).xyz +
        texture2D( _NormalMap, uv2 ).xyz +
        texture2D( _NormalMap, uv3 ).xyz;
    
    return normalize(noise * 0.5 - 1.0);
}

void main(void) {
    vec3 normal = getNormal(vWorldPosition.xz).xzy;

    vec3 sunDir = normalize(_SunPosition);
    
    // Water Colour
    vec3 waterColour = mix(_ColourShallow, _ColourDeep, getWaterDepth());

    // Ambient
    float ambient = 0.1;

    // Diffuse
    float diffuse = saturate(dot(normal, sunDir));

    // Specular (Blinn-Phong)
    vec3 viewDir = normalize(_CamPosition.xyz - vWorldPosition.xyz);
    vec3 halfDir = normalize(sunDir + viewDir);
    float NdotL = saturate(dot(normal, sunDir));
    float NdotH = saturate(dot(normal, halfDir));
    float specular = pow(NdotH, _Shininess) * _Specular;
    vec3 specularColour = specular * _SpecularColour;

    vec3 lightingColour = vec3(ambient + diffuse) + specularColour;

    // Fog
    float distanceFromCam = length(_CamPosition - vWorldPosition.xyz);
    float fog = pow(2.0, -pow(distanceFromCam * _FogDensity, 2.0));     // Exponential square

    vec3 finalCol = waterColour + lightingColour;
    finalCol = mix(finalCol, _FogColour, 1.0 - fog);

    gl_FragColor = vec4(finalCol, 1.0);
}