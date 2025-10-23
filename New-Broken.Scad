//
// Rectangular/Square Welded Table Frame – Import‑friendly OpenSCAD
// - 1.125" square tube, wall param (0.100" default, set 0.125" for 1/8")
// - Top frame: butt joints
// - Tabs: 3 on long edges, 2 on short edges; 5" from each end; 1"x1"x(tab_thk)
// - Legs: 32" long
// - Stretcher ring: butt-jointed rectangle at height with 0.25"x0.25" corner notches
// - BOM echo with lengths and weight
// Author: M365 Copilot (for Kevin Gordon)
//

unit = 25.4;                      // mm per inch; set to 1 for inch-native display
function U(x) = x * unit;

eps = 0.01;                       // small overlap (mm) for boolean stability
$fa = 2; $fs = 0.5;

// ---------------- Parameters ----------------

// Size (outside dimensions)
outer_x_in = 48;                  // long direction (X) – set equal to Y for a square
outer_y_in = 22;                  // short direction (Y)

// Tube spec
tube_od_in = 1.125;               // square tube OD
wall_in    = 0.100;               // wall thickness (0.100 or 0.125)

// Frame fit
fit_gap_in = 0.00;                // relief on the short frame members (Y) if desired

// Legs
add_legs   = true;
leg_len_in = 32.0;

// Stretcher ring (replaces earlier 4‑rail perimeter)
add_stretcher_ring            = true;
stretcher_bottom_from_floor_in = 6.0;   // bottom of ring above floor
stretcher_notch_in            = 0.25;   // 0.25" x 0.25" corner notch

// Plywood & tabs (support ledges)
add_tabs          = true;
ply_thick_in      = 23/32;              // 0.71875 typical 3/4" plywood
ply_clear_in      = 0.02;               // vertical install clearance
recess_in         = 0.00;               // 0 = flush top; set 0.125 to recess 1/8"

tab_len_in        = 1.00;               // 1" along side
tab_depth_in      = 1.00;               // 1" inward
tab_thk_in        = 0.125;              // default 1/8" tabs (set 0.100 to match 0.100" wall)
tab_edge_margin_in = 5.00;              // centers 5" from each end

// Tab counts (as requested)
n_tabs_long_side  = 3;                  // long edges
n_tabs_short_side = 2;                  // short edges

// Tab holes (optional)
tabs_with_holes   = false;              // set true to add screw holes
hole_dia_in       = 0.188;              // ~3/16"
hole_inset_in     = 0.50;               // hole center inset from wall into tab

// BOM / weight echo (console output)
do_bom_echo             = true;
material_name           = "Steel";       // label only
material_density_lb_in3 = 0.283;         // Steel ~0.283, Aluminum ~0.0975

// ---------------- Derived (model units) ----------------

tube_od  = U(tube_od_in);
wall     = U(wall_in);
fit_gap  = U(fit_gap_in);

outer_x  = U(outer_x_in);
outer_y  = U(outer_y_in);
inner_x  = outer_x - 2 * tube_od;
inner_y  = outer_y - 2 * tube_od;

leg_len  = U(leg_len_in);

stretcher_bottom_from_floor = U(stretcher_bottom_from_floor_in);
stretcher_notch = U(stretcher_notch_in);

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

    // Y rails (length outer_y - 2*od - gap) at ±X
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

