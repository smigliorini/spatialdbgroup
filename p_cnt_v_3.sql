CREATE OR REPLACE FUNCTION p_cnt_v_3 (geometry, geometry) RETURNS boolean AS $$
DECLARE
p geometry;
pxy geometry;
pxz geometry;
pyz geometry;
pch geometry;
v geometry;
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
v := $2;
x0 := ST_X(v); y0 := ST_Y(v); z0 := ST_Z(v);

-- plane of the patch
i := 1;
FOR pt IN SELECT geom FROM ST_DUMPPOINTS(p) ORDER BY path[1] LOOP
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

IF (abs(a1*x0 + b1*y0 + c1*z0 + d1) > 10^(-12)) THEN
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
   IF areaxy > areayz THEN xc := x0; yc := y0; pch := pxy;  
   ELSE xc := y0; yc := z0; pch := pyz;  
   END IF;
ELSE
   IF areaxz > areayz THEN xc := x0; yc := z0; pch := pxz;
   ELSE xc := y0; yc := z0; pch := pyz;
   END IF;
END IF;
RETURN ST_WITHIN(ST_GEOMFROMEWKT('SRID='||ST_SRID(p)||';POINT('||xc::text||' '||yc::text||')'), pch);
RETURN false;
END;
$$ LANGUAGE plpgsql;
