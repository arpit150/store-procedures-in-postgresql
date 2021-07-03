--1.1.23
--6 sec 365 msec
SELECT t."ID",'DL_POI','ID',t."ID"::text,'Poi and its edgeline id does not match','1.1.23'
FROM ( SELECT "ID" FROM mmi_master."DL_POI" EXCEPT SELECT "ID" FROM mmi_master."DL_POI_EDGELINE" ) As t, mmi_master."DL_POI" As t1  
WHERE t."ID" = t1."ID"	

--1.1.23
--2 sec 380 msec
SELECT t."ID",'DL_POI','EDGE_ID',t."EDGE_ID"::text,'Poi and its edgeline edge_id does not match','1.1.23'            
FROM mmi_master."DL_POI" As t JOIN mmi_master."DL_POI_EDGELINE" As t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" AND 
t."EDGE_ID" <> t1."EDGE_ID"


--1.1.34
--2 sec 192 msec
SELECT t3.id,'DL_POI','Intersection',t3.geom,'Poi does not intersects with edgeline','1.1.34' FROM (SELECT t2."ID" As ID, 
t2.ST_Intersects As geom FROM (SELECT t."ID", ST_Intersects(t."SP_GEOMETRY", ST_StartPoint(t1."SP_GEOMETRY")) FROM mmi_master."DL_POI" As t 
INNER JOIN mmi_master."DL_POI_EDGELINE" As t1 ON t."ID" = t1."ID" ) t2 WHERE ST_Intersects='f') As t3
		
