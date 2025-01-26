shader_type canvas_item;
//render_mode unshaded, cull_disabled;

uniform bool billboard = false;

group_uniforms ANIMATION;
uniform float progress : hint_range(0.0, 1.0, 0.01);
uniform float derive_progress : hint_range(-1.0, 2.0, 1.0) = 0.0;
uniform float ease_progress : hint_range(-1.0, 2.0, 1.0) = 0.0;
uniform float time_scale : hint_range(0.0, 8.0, 0.01) = 1.0;
uniform sampler2D anim_mask : hint_default_white;
uniform float index_rot : hint_range(0.0, 1.0, 1.0) = 0.0;
uniform float shimer_speed = 0.0;
uniform float shimer_amt = 0.0;
group_uniforms;

group_uniforms SHAPE;
uniform float points : hint_range(1.0, 16.0, 1.0) = 3;
uniform float arc = 0.1;
uniform float feather = 0.0;
uniform vec2 radi = vec2(2.0,0.25);
uniform vec2 gleam_position = vec2(0.5,0.5);
uniform float gleam_rotation : hint_range(0.0, 1.0, 0.001);
uniform vec2 edge = vec2(0.0,1.0);
uniform vec2 ptedt = vec2(1.0);
uniform float ptedtofst : hint_range(0.0, 1.0, 0.001) = 0.0;
uniform sampler2D uv_noise : hint_default_black;
uniform float uvn_str : hint_range(0.0, 1.0, 0.1) = 0.0;
group_uniforms;

group_uniforms SHAPE_B;
uniform float enabled_b : hint_range(0.0, 1.0, 1.0) = 0;
uniform float points_b : hint_range(1.0, 16.0, 1.0) = 3;
uniform float arc_b = 0.1;
//uniform float feather_b = 0.0;
uniform vec2 radi_b = vec2(2.0,0.25);
uniform vec2 gleam_position_b = vec2(0.5,0.5);
uniform float gleam_rotation_b : hint_range(0.0, 1.0, 0.001);
uniform vec2 edge_b = vec2(0.0,1.0);
uniform vec2 ptedt_b = vec2(1.0);
uniform float ptedtofst_b : hint_range(0.0, 1.0, 0.001) = 0.0;
//uniform sampler2D uv_noise_b : hint_default_black;
//uniform float uvn_str_b : hint_range(0.0, 1.0, 0.1) = 0.0;
group_uniforms;

group_uniforms COLORING;
uniform float mix_str : hint_range(0.0, 2.0, 0.1) = 1.0;
uniform sampler2D color_lookup : source_color, hint_default_black;
uniform float rotate_lookup = 0.0;
uniform mat4 chromatic_offset = mat4(
	vec4(1.0,1.0,0.0,0.0),
	vec4(1.0,1.0,0.0,0.0),
	vec4(1.0,1.0,0.0,0.0),
	vec4(0.0,0.0,0.0,0.0)
	);
group_uniforms;

varying float LIFETIME;
varying float INDEX;

float random (vec2 uv) {
	return fract(sin(dot(uv.xy,
		vec2(12.9898,78.233))) * 43758.5453123);
}

vec2 scale(vec2 uv, float x, float y) {
	mat2 scale = mat2(vec2(x, 0.0), vec2(0.0, y));
	uv -= 0.5;
	uv = uv * scale;
	uv += 0.5;
	return uv;
}

vec2 rotate(vec2 uv, vec2 pivot, float angle) {
	mat2 rotation = mat2(vec2(sin(angle), -cos(angle)),
						vec2(cos(angle), sin(angle)));
	uv -= pivot;
	uv = uv * rotation;
	uv += pivot;
	return uv;
}

// Easing Functions Adapted From https://easings.net/

float easeOutExpo(float x) {
	return 1.0 - pow(2.0, -10.0 * x);
}

float easeInExpo(float x) {
	return pow(2.0, 10.0 * x - 10.0);
}

//Circ
float easeInOut(float x) {
	float result;
	if (x < 0.5) {result = (1.0 - sqrt(1.0 - pow(2.0 * x, 2.0))) / 2.0;}
	else {result =(sqrt(1.0 - pow(-2.0 * x + 2.0, 2.0)) + 1.0) / 2.0;}
	return result;
}

float easeInOutExpo(float x) {
	float result;
	if (x == 0.0) {result = 0.0;}
	else if (x == 1.0) {result = 1.0;}
	else if (x < 0.5) {result = pow(2.0, 20.0 * x - 10.0) / 2.0;}
	else {result = (2.0 - pow(2.0, -20.0 * x + 10.0)) / 2.0;}
	return result;
}

