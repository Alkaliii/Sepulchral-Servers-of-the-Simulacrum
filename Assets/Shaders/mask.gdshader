shader_type canvas_item;

uniform sampler2D mask : hint_default_white, filter_linear_mipmap;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR.rgb = texture(TEXTURE,UV).rgb;
	COLOR.a = texture(mask,UV).r;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
