shader_type canvas_item;


uniform int num_colors: hint_range(2, 19) = 8;
uniform sampler2D PALETTE_TEXTURE: hint_default_black;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable,filter_nearest;
uniform float pixel_size : hint_range(1.0, 16.0, 1.0) = 1.0;
uniform int excluded_colors: hint_range(1, 10) = 4;
uniform sampler2D EXCLUDED_TEXTURE: hint_default_black;


vec3 palette_limiter (in vec3 albedo) {
	float estimation_cutoff = 0.001;
	vec3 closest_color;
	float min_dist = 2.0;
	float n = float(num_colors);

	for (int i=0; i<num_colors; i++ ){
		float index = 1.000 / (2.000 * n) + float(i) / n;
		vec3 index_color = texture(PALETTE_TEXTURE, vec2(index, 0.5)).rgb;
		float dist = length(index_color - albedo);
		if (dist < min_dist) {
			min_dist = dist;
			closest_color = index_color;
			if (min_dist < estimation_cutoff) {
				return closest_color;
			}
		}
	}
	return closest_color;
}

void fragment() {
	float x = FRAGCOORD.x - mod(FRAGCOORD.x, pixel_size);
	float y = FRAGCOORD.y - mod(FRAGCOORD.y, pixel_size);
	COLOR = texture(SCREEN_TEXTURE, vec2(x, y) * SCREEN_PIXEL_SIZE);

	float n = float(excluded_colors);
	bool excluded = false;
	for (int i=0; i<excluded_colors; i++ ){
		float index = 1.000 / (2.000 * n) + float(i) / n;
		vec3 index_color = texture(EXCLUDED_TEXTURE, vec2(index, 0.5)).rgb;
		if (index_color.rgb == COLOR.rgb) {
			excluded = true;
		}
	}

	if (!excluded) {
		COLOR.rgb = palette_limiter(COLOR.rgb);
	}
}
