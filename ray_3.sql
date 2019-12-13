CREATE OR REPLACE FUNCTION ray_3 (geometry, geometry) RETURNS integer AS $$
DECLARE
p geometry;
sup geometry;
patch geometry;
patchxy geometry;
patchxz geometry;
patchyz geometry;
pt geometry;
pt1 geometry;
x0 double precision;
y0 double precision;
z0 double precision;
x1 double precision;
x2 double precision;
x3 double precision;
y1 double precision;
y2 double precision;
y3 double precision;
z1 double precision;
z2 double precision; 
z3 double precision;
a double precision;
b double precision;
c double precision;
d double precision;
areaxy double precision;
areaxz double precision;
areayz double precision;
i integer;
gt1 text;
gt2 text;
nint integer;
xint double precision;
debug boolean = true;

BEGIN
p := $1;
sup := $2;
IF ST_ISEMPTY(p) OR ST_ISEMPTY(sup) THEN
   IF dbug THEN RAISE NOTICE 'una delle geometrie è vuota'; END IF;
   RETURN null;
END IF;

IF GEOMETRYTYPE(p) <> 'POINT' OR GEOMETRYTYPE(sup) <> 'POLYHEDRALSURFACE' THEN
   RAISE NOTICE 'wrong types';
   RETURN null;
END IF;

x0 := ST_X(p);
y0 := ST_Y(p);
z0 := ST_Z(p);
nint := 0;
FOR patch IN SELECT geom FROM ST_DUMP(sup) LOOP
    i := 1;
    IF (ST_XMAX(patch) >= x0) THEN
	FOR pt IN SELECT geom FROM ST_DUMPPOINTS(patch) ORDER BY path[1] LOOP
	    IF (i > 3) THEN EXIT; END IF;
	    IF (i = 1) THEN x1 := ST_X(pt);  y1 := ST_Y(pt); z1 := ST_Z(pt); END IF;
	    IF (i = 2) THEN x2 := ST_X(pt);  y2 := ST_Y(pt); z2 := ST_Z(pt); END IF;
	    IF (i = 3) THEN x3 := ST_X(pt);  y3 := ST_Y(pt); z3 := ST_Z(pt); END IF;
	    i := i + 1;
	END LOOP;    
	a := (y2 - y1)*(z3 - z1) - (z2 - z1)*(y3 - y1);
	b := -((x2 - x1)*(z3 - z1) - (z2 - z1)*(x3 - x1));
	c := (x2 - x1)*(y3 - y1) - (y2 - y1)*(x3 - x1);
	d := - (a*x1 + b*y1 + c*z1);
	IF (a = 0) THEN
	   CONTINUE;
	END IF;
	xint := -(d + b*y0 + c*z0)/a;
	patchxy := ST_FORCE_2D(patch);
	gt1 := 'SRID=' || ST_SRID(patch)::text || ';POLYGON((';
	gt2 = gt1;
	FOR pt1 IN SELECT geom FROM ST_DUMPPOINTS(patch) ORDER BY path[1] LOOP
	    gt1 = gt1 || ST_X(pt1)::text ||' '|| ST_Z(pt1)::text || ',';
	    gt2 = gt2 || ST_Y(pt1)::text || ' ' || ST_Z(pt1)::text || ',';
	END LOOP;
	gt1 := substring(gt1 from 1 for length(gt1)-1);
	gt2 := substring(gt2 from 1 for length(gt2)-1);
	gt1 := gt1 || '))';
	gt2 := gt2 || '))';
	patchxz := ST_GEOMFROMEWKT(gt1);
	patchyz := ST_GEOMFROMEWKT(gt2);
        areaxy := 0; IF ST_ISVALID(patchxy) THEN areaxy := ST_AREA(patchxy); END IF;
        areaxz := 0; IF ST_ISVALID(patchxz) THEN areaxz := ST_AREA(patchxz); END IF;
        areayz := 0; IF ST_ISVALID(patchyz) THEN areayz := ST_AREA(patchyz); END IF;
	IF areaxy > areaxz THEN
	   IF areaxy > areayz THEN
	      IF ST_WITHIN(ST_GEOMFROMEWKT('SRID='||ST_SRID(p)||';POINT('||xint::text||' '||y0::text||')'), 
		 patchxy) THEN
		 IF (abs(a*x0 + b*y0 + c*z0 + d) <= 10^(-12)) THEN
		    RETURN 0;
		 END IF;
		 nint := nint + 1;
	      END IF;
	   ELSE
	      IF ST_WITHIN(ST_GEOMFROMEWKT('SRID='||ST_SRID(p)||';POINT('||y0::text||' '||z0::text||')'), 
		 patchyz) THEN
		 IF (abs(a*x0 + b*y0 + c*z0 + d) <= 10^(-12)) THEN
		    RETURN 0;
		 END IF;
		 nint := nint + 1;
	       END IF;
	   END IF;
	ELSE
	   IF areaxz > areayz THEN
	      IF ST_WITHIN(ST_GEOMFROMEWKT('SRID='||ST_SRID(p)||';POINT('||xint::text||' '||z0::text||')'), 
		 patchxz) THEN
		 IF (abs(a*x0 + b*y0 + c*z0 + d) <= 10^(-12)) THEN
		    RETURN 0;
		 END IF;
		 nint := nint + 1;
	      END IF;
	   ELSE
	      IF ST_WITHIN(ST_GEOMFROMEWKT('SRID='||ST_SRID(p)::text||';POINT('||y0::text||' '||z0::text||')'), 
		 patchyz) THEN
		 IF (abs(a*x0 + b*y0 + c*z0 + d) <= 10^(-12)) THEN
		    RETURN 0;
		 END IF;
		 nint := nint + 1;
	      END IF;
	   END IF;
	END IF;
    END IF;
END LOOP;

RETURN nint;
END;
$$ LANGUAGE plpgsql;
