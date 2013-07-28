attribute vec3 position;
attribute vec3 normal;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 normalMatrix;

uniform vec3 lightDirection;
uniform vec4 lightDiffuse;
uniform vec4 materialDiffuse;

uniform vec4 ambientColor;

varying vec4 finalColor;
void main(void) {
  vec4 N     = normalize(normalMatrix * vec4(normal, 1.0));
  vec4 L     = normalize(vec4(lightDirection, 1.0));
  float lam  = max(dot(N.xyz, lightDirection), 0.0);
  vec4 id    = materialDiffuse * lightDiffuse * lam;
  finalColor = id + ambientColor;
  vec4 pos   = modelViewMatrix * vec4(position, 1.0);

  gl_Position = projectionMatrix * pos;
} 
