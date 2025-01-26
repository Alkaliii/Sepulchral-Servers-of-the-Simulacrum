shader_type spatial;

// try and add a border to edges https://godotshaders.com/shader/2d-dissolve-with-burn-edge/

group_uniforms MASK;
uniform sampler2D mask_texture;
uniform sampler2D mask_mix: hint_default_white;
uniform float mm_str = 1.0;
uniform vec2 edge_ctrl = vec2(0.0,1.0);
group_uniforms;
group_uniforms TEXTURE;
uniform sampler2D main_texture : source_color;
uniform vec2 UVscale = vec2(1.0,1.0);
uniform vec4 main_texture_mix : source_color = vec4(1.0);
uniform sampler2D mtm_noise : source_color, hint_default_black;
uniform float mtm_str = 0.5;
uniform vec2 mtm_edge = vec2(0.0,1.0);
group_uniforms;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	float mask = 1.0 - texture(mask_texture, UV).r;
	mask *= (texture(mask_mix, UV).r * mm_str);
	vec4 projected_coords = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	
	vec4 mta = texture(main_texture, projected_coords.xz * UVscale);
	vec4 mtm = main_texture_mix;// * (texture(mtm_noise, UV).r * mtm_str);
	float mtmn = smoothstep(mtm_edge.x,mtm_edge.y,texture(mtm_noise, UV).r * mtm_str);
	
	vec4 final = mix(mta,mtm,mtmn);
	
	ALBEDO = final.rgb;
	ALPHA = smoothstep(edge_ctrl.x,edge_ctrl.y,mask);
}
