shader_type canvas_item;

// try and add a border to edges https://godotshaders.com/shader/2d-dissolve-with-burn-edge/

group_uniforms MASK;
uniform sampler2D mask_texture;
uniform sampler2D mask_mix: hint_default_white;
uniform float mm_str = 1.0;
uniform vec2 edge_ctrl = vec2(0.0,1.0);
uniform bool polar = false;
group_uniforms;
group_uniforms TEXTUREE;
uniform sampler2D main_texture : source_color,repeat_enable;
uniform vec2 UVscale = vec2(1.0,1.0); //9 for 64px texture, 6.75 for 128px
uniform vec4 main_texture_mix : source_color = vec4(1.0);
uniform sampler2D mtm_noise : source_color, hint_default_black;
uniform float mtm_str = 0.5;
uniform vec2 mtm_edge = vec2(0.0,1.0);
group_uniforms;

varying vec2 world_position;

vec2 polar_coords(vec2 uv, vec2 center, float zoom, float repeat){
	vec2 dir = uv - center;
	float radius = length(dir) * 2.0;
	float angle = atan(dir.y , dir.x) * 1.0 / (PI * 2.0);
	return mod(vec2(radius * zoom, angle * repeat), 1.0);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 uv = UV;
	if (polar == true) {
		uv = polar_coords(UV,vec2(0.5),1.0,1.0);
	}
	
	float mask = 1.0 - texture(mask_texture, uv).r;
	mask *= (texture(mask_mix, uv).r * mm_str);
	vec2 projected_coords = uv * UVscale;//world_position;//INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	
	vec4 mta = texture(main_texture, projected_coords * UVscale);
	vec4 mtm = main_texture_mix;// * (texture(mtm_noise, UV).r * mtm_str);
	float mtmn = smoothstep(mtm_edge.x,mtm_edge.y,texture(mtm_noise, UV).r * mtm_str);
	
	vec4 final = mix(mta,mtm,mtmn);
	
	COLOR.rgb = final.rgb;
	COLOR.a = smoothstep(edge_ctrl.x,edge_ctrl.y,mask * mta.a);
}
