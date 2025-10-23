//
// Rectangular/Square Welded Table Frame – OpenSCAD (FreeCAD‑friendly)
// - 1.125" square tubing (wall param), butt joints
// - Plywood support tabs: 1" x 1" x tab_thk, 2 per side @ 5" from each end
// - Legs 32" long
// - Perimeter stretchers with end overlap into legs
// - BOM echo block with lengths and weight
// Author: M365 Copilot (for Kevin Gordon)
//

unit = 25.4;                      // mm per inch (set to 1 for inch-native display)
function U(x) = x * unit;

eps = 0.01;                       // small overlap (mm) for boolean stability
$fa = 2; $fs = 0.5;

// ---------------- Parameters ----------------

// Size (outside dimensions)
outer_x_in = 48;                  // X (width/long direction); set equal to Y for square
outer_y_in = 22;                  // Y (depth/short direction)

// Tube spec
tube_od_in = 1.125;               // outside dimension of square tube
wall_in    = 0.100;               // wall thickness (e.g., 0.100 or 0.125)

// Legs
add_legs   = true;
leg_len_in = 32.0;

// Stretchers (perimeter between legs)
add_stretchers                 = true;
stretcher_bottom_from_floor_in = 6.0;   // bottom of stretcher above floor
stretcher_gap_in               = 0.00;  // length relief (each rail loses 2*gap total)
stretcher_attach_overlap_in    = 0.25;  // each end penetrates into leg by this amount

// Plywood & tabs (support ledges)
add_tabs          = true;
ply_thick_in      = 23/32;              // 0.71875 typical 3/4" plywood
ply_clear_in      = 0.02;               // vertical install clearance
recess_in         = 0.00;               // 0 = flush top; set 0.125 to recess 1/8"

tab_len_in        = 1.00;               // 1" along side
tab_depth_in      = 1.00;               // 1" inward
tab_thk_in        = 0.125;              // 1/8" tabs (set 0.100 if matching .100" wall)
tab_edge_margin_in = 5.00;              // centers 5" from each end; exactly 2 tabs per side

tabs_with_holes   = false;              // optional screw holes in tabs
hole_dia_in       = 0.188;              // ~3/16"
hole_inset_in     = 0.50;               // hole center from wall (0.5" centers in 1"-deep tab)

// BOM / weight echo
do_bom_echo             = true;
material_name           = "Steel";       // label only
material_density_lb_in3 = 0.283;         // Steel ~0.283, Aluminum ~0.0975

// ---------------- Derived (model units) ----------------

tube_od  = U(tube_od_in);
wall     = U(wall_in);

outer_x  = U(outer_x_in);
outer_y  = U(outer_y_in);
inner_x  = outer_x - 2 * tube_od;
inner_y  = outer_y - 2 * tube_od;

leg_len  = U(leg_len_in);

stretcher_bottom_from_floor = U(stretcher_bottom_from_floor_in);
stretcher_gap               = U(stretcher_gap_in);
stretcher_attach_overlap    = U(stretcher_attach_overlap_in);

ply_thick = U(ply_thick_in);
ply_clear = U(ply_clear_in);
recess    = U(recess_in);

tab_len   = U(tab_len_in);
tab_depth = U(tab_depth_in);
tab_thk   = U(tab_thk_in);
tab_margin = U(tab_edge_margin_in);

hole_dia  = U(hole_dia_in);
hole_inset = U(hole_inset_in);

// ---------------- Geometry Modules ----------------

// Hollow square tube along X
module square_tube_x(L, od=tube_od, w=wall) {
    difference() {
        translate([-L/2, -od/2, -od/2]) cube([L, od, od], center=false);
        // hollow
        translate([-L/2 - eps, -(od/2 - w), -(od/2 - w)])
            cube([L + 2*eps, od - 2*w, od - 2*w], center=false);
    }
}

// Hollow square tube along Z; TOP at z=0; extends downward by L
module square_tube_z(L, od=tube_od, w=wall) {
    difference() {
        translate([-od/2, -od/2, -L]) cube([od, od, L], center=false);
        translate([-(od/2 - w), -(od/2 - w), -L - eps])
            cube([od - 2*w, od - 2*w, L + 2*eps], center=false);
    }
}

// Rectangular butt-jointed frame (two X rails full length, two Y rails between)
module frame_rect(ox=outer_x, oy=outer_y, od=tube_od, w=wall, gap=0) {
    // X rails (full outer_x) at ±Y
    translate([0,  (oy/2 - od/2), 0]) square_tube_x(ox + eps, od, w);
    translate([0, -(oy/2 - od/2), 0]) square_tube_x(ox + eps, od, w);

