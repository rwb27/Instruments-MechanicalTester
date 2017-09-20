$fn=16;
difference(){
    translate([-6,0,0]) cube([12,15,3]);
    
    translate([0,4,-1]) cylinder(d=3.6,h=99);
    translate([0,4+7.5,-1]) cylinder(d=3.6,h=99);
}