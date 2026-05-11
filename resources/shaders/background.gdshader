shader_type canvas_item;

uniform vec4 color_a : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 color_b : source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform float speed : hint_range(0.1, 5.0) = 1.0;
uniform float gradient_direction : hint_range(0.0, 1.0) = 1.0; // 0 = горизонталь, 1 = вертикаль

void fragment() {
    // Плавный пинг-понг между двумя цветами по времени
    float t = (sin(TIME * speed) + 1.0) / 2.0;
    vec4 base_color = mix(color_a, color_b, t);

    // Чёрный градиент поверх (от прозрачного до чёрного)
    float grad = mix(0.0, 1.0, gradient_direction == 1.0 ? UV.y : UV.x);
    vec4 black_grad = vec4(0.0, 0.0, 0.0, grad);

    // Накладываем градиент поверх цвета
    vec4 final_color = mix(base_color, vec4(0.0, 0.0, 0.0, 1.0), black_grad.a);
    final_color.a = base_color.a;

    COLOR = final_color;
}