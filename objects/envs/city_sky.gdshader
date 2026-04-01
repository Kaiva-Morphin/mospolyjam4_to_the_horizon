shader_type sky;

render_mode use_half_res_pass;

uniform sampler2D source_panorama : filter_linear, source_color, hint_default_black;
uniform bool add_clouds = true;
uniform bool clouds_below = false;
uniform float cloud_scale : hint_range(0.0, 1.0, 0.01) = 0.25;
uniform float speed : hint_range(0.0, 0.25, 0.001) = 0.002;
uniform float cloud_dark : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float cloud_light : hint_range(0.0, 1.0, 0.01) = 0.3;
uniform float cloud_cover : hint_range(0.0, 1.0, 0.01) = 0.2;
uniform float cloud_alpha : hint_range(0.0, 10.0, 0.01) = 8.0;
uniform float sky_tint : hint_range(0.0, 1.0, 0.001) = 0.5;
uniform float height_offset : hint_range(0.0, 1.0, 0.001) = 0.2;
uniform float sky_contribution : hint_range(0.0, 1.0, 0.1) = 0.5;
//uniform float sky_contribution : 

const mat2 m = mat2(vec2( 1.6, 1.2), vec2(-1.2, 1.6));

vec2 hash( vec2 p ) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise( in vec2 p ) {
	const float K1 = 0.366025404; // (sqrt(3)-1)/2;
	const float K2 = 0.211324865; // (3-sqrt(3))/6;
	vec2 i = floor(p + (p.x + p.y)*K1);
	vec2 a = p - i + (i.x + i.y) * K2;
	vec2 o = (a.x > a.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec2 b = a - o + K2;
	vec2 c = a - 1.0 + 2.0 * K2;
	vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0 );
	vec3 n = h * h * h * h * vec3(dot(a, hash(i + 0.0)), dot(b, hash(i + o)), dot(c, hash(i + 1.0)));
	return dot(n, vec3(70.0));
}

float fbm(vec2 n) {
	float total = 0.0, amplitude = 0.1;
	for (int i = 0; i < 7; i++) {
		total += noise(n) * amplitude;
		n = m * n;
		amplitude *= 0.4;
	}
	return total;
}




//#define USE_TWINKLE

group_uniforms sky;
uniform vec3 sky_color: source_color = vec3(0.03, 0.05, 0.11);
uniform vec3 cloud_color: source_color = vec3(0.1, 0.0, 0.11);

group_uniforms stars;
uniform vec3 star_base_color: source_color = vec3(0.8, 1.0, 0.3);
uniform float star_hue_offset: hint_range(0., 1.) = 0.6;
uniform float star_intensity: hint_range(0., 0.2) = 0.08;
#ifdef USE_TWINKLE
uniform float star_twinkle_speed: hint_range(0.0, 2.0) = 0.8;
uniform float star_twinkle_intensity: hint_range(0.0, 1.0) = 0.2;
#endif

group_uniforms layers;
uniform float layer_scale: hint_range(0., 60.) = 20.;
uniform float layer_scale_step: hint_range(0., 40.) = 10.;
uniform int layers_count: hint_range(0, 12) = 3;


