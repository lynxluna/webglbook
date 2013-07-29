attribute vec3 position;
attribute vec3 normal;
attribute vec2 texcoord;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 normalMatrix;

varying vec3 fNormal;
varying vec3 fEyeVec;
varying vec2 fTexCoord;

void main(void) { 
  vec4 pos = modelViewMatrix * vec4(position, 1.0);
  fNormal = vec3(normalMatrix * vec4(normal, 1.0));
  fEyeVec = -vec3(pos.xyz);
  fTexCoord = texcoord;
  gl_Position = projectionMatrix * pos;
} 
