// modified from GDQuest's Transition Shader in Godot (tutorial)(Oct 17, 2018)(https://www.youtube.com/watch?v=K9FBpJ2Ypb4)
// Uses original color instead of custom mask
shader_type canvas_item;
render_mode unshaded;

uniform float value: hint_range(0.0, 1.0, 0.01);
uniform float smooth_size: hint_range(0.0, 1.0, 0.0001);
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	float alpha;
	alpha = 1.0 - smoothstep(value, value + smooth_size, COLOR.r * (1.0 - smooth_size) + smooth_size);
	alpha *= COLOR.a;
	COLOR.rgb = color.rgb;
	COLOR = vec4(color.rgb, COLOR.a * alpha);
}