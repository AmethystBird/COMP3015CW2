#version 460

layout (location = 0) in vec3 vertexPosition;
layout (location = 1) in vec3 vertexVelocity;
layout (location = 2) in float vertexAge;

uniform sampler1D randomTexture;

const float pi = 3.14159265359;

out float transparency;
out vec2 textureCoordinate;

out vec3 position;
out vec3 velocity;
out float age;

//uniform float time;
uniform float particleLifetime;
uniform float particleSize;
uniform int pass;
uniform float deltaTime;
uniform vec3 acceleration;
uniform mat3 emitterBasis;
uniform vec3 emitter = vec3(0);

uniform mat4 modelViewMatrix;
uniform mat4 projection;

const vec3 offsets[] = vec3[](vec3(-0.5, -0.5, 0), vec3(0.5, -0.5, 0), vec3(0.5, 0.5, 0), vec3(-0.5, -0.5, 0), vec3(0.5, 0.5, 0), vec3(-0.5, 0.5, 0));
const vec2 textureCoordinates[] = vec2[](vec2(0,0), vec2(1,0), vec2(1,1), vec2(0,0), vec2(1,1), vec2(0,1));

vec3 RandomInitialVelocity()
{
	float theta = mix(0.0, pi / 8.0, texelFetch(randomTexture, 3 * gl_VertexID, 0).r);
	float phi = mix(0.0, pi * 2.0, texelFetch(randomTexture, 3 * gl_VertexID + 1, 0).r);
	float vel = mix(1.25, 1.5, texelFetch(randomTexture, 3 * gl_VertexID + 2, 0).r);
	vec3 v = vec3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi));
	return normalize(emitterBasis * v) * vel;
}

void Update()
{
	if (vertexAge < 0 || vertexAge > particleLifetime)
	{
		//recycle
		position = emitter;
		velocity = RandomInitialVelocity();
		if (vertexAge < 0)
		{
			age = vertexAge + deltaTime;
		}
		else
		{
			age = (vertexAge - particleLifetime) + deltaTime;
		}
	}
	else
	{
		//update
		position = vertexPosition + vertexVelocity * deltaTime;
		velocity = vertexVelocity + acceleration * deltaTime;
		age = vertexAge + deltaTime;
	}
}

void Render()
{
	transparency = 0.0;
	vec3 cameraPosition = vec3(0.0);
	if (vertexAge >= 0.0)
	{
		cameraPosition = (modelViewMatrix * vec4(vertexPosition, 1)).xyz + offsets[gl_VertexID] * particleSize;
		transparency = clamp(1.0 - vertexAge / particleLifetime, 0, 1);
	}
	textureCoordinate = textureCoordinates[gl_VertexID];
	gl_Position = projection * vec4(cameraPosition, 1);
}

void main()
{
	if (pass == 1)
	{
		Update();
	}
	else
	{
		Render();
	}
}