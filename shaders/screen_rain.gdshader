shader_type canvas_item;
uniform vec4 tint : source_color = vec4(0.1,1.0,0.75,1.0);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 vec2 uv=UV;float glitch=step(.98,hash(vec2(floor(TIME*8.0),floor(uv.y*18.0))));
 uv.x+=glitch*.05;vec2 cell=vec2(uv.x*24.,uv.y*15.+TIME*mix(1.,4.,hash(vec2(floor(uv.x*24.),1.))));
 vec2 id=floor(cell);vec2 f=fract(cell);float code=hash(vec2(id.x,floor(TIME*2.)+id.y));
 float glyph=step(.24,f.x)*step(f.x,.78)*step(.17,f.y)*step(f.y,.83);
 glyph*=max(step(abs(f.x-.5),.06),step(abs(f.y-.5),.08)+step(code,.35)*step(abs(f.y-.25),.06));
 float trail=pow(fract(id.y*.067+hash(vec2(id.x,3.))+TIME*.17),3.);
 float scan=.85+.15*sin(uv.y*500.);COLOR=vec4(tint.rgb*(.07+glyph*trail)*scan, .86);
}