--1.1.29
--785 msec
SELECT t2."ID",'DL_POI','EDGE_SIDE',t2."EDGE_SIDE"::text,'Poi and its edgeline side does not match','1.1.29' 
FROM (SELECT t."ID", t."EDGE_SIDE" FROM mmi_master."DL_POI" As t JOIN mmi_master."DL_POI_EDGELINE"
AS t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" AND t."EDGE_ID"=t1."EDGE_ID" AND t."EDGE_SIDE"<>t1."SIDE" ) As t2



--1.1.70
--11 sec 20 msec
select t3."ID",'DL_POI','EXCP','overshoot EDGELINE difference of 0.1','1.1.70' from 
(select t1."ID",st_distance(ST_ENDPOINT(t1."SP_GEOMETRY")::Geography,ST_intersection(t2."SP_GEOMETRY",t1."SP_GEOMETRY")::
Geography,TRUE) as dist  FROM mmi_master."DL_POI_EDGELINE" t1,mmi_master."DL_ROAD_NETWORK" AS t2 where st_crosses
(t1."SP_GEOMETRY",t2."SP_GEOMETRY") and t1."EDGE_ID" = t2."EDGE_ID") t3 where t3.dist>0.1


--1.1.66
--240 msec
SELECT t1."ID", 'DL_POI','EXCP','Edgeline should not have more then 2 nodes
','1.1.66' FROM mmi_master."DL_POI_EDGELINE" AS t1 where ST_npoints("SP_GEOMETRY")>2	


--1.1.63
--2 sec 63 msec
select t1."ID", 'DL_POI','EXCP','Poi not intersect with edge_line END point
','1.1.63' from mmi_master."DL_POI" t1,mmi_master."DL_POI_EDGELINE" AS t2 
where t1."EDGE_ID" = t2."EDGE_ID" and ST_Intersects(t1."SP_GEOMETRY",ST_Endpoint(t2."SP_GEOMETRY")) = TRUE  


--1.1.25
--2 sec 14 msec
SELECT t1."ID",'DL_POI','EDGE_ID',t."EDGE_ID"::text,'Poi and its non-shift entry edge_id does not match','1.1.25'            
FROM mmi_master."DL_POI" As t JOIN mmi_master."DL_POI_ENTRYNONSHIFT" As t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" 		
AND t."EDGE_ID" <> t1."EDGE_ID"  		


--1.1.39
--801 msec
SELECT t."ID",'GA_POI','ID',t."ID"::text,'Poi and its non-shift entry id does not match','1.1.39'
FROM ( SELECT "ID" FROM mmi_master."DL_POI" EXCEPT SELECT "ID" FROM mmi_master."DL_POI_ENTRYNONSHIFT" ) As t,
mmi_master."DL_POI" As t1 WHERE t."ID" = t1."ID"


--1.1.24
--1 sec 460 msec
SELECT t1."ID",'DL_POI','EDGE_ID',t."EDGE_ID"::text,'Poi and its shift entry edge_id does not match','1.1.24'            
FROM mmi_master."DL_POI" As t JOIN mmi_master."DL_POI_ENTRYSHIFT" As t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" 
AND t."EDGE_ID" <> t1."EDGE_ID"	


--1.1.38
--755 msec
SELECT t."ID",'DL_POI','ID',t."ID"::text,'Poi and its shift entry id does not match','1.1.38'
FROM ( SELECT "ID" FROM mmi_master."DL_POI" EXCEPT SELECT "ID" FROM mmi_master."DL_POI_ENTRYSHIFT" ) As t,
mmi_master."DL_POI" As t1 WHERE t."ID" = t1."ID"

--1.1.72
--685 msec
SELECT t1."ID",'DL_POI','ID',t1."ID"::text,'ID mismatch in Shift and Non-Shift Entry','1.1.72' FROM 
( SELECT "ID" FROM mmi_master."DL_POI_ENTRYNONSHIFT" EXCEPT (SELECT "ID" FROM mmi_master."DL_POI_ENTRYNONSHIFT" )) As t,
mmi_master."DL_POI" As t1  WHERE t."ID" <> t1."ID"


--1.1.36
--1 sec 14 msec
SELECT t3.id,'DL_POI','Intersection',t3.geom,'Non-shift entry point should be intersects with end node of Edgeline','1.1.36' 
FROM (SELECT t2."ID" As ID, t2.ST_Intersects As geom FROM (SELECT t."ID", ST_Intersects(t."SP_GEOMETRY", ST_EndPoint
(t1."SP_GEOMETRY")) FROM mmi_master."DL_POI_ENTRYNONSHIFT" As t 
INNER JOIN mmi_master."DL_POI_EDGELINE" As t1 ON t."ID" = t1."ID") t2 WHERE ST_Intersects='f') As t3 



SELECT t."ID",'DL_POIDL_POI','ID',t."ID"::text,'Shift entry point should be near end node of Edgeline between 0.4m and 0.6m range','1.1.35' 
FROM (SELECT a."ID",ST_Intersects(ST_Buffer(b."SP_GEOMETRY",0.000001),a."SP_GEOMETRY"), ST_Distance(a."SP_GEOMETRY", ST_EndPoint(b."SP_GEOMETRY"),true) 
FROM mmi_master."DL_POI_ENTRYSHIFT" a, mmi_master."DL_POI_EDGELINE" b WHERE a."ID"=b."ID") As t WHERE t.ST_Distance NOT BETWEEN 0.4 AND 0.6 AND ST_Distance ='f'
		
--1.37.4
-- 157 msec
SELECT t."ID",'DL_POI','EDGE_ID',t."EDGE_ID"::text,'Poi should not be attached with ’NMR’ roads in Road Network','1.37.4'            
FROM mmi_master."DL_POI" As t JOIN mmi_master."DL_ROAD_NETWORK" As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND t1."FTR_CRY"='NMR'

--1.1.27
--84 msec
SELECT t."ID",'DL_POI','EDGE_ID',t."EDGE_ID"::text,'Poi point should not be attached with ferry roads','1.1.27'            
FROM mmi_master."DL_POI" As t JOIN mmi_master."DL_ROAD_NETWORK"  As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND t1."FT"=1

--1.1.28
--864 msec
SELECT t."ID",'DL_POI','EDGE_ID',t."EDGE_ID"::text,'Poi’s Stt_Id does not match with its Road Network Stt_Id','1.1.28'            
FROM mmi_master."DL_POI" As t JOIN mmi_master."DL_ROAD_NETWORK"  As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND t."STT_ID"<>t1."STT_ID"
		
--1.37.1
--2 sec 549 msec
SELECT t1."ID",'DL_POI','EDGE_ID',t1."EDGE_ID"::text,'Poi’s Edge_Id does not match with its Road Network Edge_Id','1.37.1'
FROM (SELECT "EDGE_ID" FROM mmi_master."DL_POI" EXCEPT (SELECT "EDGE_ID" FROM mmi_master."DL_ROAD_NETWORK" )) As t , 
mmi_master."DL_POI"  AS t1 WHERE t."EDGE_ID" = t1."EDGE_ID"	


--1.1.44
--170 msec
SELECT a."ID",'DL_POI','EXCP',a."EXCP"::text,'If Poi attached with Bridge, then maintain ’BRY’ in EXCP','NO ERROR CODE' 
FROM mmi_master."DL_POI" As a ,mmi_master."DL_ROAD_NETWORK" As b WHERE (ST_Intersects(a."SP_GEOMETRY",b."SP_GEOMETRY")=true) AND COALESCE(a."EXCP",'') NOT LIKE '%BRY%' AND 
b."FOW_PREV"='BR' GROUP BY a."ID",a."EXCP"


--1.1.45
--185 msec
SELECT a."ID",'DL_POI','EXCP',a."EXCP"::text,'If Poi attached with Ferry, then maintain ’FTY’ in EXCP','NO ERROR CODE' 
FROM mmi_master."DL_POI" As a, mmi_master."DL_ROAD_NETWORK" As b WHERE (ST_Intersects(a."SP_GEOMETRY",b."SP_GEOMETRY")=true) AND COALESCE(a."EXCP",'') NOT LIKE '%FTY%' AND 
(b."FT"=1 OR b."FT"=2) GROUP BY a."ID",a."EXCP"	

--1.1.46
--179 msec
SELECT a."ID",'DL_POI','EXCP',a."EXCP"::text,'If Poi attached with Ferry, then maintain ’FTY’ in EXCP','1.1.46' 
FROM mmi_master."DL_POI" As a, mmi_master."DL_ROAD_NETWORK" As b WHERE (ST_Intersects(a."SP_GEOMETRY",b."SP_GEOMETRY")=true) AND COALESCE(a."EXCP",'') NOT LIKE '%FTY%' AND 
(b."FT"=1 OR b."FT"=2) GROUP BY a."ID",a."EXCP"		


--1.1.67
--21 sec 414 msec
select t1."ID", 'DL_POI','EXCP','EntryPoint not intersecting Road','1.1.67' from mmi_master."DL_POI_ENTRYNONSHIFT" t1,mmi_master."DL_ROAD_NETWORK" AS t2 
where t1."EDGE_ID" = t2."EDGE_ID" and ST_Intersects(ST_Buffer(t1."SP_GEOMETRY",0.000001,''),t2."SP_GEOMETRY")=false


--1.5.1
--1 sec 430 msec
SELECT t1."ID",'DL_POI','SUB_CRY',t1."SUB_CRY"::text,'Poi’s Sub_Cry does not match with Mtr_Subcod in Poi Cat','1.5.1'
FROM ( (SELECT "SUB_CRY" FROM mmi_master."DL_POI" WHERE (COALESCE("SUB_CRY",'')<> '') ) EXCEPT
(SELECT "MTR_SUBCOD" FROM mmi_master."POI_CAT" WHERE (COALESCE("MTR_SUBCOD",'')<> '') ) ) As t, mmi_master."DL_POI" As t1 WHERE 
t."SUB_CRY"=t1."SUB_CRY"


--1.5.1
-- 1 sec 192 msec 
SELECT t1."ID",'DL_POI','SUB_CRY',t1."SUB_CRY"::text,'Poi’s Sub_Cry does not match with Mtr_Subcod in Poi Cat','1.5.1'
FROM ( (SELECT "SUB_CRY" FROM mmi_master."DL_POI" WHERE (COALESCE("SUB_CRY",'')<> '') ) EXCEPT
(SELECT "MTR_SUBCOD" FROM mmi_master."POI_CAT" WHERE (COALESCE("MTR_SUBCOD",'')<> '') ) ) As t, mmi_master."DL_POI" As t1 WHERE 
t."SUB_CRY"=t1."SUB_CRY"
		
--1.5.4
--1 sec 93 msec
SELECT t."ID",'DL_POI','SUB_CRY',t."SUB_CRY"::text,'Poi’s Sub_Cry must be part of Mtr_Subcod group in Poi Cat','1.5.4'
FROM mmi_master."DL_POI" As t WHERE  t."SUB_CRY" NOT IN ( 
SELECT "MTR_SUBCOD" FROM mmi_master."POI_CAT" WHERE (COALESCE("MTR_SUBCOD",'')<> '')) AND t."SUB_CRY" IN ( 
SELECT "MTR_SUBCOD" FROM mmi_master."POI_CAT"  WHERE (COALESCE("MTR_SUBCOD",'')<> ''))
		

--1.1.3
-- 1 sec 196 msec 
SELECT t4."ID",'DL_POI','FTR_CRY',t4."FTR_CRY"::text,'Poi’s Ftr_Cry does not match with Mtsr_Code in Poi Cat','1.1.3' FROM (( SELECT "FTR_CRY"
FROM mmi_master."DL_POI" ) EXCEPT (SELECT "MSTR_CODE" FROM mmi_master."POI_CAT" WHERE (COALESCE("MSTR_CODE",'')<> '')) ) As t1, 
mmi_master."DL_POI" t4 WHERE t1."FTR_CRY" = t4."FTR_CRY"


--2.47.287
--606 msec
SELECT t."ID",'DL_POI','BRAND_NME',t."BRAND_NME"::text,'Brand_Nme must not be match with NAME, Poplr_Nme, Alias_1,2,3 and Address','2.47.287' 
FROM mmi_master."DL_POI" As t WHERE  COALESCE(t."BRAND_NME",'')<> '' AND t."BRAND_NME" Not In (Select "BND_NAME" From mmi_master."BRAND_LIST") AND 
t."BRAND_NME"=t."NAME" OR t."BRAND_NME"=t."POPLR_NME" OR t."BRAND_NME"=t."ALIAS_1" OR t."BRAND_NME"=t."ALIAS_2" OR t."BRAND_NME"=t."ALIAS_3" OR t."BRAND_NME"=t."ADDRESS"

	
--1.48.1
--1 sec 49 msec 
SELECT t."ID",'DL_POI','BRAND_NME',t."BRAND_NME"::text,'Poi’s Brand_Nme must match with Bnd_Nme maintained in latest Brand List','1.48.1' 
FROM mmi_master."DL_POI" As t WHERE
t."BRAND_NME" NOT IN (SELECT "BND_NAME" FROM mmi_master."BRAND_LIST" ) AND (COALESCE(t."BRAND_NME",'')<> '')


--1.10.1
--580 msec
SELECT t."ID",'DL_POI','t.POPLR_NME',t."POPLR_NME"::text,'Poi’s Poplr_Nme must match with Bnd_Pop in Brand List','1.10.1' 
FROM mmi_master."DL_POI" As t JOIN mmi_master."BRAND_LIST" As t1 ON (COALESCE(t."BRAND_NME",'')<> '') AND 
(COALESCE(t."POPLR_NME",'')<> '') AND (COALESCE(t1."BND_NAME",'')<> '') AND t."BRAND_NME" = t1."BND_NAME" AND t."POPLR_NME" NOT IN (SELECT "BND_POP" 
FROM mmi_master."BRAND_LIST" As t1 WHERE (COALESCE(t1."BND_POP",'')<> ''))

--1.1.7
--594 msec
SELECT t."ID",'DL_POI','BRAND_NME',t."BRAND_NME"::text,'Poi’s Brand_Nme and Ftr_Cry does not match with Bnd_Nme and Ftr_Cry in Brand List','1.1.7' 
FROM mmi_master."DL_POI" As t INNER JOIN mmi_master."BRAND_LIST" As t1 ON t."NAME" = t1."BND_NAME" WHERE
COALESCE(t."BRAND_NME",'')<>'' AND TRIM(t."BRAND_NME") <> TRIM(t1."BND_NAME") AND TRIM(t."FTR_CRY") <> TRIM(t1."FTR_CRY")

--1.1.7
--625 msec
SELECT t."ID",'DL_POI','BRAND_NME',t."BRAND_NME"::text,'Poi’s NAME and Ftr_Cry match but Brand_Nme does not match with Bnd_Nme in Brand List','1.1.7'
FROM mmi_master."DL_POI" As t INNER JOIN mmi_master."BRAND_LIST" As t1 ON t."NAME" = t1."BND_NAME" WHERE 
COALESCE(t."BRAND_NME",'')<>'' AND TRIM(t."BRAND_NME") <> TRIM(t1."BND_NAME") AND TRIM(t."FTR_CRY")=TRIM(t1."FTR_CRY")

--1.1.9
--1 sec 217 msec 
SELECT t."ID",'GA_POI','BRAND_NME',t."BRAND_NME"::text,'Poi’s Brand_Nme should not be blank if Poi’s NAME and Ftr_Cry match with Poi_Nme and Ftr_Cry in Brand List','1.48.7' 
FROM mmi_master."DL_POI" As t INNER JOIN mmi_master."BRAND_LIST" As t1 ON t."NAME" = t1."POI_NME" WHERE 
COALESCE(t."BRAND_NME",'')='' AND TRIM(t."FTR_CRY")=TRIM(t1."FTR_CRY")

--1 sec 73 msec
SELECT t1."NAME",t1."BRAND_NME",t1."POPLR_NME",t2."BND_NAME",t2."BND_NAME",t2."BND_POP" from mmi_master."DL_POI" AS t1,mmi_master."BRAND_LIST" AS t2
where t1."NAME"=t2."BND_NAME" AND t1."BRAND_NME"=t2."BND_NAME" AND t1."POPLR_NME"<> t2."BND_POP"


--1 sec 68 msec
SELECT t1."NAME",t1."BRAND_NME",t1."ALIAS_1",t2."BND_NAME",t2."BND_NAME",t2."BND_ALIAS1" from mmi_master."DL_POI" AS t1,mmi_master."BRAND_LIST" AS t2
where t1."NAME"=t2."BND_NAME" AND t1."BRAND_NME"=t2."BND_NAME" AND t1."ALIAS_1"<> t2."BND_ALIAS1"
	 		

--1.1.58
--5 sec 956 msec 
SELECT t1."ID",'DL_POI','SP_GEOMETRY', t1."SP_GEOMETRY",'Poi should be inside the city area according to city id','1.1.58' 
FROM mmi_master."DL_POI" As t1, mmi_master."DL_CITY_BOUNDARY" As t2 
WHERE (t1.status NOT IN('0','5') OR COALESCE(t1.status,'')='') AND t1."CITY_ID"=t2."ID" AND 
ST_Within(t1."SP_GEOMETRY",t2."SP_GEOMETRY")='f'

--1.41.3
--688 msec
SELECT t,"ID",'GA_POI','VICIN_ID',t."VICIN_ID"::text,'Poi’s Vicin_Id does not match with its City Boundary Id','1.41.3' 
FROM mmi_master."DL_POI" As t WHERE t."VICIN_ID"<>0 AND t."BRAND_NME" NOT ILIKE '%TOYOTA%' AND t."VICIN_ID" NOT IN 
(SELECT "ID" FROM mmi_master."DL_CITY_BOUNDARY" As t1 WHERE t1."ID"<>0)


select "ID","VICIN_ID" FROM mmi_master."AN_POI" WHERE "VICIN_ID"<>0 AND "BRAND_NME" ILIKE '%TOYOTA%' AND "VICIN_ID" NOT IN
(SELECT "ID" FROM mmi_master."AN_CITY_BOUNDARY" as t union select "ID" from mmi_master."AN_DISTRICT_BOUNDARY" AS t2)

--1.8.1
--709 msec
SELECT t3.id,'GA_POI','CITY_ID',t3."CITY_ID"::text,'Poi’s City_Id does not match with its City Boundary Id','1.8.1' 
FROM (SELECT t2."ID" As ID, t2."CITY_ID", t2.ST_Within As geom FROM (SELECT t."ID", t."CITY_ID", ST_Within(t."SP_GEOMETRY",t1."SP_GEOMETRY") 
FROM (SELECT * FROM mmi_master."DL_POI" ) As t, 
mmi_master."DL_CITY_BOUNDARY" As t1 WHERE t."CITY_ID"<>t1."ID" AND t1."ID"<>0 AND t."CITY_ID"<>0) As t2 WHERE ST_Within='t') As t3	



WITH state_name AS (SELECT "STT_NME" FROM mmi_master."STATE_BOUNDARY" WHERE "STT_CODE" = 'DL')
Select * From (Select t1."ID",REPLACE(t1."ADDRESS", ' ','') AS "ADDRESS",t2."STT_NME" 
FROM mmi_master."DL_POI" As t1, state_name As t2  
WHERE (COALESCE("ADDRESS",'')<>'') AND TRIM("ADDRESS", ' ') like '%,'||t2."STT_NME"||'' OR TRIM("ADDRESS", ' ') like ''||t2."STT_NME"||',%' OR TRIM("ADDRESS", ' ') like '%,'||t2."STT_NME"||'%') t3 
where "ADDRESS" ~ ('\y'||"STT_NME"||'\y')


--1.1.14
--3 sec 406 msec 
SELECT t2."ID",'GA_POI','ADDRESS',t2."ADDRESS"::text,'Poi’s Address contain Pin Code ','1.1.14'
FROM (SELECT "ID",UNNEST(STRING_TO_ARRAY("ADDRESS", ' ')) As address FROM mmi_master."DL_POI" WHERE "ADDRESS" ~ '[1-9][0-9]{5}' 
) As t, mmi_master."DL_POI" As t2
WHERE t.address LIKE ANY(SELECT "PINCODE" FROM mmi_master."PINCODE_BOUNDARY" ) AND t."ID"=t2."ID"


SELECT a."ID",'DL_POI','ADMIN_ID',a."ADMIN_ID"::text,'Poi’s Admin_Id does not match with its Admin Boundary Id','1.1.18' 
FROM mmi_master."DL_POI" a, mmi_master."DL_POI" b WHERE ST_Within(a."SP_GEOMETRY",b."SP_GEOMETRY")='t' AND 
a."ADMIN_ID"<>b."ID" AND a."ADMIN_ID"<>0
	

--1.1.19
-- 2 sec 795 msec
SELECT a."ID",'DL_POI','ADMIN_ID',a."ADMIN_ID"::text,'Poi’s Admin_Id should be 0 if Poi does not fall within its Admin Boundary','1.1.19' 
FROM mmi_master."DL_POI" a, mmi_master."DL_POI" b WHERE ST_Within(a."SP_GEOMETRY",b."SP_GEOMETRY")='f' AND 
a."ADMIN_ID"=b."ID" AND a."ADMIN_ID"<>0	


--1.1.20
--12 sec 365 msec
SELECT a."ID",'DL_POI','CITY_ID',a."CITY_ID"::text,'Poi’s City_Id does not match with its Admin Boundary City_Id','1.1.20' 
FROM mmi_master."DL_POI" a, mmi_master."DL_POI" b WHERE ST_Within(a."SP_GEOMETRY",b."SP_GEOMETRY")='t' AND 
a."CITY_ID"<>b."CITY_ID" AND a."CITY_ID"<>0 AND b."CITY_ID"<>0


--1.1.21
--12 sec 108 msec 
SELECT a."ID",'DL_POI','STT_ID',a."STT_ID"::text,'Poi’s Stt_Id does not match with its Admin Boundary Stt_Id','1.1.21' 
FROM mmi_master."DL_POI" a, mmi_master."DL_POI" b WHERE ST_Within(a."SP_GEOMETRY",b."SP_GEOMETRY")='t' AND 
a."STT_ID"<>b."STT_ID" AND a."STT_ID"<>0 AND b."STT_ID"<>0

