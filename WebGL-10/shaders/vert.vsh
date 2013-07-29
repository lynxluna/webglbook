attribute vec3 position;
attribute vec3 normal;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 normalMatrix;

varying vec3 fNormal;
varying vec3 fEyeVec;

void main(void) { 
  vec4 pos = modelViewMatrix * vec4(position, 1.0);
  fNormal = vec3(normalMatrix * vec4(normal, 1.0));
  fEyeVec = -vec3(pos.xyz);

  gl_Position = projectionMatrix * pos;
} 
