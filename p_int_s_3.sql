CREATE OR REPLACE FUNCTION p_int_s_3 (geometry, geometry) RETURNS boolean AS $$
DECLARE
p geometry;
pxy geometry;
pxz geometry;
pyz geometry;
pch geometry;
s geometry;
p1 geometry;
p2 geometry;
pt geometry;
areaxy double precision;
areaxz double precision;
areayz double precision;
a1 double precision;
b1 double precision;
c1 double precision;
t1 double precision;
a2 double precision;
b2 double precision;
c2 double precision;
t2 double precision;
a3 double precision;
b3 double precision;
c3 double precision;
t3 double precision;
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
xint double precision;
yint double precision;
zint double precision;
xc double precision;
yc double precision;
deltay double precision;
deltaz double precision;
det double precision;
gt1 text;
gt2 text;
i integer;
debug boolean = true;
BEGIN
p := $1;
s := $2;
p1 := ST_STARTPOINT(s); x1 := ST_X(p1); y1 := ST_Y(p1); z1 := ST_Z(p1);
p2 := ST_ENDPOINT(s); x2 := ST_X(p2); y2 := ST_Y(p2); z2 := ST_Z(p2);

IF (x2-x1) = 0 THEN 
   deltay := 0; deltaz := 0; 
ELSE
   deltay := (y2-y1)/(x2-x1); 
   deltaz := (z2-z1)/(x2-x1);
END IF;

-- first plane
x3 := (x1+x2)/2 + 1; 
y3 := (y1+y2)/2 + deltay - 5; 
z3 := (z1+z2)/2 + deltaz - 7;
a1 := (y2 - y1)*(z3 - z1) - (z2 - z1)*(y3 - y1);
b1 := -((x2 - x1)*(z3 - z1) - (z2 - z1)*(x3 - x1));
c1 := (x2 - x1)*(y3 - y1) - (y2 - y1)*(x3 - x1);
t1 := (a1*x1 + b1*y1 + c1*z1);

-- second plane
x3 := (x1+x2)/2 - 1; 
y3 := (y1+y2)/2 + deltay + 3; 
z3 := (z1+z2)/2 + deltaz + 5;
a2 := (y2 - y1)*(z3 - z1) - (z2 - z1)*(y3 - y1);
b2 := -((x2 - x1)*(z3 - z1) - (z2 - z1)*(x3 - x1));
c2 := (x2 - x1)*(y3 - y1) - (y2 - y1)*(x3 - x1);
t2 := (a2*x1 + b2*y1 + c2*z1);

-- third plane
i := 1;
FOR pt IN SELECT geom FROM ST_DUMPPOINTS(p) ORDER BY path[1] LOOP
    IF (i > 3) THEN EXIT; END IF;
    IF (i = 1) THEN x1 := ST_X(pt);  y1 := ST_Y(pt); z1 := ST_Z(pt); END IF;
    IF (i = 2) THEN x2 := ST_X(pt);  y2 := ST_Y(pt); z2 := ST_Z(pt); END IF;
    IF (i = 3) THEN x3 := ST_X(pt);  y3 := ST_Y(pt); z3 := ST_Z(pt); END IF;
    i := i + 1;
END LOOP;    
a3 := (y2 - y1)*(z3 - z1) - (z2 - z1)*(y3 - y1);
b3 := -((x2 - x1)*(z3 - z1) - (z2 - z1)*(x3 - x1));
c3 := (x2 - x1)*(y3 - y1) - (y2 - y1)*(x3 - x1);
t3 := (a3*x1 + b3*y1 + c3*z1);

det := (a1*b2*c3) + (b1*c2*a3) + (c1*a2*b3) - (c1*b2*a3) - (a2*b1*c3) - (a1*b3*c2);
IF (det = 0) THEN RETURN false; END IF;

xint := ((t1*b2*c3) + (b1*c2*t3) + (c1*t2*b3) - (c1*b2*t3) - (t2*b1*c3) - (t1*b3*c2))/det;
yint := ((a1*t2*c3) + (t1*c2*a3) + (c1*a2*t3) - (c1*t2*a3) - (a2*t1*c3) - (a1*t3*c2))/det;
zint := ((a1*b2*t3) + (b1*t2*a3) + (t1*a2*b3) - (t1*b2*a3) - (a2*b1*t3) - (a1*b3*t2))/det;
--pint := ST_GEOMFROMEWKT('SRID='||ST_SRID(p)||';POINT('||xint||' '||yint||' '||zint||')');
RAISE NOTICE 'xint: % yint: % zint: %', xint, yint, zint;

IF xint < ST_XMIN(s) OR xint > ST_XMAX(s) OR
   yint < ST_YMIN(s) OR yint > ST_YMAX(s) OR
   zint < ST_ZMIN(s) OR zint > ST_ZMAX(s) THEN
   RAISE NOTICE 'not in MBB';
   RETURN false;
END IF;

pxy := ST_FORCE_2D(p);
gt1 := 'SRID=' || ST_SRID(p)::text || ';POLYGON((';
gt2 = gt1;
FOR pt IN SELECT geom FROM ST_DUMPPOINTS(p) ORDER BY path[1] LOOP
    gt1 = gt1 || ST_X(pt)::text ||' '|| ST_Z(pt)::text || ',';
    gt2 = gt2 || ST_Y(pt)::text ||' '|| ST_Z(pt)::text || ',';
END LOOP;
gt1 := substring(gt1 from 1 for length(gt1)-1);
gt2 := substring(gt2 from 1 for length(gt2)-1);
gt1 := gt1 || '))';
gt2 := gt2 || '))';
pxz := ST_GEOMFROMEWKT(gt1);
pyz := ST_GEOMFROMEWKT(gt2);

areaxy := 0; IF ST_ISVALID(pxy) THEN areaxy := ST_AREA(pxy); END IF;
areaxz := 0; IF ST_ISVALID(pxz) THEN areaxz := ST_AREA(pxz); END IF;
areayz := 0; IF ST_ISVALID(pyz) THEN areayz := ST_AREA(pyz); END IF;

IF areaxy > areaxz THEN
   IF areaxy > areayz THEN xc := xint; yc := yint; pch := pxy;  
   ELSE xc := yint; yc := zint; pch := pyz;  
   END IF;
ELSE
   IF areaxz > areayz THEN xc := xint; yc := zint; pch := pxz;
   ELSE xc := yint; yc := zint; pch := pyz;
   END IF;
END IF;
RETURN ST_WITHIN(ST_GEOMFROMEWKT('SRID='||ST_SRID(p)||';POINT('||xc::text||' '||yc::text||')'), pch);
END;
$$ LANGUAGE plpgsql;