// Stretcher ring at height with 0.25"x0.25" corner notches
// Outer size = inner_x × inner_y, so ring OUTER faces align with legs' INNER faces.
module stretcher_ring_notched_rect(ix=inner_x, iy=inner_y, od=tube_od, w=wall,
                                   legL=leg_len, bottom_from_floor=stretcher_bottom_from_floor,
                                   notch=stretcher_notch) {
    // Vertical placement
    z_leg_bottom = -od/2 - legL;
    z_bottom     =  z_leg_bottom + bottom_from_floor;  // bottom of ring tubes
    z_center     =  z_bottom + od/2;                   // square_tube_x is centered in Z

    difference() {
        // Ring itself: butt-jointed frame with outer = (ix, iy)
        translate([0,0,z_center]) frame_rect(ix, iy, od, w, 0);

        // Corner notches (4 cubes). Remove a 0.25"x0.25" bite through tube depth.
        // NE (+X,+Y)
        translate([ +ix/2 - notch, +iy/2 - notch, z_center - od/2 - eps ])
            cube([ notch, notch, od + 2*eps ], center=false);
        // NW (−X,+Y)
        translate([ -ix/2,         +iy/2 - notch, z_center - od/2 - eps ])
            cube([ notch, notch, od + 2*eps ], center=false);
        // SW (−X,−Y)
        translate([ -ix/2,         -iy/2,         z_center - od/2 - eps ])
            cube([ notch, notch, od + 2*eps ], center=false);
        // SE (+X,−Y)
        translate([ +ix/2 - notch, -iy/2,         z_center - od/2 - eps ])
            cube([ notch, notch, od + 2*eps ], center=false);
    }
}

// Tabs: 3 on the long edges, 2 on the short edges; centers at 5" from each end.
// Long axis determined by comparing outer_x vs outer_y.
module tabs_rect_all_sides(ix=inner_x, iy=inner_y, od=tube_od) {
    if (add_tabs) {
        // Vertical placement: tab top meets plywood underside
        z_top =  +od/2 - recess - ply_thick - ply_clear;
        z0    =  z_top - tab_thk;

        // Decide which axis is long (ties → X treated as long)
        longX = (outer_x >= outer_y);
        m = tab_margin;

        // Offsets from center to tab centers on each side
        px = ix/2 - m;   // along X for top/bottom sides
        py = iy/2 - m;   // along Y for left/right sides

        if (longX) {
            // --- Long edges are TOP/BOTTOM (±Y): place 3 tabs each at X = -px, 0, +px ---
            // TOP (+Y): extend −Y
            translate([ -px - tab_len/2, +iy/2 - tab_depth, z0 ]) cube([ tab_len, tab_depth, tab_thk ], center=false);
            translate([  0  - tab_len/2, +iy/2 - tab_depth, z0 ]) cube([ tab_len, tab_depth, tab_thk ], center=false);
            translate([ +px - tab_len/2, +iy/2 - tab_depth, z0 ]) cube([ tab_len, tab_depth, tab_thk ], center=false);
            // BOTTOM (−Y): extend +Y
            translate([ -px - tab_len/2, -iy/2, z0 ]) cube([ tab_len, tab_depth, tab_thk ], center=false);
            translate([  0  - tab_len/2, -iy/2, z0 ]) cube([ tab_len, tab_depth, tab_thk ], center=false);
            translate([ +px - tab_len/2, -iy/2, z0 ]) cube([ tab_len, tab_depth, tab_thk ], center=false);

            // --- Short edges are LEFT/RIGHT (±X): place 2 tabs each at Y = ±py ---
            // RIGHT (+X): extend −X
            translate([ +ix/2 - tab_depth, -py - tab_len/2, z0 ]) cube([ tab_depth, tab_len, tab_thk ], center=false);
            translate([ +ix/2 - tab_depth, +py - tab_len/2, z0 ]) cube([ tab_depth, tab_len, tab_thk ], center=false);
            // LEFT (−X): extend +X
            translate([ -ix/2, -py - tab_len/2, z0 ]) cube([ tab_depth, tab_len, tab_thk ], center=false);
            translate([ -ix/2, +py - tab_len/2, z0 ]) cube([ tab_depth, tab_len, tab_thk ], center=false);
        } else {
            // --- Long edges are LEFT/RIGHT (±X): place 3 tabs each at Y = -py, 0, +py ---
            // RIGHT (+X): extend −X
            translate([ +ix/2 - tab_depth, -py - tab_len/2, z0 ]) cube([ tab_depth, tab_len, tab_thk ], center=false);
            translate([ +ix/2 - tab_depth,  0  - tab_len/2, z0 ]) cube([ tab_depth, tab_len, tab_thk ], center=false);
            translate([ +ix/2 - tab_depth, +py - tab_len/2, z0 ]) cube([ tab_depth, tab_len, tab_thk ], center=false);
            // LEFT (−X): extend +X
            translate([ -ix/2, -py - tab_len/2, z0 ]) cube([ tab_depth, tab_len, tab_thk ], center=false);
            translate([ -ix/2,  0  - tab_len/2, z0 ]) cube([ tab_depth, tab_len, tab_thk ], center=false);
            translate([ -ix/2, +py - tab_len/2, z0 ]) cube([ tab_depth, tab_len, tab_thk ], center=false);

            // --- Short edges are TOP/BOTTOM (±Y): place 2 tabs each at X = ±px ---
            // TOP (+Y): extend −Y
            translate([ -px - tab_len/2, +iy/2 - tab_depth, z0 ]) cube([ tab_len, tab_depth, tab_thk ], center=false);
            translate([ +px - tab_len/2, +iy/2 - tab_depth, z0 ]) cube([ tab_len, tab_depth, tab_thk ], center=false);
            // BOTTOM (−Y): extend +Y
            translate([ -px - tab_len/2, -iy/2, z0 ]) cube([ tab_len, tab_depth, tab_thk ], center=false);
            translate([ +px - tab_len/2, -iy/2, z0 ]) cube([ tab_len, tab_depth, tab_thk ], center=false);
        }
    }
}