    // Y rails (length outer_y - 2*od) at ±X
    Ly = oy - 2*od - gap;
    translate([ (ox/2 - od/2), 0, 0]) rotate([0,0,90]) square_tube_x(Ly + eps, od, w);
    translate([-(ox/2 - od/2), 0, 0]) rotate([0,0,90]) square_tube_x(Ly + eps, od, w);
}

// Four legs at outer corners; top of leg flush to frame bottom (z = -od/2)
module legs_four_rect(ox=outer_x, oy=outer_y, od=tube_od, L=leg_len) {
    cx = ox/2 - od/2;
    cy = oy/2 - od/2;
    translate([ +cx, +cy, -od/2 ]) square_tube_z(L, od);
    translate([ -cx, +cy, -od/2 ]) square_tube_z(L, od);
    translate([ -cx, -cy, -od/2 ]) square_tube_z(L, od);
    translate([ +cx, -cy, -od/2 ]) square_tube_z(L, od);
}

// Perimeter stretchers with end overlap into legs
module stretchers_perimeter_rect(ox=outer_x, oy=outer_y, od=tube_od, w=wall,
                                 legL=leg_len,
                                 bottom_from_floor=stretcher_bottom_from_floor,
                                 end_gap=stretcher_gap,
                                 end_overlap=stretcher_attach_overlap) {
    // Leg bottom and stretcher Z
    z_leg_bottom = -od/2 - legL;
    z_bottom     =  z_leg_bottom + bottom_from_floor;
    z_center     =  z_bottom + od/2;

    // Inner spans
    inner_span_x = ox - 2*od;
    inner_span_y = oy - 2*od;

    // Rail lengths (embed into legs)
    Lx = inner_span_x - 2*end_gap + 2*end_overlap;
    Ly = inner_span_y - 2*end_gap + 2*end_overlap;

    // Offsets so stretcher OUTER face is co-planar with leg INNER face plane
    offY = oy/2 - 1.5*od;   // for X-running rails (front/back)
    offX = ox/2 - 1.5*od;   // for Y-running rails (left/right)

    // Front (+Y), Back (−Y)
    translate([ 0, +offY, z_center ]) square_tube_x(Lx, od, w);
    translate([ 0, -offY, z_center ]) square_tube_x(Lx, od, w);

    // Right (+X), Left (−X)
    translate([ +offX, 0, z_center ]) rotate([0,0,90]) square_tube_x(Ly, od, w);
    translate([ -offX, 0, z_center ]) rotate([0,0,90]) square_tube_x(Ly, od, w);
}

// Tabs: 2 per side, centers 5" from each end (rectangular-aware), plus optional holes
module tabs_rect_all_sides(ix=inner_x, iy=inner_y, od=tube_od) {
    if (add_tabs) {
        // Vertical placement: top of tabs meets plywood underside
        z_top =  +od/2 - recess - ply_thick - ply_clear;
        z0    =  z_top - tab_thk;

        // Centers ±(span/2 − margin)
        px = ix/2 - tab_margin;   // along X for top/bottom sides
        py = iy/2 - tab_margin;   // along Y for left/right sides

        // Right wall (+X): extend −X
        translate([ +ix/2 - tab_depth, -py - tab_len/2, z0 ]) cube([ tab_depth, tab_len, tab_thk ], center=false);
        translate([ +ix/2 - tab_depth, +py - tab_len/2, z0 ]) cube([ tab_depth, tab_len, tab_thk ], center=false);

        // Left wall (−X): extend +X
        translate([ -ix/2, -py - tab_len/2, z0 ]) cube([ tab_depth, tab_len, tab_thk ], center=false);
        translate([ -ix/2, +py - tab_len/2, z0 ]) cube([ tab_depth, tab_len, tab_thk ], center=false);

        // Top wall (+Y): extend −Y
        translate([ -px - tab_len/2, +iy/2 - tab_depth, z0 ]) cube([ tab_len, tab_depth, tab_thk ], center=false);
        translate([ +px - tab_len/2, +iy/2 - tab_depth, z0 ]) cube([ tab_len, tab_depth, tab_thk ], center=false);

        // Bottom wall (−Y): extend +Y
        translate([ -px - tab_len/2, -iy/2, z0 ]) cube([ tab_len, tab_depth, tab_thk ], center=false);
        translate([ +px - tab_len/2, -iy/2, z0 ]) cube([ tab_len, tab_depth, tab_thk ], center=false);
    }
}