vec3 hue(vec3 input, float offset, int range_index) {
	// RGB to HSV
	vec4 k = vec4(0., -1./3., 2./3., -1.);
	vec4 p = mix(vec4(input.bg, k.wz), vec4(input.gb, k.xy), step(input.b, input.g));
	vec4 q = mix(vec4(p.xyw, input.r), vec4(input.r, p.yzx), step(p.x, input.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.e-10;
	vec3 hsv = vec3(abs(q.z + (q.w - q.y) / (6. * d + e)), d / (q.x + e), q.x);

	offset = (range_index == 0) ? offset / 360. : offset;
	float hue = hsv.x + offset;
	if (hue < 0.) {
		hsv.x = hue + 1.;
	} else if (hue > 1.) {
		hsv.x = hue - 1.;
	} else {
		hsv.x = hue;
	}

	// HSV to RGB
	vec4 k2 = vec4(1., 2./3., 1./3., 3.);
	vec3 p2 = abs(fract(hsv.xxx + k2.xyz) * 6. - k2.www);
	vec3 rgb = hsv.z * mix(k2.xxx, clamp(p2 - k2.xxx, 0., 1.), hsv.y);
	return rgb;
}

// Voronoi method credit:
// The MIT License
// Copyright © 2013 Inigo Quilez
// https://www.shadertoy.com/view/ldl3Dl

vec3 hash(vec3 x) {
	x = vec3(dot(x, vec3(127.1,311.7, 74.7)),
			 dot(x, vec3(269.5,183.3,246.1)),
			 dot(x, vec3(113.5,271.9,124.6)));
	return fract(sin(x) * 43758.5453123);
}

uniform sampler3D noise_tex : filter_linear, repeat_enable;

uniform sampler3D voronoi_tex : filter_linear, repeat_enable;

vec2 voronoi(in vec3 x){
	//vec3 p = floor(x);
	//vec3 f = fract(x);
	//
	//float res = 100.;
	//float id = 0.;
	//
	//for (float k = -1.; k <= 1.; k += 1.) {
		//for (float j = -1.; j <= 1.; j += 1.) {
			//for (float i = -1.; i <= 1.; i += 1.) {
				//vec3 b = vec3(i, j, k);
				//vec3 r = vec3(b) - f + hash(p + b);
				//float d = dot(r, r);
				//if (d < res) {
					//res = d;
					//id = dot(p + b, vec3(0., 57., 113.));
				//}
		    //}
		//}
	//}
	
	//return vec2(sqrt(res), 0.0);
	return vec2(texture(voronoi_tex, fract(x * 0.09)).r, 0.0);
}


void sky() {
	
	COLOR = sky_color;
	vec3 normal = normalize(EYEDIR);
	
	for (int i = 0; i < layers_count; i++) {
		vec3 pos = EYEDIR * (layer_scale + float(i) * layer_scale_step);
		vec2 layer = voronoi(pos);
		
		//vec3 rand = hash(vec3(layer.y));
		vec3 rand = texture(noise_tex, vec3(layer.y)).xyz;
		
		#ifdef USE_TWINKLE
			float twinkle = sin(TIME * PI * star_twinkle_speed + rand.x * TAU);
			twinkle *= star_twinkle_intensity;
			float star = smoothstep(star_intensity + star_intensity * twinkle, 0., layer.x);
		#else
			float star = smoothstep(star_intensity, 0., layer.x);
			//COLOR = vec3(layer.x);
		#endif
		
		vec3 star_color = star * hue((COLOR + star_base_color), rand.y * star_hue_offset, 1);
		
		float horizon_stars_fall_off = clamp(normal.y * 10.0, 0.0, 1.0);
		COLOR += star_color * horizon_stars_fall_off;
	}
	
	
	//COLOR = texture(source_panorama, SKY_COORDS).rgb;
	if(AT_CUBEMAP_PASS){
		COLOR *= sky_contribution;
    }else if(add_clouds){
		vec3 plane_intersect = normal / (normal.y + height_offset);
		
		if(clouds_below){
			plane_intersect = normal / -(normal.y - height_offset);
		}
		
		vec2 p = plane_intersect.xz;
		p.y *= -1.0;
		vec2 uv = p;
		
		float time = TIME * speed;
		float q = fbm(uv * cloud_scale * 0.5);
		
		//ridged noise shape
		float r = 0.0;
		uv *= cloud_scale;
		uv -= q - time;
		float weight = 0.8;
		for(int i = 0; i < 8; i++){
			r += abs(weight*noise( uv ));
			uv = m*uv + time;
			weight *= 0.7;
		}
		
		//noise shape
		float f = 0.0;
		uv = p;
		uv *= cloud_scale;
		uv -= q - time;
		weight = 0.7;
		for(int i = 0; i < 8; i++){
			f += weight*noise( uv );
			uv = m*uv + time;
			weight *= 0.6;
		}
		
		f *= r + f;
		
		//noise colour
		float c = 0.0;
		time = TIME * speed * 2.0;
		uv = p;
		uv *= cloud_scale * 2.0;
		uv -= q - time;
		weight = 0.4;
		for(int i = 0; i < 7; i++){
			c += weight*noise( uv );
			uv = m*uv + time;
			weight *= 0.6;
		}
		
		//noise ridge colour
		float c1 = 0.0;
		time = TIME * speed * 3.0;
		uv = p;
		uv *= cloud_scale * 3.0;
		uv -= q - time;
		weight = 0.4;
		for (int i = 0; i < 7; i++){
			c1 += abs(weight*noise( uv ));
			uv = m*uv + time;
			weight *= 0.6;
		}
		
		c += c1;
		
		vec3 skycolour = COLOR ;
		
		//vec3 skycolour = vec3(0.4, 0.0, 0.7);
		vec3 cloudcolour = vec3(1.1, 1.1, 0.9) * clamp((cloud_dark + cloud_light * c), 0.0, 1.0);
		float horizon_fall_off = max(normal.y, 0.0);
		
		if(clouds_below){
			horizon_fall_off = max(-normal.y, 0.0);
		}
		
		f = cloud_cover + cloud_alpha * f * r;
		
		vec3 res = 1.0 - mix(vec3(0.0, 0.0, 0.0), clamp(cloudcolour, 0.0, 1.0), clamp(f + c, 0.0, 1.0) * horizon_fall_off ) * 3.0;
		float re = clamp((res.r + res.g + res.b) / 3.0, 0.0, 1.0);
		vec3 result = mix(vec3(re) * clamp(skycolour, 0.0, 1.0), clamp(sky_tint * vec3(re) * clamp(skycolour, 0.0, 1.0) + cloudcolour, 0.0, 1.0) * cloud_color, clamp(f + c, 0.0, 1.0) * horizon_fall_off );
		// Convert the color to black and white.
		//result = vec3(horizon_stars_fall_off);
		COLOR = result; // vec3(result.r + result.g + result.b);
	}
}


