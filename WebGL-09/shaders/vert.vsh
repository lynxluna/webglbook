attribute vec3 position;
attribute vec3 normal;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 normalMatrix;

uniform vec3 lightDirection;
uniform vec4 lightDiffuse;
uniform vec4 lightAmbient;
uniform vec4 lightSpecular;

uniform vec4 materialDiffuse;
uniform vec4 materialAmbient;
uniform vec4 materialSpecular;

uniform float shininess;

varying vec4 finalColor;

void main(void) { 
  vec4 pos = modelViewMatrix * vec4(position, 1.0);
  vec3 N = vec3(normalMatrix * vec4(normal, 1.0));
  vec3 L = normalize(lightDirection);

  float lambertTerm = clamp(dot(N, -L), 0.0, 1.0);

  vec4 Ia = lightAmbient * materialAmbient;
  vec4 Id = vec4(0.0, 0.0, 0.0, 1.0);
  vec4 Is = vec4(0.0, 0.0, 0.0, 1.0);


  Id = lightDiffuse * materialDiffuse * lambertTerm;

  vec3 eyeVec = -vec3(pos.xyz);

  vec3 E = normalize(eyeVec);
  vec3 R = reflect(L, N);

  float specular = pow(max(dot(R, E), 0.0), shininess );
  Is = lightSpecular * materialSpecular * specular;


  finalColor = Ia + Id + Is;
  finalColor.a = 1.0;

  gl_Position = projectionMatrix * pos;
} 
