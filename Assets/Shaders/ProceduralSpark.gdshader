shader_type canvas_item;
render_mode unshaded;
// remove unshaded if you want glow

group_uniforms ANIMATION;
uniform float progress : hint_range(0.0, 1.0, 0.01) = 0.0;
// This value animates this shader when DERIVE_PROGRESS is set to 0.0
uniform float derive_progress : hint_range(-1.0, 1.0, 1.0) = 0.0;
// 0.0 Use PROGRESS (Change value in code or animation player)
// -1.0 Use TIME (Idle Loop)
// 1.0 use LIFETIME (Particle)
uniform float ease_progress : hint_range(-1.0, 2.0, 1.0) = 0.0;
// 0.0 No exponential
// -1.0 Expo In
// 1.0 Expo Out
// 2.0 Expo In Out
uniform float time_scale : hint_range(0.0, 8.0, 0.01) = 1.0;
//uniform float anim_rot_amt : hint_range(0.0, 1.0, 0.01) = 1.0;
// ^^^
// The shader is setup to rotate the main image as it progresses,
// set this to 0 to disable that behaviour
group_uniforms;

//uniform float billboard : hint_range(-1.0, 1.0, 1.0);
uniform sampler2D base_noise : hint_default_white;
uniform sampler2D radial_mask : hint_default_transparent, repeat_disable;
uniform vec2 spark_origin = vec2(0.5);
uniform float spark_zoom = 0.1;
uniform float spark_rotate : hint_range(0.0, 360.0, 0.1) = 90;
uniform vec4 spark_color : source_color = vec4(1.0);
uniform float mix_strength : hint_range(0.0, 1.0, 0.1);
uniform float emission_strength : hint_range(0.0, 1.0, 0.1);

varying float LIFETIME;
varying float INDEX;

vec2 polar_coordinates(vec2 uv, vec2 center, float zoomm, float repeat) {
	vec2 dir = uv - center;
	float radius = length(dir) * 2.0;
	float angle = atan(dir.y, dir.x) * 1.0/(3.1416 * 2.0);
	return mod(vec2(radius * zoomm, angle * repeat), 1.0);
}

vec2 rotate(vec2 uv, vec2 pivot, float angle) {
	mat2 rotation = mat2(vec2(sin(angle), -cos(angle)),
						vec2(cos(angle), sin(angle)));
	uv -= pivot;
	uv = uv * rotation;
	uv += pivot;
	return uv;
}

vec2 scale(vec2 uv, float x, float y) {
	mat2 scale = mat2(vec2(x, 0.0), vec2(0.0, y));
	uv -= 0.5;
	uv = uv * scale;
	uv += 0.5;
	return uv;
}

void vertex() {
	LIFETIME = INSTANCE_CUSTOM.y;
	INDEX = float(INSTANCE_ID);
}

float circle(vec2 position, float radius, float feather) {
	return smoothstep(radius, radius + feather, length(position - vec2(0.5)));
}

float easeOutExpo(float x) {
	return 1.0 - pow(2.0, -10.0 * x);
}

float easeInExpo(float x) {
	return pow(2.0, 10.0 * x - 10.0);
}

float easeInOutExpo(float x) {
	float result;
	if (x == 0.0) {result = 0.0;}
	else if (x == 1.0) {result = 1.0;}
	else if (x < 0.5) {result = pow(2.0, 20.0 * x - 10.0) / 2.0;}
	else {result = (2.0 - pow(2.0, -20.0 * x + 10.0)) / 2.0;}
	return result;
}

float easeInOutSine(float x) {
	return -(cos(PI * x) - 1.0) / 2.0;
}

float get_progress() {
	float p;
	float final;
	if (derive_progress > 0.0) {p = LIFETIME;}
	else if (derive_progress < 0.0) {p = mod(TIME * time_scale,1.0);}
	// abs(sin(TIME * time_scale)) [Back and Forth]
	// mod(TIME * time_scale,1.0) [Over and Over]
	else {p = progress;}

	if (ease_progress > 1.0) {final = easeInOutSine(p);}
	else if (ease_progress > 0.0 && ease_progress < 2.0) {final = easeOutExpo(p);}
	else if (ease_progress < 0.0) {final = easeInExpo(p);}
	else {final = p;}

	return final;
}

void fragment() {
	float p = get_progress();
	vec2 aUV = polar_coordinates(rotate(UV,vec2(0.5),radians(spark_rotate)),spark_origin,spark_zoom,1.0);
	vec4 b = texture(base_noise,aUV - vec2(p,0.0));

	vec2 rmsv = vec2((abs(cos(p * PI)) * 0.5) + 1.0);
	vec4 rm = texture(radial_mask,UV);
	//float clr = circle(UV,clamp(p - 0.5,0.0,1.0),0.01);
	vec4 prefinal = clamp(b - rm,0.0,1.0);

	//ALBEDO = b.rgb - rm.rgb;
	float start = 1.0-abs(sin(p * PI));
	float end = 1.0-abs(sin(p * PI));
	float pf_alpha = clamp(smoothstep(start,end,prefinal.r),0.0,1.0);

	float crp = 1.0-circle(UV,0.5,0.01);
	COLOR.rgb *= spark_color.rgb;
	if (mix_strength > 0.0) {
		COLOR.rgb *= (prefinal * mix_strength).rgb;
	}
	if (emission_strength > 0.0) {
		COLOR.rgb *= 1.0 + emission_strength;
	}

	COLOR.a *= pf_alpha * COLOR.a; //+ smoothstep(clamp(start,0.0,0.2),clamp(end,0.0,0.2),(high.r * 0.2)),0.0,1.0) * COLOR.a;
	COLOR.a *= crp;
	//COLOR.a = clamp(b.r - rm.r,0.0,1.0);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
