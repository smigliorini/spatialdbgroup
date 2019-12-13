CREATE OR REPLACE FUNCTION EQ_3 (geometry, geometry) RETURNS boolean AS $$
DECLARE
g1 geometry;
g2 geometry;
pt1 geometry;
pt2 geometry[];
p geometry;
i integer;
debug boolean = true;

BEGIN
g1 := $1;
g2 := $2;
IF NOT ST_EQUALS(g1,g2) THEN RETURN false; END IF;
RAISE NOTICE 'Uguali 2D';
i := 1;
FOR p IN SELECT geom FROM ST_DUMPPOINTS(g2) ORDER BY ST_X(geom),ST_Y(geom),ST_Z(geom) LOOP
    pt2[i] := p;
    i := i + 1;
END LOOP;
i := 1;
FOR pt1 IN SELECT geom FROM ST_DUMPPOINTS(g1) ORDER BY ST_X(geom),ST_Y(geom),ST_Z(geom) LOOP
    p := pt2[i];
    IF ST_X(pt1) <> ST_X(p) OR ST_Y(pt1) <> ST_Y(p) OR ST_Z(pt1) <> ST_Z(p) THEN
       RETURN false;
    ELSE
       i := i + 1;
    END IF;
END LOOP;
RETURN true;
END;
$$ LANGUAGE plpgsql;
