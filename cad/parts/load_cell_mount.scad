// A basic mount to attach a load cell to an OpenBeam strut
// The load cell is at 90 degrees to the strut, with its hole
// in line with the centre of the strut.
// This is designed for Phidgets 3132, 3133 and 3134 load cells

holes = [[5, 40], [3, 30], [3, 22.5]];
cell_w = 12;
mount_w = cell_w + 20;
ob = 15; //openbeam size
t = 6; //thickness of mount
$fn=16;

difference(){
    union(){
        hull(){
            for(h=holes) translate([0,h[1],6]) cube(12, center=true);
            //for(h=holes) translate([0,h[1],ob+t-6]) cube(12, center=true); //uncomment for tension mount
            
            translate([-mount_w/2,ob/2+1,0]) cube([mount_w, 1, 12]);
            translate([-mount_w/2, ob/2, ob-5+t]) cube([mount_w, 2, 5]);
        }
        translate([-mount_w/2, -ob/2, 0]) cube([mount_w, ob+2, t]);
    }
    
    //mounting holes
    //translate([0,0,ob+t]) mirror([0,0,1]) //uncomment for tension
    union(){
        for(h=holes) translate([0,h[1],-99]) cylinder(d=h[0]*1.1, h=999);
        hull() for(h=holes){
            translate([0,h[1],t]) cylinder(r=h[0]*1.3, h=999);
        }
    }
    
    for(d=[-1,1]) translate([d*(cell_w/2+5), 0, -99]) cylinder(d=3*1.1,h=999);
        
    //this allows the "compression" version to do tension too
    translate([0, ob/2+t, ob/2+t]) rotate([-90,0,0]){
        translate([0,0,-99]) cylinder(d=3*1.1, h=99+1);
        cylinder(r=3*1.3, h=holes[0][1]-ob/2-t);
    }
}
    