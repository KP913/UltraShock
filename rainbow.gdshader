shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}



vec3 hsv2rgb(vec3 _c) {
    vec4 _K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 _p = abs(fract(_c.xxx + _K.xyz) * 6.0 - _K.www);
    return _c.z * mix(_K.xxx, clamp(_p - _K.xxx, 0.0, 1.0), _c.y);
}

vec4 rgb2hsv(vec4 rgb) { //Converts RGB values to HSV
float r = rgb.r;
float g = rgb.g;
float b = rgb.b;

float cmax = max(r,max(g,b));
float cmin = min(r,min(g,b));
float delta = cmax - cmin;

float h = 0.; //hue

if (delta > 0.){
	if (cmax == r){
		h = (g-b)/delta;
		h = mod(h,6.);
	} else if (cmax == g){
		h = ((b - r) / delta) + 2.;
	} else {
		h = ((r-g)/delta) + 4.;
	}
	h = h * 60.;
}
float s = 0.; //saturation
if (cmax > 0.){
	s = delta / cmax;
}

return vec4(h,s,cmax,rgb.a); // Keep original alpha value

}

void fragment() {
	COLOR = texture(TEXTURE,UV);
	COLOR.rgb = mix(vec3((COLOR.r + COLOR.g + COLOR.b) / 3.0),  vec3(0.299 * COLOR.r + 0.587 * COLOR.g + 0.114 * COLOR.b), 0);
	vec3 c = hsv2rgb(vec3((UV.x*6.+UV.y*4.)/1.-TIME/2.,1.,2.));
	COLOR.r *= c.x;
	COLOR.g *= c.y;
	COLOR.b *= c.z;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
