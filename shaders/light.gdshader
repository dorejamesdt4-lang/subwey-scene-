shader_type canvas_item;
uniform vec4 tint:source_color=vec4(.2,1.,.8,1.);
uniform float seed=0.;
void fragment(){float r=length((UV-.5)*2.);float pulse=.75+.15*sin(TIME*1.8+seed);float flicker=step(.06,fract(sin(floor(TIME*9.+seed))*43758.));COLOR=vec4(tint.rgb,pow(max(0.,1.-r),3.)*.22*pulse*flicker);}
