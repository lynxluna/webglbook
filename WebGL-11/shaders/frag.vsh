precision highp float;

uniform vec3 lightDirection;
uniform vec4 lightDiffuse;
uniform vec4 lightAmbient;
uniform vec4 lightSpecular;

uniform vec4 materialDiffuse;
uniform vec4 materialAmbient;
uniform vec4 materialSpecular;

uniform float shininess;

uniform sampler2D sampler;

varying vec3 fNormal;
varying vec3 fEyeVec;
varying vec2 fTexCoord;

void main(void) {
  vec3 L = normalize(lightDirection);
  vec3 N = normalize(fNormal);
  vec4 matDiffuse = texture2D(sampler, fTexCoord);

  float lambertTerm = clamp(dot(N, -L), 0.0, 1.0);

  vec4 Ia = lightAmbient * materialAmbient;
  vec4 Id = vec4(0.0, 0.0, 0.0, 1.0);
  vec4 Is = vec4(0.0, 0.0, 0.0, 1.0);


  Id = lightDiffuse * (materialDiffuse) * lambertTerm;

  vec3 E = normalize(fEyeVec);
  vec3 R = reflect(L, N);

  float specular = pow(max(dot(R, E), 0.0), shininess );
  Is = lightSpecular * materialSpecular * specular;


  vec4 finalColor = (Ia + Id + Is) * matDiffuse;
  finalColor.a = 1.0;


  gl_FragColor = finalColor;
}

