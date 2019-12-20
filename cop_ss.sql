CREATE OR REPLACE FUNCTION cop_ss(geometry, geometry)
  RETURNS boolean AS
$BODY$
DECLARE
g1 geometry;
g2 geometry;
s1 geometry;
s2 geometry;
pt1 geometry;
pt2 geometry;
pt3 geometry;
pt geometry;
A double precision;
A1 double precision;
A2 double precision;
A3 double precision;
prec double precision;
BEGIN
prec := 0.01;
g1 := $1;
g2 := $2;

IF g1 IS NULL OR ST_ISEMPTY(g1) OR g2 IS NULL OR ST_ISEMPTY(g2) THEN
  RETURN false;
END IF;

IF GEOMETRYTYPE(g1) = 'LINESTRING' AND GEOMETRYTYPE(g2) = 'LINESTRING' AND 
   ST_NUMPOINTS(g1) = 2 AND ST_NUMPOINTS(g2) = 2 THEN
   IF ST_NDIMS(g1) <> 3 OR ST_NDIMS(g2) <> 3 THEN
      RAISE NOTICE 'Input segments are not 3D';
      RETURN false;
   END IF;
   RAISE NOTICE 'COPLANAR between two 3D segments';
   s1 := g1;
   s2 := g2;
   RAISE NOTICE 'Segment 1: %', ST_ASEWKT(s1);
   RAISE NOTICE 'Segment 2: %', ST_ASEWKT(s2);
   pt1 := ST_PointN(g1,1);
   pt2 := ST_PointN(g1,2);
   pt3 := ST_PointN(g2,1);
   pt := ST_PointN(g2,2);
   
   -- apply the Cramer's method for computing the coefficients A1 A2 and A3 of the plane that passes throuth the points p1, p2 and p3
   -- A is determinat of the matrix of coordinates and represents the denominator or the known term
   -- like A1 * x + A2 * y +A3 * z = A that derives from multiplying for A the following equation:
   -- A1/A * x + A2/A * y + A3/A * z = 1
   
   A := ST_X(pt1)*(ST_Y(pt2)*ST_Z(pt3) - ST_Y(pt3)*ST_Z(pt2)) - 
        ST_X(pt2)*(ST_Y(pt1)*ST_Z(pt3) - ST_Y(pt3)*ST_Z(pt1)) + 
        ST_X(pt3)*(ST_Y(pt1)*ST_Z(pt2) - ST_Y(pt2)*ST_Z(pt1));

   -- A1 is the determinat of the matrix of coordinates where the known term (1 1 1) is substituted to the column of x										
   A1 := (ST_Y(pt2)*ST_Z(pt3) - ST_Y(pt3)*ST_Z(pt2)) - 
         (ST_Y(pt1)*ST_Z(pt3) - ST_Y(pt3)*ST_Z(pt1)) +
         (ST_Y(pt1)*ST_Z(pt2) - ST_Y(pt2)*ST_Z(pt1));   
   -- A2 is the determinat of the matrix of coordinates where the known term (1 1 1) is substituted to the column of y	
   A2 := ST_X(pt1)*(ST_Z(pt3) - ST_Z(pt2)) -
         ST_X(pt2)*(ST_Z(pt3) - ST_Z(pt1)) +
         ST_X(pt3)*(ST_Z(pt2) - ST_Z(pt1));
   -- A3 is the determinat of the matrix of coordinates where the known term (1 1 1) is substituted to the column of z	
   A3 := ST_X(pt1)*(ST_Y(pt2) - ST_Y(pt3)) -
         ST_X(pt2)*(ST_Y(pt1) - ST_Y(pt3)) +
         ST_X(pt3)*(ST_Y(pt1) - ST_Y(pt2));

   --RAISE NOTICE 'A: %, A1: %, A2: %, A3: % val: %', A, A1, A2, A3, abs((ST_X(pt)*A1 + ST_Y(pt)*A2 + ST_Z(pt)*A3) - A);            
   IF abs((ST_X(pt)*A1 + ST_Y(pt)*A2 + ST_Z(pt)*A3) - A) < prec THEN     
      RETURN true;
   ELSE 
      RETURN false;
   END IF;      
ELSE
   RAISE NOTICE 'Input geometries are not segments';
   RETURN false;
END IF;   
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
