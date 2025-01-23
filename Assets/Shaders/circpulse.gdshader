shader_type canvas_item;
render_mode unshaded;

uniform bool mask = false;
uniform sampler2D world_masked_texture : source_color, repeat_enable;
uniform vec2 mask_scroll = vec2(0.0);
varying vec2 world_position;
uniform float wscale = 1.0; //1/texture size

group_uniforms ANIMATION;
uniform float progress : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float derive_progress : hint_range(-1.0, 2.0, 1.0) = 0.0;
uniform float ease_progress : hint_range(-1.0, 2.0, 1.0) = 0.0;
uniform float time_scale : hint_range(0.0, 8.0, 0.01) = 1.0;
//uniform bool use_lifetime = false;
//uniform bool exponize_progress = false;
uniform bool auto_fade = false;
uniform float direction : hint_range(0.0, 1.0, 1.0) = 0.0;
group_uniforms;

group_uniforms APPEARANCE;
//uniform bool billboard = false;
uniform vec4 modulate : source_color = vec4(1.0);
//If you know what you're doing you can remove this uniform and tweak the shader properly lol
uniform float pulse_max_scale : hint_range(0.0, 1.0, 0.01) = 0.49;
uniform float pulse_offset : hint_range(-0.5, 0.5, 0.01) = 0.0;
uniform float outer_feather : hint_range(0.0, 1.0, 0.01) = 0.01;
uniform float inner_feather : hint_range(0.0, 1.0, 0.01) = 0.01;
uniform vec2 ss_edges = vec2(0.);
uniform float mix_strength : hint_range(0.0, 3.0, 0.1) = 0.0;
uniform sampler2D color_overlay : source_color,hint_default_white;
uniform sampler2D col_ovr_distort : hint_default_white;
uniform float col_ovr_dis_str : hint_range(0.0, 1.0, 0.1) = 0.0;
group_uniforms;

group_uniforms NOISE;
uniform bool polarize_opacity_noise = false;
uniform vec3 animate_opacity_noise = vec3(0.0);
uniform vec2 scale_opacity_noise = vec2(1.0);
uniform sampler2D opacity_noise : hint_default_black;
uniform sampler2D opacity_noise_b : hint_default_white;
group_uniforms;

varying float LIFETIME;
varying float INDEX;

vec2 scale(vec2 uv, float x, float y) {
	mat2 scale = mat2(vec2(x, 0.0), vec2(0.0, y));
	uv -= 0.5;
	uv = uv * scale;
	uv += 0.5;
	return uv;
}

float circle(vec2 position, float radius, float feather) {
	return smoothstep(radius, radius + feather, length(position - vec2(0.5)));
}

vec2 polar_coordinates(vec2 uv, vec2 center, float zoom, float repeat) {
	vec2 dir = uv - center;
	float radius = length(dir) * 2.0;
	float angle = atan(dir.y, dir.x) * 1.0/(3.1416 * 2.0);
	return mod(vec2(radius * zoom, angle * repeat), 1.0);
}

//Adapted from easings.net
float easeOutExpo(float x) {
	return 1.0 - pow(2.0, -10.0 * x);
}

float easeInExpo(float x) {
	return pow(2.0, 10.0 * x - 10.0);
}

float easeOutCirc(float x) {
	return sqrt(1.0 - pow(x - 1.0, 2.0));
}

float easeInCirc(float x) {
	return 1.0 - sqrt(1.0 - pow(x, 2.0));
}

float easeInOutSine(float x) {
	return -(cos(PI * x) - 1.0) / 2.0;
}

float easeOutQuad(float x) {
	return 1.0 - (1.0 - x) * (1.0 - x);
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

float get_opacity_noise(vec2 uv, float pgrs) {
	vec3 offset = pgrs * animate_opacity_noise;
	vec2 tUV = scale(uv,offset.z + scale_opacity_noise.x,offset.z + scale_opacity_noise.x);
	if (polarize_opacity_noise == true) {
		tUV = polar_coordinates(uv,vec2(0.5), (0.3 * offset.z) + scale_opacity_noise.y, 1.0);
	}
	return texture(opacity_noise,(tUV + offset.xy)).r * texture(opacity_noise_b,(tUV + offset.xy)).r;
}

void vertex() {
	// Called for every vertex the material is visible on.
	//if (billboard == true)  {
		//MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		//MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
		//MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	//}
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	
	LIFETIME = INSTANCE_CUSTOM.y;
	INDEX = float(INSTANCE_ID);
}

void fragment() {
	// Called for every pixel the material is visible on.
	//float raw_pgrs = get_progress();
	//if (use_lifetime == true) {
		//raw_pgrs = LIFETIME;
	//} else {
		//raw_pgrs = progress;
		//// Try setting raw_pgrs to one of these!:
		//// progress [Normal]
		//// abs(cos(progress * PI)) [Bounce]
		//// abs(cos(mod(TIME,1.0) * PI)) [Bounce Loop]
		//// abs(sin(TIME)) [Idle Loop]
		//// mod(TIME,1.0) [Alternate Loop]
	//}

	float pgrs = abs(direction-get_progress());
	//if (exponize_progress == true) {
		//pgrs = easeOutExpo(abs(direction-raw_pgrs));
	//} else {pgrs = abs(direction-raw_pgrs);}

	float ocr = mix(0.0,pulse_max_scale,easeOutExpo(pgrs));
	float icr = mix(0.0,clamp(pulse_max_scale - pulse_offset,-1.0,pulse_max_scale),easeOutQuad(pgrs)); //easeOutCirc(pgrs)

	vec3 outer_circle = vec3(circle(UV,ocr,outer_feather));
	vec3 inner_circle = vec3(circle(UV,icr,inner_feather));

	vec3 combined = abs(outer_circle - inner_circle);
	float alpha = smoothstep(ss_edges.x,ss_edges.y,clamp(combined.g - get_opacity_noise(UV,pgrs),0.0,1.0) * COLOR.a);

	vec2 cod = UV + (vec2((texture(col_ovr_distort,UV).r - 0.5) * 2.0) * col_ovr_dis_str);
	vec3 co = texture(color_overlay,cod).rgb * mix_strength + clamp((1.0 * (1.0-mix_strength)),0.0,1.0);
	
	if (mask == true) {
		vec4 mt = texture(world_masked_texture,world_position * wscale + (mask_scroll * TIME));
		COLOR.rgb = mt.rgb;
		alpha *= mt.a;
	} else {
		COLOR.rgb = (combined * mix_strength + clamp((1.0 * (1.0-mix_strength)),0.0,1.0)) * COLOR.rgb * modulate.rgb;
	}
	COLOR.rgb *= co;
	if (auto_fade == true) {
		COLOR.a *= alpha * abs(sin(pgrs * PI));
	} else {COLOR.a *= alpha;}
}
// A a static uniform for o noise scale

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}