//modified : https://godotshaders.com/shader/slipgate-texture-warp/
shader_type canvas_item;
//render_mode unshaded, depth_draw_always; // NO LIGHTING!, "depth_draw_always" to 'fix' Z-ordering

uniform bool polar_coordinates = false;
uniform vec2 polar_center = vec2(0.5);
uniform float fisheye_amt = 1.1;
uniform int fbm_octaves = 5;
uniform float center_bias = 1.5;
uniform float swirl_str = 0.02;
uniform int swirl_arms = 1;
uniform float swirl_size = 10.0;
uniform vec2 marble_multipliers = vec2(2.5);
//uniform sampler2D edge_blend : source_color, filter_linear_mipmap, repeat_enable;
//uniform sampler2D radial_mask : source_color, filter_linear_mipmap, repeat_enable;
uniform float rotation_speed = 1.0;
uniform float rotation_speed_b = 1.0;
uniform vec2 time_scale = vec2(1.0);
uniform vec2 time_scale_b = vec2(1.0);
uniform vec2 edges = vec2(0.0,1.0);
uniform sampler2D color_lookup : source_color, hint_default_black;
uniform bool use_color_lookup = false;

float swirl(vec2 uv, float size, int arms) {
	float angle = atan(-uv.y + 0.5, uv.x - 0.5) ;
	float len = length(uv - vec2(0.5, 0.5));
	
	return sin(len * size + angle * float(arms) - (TIME * rotation_speed_b));
}

vec2 polar_coords(vec2 uv, vec2 center, float zoom, float repeat){
	vec2 dir = uv - center;
	float radius = length(dir) * 2.0;
	float angle = atan(dir.y , dir.x) * 1.0 / (PI * 2.0);
	return mod(vec2(radius * zoom, angle * repeat), 1.0);
}

vec2 fisheye(vec2 p, float screen_proportion, float effect_amount) {
	//source: https://godotshaders.com/shader/fisheye-anti-fisheye-camera-effect/
	float prop = screen_proportion;
	//center coords
	vec2 m = vec2(0.5, 0.5 / prop);
	//vector from center to current fragment
	vec2 d = p - m;
	// distance of pixel from center
	float r = sqrt(dot(d, d)); 
	
	float power = effect_amount;

	//radius of 1:1 effect
	float bind;
	
	//stick to borders
	if (power > 0.0) 
		bind = sqrt(dot(m, m));
	else {
		if (prop < 1.0) 
			bind = m.x; 
		else 
			bind = m.y;
	}
	
	vec2 uv;
	//fisheye
	if (power > 0.0)
		uv = m + normalize(d) * tan(r * power) * bind / tan( bind * power);
	//antifisheye
	else if (power < 0.0)
		uv = m + normalize(d) * atan(r * -power * 10.0) * bind / atan(-power * bind * 10.0);
	//no effect for power = 1.0
	else
		uv = p;
	uv.y *= prop;
	return uv;
}

float random(vec2 uv) {
	return fract(sin(dot(uv.xy,
		vec2(12.9898,78.233))) *
			43758.5453123);
}

float noise(vec2 uv) {
	vec2 uv_index = floor(uv);
	vec2 uv_fract = fract(uv);
	
	// Four corners in 2D of a tile
	float a = random(uv_index);
	float b = random(uv_index + vec2(1.0, 0.0));
	float c = random(uv_index + vec2(0.0, 1.0));
	float d = random(uv_index + vec2(1.0, 1.0));
	
	vec2 blur = smoothstep(0.0, 1.0, uv_fract);
	
	return mix(a, b, blur.x) +
			(c - a) * blur.y * (1.0 - blur.x) +
			(d - b) * blur.x * blur.y;
}

float fbm(vec2 uv) {
	int octaves = fbm_octaves;
	float amplitude = 0.7;
	float frequency = 1.0;
	float value = 0.0;
	
	for(int i = 0; i < octaves; i++) {
		value += amplitude * noise(frequency * uv);
		amplitude *= 0.5;
		frequency *= 2.0;
	}
	return value;
}

vec2 rotate(vec2 uv, vec2 pivot, float angle) {
	mat2 rotation = mat2(vec2(sin(angle), -cos(angle)),
						vec2(cos(angle), sin(angle)));
	
	uv -= pivot;
	uv = uv * rotation;
	uv += pivot;
	return uv;
}

float warp_pattern(vec2 p) {
	vec2 q = vec2(fbm(p + vec2(1.0)),
	fbm(p + vec2(5.2,8.3))) - sin(TIME * time_scale_b);
	
	vec2 r = vec2(fbm(p + marble_multipliers.x*q + vec2(9.7,9.2)),
	fbm(p + marble_multipliers.y*q + vec2(9.3,2.8)));
	
	return fbm(p + 4.0*r) + (1.0-length(p - 2.0) * center_bias);
}

void fragment() {
	vec2 uv = vec2(0.0);
	float prop = (1.0 / SCREEN_PIXEL_SIZE).x / (1.0 / SCREEN_PIXEL_SIZE).x;
	float swirl_distort = ((swirl(UV,swirl_size,swirl_arms) * warp_pattern(UV))-0.5) * 2.0;
	
	if (polar_coordinates == true){
		uv = polar_coords(rotate(fisheye(UV,prop,fisheye_amt),vec2(0.5),TIME * (0.2 * rotation_speed)),polar_center,0.6,1.0) + (swirl_distort * swirl_str);
	} else {
		uv = rotate(fisheye(UV + (swirl_distort * swirl_str),prop,fisheye_amt),vec2(0.5),TIME * (0.2 * rotation_speed));
		//uv = rotate(swirl2(fisheye(UV,prop,fisheye_amt),-100,0,.9,0.1),vec2(0.5),TIME * (0.2 * rotation_speed));
	}
	
	// TODO: ADD NOISE SAMPLER INSTEAD OF USING TRIG?
	
	// TWEAK THE COEFFS AND/OR EQUATION FOR A DIFFERENT WARP PATTERN
	uv.x += sin(uv.y * 1.54 * PI + (TIME * time_scale.y)) * cos(uv.y * 1.31 * PI + (-TIME * time_scale.x)) * 0.1; 
	uv.y += cos(uv.x * 1.74 * PI + (TIME * time_scale.y)) * -sin(uv.y * 1.64 * PI + (-TIME * time_scale.x)) * 0.1; 
	
	//vec4 color = texture(texture_albedo, uv * 2.0);
	vec4 color = vec4(warp_pattern(uv * 4.0));
	
	//if (polar_coordinates == true) {
		////color *= texture(edge_blend,polar_coords(rotate(UV,vec2(0.5),TIME * (0.2 * rotation_speed)),vec2(0.5),1.0,1.0));
		//color *= 1.0-(length(UV - 0.5) * 1.5);
	//}
	
	//color *= texture(radial_mask,UV);
	if (use_color_lookup == true) {
		COLOR.rgb = texture(color_lookup,vec2(smoothstep(edges.x,edges.y,color.xyz).r,0)).rgb;
	} else {
		COLOR.rgb = smoothstep(edges.x,edges.y,color.xyz);
	}
	
	//COLOR.rgb *= 1.0-(length(UV - 0.5) * 1.5);
	//COLOR.rgb = vec3(uv,1.0);
	//COLOR.a *= color.a;
}