module tab_holes_rect(ix=inner_x, iy=inner_y, od=tube_od) {
    if (add_tabs && tabs_with_holes) {
        z_top =  +od/2 - recess - ply_thick - ply_clear;
        z0    =  z_top - tab_thk;

        px = ix/2 - tab_margin;
        py = iy/2 - tab_margin;

        // Right/Left (vary Y)
        translate([ +ix/2 - hole_inset, -py, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
        translate([ +ix/2 - hole_inset, +py, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
        translate([ -ix/2 + hole_inset, -py, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
        translate([ -ix/2 + hole_inset, +py, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);

        // Top/Bottom (vary X)
        translate([ -px, +iy/2 - hole_inset, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
        translate([ +px, +iy/2 - hole_inset, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
        translate([ -px, -iy/2 + hole_inset, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
        translate([ +px, -iy/2 + hole_inset, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
    }
}

// ---------------- Top-level CSG ----------------

render() difference() {
    union() {
        // Frame
        frame_rect(outer_x, outer_y, tube_od, wall, 0);

        // Tabs
        tabs_rect_all_sides(inner_x, inner_y, tube_od);

        // Legs
        if (add_legs) legs_four_rect(outer_x, outer_y, tube_od, leg_len);

        // Stretchers
        if (add_stretchers)
            stretchers_perimeter_rect(outer_x, outer_y, tube_od, wall,
                                      leg_len,
                                      stretcher_bottom_from_floor,
                                      stretcher_gap,
                                      stretcher_attach_overlap);
    }
    // Tab holes (optional)
    tab_holes_rect(inner_x, inner_y, tube_od);
}

// ---------------- BOM / Weight Echo ----------------

if (do_bom_echo) {
    // Per-piece lengths in inches
    frame_long_len_in = outer_x_in;
    frame_short_len_in = outer_y_in - 2 * tube_od_in;
    stretcher_x_len_in = (outer_x_in - 2 * tube_od_in) - 2*stretcher_gap_in + 2*stretcher_attach_overlap_in;
    stretcher_y_len_in = (outer_y_in - 2 * tube_od_in) - 2*stretcher_gap_in + 2*stretcher_attach_overlap_in;

    // Quantities
    q_frame_long = 2;
    q_frame_short = 2;
    q_leg = 4;
    q_stretch_x = 2;
    q_stretch_y = 2;
    q_tabs = 8;

    // Cross-section area (in^2) for hollow square tube
    inner_side_in = tube_od_in - 2*wall_in;
    xsec_area_in2 = tube_od_in*tube_od_in - inner_side_in*inner_side_in;

    // Total lengths (in)
    total_len_in = q_frame_long*frame_long_len_in +
                   q_frame_short*frame_short_len_in +
                   q_leg*leg_len_in +
                   q_stretch_x*stretcher_x_len_in +
                   q_stretch_y*stretcher_y_len_in;

    // Tube weight (lb)
    tube_weight_lb = xsec_area_in2 * total_len_in * material_density_lb_in3;

    // Tabs weight (lb)
    tab_vol_in3 = 1.0 * 1.0 * tab_thk_in;   // each 1" x 1" x tab_thk
    tabs_weight_lb = q_tabs * tab_vol_in3 * material_density_lb_in3;

    total_weight_lb = tube_weight_lb + tabs_weight_lb;

    // Echo in CSV-like lines
    echo(str("BOM, material=", material_name, ", density_lb_in3=", material_density_lb_in3));
    echo(str("BOM, frame_long, qty=", q_frame_long, ", len_in=", frame_long_len_in, ", stock=1.125x", wall_in, " sq tube"));
    echo(str("BOM, frame_short, qty=", q_frame_short, ", len_in=", frame_short_len_in, ", stock=1.125x", wall_in, " sq tube"));
    echo(str("BOM, leg, qty=", q_leg, ", len_in=", leg_len_in, ", stock=1.125x", wall_in, " sq tube"));
    echo(str("BOM, stretcher_x, qty=", q_stretch_x, ", len_in=", stretcher_x_len_in, ", stock=1.125x", wall_in, " sq tube"));
    echo(str("BOM, stretcher_y, qty=", q_stretch_y, ", len_in=", stretcher_y_len_in, ", stock=1.125x", wall_in, " sq tube"));
    echo(str("BOM, tabs, qty=", q_tabs, ", size_in=1x1x", tab_thk_in));

    echo(str("BOM_TOTAL, tube_len_in=", total_len_in, ", tube_len_ft=", total_len_in/12.0));
    echo(str("BOM_TOTAL, tube_weight_lb=", tube_weight_lb, ", tabs_weight_lb=", tabs_weight_lb, ", total_weight_lb=", total_weight_lb));

    // Helpful sanity echoes
    echo(str("INFO, inner_opening_x_in=", (inner_x/25.4), ", inner_opening_y_in=", (inner_y/25.4)));
}