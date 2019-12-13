CREATE OR REPLACE FUNCTION s_cnt_v_3 (geometry, geometry) RETURNS boolean AS $$
DECLARE
s geometry;
p geometry;
p1 geometry;
p2 geometry;
p3 geometry;
a double precision;
b double precision;
c double precision;
d double precision;
x0 double precision;
y0 double precision;
z0 double precision;
x1 double precision;
y1 double precision;
z1 double precision;
x2 double precision;
y2 double precision;
z2 double precision;
x3 double precision;
y3 double precision;
z3 double precision;
deltay double precision;
deltaz double precision;
i integer;
debug boolean = true;
BEGIN
s := $1;
p := $2; x0 := ST_X(p); y0 := ST_Y(p); z0 := ST_Z(p);
IF ST_X(p) < ST_XMIN(s) OR ST_X(p) > ST_XMAX(s) OR
   ST_Y(p) < ST_YMIN(s) OR ST_Y(p) > ST_YMAX(s) OR
   ST_Z(p) < ST_ZMIN(s) OR ST_Z(p) > ST_XMAX(s) THEN
   RAISE NOTICE 'not in MBB';
   RETURN false;
END IF;

p1 := ST_STARTPOINT(s); x1 := ST_X(p1); y1 := ST_Y(p1); z1 := ST_Z(p1);
p2 := ST_ENDPOINT(s); x2 := ST_X(p2); y2 := ST_Y(p2); z2 := ST_Z(p2);
RAISE NOTICE 'INPUT: S % % % - % % %', x1, y1, z1, x2, y2, z2;
RAISE NOTICE 'INPUT: P % % %', x0, y0, z0;

IF (x2-x1) = 0 THEN 
   deltay := 0; deltaz := 0; 
ELSE 
   deltay := (y2-y1)/(x2-x1); 
   deltaz := (z2-z1)/(x2-x1);
END IF;

x3 := (x1+x2)/2 - 1; 
y3 := (y1+y2)/2 + deltay - 5; 
z3 := (z1+z2)/2 + deltaz - 7;

a := (y2 - y1)*(z3 - z1) - (z2 - z1)*(y3 - y1);
b := -((x2 - x1)*(z3 - z1) - (z2 - z1)*(x3 - x1));
c := (x2 - x1)*(y3 - y1) - (y2 - y1)*(x3 - x1);
d := -(a*x1 + b*y1 + c*z1);
RAISE NOTICE 'a: % b: % c: % d: %', a, b, c, d;

IF (abs(a*x0 + b*y0 + c*z0 + d) > 10^(-12)) THEN
   RAISE NOTICE 'not in first plane: %', abs(a*x0 + b*y0 + c*z0 + d);
   RETURN false;
END IF;

x3 := (x1+x2)/2 + 1; 
y3 := (y1+y2)/2 + deltay + 3; 
z3 := (z1+z2)/2 + deltaz + 5;

a := (y2 - y1)*(z3 - z1) - (z2 - z1)*(y3 - y1);
b := -((x2 - x1)*(z3 - z1) - (z2 - z1)*(x3 - x1));
c := (x2 - x1)*(y3 - y1) - (y2 - y1)*(x3 - x1);
d := - (a*x1 + b*y1 + c*z1);
RAISE NOTICE 'a: % b: % c: % d: %', a, b, c, d;

IF (abs(a*x0 + b*y0 + c*z0 + d) > 10^(-12)) THEN
   RAISE NOTICE 'not in second plane';
   RETURN false;
END IF;

RETURN true;
END;
$$ LANGUAGE plpgsql;
