CREATE OR REPLACE FUNCTION cop_pp(geometry, geometry)
  RETURNS boolean AS
$BODY$
DECLARE
g1 geometry;
g2 geometry;
pa1 geometry;
pa2 geometry;
pt1 geometry;
pt2 geometry;
pt3 geometry;
pt geometry;
A double precision;
A1 double precision;
A2 double precision;
A3 double precision;
prec double precision;
isPlanar boolean;
BEGIN
prec := 0.01;
g1 := $1;
g2 := $2;

IF g1 IS NULL OR ST_ISEMPTY(g1) OR g2 IS NULL OR ST_ISEMPTY(g2) THEN
  RETURN false;
END IF;

IF (GEOMETRYTYPE(g1) = 'POLYGON' AND GEOMETRYTYPE(g2) = 'POLYGON') THEN
   IF ST_NDIMS(g1) <> 3 OR ST_NDIMS(g2) <> 3 THEN
      RAISE NOTICE 'Input geometries are not 3D';
      RETURN false;
   END IF;
   RAISE NOTICE 'COPLANAR between two patches in 3D';
   pa1 := g1;
   pa2 := g2;
   RAISE NOTICE 'Patch 1: %', ST_ASEWKT(pa1);
   RAISE NOTICE 'Patch 2: %', ST_ASEWKT(pa2);
   
   -- Testing if pa1 is planar
   pt1 := ST_PointN(ST_EXTERIORRING(pa1),1);
   --RAISE NOTICE 'Pt1: %', ST_ASEWKT(pt1);
   pt2 := ST_PointN(ST_EXTERIORRING(pa1),2);
   --RAISE NOTICE 'Pt2: %', ST_ASEWKT(pt2);
   pt3 := ST_PointN(ST_EXTERIORRING(pa1),3);
   --RAISE NOTICE 'Pt3: %', ST_ASEWKT(pt3);
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
   isPlanar := true;
   
   FOR pt IN SELECT geom FROM ST_DUMPPOINTS(pa1) LOOP
		--RAISE NOTICE 'Pti: %', ST_ASEWKT(pt);			 
   		IF (ST_EQUALS(pt1,pt) OR ST_EQUALS(pt2,pt) OR ST_EQUALS(pt3,pt)) THEN
		   --RAISE NOTICE 'same point: %', ST_ASEWKT(pt);
		   CONTINUE;
		END IF;
        -- test coplanarity
	    --RAISE NOTICE 'A: %, A1: %, A2: %, A3: % val: %', A, A1, A2, A3, abs((ST_X(pt)*A1 + ST_Y(pt)*A2 + ST_Z(pt)*A3) - A);            
	    IF abs((ST_X(pt)*A1 + ST_Y(pt)*A2 + ST_Z(pt)*A3) - A) < prec THEN     
		   CONTINUE;
	    ELSE
		   RAISE NOTICE 'Input 3D polygon 1 is not planar';
		   RETURN false;
	    END IF;					   
   END LOOP;
	
   -- Testing if pa2 is planar	
   pt1 := ST_PointN(ST_EXTERIORRING(pa2),1);
   --RAISE NOTICE 'Pt1: %', ST_ASEWKT(pt1);
   pt2 := ST_PointN(ST_EXTERIORRING(pa2),2);
   --RAISE NOTICE 'Pt2: %', ST_ASEWKT(pt2);
   pt3 := ST_PointN(ST_EXTERIORRING(pa2),3);
   --RAISE NOTICE 'Pt3: %', ST_ASEWKT(pt3);
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
   isPlanar := true;
   
   FOR pt IN SELECT geom FROM ST_DUMPPOINTS(pa2) LOOP
		--RAISE NOTICE 'Pti: %', ST_ASEWKT(pt);			 
   		IF (ST_EQUALS(pt1,pt) OR ST_EQUALS(pt2,pt) OR ST_EQUALS(pt3,pt)) THEN
		   --RAISE NOTICE 'same point: %', ST_ASEWKT(pt);
		   CONTINUE;
		END IF;
        -- test coplanarity
	    --RAISE NOTICE 'A: %, A1: %, A2: %, A3: % val: %', A, A1, A2, A3, abs((ST_X(pt)*A1 + ST_Y(pt)*A2 + ST_Z(pt)*A3) - A);            
	    IF abs((ST_X(pt)*A1 + ST_Y(pt)*A2 + ST_Z(pt)*A3) - A) < prec THEN     
		   CONTINUE;
	    ELSE
		   RAISE NOTICE 'Input 3D polygon 2 is not planar';
		   RETURN false;
	    END IF;					   
   END LOOP;
						 
   FOR pt IN SELECT geom FROM ST_DUMPPOINTS(pa1) LOOP
	   --RAISE NOTICE 'Pti: %', ST_ASEWKT(pt);								 
	   IF abs((ST_X(pt)*A1 + ST_Y(pt)*A2 + ST_Z(pt)*A3) - A) > prec THEN  
		  RETURN false;
	   END IF;
   END LOOP;
   RETURN true;
ELSE								 
   RAISE NOTICE 'Input geometries are not polygons';
   RETURN false;
END IF;   
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
