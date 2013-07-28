attribute vec3 position;
attribute vec3 normal;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 normalMatrix;

uniform vec3 lightDirection;
uniform vec4 lightDiffuse;

varying vec4 finalColor;
void main(void) {
   vec3 N = normalize(vec3(normalMatrix * vec4(normal, 1.0)));
   vec3 L = normalize(lightDirection);
   float lambertTerm = dot(N, -L);
   vec4 id = materialDiffuse * lightDiffuse * lambertTerm;
   finalColor = id;
   finalColor.a = 1.0;
   vec4 pos = modelViewMatrix * vec4(position, 1.0);
   gl_Position = projectionMatrix * pos;
} 
