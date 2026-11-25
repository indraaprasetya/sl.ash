shader_type canvas_item;

uniform vec4 element_color : source_color = vec4(0.35, 0.88, 1.0, 1.0);
uniform float glow_strength : hint_range(0.0, 2.0) = 0.0;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool dark_outline = false;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 modulated = COLOR;
	vec2 px = TEXTURE_PIXEL_SIZE;

	if (tex.a < 0.1) {
		float n4 = 0.0;
		n4 = max(n4, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
		n4 = max(n4, texture(TEXTURE, UV - vec2(px.x, 0.0)).a);
		n4 = max(n4, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
		n4 = max(n4, texture(TEXTURE, UV - vec2(0.0, px.y)).a);
		if (dark_outline) {
			if (n4 > 0.5) {
				vec3 outline_rgb = mix(vec3(0.047, 0.055, 0.086), element_color.rgb * 0.45, clamp((glow_strength - 0.8) * 0.5, 0.0, 0.45));
				COLOR = vec4(outline_rgb, 1.0);
			} else if (glow_strength > 0.01) {
				float n_outer = 0.0;
				n_outer = max(n_outer, texture(TEXTURE, UV + vec2(px.x, px.y)).a);
				n_outer = max(n_outer, texture(TEXTURE, UV + vec2(-px.x, px.y)).a);
				n_outer = max(n_outer, texture(TEXTURE, UV + vec2(px.x, -px.y)).a);
				n_outer = max(n_outer, texture(TEXTURE, UV + vec2(-px.x, -px.y)).a);
				n_outer = max(n_outer, texture(TEXTURE, UV + vec2(px.x * 2.0, 0.0)).a);
				n_outer = max(n_outer, texture(TEXTURE, UV - vec2(px.x * 2.0, 0.0)).a);
				n_outer = max(n_outer, texture(TEXTURE, UV + vec2(0.0, px.y * 2.0)).a);
				n_outer = max(n_outer, texture(TEXTURE, UV - vec2(0.0, px.y * 2.0)).a);
				if (n_outer > 0.5) {
					COLOR = vec4(element_color.rgb, clamp(glow_strength * 0.55, 0.0, 0.85));
				} else {
					COLOR = vec4(0.0);
				}
			} else {
				COLOR = vec4(0.0);
			}
		} else if (glow_strength > 0.01 && n4 > 0.5) {
			COLOR = vec4(element_color.rgb, clamp(glow_strength * 0.85, 0.0, 1.0));
		} else {
			COLOR = vec4(0.0);
		}
	} else {
		vec3 col = modulated.rgb;
		if (glow_strength > 0.15) {
			col = mix(col, element_color.rgb, clamp(glow_strength * 0.14, 0.0, 0.35));
		}
		col = mix(col, flash_color.rgb, flash_amount);
		COLOR = vec4(col, modulated.a);
	}
}