float get_progress() {
	float p;
	float final;
	if (derive_progress > 0.0) {p = LIFETIME;}
	else if (derive_progress < 0.0) {p = mod(TIME * time_scale,1.0);}
	// abs(sin(TIME * time_scale)) [Back and Forth]
	// mod(TIME * time_scale,1.0) [Over and Over]
	else {p = progress;}

	if (ease_progress > 1.0) {final = easeInOutExpo(p);}
	else if (ease_progress > 0.0 && ease_progress < 2.0) {final = easeOutExpo(p);}
	else if (ease_progress < 0.0) {final = easeInExpo(p);}
	else {final = p;}

	return final;
}

void vertex() {
	LIFETIME = INSTANCE_CUSTOM.y;
	INDEX = float(INSTANCE_ID);
}

float gleam(vec2 uv) {
	vec2 pos = (gleam_position-uv) - vec2(0.0,mod(points,2) * 0.05);
	
	float r = length(pos) * radi.x;
	float a = atan(pos.x,pos.y);
	float rndrot = random(vec2(INDEX));
	
	float pnts = points / 2.0;
	float f = 1.0 - pow(abs(cos((a + ((2.0 * PI) * (gleam_rotation + (rndrot * index_rot)))) * pnts)), arc) + radi.y;
	float m = mix(ptedt.x + (sin(TIME * shimer_speed) * shimer_amt),ptedt.y + (cos(TIME * shimer_speed) * shimer_amt),sin((a + ((2.0 * PI) * (gleam_rotation + (rndrot * index_rot))) + ((2.0 * PI) * ptedtofst))*pnts) + 1.0);
	f *= m;

	return 1.0-smoothstep(f,f+feather,r);
}

float gleamb(vec2 uv) {
	vec2 pos = (gleam_position_b-uv) - vec2(0.0,mod(points_b,2) * 0.05);
	
	float r = length(pos) * radi_b.x;
	float a = atan(pos.x,pos.y);
	
	float pnts = points_b / 2.0;
	float f = 1.0 - pow(abs(cos((a + ((2.0 * PI) * gleam_rotation_b)) * pnts)), arc_b) + radi_b.y;
	float m = mix(ptedt_b.x,ptedt_b.y,sin((a + ((2.0 * PI) * gleam_rotation_b) + ((2.0 * PI) * ptedtofst_b))*pnts) + 1.0);
	f *= m;
	
	return 1.0-smoothstep(f,f+feather,r);
}

void fragment() {
	float p = get_progress();
	float clp = abs(cos(p * PI));
	vec4 uvd = texture(uv_noise,UV);
	vec2 aUV = UV + (vec2((uvd.r - 0.5) * 2.0) * uvn_str);
	float r = gleam(scale(rotate(aUV + chromatic_offset[0].zw,gleam_position,radians(chromatic_offset[3].x)),chromatic_offset[0].x,chromatic_offset[0].y)); //gleam(UV + chromatic_offset[0].xy);
	float g = gleam(scale(rotate(aUV + chromatic_offset[1].zw,gleam_position,radians(chromatic_offset[3].y)),chromatic_offset[1].x,chromatic_offset[1].y)); //gleam(UV + chromatic_offset[1].xy);
	float b = gleam(scale(rotate(aUV + chromatic_offset[2].zw,gleam_position,radians(chromatic_offset[3].z)),chromatic_offset[2].x,chromatic_offset[2].y)); //gleam(UV + chromatic_offset[2].xy);
	
	float r_b = gleamb(scale(rotate(aUV + chromatic_offset[0].zw,gleam_position,radians(chromatic_offset[3].x)),chromatic_offset[0].x,chromatic_offset[0].y));
	float g_b = gleamb(scale(rotate(aUV + chromatic_offset[1].zw,gleam_position,radians(chromatic_offset[3].y)),chromatic_offset[1].x,chromatic_offset[1].y));
	float b_b = gleamb(scale(rotate(aUV + chromatic_offset[2].zw,gleam_position,radians(chromatic_offset[3].z)),chromatic_offset[2].x,chromatic_offset[2].y));
	
	vec3 final = clamp(vec3(r + (r_b * enabled_b),g + (g_b * enabled_b),b + (b_b * enabled_b)),0.0,1.0);

	COLOR.rgb += (texture(color_lookup,rotate(vec2(UV.y,0.0),vec2(0.5),radians(rotate_lookup + 90.0))).rgb * (1.0-clp)) * mix_str;
	COLOR.rgb *= (final * mix_str) + (1.0 * clamp(1.0-mix_str,0.0,1.0));
	COLOR.a *= smoothstep(edge.x + clp,edge.y + clp,min(min(final.r,final.g),final.b) * texture(anim_mask,UV).r); //min(min(final.r,final.g),final.b)
}
