shader_type canvas_item;
uniform vec4 tint : source_color=vec4(.45,.65,.68,1.);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){vec2 p=UV*vec2(5.,3.)+vec2(TIME*.045,-TIME*.012);float n=noise(p)+.5*noise(p*2.1);float a=smoothstep(.4,1.1,n)*smoothstep(.48,.95,UV.y)*.15;COLOR=vec4(tint.rgb,a);}