// Optional: tab holes matching the 3/2 placement
module tab_holes_rect(ix=inner_x, iy=inner_y, od=tube_od) {
    if (add_tabs && tabs_with_holes) {
        z_top =  +od/2 - recess - ply_thick - ply_clear;
        z0    =  z_top - tab_thk;

        longX = (outer_x >= outer_y);
        m = tab_margin;

        px = ix/2 - m;   // along X (top/bottom)
        py = iy/2 - m;   // along Y (left/right)

        if (longX) {
            // TOP (+Y): 3 holes at X = -px, 0, +px
            translate([ -px, +iy/2 - hole_inset, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
            translate([  0,  +iy/2 - hole_inset, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
            translate([ +px, +iy/2 - hole_inset, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
            // BOTTOM (−Y)
            translate([ -px, -iy/2 + hole_inset, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
            translate([  0,  -iy/2 + hole_inset, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
            translate([ +px, -iy/2 + hole_inset, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);

            // RIGHT/LEFT (short edges): 2 holes at Y = ±py
            translate([ +ix/2 - hole_inset, -py, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
            translate([ +ix/2 - hole_inset, +py, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
            translate([ -ix/2 + hole_inset, -py, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
            translate([ -ix/2 + hole_inset, +py, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
        } else {
            // RIGHT/LEFT (long edges): 3 holes at Y = -py, 0, +py
            translate([ +ix/2 - hole_inset, -py, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
            translate([ +ix/2 - hole_inset,  0,  z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
            translate([ +ix/2 - hole_inset, +py, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
            translate([ -ix/2 + hole_inset, -py, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
            translate([ -ix/2 + hole_inset,  0,  z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
            translate([ -ix/2 + hole_inset, +py, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);

            // TOP/BOTTOM (short edges): 2 holes at X = ±px
            translate([ -px, +iy/2 - hole_inset, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
            translate([ +px, +iy/2 - hole_inset, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
            translate([ -px, -iy/2 + hole_inset, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
            translate([ +px, -iy/2 + hole_inset, z0 - eps ]) cylinder(h = tab_thk + 2*eps, d = hole_dia, center=false, $fn=48);
        }
    }
}

// ---------------- Top-level CSG ----------------

render() difference() {
    union() {
        // Top frame
        frame_rect(outer_x, outer_y, tube_od, wall, fit_gap);

        // Tabs
        tabs_rect_all_sides(inner_x, inner_y, tube_od);

        // Legs
        if (add_legs) legs_four_rect(outer_x, outer_y, tube_od, leg_len);

        // Stretcher ring (clean fabrication detail)
        if (add_stretcher_ring)
            stretcher_ring_notched_rect(inner_x, inner_y, tube_od, wall,
                                        leg_len, stretcher_bottom_from_floor,
                                        stretcher_notch);
    }
    // Tab holes (optional)
    tab_holes_rect(inner_x, inner_y, tube_od);
}

// ---------------- Guardrails / Info Echo ----------------

if ((inner_x/2) <= tab_margin || (inner_y/2) <= tab_margin)
    echo("WARNING: tab_edge_margin too large for inner opening; reduce from 5.00 in or enlarge frame.");

// ---------------- BOM / Weight Echo (console) ----------------

if (do_bom_echo) {
    // Clear openings (in)
    inner_x_in = outer_x_in - 2 * tube_od_in;
    inner_y_in = outer_y_in - 2 * tube_od_in;

    // Top frame (butt-jointed)
    frame_long_len_in  = outer_x_in;                        // 2 pcs
    frame_short_len_in = outer_y_in - 2 * tube_od_in - fit_gap_in;  // 2 pcs

    // Stretcher ring (outer = inner opening)
    ring_long_len_in  = inner_x_in;                         // 2 pcs
    ring_short_len_in = inner_y_in - 2 * tube_od_in;        // 2 pcs

    // Legs
    leg_len_each_in = leg_len_in;                           // 4 pcs

    // Tabs: 3 per long side, 2 per short side (two sides each)
    longX_flag = (outer_x_in >= outer_y_in);
    tabs_on_long_side  = n_tabs_long_side;
    tabs_on_short_side = n_tabs_short_side;
    q_tabs = 2 * (longX_flag ? tabs_on_long_side : tabs_on_short_side)
           + 2 * (longX_flag ? tabs_on_short_side : tabs_on_long_side);

    // Quantities
    q_frame_long  = 2;
    q_frame_short = 2;
    q_ring_long   = 2;
    q_ring_short  = 2;
    q_leg         = 4;

    // Cross-section area (in^2) for hollow square tube
    inner_side_in = tube_od_in - 2*wall_in;
    xsec_area_in2 = tube_od_in*tube_od_in - inner_side_in*inner_side_in;

    // Total tube length (in)
    total_len_in = q_frame_long*frame_long_len_in +
                   q_frame_short*frame_short_len_in +
                   q_ring_long*ring_long_len_in +
                   q_ring_short*ring_short_len_in +
                   q_leg*leg_len_each_in;

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
    echo(str("BOM, ring_long, qty=", q_ring_long, ", len_in=", ring_long_len_in, ", stock=1.125x", wall_in, " sq tube"));
    echo(str("BOM, ring_short, qty=", q_ring_short, ", len_in=", ring_short_len_in, ", stock=1.125x", wall_in, " sq tube"));
    echo(str("BOM, leg, qty=", q_leg, ", len_in=", leg_len_each_in, ", stock=1.125x", wall_in, " sq tube"));
    echo(str("BOM, tabs, qty=", q_tabs, ", size_in=1x1x", tab_thk_in));

    echo(str("BOM_TOTAL, tube_len_in=", total_len_in, ", tube_len_ft=", total_len_in/12.0));
    echo(str("BOM_TOTAL, tube_weight_lb=", tube_weight_lb, ", tabs_weight_lb=", tabs_weight_lb, ", total_weight_lb=", total_weight_lb));

    // Sanity info
    echo(str("INFO, inner_opening_x_in=", inner_x_in, ", inner_opening_y_in=", inner_y_in));
    echo(str("INFO, long_axis=", longX_flag ? "X" : "Y", ", tabs_long_side=", n_tabs_long_side, ", tabs_short_side=", n_tabs_short_side));
}