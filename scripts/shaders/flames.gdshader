shader_type canvas_item;

void fragment(){
	vec2 distortedUV = UV;
	if (distortedUV.y < 0.7) {
		distortedUV.x += sin(distortedUV.y * 7.5 + TIME * 2.0) * 0.05;
	}
	COLOR = texture(TEXTURE, distortedUV);
}