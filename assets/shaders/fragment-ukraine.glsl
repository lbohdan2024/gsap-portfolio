uniform float time;
uniform float randomSeed;
uniform float objectOpacity;
uniform float noisePower;
uniform float pixelRatio;
uniform vec2 resolution;
uniform vec3 color1;
uniform vec3 color2;
uniform vec3 color3;

varying vec3 vPosition;

vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}

float snoise(vec3 v){
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //  x0 = x0 - 0. + 0.0 * C
  vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1. + 3.0 * C.xxx;

// Permutations
  i = mod(i, 289.0 );
  vec4 p = permute( permute( permute(
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients
// ( N*N points uniformly over a square, mapped onto an octahedron.)
  float n_ = 1.0/7.0; // N=7
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1),
                                dot(p2,x2), dot(p3,x3) ) );
}

float lines(vec2 uv, float offset) {
  return smoothstep(
    0.0,
    0.5 + offset * 0.5,
    abs(0.55 * (sin(uv.x * 12.0) + offset * 2.0))
  );
}

vec3 normalizeRGBColor(vec3 color) {
  return color / 255.0;
}

mat2 getRotationMatrix(float angle) {
  return mat2(
    cos(angle), -sin(angle),
    sin(angle), cos(angle)
  );
}

float rand(vec2 p) {
    vec2 k1 = vec2(
        23.14069263277926, // e^pi (Gelfond's constant)
        2.665144142690225 // 2^sqrt(2) (Gelfond–Schneider constant)
    );
    return fract(
        cos(dot(p, k1)) * 12345.6789
    );
}

void main() {
  float shaderZoom = 0.25;

  // if (resolution.x > 700.0) shaderZoom = 0.25;
  // else shaderZoom = 0.3;

  vec3 _color1 = normalizeRGBColor(color1);
  vec3 _color2 = normalizeRGBColor(color2);
  vec3 _color3 = normalizeRGBColor(color3);

  float noise = snoise(vPosition + time * 0.175 + randomSeed * 100.0) * (noisePower * 0.125);

  vec2 baseUv = getRotationMatrix(noise + -1.525) * vPosition.xy * shaderZoom;

  float firstPattern = lines(baseUv, 0.35);
  // float secondPattern = lines(baseUv, 0.05, 15.0);

  vec3 resColor = mix(_color1, _color2, firstPattern);
  // vec3 resColor = mix(firstColor, _color1, secondPattern);

  float grainStrength = 0.075;
  if (pixelRatio > 2.0) grainStrength = 0.135;

  vec2 uvNoise = vPosition.xy;
  uvNoise.y *= rand(vec2(uvNoise.y, randomSeed));
  vec3 grain = vec3(rand(uvNoise) * grainStrength);

  resColor += grain;

  gl_FragColor = vec4(resColor, 1.0) * objectOpacity;
}
