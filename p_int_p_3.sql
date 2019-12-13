CREATE OR REPLACE FUNCTION p_int_p_3 (geometry, geometry) RETURNS boolean AS $$
DECLARE
pxy geometry;
pxz geometry;
pyz geometry;
pch geometry;
ints geometry;
p1 geometry;
p2 geometry;
pt geometry;
areaxy double precision;
areaxz double precision;
areayz double precision;
a1 double precision;
b1 double precision;
c1 double precision;
d1 double precision;
a2 double precision;
b2 double precision;
c2 double precision;
d2 double precision;
a3 double precision;
b3 double precision;
c3 double precision;
d3 double precision;
xs0 double precision;
ys0 double precision;
xe0 double precision;
ye0 double precision;
x1 double precision;
y1 double precision;
z1 double precision;
x2 double precision;
y2 double precision;
z2 double precision;
x3 double precision;
y3 double precision;
z3 double precision;
xs double precision;
ys double precision;
zs double precision;
xe double precision;
ye double precision;
ze double precision;
t1 double precision;
t2 double precision;
det double precision;
gt1 text;
gt2 text;
i integer;
debug boolean = true;
BEGIN
p1 := $1;
p2 := $2;

i := 1;
FOR pt IN SELECT geom FROM ST_DUMPPOINTS(p1) ORDER BY path[1] LOOP
    IF (i > 3) THEN EXIT; END IF;
    IF (i = 1) THEN x1 := ST_X(pt);  y1 := ST_Y(pt); z1 := ST_Z(pt); END IF;
    IF (i = 2) THEN x2 := ST_X(pt);  y2 := ST_Y(pt); z2 := ST_Z(pt); END IF;
    IF (i = 3) THEN x3 := ST_X(pt);  y3 := ST_Y(pt); z3 := ST_Z(pt); END IF;
    i := i + 1;
END LOOP;    
a1 := (y2 - y1)*(z3 - z1) - (z2 - z1)*(y3 - y1);
b1 := -((x2 - x1)*(z3 - z1) - (z2 - z1)*(x3 - x1));
c1 := (x2 - x1)*(y3 - y1) - (y2 - y1)*(x3 - x1);
d1 := - (a1*x1 + b1*y1 + c1*z1);
RAISE NOTICE 'a: % b: % c: % d: %', a1, b1, c1, d1;
i := 1;
FOR pt IN SELECT geom FROM ST_DUMPPOINTS(p2) ORDER BY path[1] LOOP
    IF (i > 3) THEN EXIT; END IF;
    IF (i = 1) THEN x1 := ST_X(pt);  y1 := ST_Y(pt); z1 := ST_Z(pt); END IF;
    IF (i = 2) THEN x2 := ST_X(pt);  y2 := ST_Y(pt); z2 := ST_Z(pt); END IF;
    IF (i = 3) THEN x3 := ST_X(pt);  y3 := ST_Y(pt); z3 := ST_Z(pt); END IF;
    i := i + 1;
END LOOP;    
a2 := (y2 - y1)*(z3 - z1) - (z2 - z1)*(y3 - y1);
b2 := -((x2 - x1)*(z3 - z1) - (z2 - z1)*(x3 - x1));
c2 := (x2 - x1)*(y3 - y1) - (y2 - y1)*(x3 - x1);
d2 := - (a2*x1 + b2*y1 + c2*z1);
RAISE NOTICE 'a: % b: % c: % d: %', a2, b2, c2, d2;

IF (a1*b2)-(a2*b1) = 0 AND (a1*c2)-(a2*c1) = 0 AND 
   (b1*c2)-(b2*c1) = 0 THEN RAISE NOTICE 'coplanar planes'; RETURN false; END IF;

-- intersecting planes: compute straight line of intersection
xs := ST_XMIN(p1);
IF (ST_XMIN(p2) < xs) THEN xs := ST_XMIN(p2); END IF;
xe := ST_XMAX(p1);
IF (ST_XMAX(p2) > xe) THEN xe := ST_XMAX(p2); END IF;

det := (b1*c2)-(b2*c1); 
t1 := -d1 - a1*xs; t2 := -d2 - a2*xs;
ys := ((t1*c2)-(t2*c1))/det;
zs := ((b1*t2)-(b2*t1))/det;
t1 := -d1 - a1*xe; t2 := -d2 - a2*xe;
ye := ((t1*c2)-(t2*c1))/det;
ze := ((b1*t2)-(b2*t1))/det;

-- analyzing first patch
pxy := ST_FORCE_2D(p1);
gt1 := 'SRID=' || ST_SRID(p1)::text || ';POLYGON((';
gt2 = gt1;
FOR pt IN SELECT geom FROM ST_DUMPPOINTS(p1) ORDER BY path[1] LOOP
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
   IF areaxy > areayz THEN xs0 := xs; ys0 := ys; xe0 := xe; ye0 := ye; pch := pxy;  
   ELSE xs0 := ys; ys0 := zs; xe0 := ye; ye0 := ze; pch := pyz;  
   END IF;
ELSE
   IF areaxz > areayz THEN xs0 := xs; ys0 := zs; xe0 := xe; ye0 := ze; pch := pxz;
   ELSE xs0 := ys; ys0 := zs; xe0 := ye; ye0 := ze; pch := pyz;
   END IF;
END IF;

ints := ST_GEOMFROMEWKT('SRID='||ST_SRID(p1)||';LINESTRING('||xs0||' '||ys0||','||xe0||' '||ye0||')');
IF NOT (ST_CROSSES(pch,ints) OR ST_CONTAINS(pch,ints)) THEN RETURN false; END IF;

ints := ST_INTERSECTION(pch,ints);

-- analyzing second patch
xs := ST_X(ST_STARTPOINT(ints));
xe := ST_X(ST_ENDPOINT(ints));

t1 := -d1 - a1*xs; t2 := -d2 - a2*xs;
ys := ((t1*c2)-(t2*c1))/det;
zs := ((b1*t2)-(b2*t1))/det;
t1 := -d1 - a1*xe; t2 := -d2 - a2*xe;
ye := ((t1*c2)-(t2*c1))/det;
ze := ((b1*t2)-(b2*t1))/det;

pxy := ST_FORCE_2D(p2);
gt1 := 'SRID=' || ST_SRID(p2)::text || ';POLYGON((';
gt2 = gt1;
FOR pt IN SELECT geom FROM ST_DUMPPOINTS(p2) ORDER BY path[1] LOOP
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
   IF areaxy > areayz THEN xs0 := xs; ys0 := ys; xe0 := xe; ye0 := ye; pch := pxy;  
   ELSE xs0 := ys; ys0 := zs; xe0 := ye; ye0 := ze; pch := pyz;  
   END IF;
ELSE
   IF areaxz > areayz THEN xs0 := xs; ys0 := zs; xe0 := xe; ye0 := ze; pch := pxz;
   ELSE xs0 := ys; ys0 := zs; xe0 := ye; ye0 := ze; pch := pyz;
   END IF;
END IF;

ints := ST_GEOMFROMEWKT('SRID='||ST_SRID(p1)||';LINESTRING('||xs0||' '||ys0||','||xe0||' '||ye0||')');
IF NOT (ST_CROSSES(pch,ints) OR ST_CONTAINS(pch,ints)) THEN RETURN false; END IF;

RETURN true;
END;
$$ LANGUAGE plpgsql;
