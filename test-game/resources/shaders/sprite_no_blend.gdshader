shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    if (tex_color.a < 0.1) {
        discard;
    }
    // 알파를 미리 곱해서 출력 (premultiplied alpha)
    COLOR = vec4(tex_color.rgb * tex_color.a, tex_color.a);
}
