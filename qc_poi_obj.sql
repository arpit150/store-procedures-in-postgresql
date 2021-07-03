-- FUNCTION: upload.qc_attribute_object(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying)


CREATE OR REPLACE FUNCTION upload.qc_attribute_object(
	user_id character varying,
	tbl_nme_poi character varying,
	tbl_nme_edgeline character varying,
	tbl_nme_shift character varying,
	tbl_nme_nonshift character varying,
	sch_name character varying,
	stat_code character varying,
	user_type character varying)
    RETURNS TABLE(poi_id integer, poi_nme character varying, table_name character varying, field_name character varying, field_value character varying, error_type character varying, error_code character varying) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$

DECLARE
f1 text; f2 text;
yyyy_mm varchar(254);
DECLARE i integer;
DECLARE r record;
DECLARE tablename varchar(100);
DECLARE count integer;
DECLARE arr text []; 
DECLARE conquery text;
DECLARE j integer;
DECLARE conquery1 text;
DECLARE mst_sch text;
DECLARE tbl_nme_road text;
DECLARE tbl_nme_addr_p text;
DECLARE tbl_nme_addr_point text;
DECLARE tbl_nme_addr_r text;
DECLARE tbl_nme_loc text;
DECLARE tbl_nme_city text;
DECLARE tbl_nme_state text;
DECLARE tbl_name_brand_list text;
DECLARE tbl_name_state_abbr text;
DECLARE tbl_name_rail text;
DECLARE tbl_name_water text;
DECLARE tbl_name_poi_cat text;
DECLARE tbl_name_pincode text;
DECLARE tbl_name_junction text;
DECLARE tbl_name_other text;
DECLARE tbl_name_green text;
DECLARE tbl_nme_dist text;
DECLARE tbl_nme_poi_addr_regn text;
declare master_tbl_poi character varying(50);
declare master_tbl_edgeline character varying(50);
DECLARE error_table character varying(50);
DECLARE attrib_error character varying(50);
DECLARE final_uploaded_schema text;
DECLARE final_uploaded_tbl_poi text;
DECLARE sqlQuery text;
DECLARE t timestamptz := clock_timestamp();
BEGIN   
	mst_sch='mmi_master';
    final_uploaded_schema = 'mmi_master_prod_final';
------------------------------------------------------error table for poi-------------------------------------------------	
	if(upper(user_type)= 'USER' or user_type = 'PACKING' or user_type = 'ADMIN' OR user_type='MASTER') then 
	
		error_table = 'qa.'||user_id||'_attobj';
		attrib_error= 'qa.attriberror_attobj';
		raise info 'tab %',error_table;
		raise info 'tab %',attrib_error;
		
	end if;
------------------------------------------------------error table for de------------------------------------------------------	
	if(upper(user_type)= 'DE') then 
	
		error_table = 'de_qa.'||user_id||'_attobj';
		attrib_error= 'de_qa.attriberror_attobj';
		raise info 'tab %',error_table;
		raise info 'tab %',attrib_error;
	end if;	
	----------------------------------------------------------------------------Error_Table---------------------------------------------------------------------------------------------
	
	yyyy_mm = to_char(now(),'yyyymmddhh24miss');
	
	RAISE WARNING 'yyyy_mm % AA :%',yyyy_mm,'';
	
	EXECUTE ' DROP TABLE IF EXISTS '||error_table||''; 
	EXECUTE 'CREATE TABLE if not exists '||error_table||'(id serial, unquid integer, table_name character varying(255), field_name character varying(255), field_value character varying(255), 
		error_type character varying(256),error_code character varying(255))';
	EXECUTE 'CREATE TABLE if not exists '||attrib_error||'(id serial,user_id text,layer_nme text, message text,context text,db_edit_datetime timestamp without time zone DEFAULT now())';	
	
	--------------------------------------------------------------------------------Poi-------------------------------------------------------------------------------------------------
	IF tbl_nme_poi='' THEN 
		f1='Poi table is not there';
		f2='Insert Poi table to process the data'; 
		EXECUTE'insert into '||attrib_error||'(message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE 'MESSAGE: check for mmi_master';
	   
		RETURN;
	END IF;
---------------------------------------------------------------------PACKING------------------------------------------------------------------	

if (user_type='PACKING' OR user_type='USER' OR user_type='ADMIN' OR user_type='MASTER') THEN 

	----------------------------------------------------------------------------poi--------------------------------------------------------------------------------------------
        BEGIN
		i=0;
		j=0;

		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____POI'' AND TABLE_SCHEMA ='''||mst_sch||'''' into count;

		IF count > 1 THEN 
			-- master_tbl_poi=''|| UPPER(stat_code) ||'_POI';
			FOR r IN EXECUTE FORMAT('SELECT table_name FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____POI'' AND TABLE_SCHEMA ='''||mst_sch||''' ') 
			LOOP
				  tablename = UPPER(r.table_name);
				  arr[i]=tablename;
				  -- RAISE WARNING 'Count % AA :%',arr[i],'';
				  i:=i+1;
			END LOOP;
			i=i-1;  
			conquery=' SELECT * FROM '||mst_sch||'."'||arr[0]||'" ';
			LOOP 
				EXIT WHEN i=0;
				conquery1='union all  SELECT * FROM '||mst_sch||'."'||arr[i]||'" ';
				conquery = CONCAT(conquery,  conquery1);
				i=i-1;
				-- RAISE WARNING 'QUERY % QUERY %',conquery,'';
			END LOOP;
			
			EXECUTE'drop table if exists '|| UPPER(stat_code) ||'_POI';
			EXECUTE'create temp table '|| UPPER(stat_code) ||'_POI As ('|| conquery||')';
			master_tbl_poi=''|| UPPER(stat_code) ||'_POI';

		ELSE
			EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_POI'' AND TABLE_SCHEMA ='''||mst_sch||'''' into count;
			
			IF count = 1 THEN
				master_tbl_poi = ''||mst_sch||'."'||UPPER(stat_code)||'_POI"';
			ELSE
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_POI DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_POI Table Does not Exists in '||mst_sch||' Schema'')';
				master_tbl_poi = '';
			END IF;
		END IF;
		RAISE INFO 'check for MASTER POI TABLE';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;

	------------------------------------------------------------------------------Checking for EDGELINE-------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_POI_EDGELINE'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			master_tbl_edgeline=''|| UPPER(stat_code) ||'_POI_EDGELINE';
		ELSE
			master_tbl_edgeline = '';
			IF master_tbl_edgeline = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_POI_EDGELINE DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_POI_EDGELINE Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'checking for _POI_EDGELINE';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
	
------------------------------------------------------------------------------------------------------------------------------------------	
--1.1.1.04
	-- ADDED BY GOLDY 13/06/2019
	if tbl_nme_poi <>'' AND master_tbl_poi <>''  then
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
				 SELECT tab1."ID",'''||tbl_nme_poi||''',''ID'',tab1."ID", ''POI IS FREEZE PLEASE CHECK IT'',''1.1.1.04''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme_poi) ||'"  as tab1 INNER JOIN '||master_tbl_poi||'  as tab2
				 on tab1."ID" = tab2."ID" WHERE COALESCE(tab2."K_PRIORITY",'''') = ''F'' AND ST_EQUALS(tab1."SP_GEOMETRY",tab2."SP_GEOMETRY") = FALSE ';

		-- SELECT tab1."ID",tab2."K_PRIORITY" FROM upload."TESTPOI1" as tab1 inner join mmi_master."DL_POI" AS tab2
		-- on tab1."ID" = tab2."ID" WHERE COALESCE(tab2."K_PRIORITY",'') = 'F' AND ST_EQUALS(tab1.sp_geometry,tab2."SP_GEOMETRY") = FALSE
			
		
		RAISE INFO '<-----------1.1.1.04';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END IF;	
	
	--1.1.1.05
	-- ADDED BY GOLDY 13/06/2019
	if tbl_nme_edgeline <>'' then
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
				 SELECT tab1."ID",'''||tbl_nme_edgeline||''',''ID'',tab1."ID", ''EDGELINE IS FREEZE PLEASE CHECK IT'',''1.1.1.05''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme_edgeline) ||'"  as tab1 INNER JOIN '||mst_sch||'."'|| UPPER(master_tbl_edgeline) ||'" as tab2
				 on tab1."ID" = tab2."ID" WHERE COALESCE(LOWER(tab2."FRZ_EL"),'''') LIKE ''y%'' AND ST_EQUALS(tab1."SP_GEOMETRY",tab2."SP_GEOMETRY") = FALSE			 ';

		-- SELECT tab1."ID",tab2."FRZ_EL" FROM upload."TESTEDGELINE1" as tab1 inner join mmi_master."DL_POI_EDGELINE" AS tab2
		-- on tab1."ID" = tab2."ID" WHERE COALESCE(LOWER(tab2."FRZ_EL"),'') LIKE 'y%' AND ST_EQUALS(tab1.sp_geometry,tab2."SP_GEOMETRY") = FALSE			
		
		RAISE INFO '<-----------1.1.1.05';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END IF;	

--1.1.1.06
	-- ADDED BY GOLDY 09/07/2019
	if tbl_nme_poi <>'' AND master_tbl_poi <>''  then
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
				 SELECT tab1."ID",'''||tbl_nme_edgeline||''',''ID'',tab1."ID", ''It is  national poi please check it movement'',''1.1.1.06''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme_poi) ||'"  as tab1, '||master_tbl_poi||'  as tab2
				 where tab1."ID"= tab2."ID" AND tab1."IMP_POI" =''IMP_NAT'' AND ST_EQUALS(tab1."SP_GEOMETRY",tab2."SP_GEOMETRY") = FALSE  ';

		-- select tab1."ID",tab1."IMP_POI" from mmi_master."DL_POI" AS tab1,mmi_master."DL_POI" AS tab2 where tab1."ID"= tab2."ID" AND tab1."IMP_POI" ='IMP_NAT'
		-- AND ST_EQUALS(tab1."SP_GEOMETRY",tab2."SP_GEOMETRY") = FALSE 
		
		RAISE INFO '<-----------1.1.1.06';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	END IF;			
END IF;
	
if (user_type='USER' OR user_type='ADMIN' OR user_type='MASTER') THEN 
----------------------------------------------------------------------------_ADDR_REGION--------------------------------------------------------------------------------------------
        BEGIN
		i=0;
		j=0;

		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____ADDR_REGION'' AND TABLE_SCHEMA ='''||mst_sch||'''' into count;

		IF count > 1 THEN 
			-- tbl_nme_poi_addr_regn=''|| UPPER(stat_code) ||'_ADDR_REGION';
			FOR r IN EXECUTE FORMAT('SELECT table_name FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____ADDR_REGION'' AND TABLE_SCHEMA ='''||mst_sch||''' ') 
			LOOP
				  tablename = UPPER(r.table_name);
				  arr[i]=tablename;
				  --RAISE WARNING 'Count % AA :%',arr[i],'';
				  --RAISE INFO '<-----------_ADDR_REGION';
				  i:=i+1;
			END LOOP;
			i=i-1;  
			conquery=' SELECT * FROM '||mst_sch||'."'||arr[0]||'" ';
			LOOP 
				EXIT WHEN i=0;
				conquery1='union all  SELECT * FROM '||mst_sch||'."'||arr[i]||'" ';
				conquery = CONCAT(conquery,  conquery1);
				i=i-1;
				--RAISE WARNING 'QUERY % QUERY %',conquery,'';
				--RAISE INFO '<-----------_ADDR_REGION';
			END LOOP;
			
			EXECUTE'drop table if exists '|| UPPER(stat_code) ||'_ADDR_REGION';
			EXECUTE'create temp table '|| UPPER(stat_code) ||'_ADDR_REGION As ('|| conquery||')';
			tbl_nme_poi_addr_regn=''|| UPPER(stat_code) ||'_ADDR_REGION';

		ELSE
			EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_ADDR_REGION'' AND TABLE_SCHEMA ='''||mst_sch||'''' into count;
			
			IF count = 1 THEN
				tbl_nme_poi_addr_regn = ''||mst_sch||'."'||UPPER(stat_code)||'_ADDR_REGION"';
			ELSE
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_ADDR_REGION DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_ADDR_REGION Table Does not Exists in '||mst_sch||' Schema'')';
				tbl_nme_poi_addr_regn = '';
			END IF;
		END IF;
		RAISE INFO 'check for addr region';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
	----------------------------------------------------------------------------Road_Network--------------------------------------------------------------------------------------------
        BEGIN
		i=0;
		j=0;

		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____ROAD_NETWORK'' AND TABLE_SCHEMA ='''||mst_sch||'''' into count;

		IF count > 1 THEN 
			-- tbl_nme_road=''|| UPPER(stat_code) ||'_ROAD_NETWORK';
			FOR r IN EXECUTE FORMAT('SELECT table_name FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____ROAD_NETWORK'' AND TABLE_SCHEMA ='''||mst_sch||''' ') 
			LOOP
				  tablename = UPPER(r.table_name);
				  arr[i]=tablename;
				  --RAISE WARNING 'Count % AA :%',arr[i],'';
				  --RAISE INFO '<-----------Road_Network';
				  i:=i+1;
			END LOOP;
			i=i-1;  
			conquery=' SELECT * FROM '||mst_sch||'."'||arr[0]||'" ';
			LOOP 
				EXIT WHEN i=0;
				conquery1='union all  SELECT * FROM '||mst_sch||'."'||arr[i]||'" ';
				conquery = CONCAT(conquery,  conquery1);
				i=i-1;
				--RAISE WARNING 'QUERY % QUERY %',conquery,'';
				--RAISE INFO '<-----------Road_Network';
			END LOOP;
			
			EXECUTE'drop table if exists '|| UPPER(stat_code) ||'_ROAD_NETWORK';
			EXECUTE'create temp table '|| UPPER(stat_code) ||'_ROAD_NETWORK As ('|| conquery||')';
			tbl_nme_road=''|| UPPER(stat_code) ||'_ROAD_NETWORK';

		ELSE
			EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_ROAD_NETWORK'' AND TABLE_SCHEMA ='''||mst_sch||'''' into count;
			
			IF count = 1 THEN
				tbl_nme_road = ''||mst_sch||'."'||UPPER(stat_code)||'_ROAD_NETWORK"';
			ELSE
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_ROAD_NETWORK DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_ROAD_NETWORK Table Does not Exists in '||mst_sch||' Schema'')';
				tbl_nme_road = '';
			END IF;
		END IF;
		RAISE INFO 'check for road network';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
	
	----------------------------------------------------------------------------poi--------------------------------------------------------------------------------------------
        BEGIN
		i=0;
		j=0;

		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____POI'' AND TABLE_SCHEMA ='''||mst_sch||'''' into count;

		IF count > 1 THEN 
			-- master_tbl_poi=''|| UPPER(stat_code) ||'_POI';
			FOR r IN EXECUTE FORMAT('SELECT table_name FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____POI'' AND TABLE_SCHEMA ='''||mst_sch||''' ') 
			LOOP
				  tablename = UPPER(r.table_name);
				  arr[i]=tablename;
				  --RAISE WARNING 'Count % AA :%',arr[i],'';
				  --RAISE INFO '<-----------poi';
				  i:=i+1;
			END LOOP;
			i=i-1;  
			conquery=' SELECT * FROM '||mst_sch||'."'||arr[0]||'" ';
			LOOP 
				EXIT WHEN i=0;
				conquery1='union all  SELECT * FROM '||mst_sch||'."'||arr[i]||'" ';
				conquery = CONCAT(conquery,  conquery1);
				i=i-1;
				--RAISE WARNING 'QUERY % QUERY %',conquery,'';
				 --RAISE INFO '<-----------poi';
			END LOOP;
			
			EXECUTE'drop table if exists '|| UPPER(stat_code) ||'_POI';
			EXECUTE'create temp table '|| UPPER(stat_code) ||'_POI As ('|| conquery||')';
			master_tbl_poi=''|| UPPER(stat_code) ||'_POI';

		ELSE
			EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_POI'' AND TABLE_SCHEMA ='''||mst_sch||'''' into count;
			
			IF count = 1 THEN
				master_tbl_poi = ''||mst_sch||'."'||UPPER(stat_code)||'_POI"';
			ELSE
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_POI DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_POI Table Does not Exists in '||mst_sch||' Schema'')';
				master_tbl_poi = '';
			END IF;
		END IF;
		RAISE INFO 'check for MASTER POI TABLE';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
	---Added By Abhinav
	----------------------------------------------------------------------------For Final Uploaded Poi Check--------------------------------------------------------------------------------------------
        BEGIN
		i=0;
		j=0;

		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____POI'' AND TABLE_SCHEMA ='''||final_uploaded_schema||'''' into count;

		IF count > 1 THEN 
			-- master_tbl_poi=''|| UPPER(stat_code) ||'_POI';
			FOR r IN EXECUTE FORMAT('SELECT table_name FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____POI'' AND TABLE_SCHEMA ='''||final_uploaded_schema||''' ') 
			LOOP
				  tablename = UPPER(r.table_name);
				  arr[i]=tablename;
				  -- RAISE WARNING 'Count % AA :%',arr[i],'';
				  i:=i+1;
			END LOOP;
			i=i-1;  
			conquery=' SELECT * FROM '||mst_sch||'."'||arr[0]||'" ';
			LOOP 
				EXIT WHEN i=0;
				conquery1='union all  SELECT * FROM '||mst_sch||'."'||arr[i]||'" ';
				conquery = CONCAT(conquery,  conquery1);
				i=i-1;
				-- RAISE WARNING 'QUERY % QUERY %',conquery,'';
			END LOOP;
			
			EXECUTE'drop table if exists '|| UPPER(stat_code) ||'_POI';
			EXECUTE'create temp table '|| UPPER(stat_code) ||'_POI As ('|| conquery||')';
			final_uploaded_tbl_poi=''|| UPPER(stat_code) ||'_POI';

		ELSE
			EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_POI'' AND TABLE_SCHEMA ='''||final_uploaded_schema||'''' into count;
			
			IF count = 1 THEN
				final_uploaded_tbl_poi = ''||final_uploaded_schema||'."'||UPPER(stat_code)||'_POI"';
			ELSE
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_POI DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_POI Table Does not Exists in '||final_uploaded_schema||' Schema'')';
				final_uploaded_tbl_poi = '';
			END IF;
		END IF;
		RAISE INFO 'check for Final Uploaded MASTER POI TABLE';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
-------------------------------------------------------------------------------Checking for Addr_Point---------------------------------------------------------------------------------------------
	BEGIN
		i=0;
		j=0;
		
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____ADDR_POINT'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		
		IF count > 1 THEN 
			-- tbl_nme_addr_point=''|| UPPER(stat_code) ||'_ADDR_POINT';
			FOR r IN EXECUTE FORMAT('SELECT table_name FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____ADDR_POINT'' AND TABLE_SCHEMA ='''||mst_sch||''' ')  
 			LOOP
				  tablename = UPPER(r.table_name);
				  arr[i]=tablename;
				  --RAISE WARNING 'Count % AA :%',arr[i],'';
				  --RAISE INFO '<-----------Addr_Point';
				  i:=i+1;
			END LOOP;
			i=i-1;
			conquery=' SELECT * FROM '|| mst_sch ||'."'||arr[0]||'" ';
			LOOP 
				EXIT WHEN i=0;
				conquery1= 'union all  SELECT * FROM '|| mst_sch ||'."'||arr[i]||'" ';
				conquery = CONCAT(conquery,  conquery1);
				i=i-1;
				-- RAISE WARNING 'QUERY % QUERY %',conquery,'';
			END LOOP;
			
			EXECUTE'drop table if exists '|| UPPER(stat_code) ||'_ADDR_POINT';
			EXECUTE'create temp table '|| UPPER(stat_code) ||'_ADDR_POINT As ('|| conquery||')';
			tbl_nme_addr_point=''|| UPPER(stat_code) ||'_ADDR_POINT';
			
			-- RAISE WARNING 'ADDR_POINT % AA :%',tbl_nme_addr_point,'';
			--RAISE INFO '<-----------Addr_Point';
			
		ELSE
			EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_ADDR_POINT'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
			IF count = 1 THEN
				tbl_nme_addr_point = ''||mst_sch||'."'||UPPER(stat_code)||'_ADDR_POINT"';
			ELSE
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_ADDR_POINT DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_ADDR_POINT Table Does not Exists in '||mst_sch||' Schema'')';
				tbl_nme_addr_point = '';
			END IF;
		END IF;
		RAISE INFO 'CHECKING FOR ADDR_POINT';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
	
------------------------------------------------------------------------------Checking for EDGELINE-------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_POI_EDGELINE'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			master_tbl_edgeline=''|| UPPER(stat_code) ||'_POI_EDGELINE';
		ELSE
			master_tbl_edgeline = '';
			IF master_tbl_edgeline = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_POI_EDGELINE DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_POI_EDGELINE Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'checking for _POI_EDGELINE';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
------------------------------------------------------------------------------Checking for Addr_Admin_R-------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_ADDR_ADMIN_R'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbl_nme_addr_r=''|| UPPER(stat_code) ||'_ADDR_ADMIN_R';
		ELSE
			tbl_nme_addr_r = '';
			IF tbl_nme_addr_r = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_ADDR_ADMIN_R DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_ADDR_ADMIN_R Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'checking for Addr_Addin_R';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
------------------------------------------------------------------------------Checking for Addr_Admin_P-------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_ADDR_ADMIN_R'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbl_nme_addr_p=''|| UPPER(stat_code) ||'_ADDR_ADMIN_P';
		ELSE
			tbl_nme_addr_p = '';
			IF tbl_nme_addr_p = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_ADDR_ADMIN_P DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_ADDR_ADMIN_P Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'Cheking for Addr_Admin_P';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
---------------------------------------------------------------------------------Checking for Edgeline--------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(tbl_nme_edgeline)||''' AND TABLE_SCHEMA ='''||sch_name||''' ' into count;
		IF count = 0 THEN
			tbl_nme_edgeline = '';
			IF tbl_nme_edgeline = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>% DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(tbl_nme_edgeline);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(tbl_nme_edgeline)||' Table Does not Exists in '||sch_name||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'Checking for edgeline';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
--------------------------------------------------------------------------------Checking for Entryshift-------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(tbl_nme_shift)||''' AND TABLE_SCHEMA ='''||sch_name||''' ' into count;
		IF count = 0 THEN
			tbl_nme_shift = '';
			IF tbl_nme_shift = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>% DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(tbl_nme_shift);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(tbl_nme_shift)||' Table Does not Exists in '||sch_name||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'checking for entryshift';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
------------------------------------------------------------------------------Checking for Non_Entryshift-----------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(tbl_nme_nonshift)||''' AND TABLE_SCHEMA ='''||sch_name||''' ' into count;
		IF count = 0 THEN
			tbl_nme_nonshift = '';
			IF tbl_nme_nonshift = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>% DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(tbl_nme_nonshift);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(tbl_nme_nonshift)||' Table Does not Exists in '||sch_name||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'checking for non_entryshift';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
----------------------------------------------------------------------------Checking for Locality Boundary----------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_LOC_BOUNDARY'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbl_nme_loc=''|| UPPER(stat_code) ||'_LOC_BOUNDARY';
-- 			RAISE WARNING 'LOC_BOUNDARY % AA :%',tbl_nme_loc,'';
		ELSE
			tbl_nme_loc = '';
			IF tbl_nme_loc = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_LOC_BOUNDARY DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_LOC_BOUNDARY Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'Checking for locality Boundary';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
------------------------------------------------------------------------------Checking for State Boundary-----------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_STATE_BOUNDARY'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbl_nme_state=''|| UPPER(stat_code) ||'_STATE_BOUNDARY';
		ELSE
			tbl_nme_state = '';
			IF tbl_nme_state = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_STATE_BOUNDARY DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_STATE_BOUNDARY Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'Checking for State Boundary';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
------------------------------------------------------------------------------Checking for City Boundary------------------------------------------------------------------------------------
	
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_CITY_BOUNDARY'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbl_nme_city=''|| UPPER(stat_code) ||'_CITY_BOUNDARY';
		ELSE
			tbl_nme_city = '';
			IF tbl_nme_city = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_CITY_BOUNDARY DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_CITY_BOUNDARY Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'Checking for CITY Boundary';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
	------------------------------------------------------------------------------Checking for DISTRICT Boundary------------------------------------------------------------------------------------
	
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_DISTRICT_BOUNDARY'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbl_nme_dist=''|| UPPER(stat_code) ||'_DISTRICT_BOUNDARY';
		ELSE
			tbl_nme_dist = '';
			IF tbl_nme_dist = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_DISTRICT_BOUNDARY DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_DISTRICT_BOUNDARY Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'Checking for DISTRICT Boundary';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
-------------------------------------------------------------------------------Checking for Brand List--------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE ''BRAND_LIST'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbl_name_brand_list='BRAND_LIST';
		ELSE
			tbl_name_brand_list = '';
			IF tbl_name_brand_list = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>BRAND_LIST DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>';
				EXECUTE'insert into '||attrib_error||'(message) values(''BRAND_LIST Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
	END;
---------------------------------------------------------------------------------Checking for Poi Cat---------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE ''POI_CAT'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbl_name_poi_cat='POI_CAT';
		ELSE
			tbl_name_poi_cat = '';
			IF tbl_name_poi_cat = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>POI_CAT DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>';
				EXECUTE'insert into '||attrib_error||'(message) values(''POI_CAT Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
	    RAISE INFO 'Checking for POI Category';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
	
	
	
-------------------------------------------------------------------------------Checking for State Abbr--------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE ''STATE_ABBR'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbl_name_state_abbr='STATE_ABBR';
		ELSE
			tbl_name_state_abbr = '';
			IF tbl_nme_city = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>STATE_ABBR DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>';
				EXECUTE'insert into '||attrib_error||'(message) values(''STATE_ABBR Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'Checking for State Abbr';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
------------------------------------------------------------------------------Checking for Rail Network-------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_RAIL_NETWORK'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbl_name_rail=''|| UPPER(stat_code) ||'_RAIL_NETWORK';
		ELSE
			tbl_name_rail = '';
			IF tbl_name_rail = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_RAIL_NETWORK DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_RAIL_NETWORK Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'Checking for RAIL Network';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
-------------------------------------------------------------------------------Checking for Luse Water--------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_NATIONAL_LUSE_WATER'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbl_name_water=''|| UPPER(stat_code) ||'_NATIONAL_LUSE_WATER';
		ELSE
			tbl_name_water = '';
			IF tbl_name_water = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_NATIONAL_LUSE_WATER DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_NATIONAL_LUSE_WATER Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'Checking for Luse Water';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
-------------------------------------------------------------------------------Checking for Pin Boundary--------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE ''PINCODE_BOUNDARY'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbl_name_pincode='PINCODE_BOUNDARY';
		ELSE
			tbl_name_pincode = '';
			IF tbl_name_pincode = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>PINCODE_BOUNDARY DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>';
				EXECUTE'insert into '||attrib_error||'(message) values(''PINCODE_BOUNDARY Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'Checking for Pin Boundary';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
-------------------------------------------------------------------------------Checking for Luse Green--------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_NATIONAL_LUSE_GREEN'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbl_name_junction=''|| UPPER(stat_code) ||'_NATIONAL_LUSE_GREEN';
		ELSE
			tbl_name_junction = '';
			IF tbl_name_junction = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_NATIONAL_LUSE_GREEN DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_NATIONAL_LUSE_GREEN Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
	END;
-------------------------------------------------------------------------------Checking for Luse Other--------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_NATIONAL_LUSE_OTHER'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbl_name_other=''|| UPPER(stat_code) ||'_NATIONAL_LUSE_OTHER';
		ELSE
			tbl_name_other = '';
			IF tbl_name_other = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_NATIONAL_LUSE_OTHER DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_NATIONAL_LUSE_OTHER Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'Checking for Luse Other';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
-----------------------------------------------------------------------------Checking for City Junction--------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_CITY_JN'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbl_name_junction=''|| UPPER(stat_code) ||'_CITY_JN';
		ELSE
			tbl_name_junction = '';
			IF tbl_name_junction = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_CITY_JN DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_CITY_JN Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'Checking for City Junction';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------Poi-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF tbl_nme_poi <> '' THEN
--POI->GEOMETRY
-- 1.1.32
-- No error code
-- 31 msec
	BEGIN
		EXECUTE'INSERT INTO '||error_table||'(  unquid, table_name, field_name, field_value, error_type , error_code ) 
		( SELECT t3.id,'''||tbl_nme_poi||''',''Geometry'',t3.geom,''Geometry of Poi should be point'',''1.1.23'' 
		FROM (SELECT t1."ID" id, t1.ST_GeometryType geom FROM (SELECT "ID", ST_GeometryType(t."SP_GEOMETRY") 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t ) As t1 WHERE t1.ST_GeometryType NOT LIKE ''%ST_Point%'') As t3)';
		
		------- SELECT t3.id,'DL_POI','Geometry',t3.geom,'Geometry of Poi should be point','1.1.23' FROM (SELECT t1."ID" id, t1.ST_GeometryType geom FROM (SELECT "ID", ST_GeometryType(t."SP_GEOMETRY") 
		--------FROM mmi_master."DL_POI" As t ) As t1 WHERE t1.ST_GeometryType NOT LIKE '%ST_Point%') As t3
		
		RAISE WARNING '<-----------POI->GEOMETRY';
		RAISE INFO '<-----------1.1.32';
		
		EXCEPTION 
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||'(message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 31.1:%',f1;
		RAISE info 'error caught 31.2:%',f2;
	END;
	RAISE INFO 'Geometry of Poi should be point';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
--------------------------------------------------------------------------------------Edgeline----------------------------------------------------------------------------------------------
IF tbl_nme_edgeline <> '' THEN
--EDGELINE->GEOMETRY
--1.1.33
--No error code
-- 4.3 sec
	BEGIN
	EXECUTE'INSERT INTO '||error_table||'(  unquid, table_name, field_name, field_value, error_type , error_code ) 
		( SELECT t3.id,'''||tbl_nme_edgeline||''',''Geometry'',t3.geom As GEOM_TYPE,''Geometry of edgeline should be line or polyline'',''1.1.33''
		FROM (SELECT t1."ID" id, t1.ST_GeometryType geom FROM (SELECT "ID", ST_GeometryType(t."SP_GEOMETRY") 
		FROM '||sch_name||'."'||UPPER(tbl_nme_edgeline)||'"  As t ) As t1 
		WHERE t1.ST_GeometryType NOT LIKE ''%ST_LineString%'') As t3)';
		
		-----SELECT t3.id,'DL_POI','Geometry',t3.geom As GEOM_TYPE,'Geometry of edgeline should be line or polyline','NO ERROR CODE'
		-----FROM (SELECT t1."ID" id, t1.ST_GeometryType geom FROM (SELECT "ID", ST_GeometryType(t."SP_GEOMETRY") 
		-----FROM mmi_master."DL_POI"  As t ) As t1 
		-----WHERE t1.ST_GeometryType NOT LIKE '%ST_LineString%') As t3
		-------
		RAISE WARNING '<-----------EDGELINE->GEOMETRY';
		RAISE INFO '<-----------1.1.33';
		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
		
	END;
	RAISE INFO 'Geometry of edgeline should be line or polyline';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--EDGELINE->LENGTH
--1.1.57
--2.47.185
-- 47 msec
	BEGIN 
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT a."ID",'''||tbl_nme_edgeline||''',''EXCP'',a."EXCP"::text,''If Poi Edgeline greater than or equal to one kilometer, then maintain ’1KY’ in EXCP'',''1.1.57'' 
		FROM '||sch_name||'."'||UPPER(tbl_nme_edgeline)||'" As a WHERE ST_Length(a."SP_GEOMETRY"::GEOGRAPHY)>=1000 AND COALESCE(a."EXCP",'''') NOT LIKE ''%1KY%'' ';	
		
       ----- SELECT a."ID",'DL_POI','EXCP',a."EXCP"::text,'If Poi Edgeline greater than or equal to one kilometer, then maintain ’1KY’ in EXCP','1.1.57' 
	   ----- FROM mmi_masterv ."DL_POI" As a WHERE ST_Length(a."SP_GEOMETRY"::GEOGRAPHY)>=1000 AND COALESCE(a."EXCP",'') NOT LIKE '%1KY%'
	   
		RAISE WARNING '<-----------EDGELINE->LENGTH';
		RAISE INFO '<-----------1.1.57';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE INFO 'If Poi Edgeline greater than or equal to one kilometer, then maintain ’1KY’ in EXCPt';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
------------------------------------------------------------------------------------Poi-Edgeline--------------------------------------------------------------------------------------------
IF tbl_nme_edgeline <> '' AND tbl_nme_poi <> '' THEN
--POI,EDGELINE->ID
--1.1.23
--1.37.3
-- 47 msec
	BEGIN
	EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		( SELECT t."ID",'''||tbl_nme_poi||''',''ID'',t."ID"::text,''Poi and its edgeline id does not match'',''1.1.23''
		FROM ( SELECT "ID" FROM '||sch_name||'."'||tbl_nme_poi||'" EXCEPT SELECT "ID" FROM '||sch_name||'."'||UPPER(tbl_nme_edgeline)||'" ) As t, '||sch_name||'."'||tbl_nme_poi||'" As t1  
		WHERE t."ID" = t1."ID")';	
		
		/*
				SELECT t."ID",'DL_POI','ID',t."ID"::text,'Poi and its edgeline id does not match','1.1.23'
				FROM ( SELECT "ID" FROM mmi_master."DL_POI" EXCEPT SELECT "ID" FROM mmi_master."DL_POI_EDGELINE" ) As t, mmi_master."DL_POI" As t1  
				WHERE t."ID" = t1."ID"

         */				
		
		RAISE WARNING '<-----------POI,EDGELINE->ID';
		RAISE INFO '<-----------1.1.23';
		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 3.1:%',f1;
		RAISE info 'error caught 3.2:%',f2;
	END;
	RAISE INFO 'Poi and its edgeline id does not match';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,EDGELINE->EDGE_ID
--1.1.23
--1.37.3
--47 msec
	BEGIN
	EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		( SELECT t."ID",'''||tbl_nme_poi||''',''EDGE_ID'',t."EDGE_ID"::text,''Poi and its edgeline edge_id does not match'',''1.1.23''            
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t JOIN  '||sch_name||'."'||UPPER(tbl_nme_edgeline)||'" As t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" AND 
	    t."EDGE_ID" <> t1."EDGE_ID" )';
		
		/*
				SELECT t."ID",'DL_POI','EDGE_ID',t."EDGE_ID"::text,'Poi and its edgeline edge_id does not match','1.1.23'            
				FROM mmi_master."DL_POI" As t JOIN mmi_master."DL_POI_EDGELINE" As t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" AND 
				t."EDGE_ID" <> t1."EDGE_ID"
		*/		
		
		RAISE WARNING '<-----------POI,EDGELINE->EDGE_ID';
		RAISE INFO '<-----------1.1.23';
		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 7.1:%',f1;
		RAISE info 'error caught 7.2:%',f2;
	END;
	RAISE INFO 'Poi and its edgeline edge_id does not match';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,EDGELINE->INTERSECTION
--1.1.34
-- No error code
-- 734 msec
--- to be review duplicate with 1.1.34,1.1.37,1.1.64
	BEGIN
	EXECUTE ' INSERT INTO '||error_table||'(  unquid, table_name, field_name, field_value, error_type , error_code ) 
		( SELECT t3.id,'''||tbl_nme_poi||''',''Intersection'',''OBJECT'',''Poi does not intersects with edgeline or Edgeline wrong digrection digitize'',''1.1.34'' FROM (SELECT t2."ID" As ID, 
		t2.ST_Intersects As geom FROM (SELECT t."ID", ST_Intersects(t."SP_GEOMETRY", ST_StartPoint(t1."SP_GEOMETRY")) FROM '||sch_name||'."'||tbl_nme_poi||'" As t 
		INNER JOIN '||sch_name||'."'||UPPER(tbl_nme_edgeline)||'" As t1 ON t."ID" = t1."ID" ) t2 WHERE ST_Intersects=''f'') As t3)';
		
        /*
			SELECT t3.id,'DL_POI','Intersection',t3.geom,'Poi does not intersects with edgeline','1.1.34' FROM (SELECT t2."ID" As ID, 
			t2.ST_Intersects As geom FROM (SELECT t."ID", ST_Intersects(t."SP_GEOMETRY", ST_StartPoint(t1."SP_GEOMETRY")) FROM mmi_master."DL_POI" As t 
			INNER JOIN mmi_master."DL_POI_EDGELINE" As t1 ON t."ID" = t1."ID" ) t2 WHERE ST_Intersects='f') As t3
		
		*/		
		RAISE WARNING '<-----------POI,EDGELINE->INTERSECTION';
		RAISE INFO '<-----------1.1.34';
		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 5.1:%',f1;
		RAISE info 'error caught 5.2:%',f2;
	END;
	RAISE INFO 'Poi does not intersects with edgeline';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,EDGELINE->SIDE
--1.1.29
--1.38.2
-- 32 msec
	BEGIN
	EXECUTE ' INSERT INTO '||error_table||'(  unquid, table_name, field_name, field_value, error_type , error_code ) 
		( SELECT t2."ID",'''||tbl_nme_poi||''',''EDGE_SIDE'',t2."EDGE_SIDE"::text,''Poi and its edgeline side does not match'',''1.1.29'' 
		FROM (SELECT t."ID", t."EDGE_SIDE" FROM '||sch_name||'."'||tbl_nme_poi||'" As t JOIN '||sch_name||'."'||UPPER(tbl_nme_edgeline)||'"
		AS t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" AND t."EDGE_ID"=t1."EDGE_ID" AND t."EDGE_SIDE"<>t1."SIDE" ) As t2)';
		
       /*
				SELECT t2."ID",'DL_POI','EDGE_SIDE',t2."EDGE_SIDE"::text,'Poi and its edgeline side does not match','1.1.29' 
				FROM (SELECT t."ID", t."EDGE_SIDE" FROM mmi_master."DL_POI" As t JOIN mmi_master."DL_POI_EDGELINE"
				AS t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" AND t."EDGE_ID"=t1."EDGE_ID" AND t."EDGE_SIDE"<>t1."SIDE" ) As t2

	   */		
		RAISE WARNING '<-----------POI,EDGELINE->SIDE';
		RAISE INFO '<-----------1.1.29';
		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 6.1:%',f1;
		RAISE info 'error caught 6.2:%',f2;
	END;
	RAISE INFO 'Poi and its edgeline side does not match';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,EDGELINE->DIRECTION OF EDGELINE
--1.1.37
--No error code
-- 766 msec
---to be review duplicate with 1.1.34,1.1.37,1.1.64
	-- BEGIN 
		-- EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		-- ( SELECT t3.id,'''||tbl_nme_edgeline||''',''OBJECT'',''WRONG DIRECTION'',''Edgeline direction should be from Poi to Road'',''1.1.37'' FROM (SELECT t2."ID" As ID, 
		-- t2.ST_Intersects As geom FROM (SELECT t."ID", ST_Intersects(t1."SP_GEOMETRY", ST_StartPoint(t."SP_GEOMETRY")) FROM '||sch_name||'."'||UPPER(tbl_nme_edgeline)||'" As t 
		-- INNER JOIN '||sch_name||'."'||tbl_nme_poi||'" As t1 ON t."ID" = t1."ID" ) t2 WHERE ST_Intersects=''f'') As t3)';
		
		-- /*
		 -- SELECT t3.id,'DL_POI','Intersection',t3.geom,'Edgeline direction should be from Poi to Road','1.1.37' FROM (SELECT t2."ID" As ID, 
		-- t2.ST_Intersects As geom FROM (SELECT t."ID", ST_Intersects(t1."SP_GEOMETRY", ST_StartPoint(t."SP_GEOMETRY")) FROM mmi_master."DL_POI_EDGELINE" As t 
		-- INNER JOIN mmi_master."DL_POI" As t1 ON t."ID" = t1."ID" ) t2 WHERE ST_Intersects='f') As t3
		-- */
		-- RAISE WARNING '<-----------POI,EDGELINE->DIRECTION OF EDGELINE';
		--RAISE INFO '<-----------1.1.37';

		-- EXCEPTION
			-- WHEN OTHERS THEN
				-- GET STACKED DIAGNOSTICS 
				-- f1=MESSAGE_TEXT,
				-- f2=PG_EXCEPTION_CONTEXT; 
		
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		-- RAISE info 'error caught 41.1:%',f1;
		-- RAISE info 'error caught 41.2:%',f2;
	-- END;
	-- RAISE INFO 'Edgeline direction should be from Poi to Road';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,EDGELINE->PARENT AND CHILD POI’S HAVE A DIFFERENT ENTRY
-- --1.1.48
-- --No error code
-- --610 msec
-- --- to be review buffer chnge 5 mtr
	-- BEGIN
	-- EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		-- SELECT Child."ID",'''||tbl_nme_poi||''',''EXCP'',Child."EXCP"::text,''If Parent and child poi’s have a different entry, then maintain ’PCY’ in EXCP'',''1.1.48'' 
		-- FROM ( SELECT c."ID",c."PIP_ID",c."EXCP",d."SP_GEOMETRY" FROM '||sch_name||'."'||tbl_nme_poi||'" As c INNER JOIN '||sch_name||'."'||UPPER(tbl_nme_edgeline)||'" As d ON c."ID"=d."ID" 
		-- WHERE c."PIP_ID"<>0 ) As Child 
		-- INNER JOIN (Select b."ID",b."SP_GEOMETRY" FROM '||sch_name||'."'||UPPER(tbl_nme_edgeline)||'" As b Where b."ID" IN (Select a."PIP_ID" FROM '||sch_name||'."'||tbl_nme_poi||'" a 
		-- WHERE a."PIP_ID"<>0 Group By a."PIP_ID")) As Parent ON Child."PIP_ID"=Parent."ID" 
		-- WHERE ST_Intersects(ST_Buffer(Cast(ST_SetSRID(ST_EndPoint(Parent."SP_GEOMETRY"),4326) As geography),5) , Child."SP_GEOMETRY"::GEOGRAPHY)=''f'' AND COALESCE(Child."EXCP",'''') NOT LIKE ''%PCY%'' ';
	
    -- /*
     -- SELECT Child."ID",'DL_POI','EXCP',Child."EXCP"::text,'If Parent and child poi’s have a different entry, then maintain ’PCY’ in EXCP','NO ERROR CODE' 
		-- FROM ( SELECT c."ID",c."PIP_ID",c."EXCP",d."SP_GEOMETRY" FROM mmi_master."DL_POI" As c INNER JOIN mmi_master."GA_POI_EDGELINE" As d ON c."ID"=d."ID" 
		-- WHERE c."PIP_ID"<>0 ) As Child 
		-- INNER JOIN (Select b."ID",b."SP_GEOMETRY" FROM mmi_master."DL_POI_EDGELINE" As b Where b."ID" IN (Select a."PIP_ID" FROM mmi_master."DL_POI" a 
		-- WHERE a."PIP_ID"<>0 Group By a."PIP_ID")) As Parent ON Child."PIP_ID"=Parent."ID" 
		-- WHERE ST_SELECT t1."ID", COUNT(t1."ID") AS multiple FROM mmi_master."DL_ROAD_NETWORK" AS t, mmi_master."DL_POI_EDGELINE" AS t1 
-- WHERE ST_Intersects(t."SP_GEOMETRY", t1."SP_GEOMETRY") GROUP BY t1."ID" ORDER BY multiple desc	(ST_Buffer(Cast(ST_SetSRID(ST_EndPoint(Parent."SP_GEOMETRY"),4326) As geography),10) , Child."SP_GEOMETRY"::GEOGRAPHY)='f' AND COALESCE(Child."EXCP",'') NOT LIKE '%PCY%'

    -- */	
		-- RAISE WARNING '<-----------POI,EDGELINE->PARENT AND CHILD POI’S HAVE A DIFFERENT ENTRY';
		--RAISE INFO '<-----------1.1.48';
		
		-- EXCEPTION
			-- WHEN OTHERS THEN
				-- GET STACKED DIAGNOSTICS 
				-- f1=MESSAGE_TEXT,
				-- f2=PG_EXCEPTION_CONTEXT; 
		
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		-- RAISE info 'error caught 41.1:%',f1;
		-- RAISE info 'error caught 41.2:%',f2;
	-- END;
	-- RAISE INFO 'If Parent and child poi’s have a different entry, then maintain ’PCY’ in EXCP';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;

-------POI, Edegeline and Road Network, Overshoot Edge_Line
----1.1.70, ABHINAV
---- 5.7 sec
    BEGIN
	EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		  SELECT t3."ID",'''||tbl_nme_poi||''',''OBJECT'',''Overshoot'',''Edegeline and Road Network Overshoot Edge_Line'',''1.1.70'' FROM 
         (SELECT t1."ID",st_distance(ST_ENDPOINT(t1."SP_GEOMETRY")::Geography,ST_intersection(t2."SP_GEOMETRY",t1."SP_GEOMETRY")::Geography,TRUE) as dist 
	     FROM '||sch_name||'."'||tbl_nme_edgeline||'" t1, '||tbl_nme_road||' AS t2 where st_crosses(t1."SP_GEOMETRY",t2."SP_GEOMETRY")
	      AND t1."EDGE_ID" = t2."EDGE_ID") t3 WHERE t3.dist>0.1 ';   
	  /*
				select t3."ID",'DL_POI','EXCP','overshoot EDGELINE difference of 0.1','1.1.70' from 
				(select t1."ID",st_distance(ST_ENDPOINT(t1."SP_GEOMETRY")::Geography,ST_intersection(t2."SP_GEOMETRY",t1."SP_GEOMETRY")::
				Geography,TRUE) as dist  FROM mmi_master."DL_POI_EDGELINE" t1,mmi_master."DL_ROAD_NETWORK" AS t2 where st_crosses
				(t1."SP_GEOMETRY",t2."SP_GEOMETRY") and t1."EDGE_ID" = t2."EDGE_ID") t3 where t3.dist>0.1

	   */
	  
	  RAISE  WARNING '<-----------POI, EDGELINE->EDGE_ID';
	  RAISE INFO '<-----------1.1.70';
	  
	  EXCEPTION
	       WHEN OTHERS THEN
		   GET STACKED DIAGNOSTICS
		   f1=MESSAGE_TEXT,
		   f2=PG_EXCEPTION_CONTEXT;
		   
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 11.1:%',f1;
		RAISE info 'error caught 11.2:%',f2;
	END;
	RAISE INFO 'overshoot EDGELINE difference of 0.1';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
-------POI, Edgeline should not have more than 2 nodes
----1.1.66, ABHINAV
---- 32 msec
    BEGIN
	EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		  SELECT t1."ID", '''||tbl_nme_poi||''',''Polyline'',''OBJECT'',''Edgeline should not have more then 2 nodes'',''1.1.66''
	     FROM '||sch_name||'."'||tbl_nme_edgeline||'" AS t1 where ST_npoints("SP_GEOMETRY")>2 ';

	   /*
			SELECT t1."ID", 'DL_POI','EXCP','Edgeline should not have more then 2 nodes
			','1.1.66' FROM mmi_master."DL_POI_EDGELINE" AS t1 where ST_npoints("SP_GEOMETRY")>2	
      */
	  
	  RAISE  WARNING '<-----------POI, EDGELINE->Geometry More then 2 nodes';
	  RAISE INFO '<-----------1.1.66';
	  
	  EXCEPTION
	       WHEN OTHERS THEN
		   GET STACKED DIAGNOSTICS
		   f1=MESSAGE_TEXT,
		   f2=PG_EXCEPTION_CONTEXT;
		   
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 11.1:%',f1;
		RAISE info 'error caught 11.2:%',f2;
	END;
	RAISE INFO 'Edgeline should not have more then 2 nodes';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
-------POI, Poi not intersect with edge_line END point
----1.1.63, ABHINAV
---- 32 msec
    BEGIN
	EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		  select t1."ID", '''||tbl_nme_poi||''',''EXCP'',''t1."EDGE_ID"'',''Poi not intersect with edge_line END point'',''1.1.63'' from '||sch_name||'."'||tbl_nme_poi||'" t1, '||sch_name||'."'||tbl_nme_edgeline||'" AS t2 
       where t1."EDGE_ID" = t2."EDGE_ID" and ST_Intersects(t1."SP_GEOMETRY",ST_Endpoint(t2."SP_GEOMETRY")) = TRUE ';

	    /*
			select t1."ID", 'DL_POI','EXCP','Poi not intersect with edge_line END point
			','1.1.63' from mmi_master."DL_POI" t1,mmi_master."DL_POI_EDGELINE" AS t2 
			where t1."EDGE_ID" = t2."EDGE_ID" and ST_Intersects(t1."SP_GEOMETRY",ST_Endpoint(t2."SP_GEOMETRY")) = TRUE  
        */
	  
	  RAISE  WARNING '<-----------POI, EDGELINE->not intersect with edge_line END point';
	  RAISE INFO '<-----------1.1.63';
	  
	  EXCEPTION
	       WHEN OTHERS THEN
		   GET STACKED DIAGNOSTICS
		   f1=MESSAGE_TEXT,
		   f2=PG_EXCEPTION_CONTEXT;
		   
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 11.1:%',f1;
		RAISE info 'error caught 11.2:%',f2;
	END;
	RAISE INFO 'Poi not intersect with edge_line END point';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
-------POI, Poi not intersect with edge_line START point
----1.1.64, ABHINAV
---- 32 msec
---- to be review duplicate with 1.1.34,1.1.37,1.1.64
  -- BEGIN
	-- EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		  -- select t1."ID", '''||tbl_nme_poi||''',''OBJECT'',t1."EDGE_ID",''Poi not intersect with edge_line start point
      -- '',''1.1.64'' from '||sch_name||'."'||tbl_nme_poi||'" t1, '||sch_name||'."'||tbl_nme_edgeline||'" AS t2 
       -- where t1."ID" = t2."ID" and ST_Intersects(t1."SP_GEOMETRY",ST_Startpoint(t2."SP_GEOMETRY")) = TRUE ';

	    -- /*
	    -- select t1."ID", 'DL_POI','EXCP','Poi not intersect with edge_line END point
        -- ','No ERROR CODE' from mmi_master."DL_POI" t1,mmi_master."DL_POI_EDGELINE" AS t2 
         -- where t1."ID" = t2."ID" and ST_Intersects(t1."SP_GEOMETRY",ST_Startpoint(t2."SP_GEOMETRY")) = TRUE  
        -- */
	  
	  -- RAISE  WARNING '<-----------POI, EDGELINE->not intersect with edge_line START point';
	  --RAISE INFO '<-----------1.1.64';
	  
	  -- EXCEPTION
	       -- WHEN OTHERS THEN
		   -- GET STACKED DIAGNOSTICS
		   -- f1=MESSAGE_TEXT,
		   -- f2=PG_EXCEPTION_CONTEXT;
		   
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		-- RAISE info 'error caught 11.1:%',f1;
		-- RAISE info 'error caught 11.2:%',f2;
	-- END;
	-- RAISE INFO 'Poi not intersect with edge_line START point';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
END IF;
------------------------------------------------------------------------------------Poi and Non_Entryshift----------------------------------------------------------------------------------
IF tbl_nme_poi <> '' AND tbl_nme_nonshift <> '' THEN
--POI,ENTRYNONSHIFT->EDGE_ID
--1.1.25
--1.37.2
--32 sec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		( SELECT t1."ID",'''||tbl_nme_poi||''',''EDGE_ID'',t."EDGE_ID"::text,''Poi and its non-shift entry edge_id does not match'',''1.1.25''            
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t JOIN '||sch_name||'."'|| UPPER(tbl_nme_nonshift) ||'" As t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" 		
		AND t."EDGE_ID" <> t1."EDGE_ID" )';
		
		/*
				SELECT t1."ID",'DL_POI','EDGE_ID',t."EDGE_ID"::text,'Poi and its non-shift entry edge_id does not match','1.1.25'            
				FROM mmi_master."DL_POI" As t JOIN mmi_master."DL_POI_ENTRYNONSHIFT" As t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" 		
				AND t."EDGE_ID" <> t1."EDGE_ID"  	
		*/
		
		
		RAISE WARNING '<-----------POI,ENTRYNONSHIFT->EDGE_ID';
	    RAISE INFO '<-----------1.1.25';

		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 11.1:%',f1;
		RAISE info 'error caught 11.2:%',f2;
	END;
	RAISE INFO 'Poi and its non-shift entry edge_id does not match';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,ENTRYNONSHIFT->ID
--1.1.39
--No Error Code
-- 31 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		( SELECT t."ID",'''||tbl_nme_poi||''',''ID'',t."ID"::text,''Poi and its non-shift entry id does not match'',''1.1.39''
		FROM ( SELECT "ID" FROM '||sch_name||'."'||tbl_nme_poi||'" EXCEPT SELECT "ID" FROM '||sch_name||'."'|| UPPER(tbl_nme_nonshift) ||'" ) As t,
		 '||sch_name||'."'||tbl_nme_poi||'" As t1 WHERE t."ID" = t1."ID" )';
		 
		 /*
		  
				SELECT t."ID",'DL_POI','ID',t."ID"::text,'Poi and its non-shift entry id does not match','1.1.39'
				FROM ( SELECT "ID" FROM mmi_master."DL_POI" EXCEPT SELECT "ID" FROM mmi_master."DL_POI_ENTRYNONSHIFT" ) As t,
				mmi_master."DL_POI" As t1 WHERE t."ID" = t1."ID"

		 */
		RAISE WARNING '<-----------POI,ENTRYNONSHIFT->ID';
		RAISE INFO '<-----------1.1.39';

		 
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 12.1:%',f1;
		RAISE info 'error caught 12.2:%',f2;
	END;
	RAISE INFO 'Poi and its non-shift entry id does not match';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
--------------------------------------------------------------------------------------Poi and Entryshift------------------------------------------------------------------------------------
IF tbl_nme_poi <> '' AND tbl_nme_shift <> '' THEN
--POI,ENTRYSHIFT->EDGE_ID
--1.1.24
--1.37.2
--31 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		( SELECT t1."ID",'''||tbl_nme_poi||''',''EDGE_ID'',t."EDGE_ID"::text,''Poi and its shift entry edge_id does not match'',''1.1.24''            
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t JOIN '||sch_name||'."'|| UPPER(tbl_nme_shift) ||'" As t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" 
		AND t."EDGE_ID" <> t1."EDGE_ID" )';
		
		/*
			SELECT t1."ID",'DL_POI','EDGE_ID',t."EDGE_ID"::text,'Poi and its shift entry edge_id does not match','1.1.24'            
			FROM mmi_master."DL_POI" As t JOIN mmi_master."DL_POI_ENTRYSHIFT" As t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" 
			AND t."EDGE_ID" <> t1."EDGE_ID"	

		*/
		
		RAISE WARNING '<-----------POI,ENTRYSHIFT->EDGE_ID';
		RAISE INFO '<-----------1.1.24';

		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 8.1:%',f1;
		RAISE info 'error caught 8.2:%',f2;
	END;
	RAISE INFO 'Poi and its shift entry edge_id does not match';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,ENTRYSHIFT->ID
--1.1.63
--32 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		( SELECT t."ID",'''||tbl_nme_poi||''',''ID'',t."ID"::text,''Poi and its shift entry id does not match'',''1.1.38''
		FROM ( SELECT "ID" FROM '||sch_name||'."'||tbl_nme_poi||'" EXCEPT SELECT "ID" FROM '||sch_name||'."'|| UPPER(tbl_nme_shift) ||'" ) As t, '||sch_name||'."'||tbl_nme_poi||'" As t1 
		WHERE t."ID" = t1."ID")';
		
		/*
			SELECT t."ID",'DL_POI','ID',t."ID"::text,'Poi and its shift entry id does not match','1.1.38'
			FROM ( SELECT "ID" FROM mmi_master."DL_POI" EXCEPT SELECT "ID" FROM mmi_master."DL_POI_ENTRYSHIFT" ) As t,
			mmi_master."DL_POI" As t1 WHERE t."ID" = t1."ID"
		*/
		
		RAISE WARNING '<-----------POI,ENTRYSHIFT->ID';
		RAISE INFO '<-----------1.1.63';

		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 9.1:%',f1;
		RAISE info 'error caught 9.2:%',f2;
	END;
	RAISE INFO 'Poi and its shift entry id does not match';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

----POI,ID mismatch in Shift and Non-Shift Entry
----1.1.72, ABHINAV
---47 msec

    BEGIN
        EXECUTE 'SELECT t1."ID",'''||tbl_nme_poi||''',''ID'',t1."ID"::text,''ID mismatch in Shift and Non-Shift Entry'',''1.1.72'' FROM 
                ( SELECT "ID" FROM '||sch_name||'."'||tbl_nme_shift||'" EXCEPT (SELECT "ID" FROM '||sch_name||'."'||tbl_nme_nonshift||'" )) As t, '||sch_name||'."'||tbl_nme_poi||'" As t1 
		         WHERE t."ID" <> t1."ID"';		 
				 /*
						SELECT t1."ID",'DL_POI','ID',t1."ID"::text,'ID mismatch in Shift and Non-Shift Entry','1.1.72' FROM 
						( SELECT "ID" FROM mmi_master."DL_POI_ENTRYNONSHIFT" EXCEPT (SELECT "ID" FROM mmi_master."DL_POI_ENTRYNONSHIFT" )) As t,
						mmi_master."DL_POI" As t1  WHERE t."ID" <> t1."ID"

				*/
				 
		RAISE WARNING '<-----------POI,ENTRYSHIFT->ID = ENTRYNONSHIFT->ID';
		RAISE INFO '<-----------1.1.72';

		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 9.1:%',f1;
		RAISE info 'error caught 9.2:%',f2;
	END;
	RAISE INFO 'POI,ID mismatch in Shift and Non-Shift Entry';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;		 
	
END IF;
-----------------------------------------------------------------------------------EdgeLine AND ENTRYNONSHIFT-------------------------------------------------------------------------------
IF tbl_nme_nonshift <> '' AND tbl_nme_edgeline <> '' THEN
--ENTRYNONSHIFT,EDGELINE->INTERSECTION
--1.1.36
-- No error code
---797 msec
 	BEGIN 
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		( SELECT t3.id,'''||tbl_nme_nonshift||''',''Intersection'',''OBJECT'',''Non-shift entry point should be intersects with end node of Edgeline'',''1.1.36'' 
		FROM (SELECT t2."ID" As ID, t2.ST_Intersects As geom FROM (SELECT t."ID", ST_Intersects(t."SP_GEOMETRY", ST_EndPoint(t1."SP_GEOMETRY")) FROM '||sch_name||'."'|| UPPER(tbl_nme_nonshift) ||'" As t 
		INNER JOIN '||sch_name||'."'||UPPER(tbl_nme_edgeline)||'" As t1 ON t."ID" = t1."ID") t2 WHERE ST_Intersects=''f'') As t3)';
		
        /*
			SELECT t3.id,'DL_POI','Intersection',t3.geom,'Non-shift entry point should be intersects with end node of Edgeline','1.1.36' 
			FROM (SELECT t2."ID" As ID, t2.ST_Intersects As geom FROM (SELECT t."ID", ST_Intersects(t."SP_GEOMETRY", ST_EndPoint
			(t1."SP_GEOMETRY")) FROM mmi_master."DL_POI_ENTRYNONSHIFT" As t 
			INNER JOIN mmi_master."DL_POI_EDGELINE" As t1 ON t."ID" = t1."ID") t2 WHERE ST_Intersects='f') As t3 

		*/		
		RAISE WARNING '<-----------ENTRYNONSHIFT,EDGELINE->INTERSECTION';
		RAISE INFO '<-----------1.1.36';

		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 38.1:%',f1;
		RAISE info 'error caught 38.2:%',f2;
	END;
	RAISE INFO 'Non-shift entry point should be intersects with end node of Edgeline';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
------------------------------------------------------------------------------------EdgeLine AND ENTRYSHIFT---------------------------------------------------------------------------------
IF tbl_nme_shift <> '' AND tbl_nme_edgeline <> '' THEN
--ENTRYSHIFT,EDGELINE->LOCATION ENTRYSHIFT POINT
--1.1.35
--No error code
-- 7.2 sec
	BEGIN 
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT t."ID",'''||tbl_nme_shift||''',''ID'',t."ID"::text,''Shift entry point should be near end node of Edgeline between 0.4m and 0.6m range'',''1.1.35'' 
		FROM (SELECT a."ID",ST_Intersects(ST_Buffer(b."SP_GEOMETRY",0.000001),a."SP_GEOMETRY"), ST_Distance(a."SP_GEOMETRY", ST_EndPoint(b."SP_GEOMETRY"),true) 
		FROM '||sch_name||'."'|| UPPER(tbl_nme_shift) ||'" a, '||sch_name||'."'||UPPER(tbl_nme_edgeline)||'" b WHERE a."ID"=b."ID") As t WHERE t.ST_Distance NOT BETWEEN 0.4 AND 0.6 AND ST_Intersects=''f'' ';
		
		/*
		--SELECT t."ID",'DL_POI','ID',t."ID"::text,'Shift entry point should be near end node of Edgeline between 0.4m and 0.6m range','1.1.35' 
		--FROM (SELECT a."ID",ST_Intersects(ST_Buffer(b."SP_GEOMETRY",0.000001),a."SP_GEOMETRY"), ST_Distance(a."SP_GEOMETRY", ST_EndPoint(b."SP_GEOMETRY"),true) 
		--FROM mmi_master."DL_POI_ENTRYSHIFT" a, mmi_master."DL_POI_EDGELINE" b WHERE a."ID"=b."ID") As t WHERE t.ST_Distance NOT BETWEEN 0.4 AND 0.6 AND ST_                 ='f'
		*/
		RAISE WARNING '<-----------ENTRYSHIFT,EDGELINE->LOCATION ENTRYSHIFT POINT';
		RAISE INFO '<-----------1.1.35';

		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 39.1:%',f1;
		RAISE info 'error caught 39.2:%',f2;
	END;
	RAISE INFO 'Shift entry point should be near end node of Edgeline between 0.4m and 0.6m range';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
----------------------------------------------------------------------------------------Road_Network----------------------------------------------------------------------------------------
IF tbl_nme_road <> '' AND tbl_nme_poi <> '' THEN
--1.1.50
--1.47.182
--- 47 msec	

--to be review with 1.1.45 both qa is same like
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		( SELECT t."ID",'''||tbl_nme_poi||''',''EDGE_ID'',t."EDGE_ID"::text,''Poi should not be attached with Walkway & Pedastrian or foot over bridge'',''1.1.50''            
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t JOIN '||tbl_nme_road||' As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND (t1."FOW_PREV"=''WW'' OR t1."FOW_PREV"=''PZ'' OR t1."FOW_PREV"=''FO'' ))';

		
     --( SELECT t."ID",'DL_POI','EDGE_ID',t."EDGE_ID"::text,'Poi should not be attached with Walkway & Pedastrian','1.47.182'            
     --FROM mmi_master."DL_POI" As t JOIN mmi_master."DL_ROAD_NETWORK" As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND
     --(t1."PJ"<>'' OR t1."FOW_PREV"='WW') )
		
		RAISE WARNING '<-----------POI,ROAD_NETWORK->INTERSECTION, FOW_PREV=''NMR''';
		RAISE INFO '<-----------1.1.50';

		
		EXCEPTION
			WHEN OTHERS THEN    
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 14.1:%',f1;
		RAISE info 'error caught 14.2:%',f2;
	END;
	RAISE INFO 'Poi should not be attached with Walkway & Pedastrian';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.1.26
--1.37.4
-- 32 msec	
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		( SELECT t."ID",'''||tbl_nme_poi||''',''EDGE_ID'',t."EDGE_ID"::text,''Poi should not be attached with ’NMR’ roads in Road Network'',''1.1.26''            
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t JOIN '||tbl_nme_road||' As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND t1."FTR_CRY"=''NMR'')';
        /*
			SELECT t."ID",'DL_POI','EDGE_ID',t."EDGE_ID"::text,'Poi should not be attached with ’NMR’ roads in Road Network','1.37.4'            
			FROM mmi_master."DL_POI" As t JOIN mmi_master."DL_ROAD_NETWORK" As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND t1."FTR_CRY"='NMR'

	*/
		
		RAISE WARNING '<-----------POI,ROAD_NETWORK->INTERSECTION, FOW_PREV=''NMR''';
		RAISE INFO '<-----------1.1.26';

		
		EXCEPTION
			WHEN OTHERS THEN    
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 14.1:%',f1;
		RAISE info 'error caught 14.2:%',f2;
	END;
	RAISE INFO 'Poi should not be attached with ’NMR’ roads in Road Network';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,ROAD_NETWORK>INTERSECTION, FT=1 OR FT=2
--1.1.27
--1.37.6
--47 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		( SELECT t."ID",'''||tbl_nme_poi||''',''EDGE_ID'',t."EDGE_ID"::text,''Poi point should not be attached with ferry roads'',''1.1.27''            
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t JOIN '||tbl_nme_road||'  As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND t1."FT"=1)';
		
       /*
						 
			SELECT t."ID",'DL_POI','EDGE_ID',t."EDGE_ID"::text,'Poi point should not be attached with ferry roads','1.1.27'            
			FROM mmi_master."DL_POI" As t JOIN mmi_master."DL_ROAD_NETWORK"  As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND t1."FT"=1

	   */		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 15.1:%',f1;
		RAISE info 'error caught 15.2:%',f2;
	END;
	RAISE INFO 'Poi point should not be attached with ferry roads';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,ROAD_NETWORK->STT_ID
--1.1.28
--1.37.5
-- 31 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		( SELECT t."ID",'''||tbl_nme_poi||''',''EDGE_ID'',t."EDGE_ID"::text,''Poi’s Stt_Id does not match with its Road Network Stt_Id'',''1.1.28''            
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t JOIN '||tbl_nme_road||'  As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND t."STT_ID"<>t1."STT_ID" 
		)';
		
		/*
		  SELECT t."ID",'DL_POI','EDGE_ID',t."EDGE_ID"::text,'Poi’s Stt_Id does not match with its Road Network Stt_Id','1.1.28'            
		FROM mmi_master."DL_POI" As t JOIN mmi_master."DL_ROAD_NETWORK"  As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND t."STT_ID"<>t1."STT_ID"
		*/
		
		RAISE WARNING '<-----------POI,ROAD_NETWORK->STT_ID';
		RAISE INFO '<-----------1.1.28';

		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 16.1:%',f1;
		RAISE info 'error caught 16.2:%',f2;
	END;
	RAISE INFO 'Poi’s Stt_Id does not match with its Road Network Stt_Id';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,ROAD_NETWORK->EDGE_ID
--1.1.22
--1.37.1
-- 47 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT t1."ID",'''||tbl_nme_poi||''',''EDGE_ID'',t1."EDGE_ID"::text,''Poi’s Edge_Id does not match with its Road Network Edge_Id'',''1.1.22''
		FROM (SELECT "EDGE_ID" FROM '||sch_name||'."'||tbl_nme_poi||'" EXCEPT (SELECT "EDGE_ID" FROM '||tbl_nme_road||' )) As t , '||sch_name||'."'||tbl_nme_poi||'"  
		AS t1 WHERE t."EDGE_ID" = t1."EDGE_ID" ';
		
		/*
		  SELECT t1."ID",'DL_POI','EDGE_ID',t1."EDGE_ID"::text,'Poi’s Edge_Id does not match with its Road Network Edge_Id','1.37.1'
		FROM (SELECT "EDGE_ID" FROM mmi_master."DL_POI" EXCEPT (SELECT "EDGE_ID" FROM mmi_master."DL_ROAD_NETWORK" )) As t , mmi_master."DL_POI"  
		AS t1 WHERE t."EDGE_ID" = t1."EDGE_ID"	
		*/
		
		RAISE WARNING '<-----------POI,ROAD_NETWORK->EDGE_ID';
		RAISE INFO '<-----------1.1.26';

		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 17.1:%',f1;
		RAISE info 'error caught 17.2:%',f2;
	END;
	RAISE INFO 'Poi’s Edge_Id does not match with its Road Network Edge_Id';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,ROAD_NETWORK->INTERSECTION
--1.1.44
-- no error code
	BEGIN 
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT a."ID",'''||tbl_nme_poi||''',''EXCP'',a."EXCP"::text,''If Poi attached with Bridge, then maintain ’BRY’ in EXCP'',''1.1.44'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As a, '||tbl_nme_road||' As b WHERE (ST_Intersects(a."SP_GEOMETRY",b."SP_GEOMETRY")=true) AND COALESCE(a."EXCP",'''') NOT LIKE ''%BRY%'' AND 
		b."FOW_PREV"=''BR'' GROUP BY a."ID",a."EXCP"';
		
		/*
			SELECT a."ID",'DL_POI','EXCP',a."EXCP"::text,'If Poi attached with Bridge, then maintain ’BRY’ in EXCP','NO ERROR CODE' 
			FROM mmi_master."DL_POI" As a ,mmi_master."DL_ROAD_NETWORK" As b WHERE (ST_Intersects(a."SP_GEOMETRY",b."SP_GEOMETRY")=true) AND COALESCE(a."EXCP",'') NOT LIKE '%BRY%' AND 
			b."FOW_PREV"='BR' GROUP BY a."ID",a."EXCP"

		*/
	
		RAISE WARNING '<-----------POI,ROAD_NETWORK->INTERSECTION';
		RAISE INFO '<-----------1.1.44';

		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE INFO 'If Poi attached with Bridge, then maintain ’BRY’ in EXCP';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,ROAD_NETWORK->POI ATTACHED WITH FLYOVERS, RAMPS, SUBWAYS
--1.1.45
-- No error code
-- 31 msec
---to be review with 1.1.50 both qa is same like
	BEGIN 
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT a."ID",'''||tbl_nme_poi||''',''EXCP'',a."EXCP"::text,''If Poi attached with Flyovers, Ramps, Subways etc, then maintain ’ELY’ in EXCP'',''1.1.45'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As a, '||tbl_nme_road||' As b WHERE (ST_Intersects(a."SP_GEOMETRY",b."SP_GEOMETRY")=true) AND 
		COALESCE(a."EXCP",'''') NOT LIKE ''%ELY%'' AND (b."FOW_PREV"=''SU'' OR b."FOW_PREV"=''FL'' OR "FOW_PREV"=''RM'' OR b."FOW_PREV"=''BR'') GROUP BY a."ID",a."EXCP"';
		
		/*
			SELECT a."ID",'DL_POI','EXCP',a."EXCP"::text,'If Poi attached with Ferry, then maintain ’FTY’ in EXCP','NO ERROR CODE' 
			FROM mmi_master."DL_POI" As a, mmi_master."DL_ROAD_NETWORK" As b WHERE (ST_Intersects(a."SP_GEOMETRY",b."SP_GEOMETRY")=true) AND COALESCE(a."EXCP",'') NOT LIKE '%FTY%' AND 
			(b."FT"=1 OR b."FT"=2) GROUP BY a."ID",a."EXCP"	

		*/
		RAISE WARNING '<-----------POI,ROAD_NETWORK->POI ATTACHED WITH FLYOVERS, RAMPS, SUBWAYS';
		RAISE INFO '<-----------1.1.45';

		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE INFO 'If Poi attached with Flyovers, Ramps, Subways etc, then maintain ’ELY’ in EXCP';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,ROAD_NETWORK->POI ATTACHED WITH FERRY ROADS
--1.1.46
-- No error Code
-- 31 msec
	BEGIN 
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT a."ID",'''||tbl_nme_poi||''',''EXCP'',a."EXCP"::text,''If Poi attached with Ferry, then maintain ’FTY’ in EXCP'',''1.1.46'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As a, '||tbl_nme_road||' As b WHERE (ST_Intersects(a."SP_GEOMETRY",b."SP_GEOMETRY")=true) AND COALESCE(a."EXCP",'''') NOT LIKE ''%FTY%'' AND 
		(b."FT"=1 OR b."FT"=2) GROUP BY a."ID",a."EXCP"';
		
		/*
			SELECT a."ID",'DL_POI','EXCP',a."EXCP"::text,'If Poi attached with Ferry, then maintain ’FTY’ in EXCP','1.1.46' 
			FROM mmi_master."DL_POI" As a, mmi_master."DL_ROAD_NETWORK" As b WHERE (ST_Intersects(a."SP_GEOMETRY",b."SP_GEOMETRY")=true) AND COALESCE(a."EXCP",'') NOT LIKE '%FTY%' AND 
			(b."FT"=1 OR b."FT"=2) GROUP BY a."ID",a."EXCP"		

		*/
		RAISE WARNING '<-----------POI,ROAD_NETWORK->POI ATTACHED WITH FERRY ROADS';
		RAISE INFO '<-----------1.1.46';

		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE INFO 'If Poi attached with Ferry, then maintain ’FTY’ in EXCP';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
--POI,ROAD_NETWORK->EntryNonPoint not intersecting Road
-- 1.1.67, ABHINAV --review
-- 21 sec
	BEGIN 
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
	    SELECT t1."ID", '''||tbl_nme_nonshift||''',''OBJECT'',''GEOMETRY'',''EntryPoint not intersecting within 0.1m with Road'',''1.1.67'' from '||sch_name||'."'||tbl_nme_nonshift||'" AS t1,'||tbl_nme_road||' AS t2 
          WHERE  t1."EDGE_ID" = t2."EDGE_ID" and ST_Intersects(ST_Buffer(t1."SP_GEOMETRY",0.000001,''''),t2."SP_GEOMETRY")=false';
		  /*
				select t1."ID", 'DL_POI','EXCP','EntryPoint not intersecting Road','1.1.67' from mmi_master."DL_POI_ENTRYNONSHIFT" t1,
				mmi_master."DL_ROAD_NETWORK" AS t2 
				where t1."EDGE_ID" = t2."EDGE_ID" and ST_Intersects(ST_Buffer(t1."SP_GEOMETRY",0.000001,''),t2."SP_GEOMETRY")=false

		*/
		RAISE WARNING '<-----------POI,ROAD_NETWORK->POI INTERSECTS THE ENTRYPOINT';
		RAISE INFO '<-----------1.1.67';

		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE INFO 'EntryPoint not intersecting Road';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
------------------------------------------------------------------------------------------POI_CAT-------------------------------------------------------------------------------------------
IF tbl_nme_poi <> '' AND tbl_name_poi_cat <> '' THEN
--POI,POI_CAT->SUB_CRY1
--1.1.1
--1.5.1
--16 msec
	BEGIN
		
		EXECUTE ' INSERT INTO '||error_table||'(  unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT t1."ID",'''||tbl_nme_poi||''',''SUB_CRY'',t1."SUB_CRY"::text,''Poi’s Sub_Cry does not match with Mtr_Subcod in Poi Cat'',''1.1.1''
		FROM ( (SELECT "SUB_CRY" FROM '||sch_name||'."'||tbl_nme_poi||'" WHERE (COALESCE("SUB_CRY",'''')<> '''') ) EXCEPT
		(SELECT "MTR_SUBCOD" FROM '|| mst_sch ||'."'||tbl_name_poi_cat||'" WHERE (COALESCE("MTR_SUBCOD",'''')<> '''') ) ) As t, '||sch_name||'."'||tbl_nme_poi||'" As t1 WHERE 
		t."SUB_CRY"=t1."SUB_CRY" ';
		/*
		
			SELECT t1."ID",'DL_POI','SUB_CRY',t1."SUB_CRY"::text,'Poi’s Sub_Cry does not match with Mtr_Subcod in Poi Cat','1.5.1'
			FROM ( (SELECT "SUB_CRY" FROM mmi_master."DL_POI" WHERE (COALESCE("SUB_CRY",'')<> '') ) EXCEPT
			(SELECT "MTR_SUBCOD" FROM mmi_master."POI_CAT" WHERE (COALESCE("MTR_SUBCOD",'')<> '') ) ) As t, mmi_master."DL_POI" As t1 WHERE 
			t."SUB_CRY"=t1."SUB_CRY"
		*/
		RAISE WARNING '<-----------POI,POI_CAT->SUB_CRY1';
		RAISE INFO '<-----------1.5.1';

		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 18.1:%',f1;
		RAISE info 'error caught 18.2:%',f2;
	END;
	RAISE INFO 'Poi’s Sub_Cry does not match with Mtr_Subcod in Poi Cat';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
--POI,POI_CAT->FTR_CRY,SUB_CRY COMBINATION
--1.1.91
--16 msec
	BEGIN
		
		EXECUTE ' INSERT INTO '||error_table||'(  unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT "ID",'''||tbl_nme_poi||''',''FTR_CRY_SUB_CRY'',ftrcrycom::text,''FTR_CRY and SUB_CRY Combination Not Match With POI_CAT'',''1.1.91''
		FROM (SELECT "ID",(COALESCE("FTR_CRY",'''') ||''_''|| COALESCE("SUB_CRY",'''')) as ftrcrycom 
		FROM '||sch_name||'."'||tbl_nme_poi||'" WHERE (COALESCE("FTR_CRY",'''') ||''_''|| COALESCE("SUB_CRY",''''))
		NOT IN (SELECT (COALESCE("MSTR_CODE",'''') ||''_''|| COALESCE("MTR_SUBCOD",'''')) FROM '|| mst_sch ||'."'||tbl_name_poi_cat||'" )) as t1 ';
		
		
		-- SELECT "ID",(COALESCE("FTR_CRY",'') ||'_'|| COALESCE("SUB_CRY",'')) FROM mmi_v180."PB_POI" WHERE (COALESCE("FTR_CRY",'') ||'_'|| COALESCE("SUB_CRY",''))
		-- NOT IN (SELECT (COALESCE("MSTR_CODE",'') ||'_'|| COALESCE("MTR_SUBCOD",'')) FROM mmi_v180."POI_CAT" )
		
		/*
				SELECT t1."ID",'DL_POI','SUB_CRY',t1."SUB_CRY"::text,'Poi’s Sub_Cry does not match with Mtr_Subcod in Poi Cat','1.5.1'
				FROM ( (SELECT "SUB_CRY" FROM mmi_master."DL_POI" WHERE (COALESCE("SUB_CRY",'')<> '') ) EXCEPT
				(SELECT "MTR_SUBCOD" FROM mmi_master."POI_CAT" WHERE (COALESCE("MTR_SUBCOD",'')<> '') ) ) As t, mmi_master."DL_POI" As t1 WHERE 
				t."SUB_CRY"=t1."SUB_CRY"
		
		*/
		
		RAISE WARNING '<-----------POI,POI_CAT->SUB_CRY1';
		RAISE INFO '<-----------1.1.91';

		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 18.1:%',f1;
		RAISE info 'error caught 18.2:%',f2;
	END;
	RAISE INFO 'Poi’s Sub_Cry does not match with Mtr_Subcod in Poi Cat';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,POI_CAT->SUB_CRY2
--1.1.2
--1.5.4
--16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		( SELECT t."ID",'''||tbl_nme_poi||''',''SUB_CRY'',t."SUB_CRY"::text,''Poi’s Sub_Cry must be part of Mtr_Subcod group in Poi Cat'',''1.1.2''
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t WHERE  t."SUB_CRY" NOT IN ( 
		SELECT "MTR_SUBCOD" FROM '|| mst_sch ||'."'||tbl_name_poi_cat||'" WHERE (COALESCE("MTR_SUBCOD",'''')<> '''')) AND t."SUB_CRY" IN ( 
		SELECT "MTR_SUBCOD" FROM '|| mst_sch ||'."'||tbl_name_poi_cat||'" WHERE (COALESCE("MTR_SUBCOD",'''')<> '''')))';
	 /*
	 
		SELECT t."ID",'DL_POI','SUB_CRY',t."SUB_CRY"::text,'Poi’s Sub_Cry must be part of Mtr_Subcod group in Poi Cat','1.5.4'
		FROM mmi_master."DL_POI" As t WHERE  t."SUB_CRY" NOT IN ( 
		SELECT "MTR_SUBCOD" FROM mmi_master."POI_CAT" WHERE (COALESCE("MTR_SUBCOD",'')<> '')) AND t."SUB_CRY" IN ( 
		SELECT "MTR_SUBCOD" FROM mmi_master."POI_CAT"  WHERE (COALESCE("MTR_SUBCOD",'')<> ''))
	 
	 */
		
		RAISE WARNING '<-----------POI,POI_CAT->SUB_CRY2';
		RAISE INFO '<-----------1.5.4';

		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
		f1=MESSAGE_TEXT,
		f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 19.1:%',f1;
		RAISE info 'error caught 19.2:%',f2;
	END;
	RAISE INFO 'Poi’s Sub_Cry must be part of Mtr_Subcod group in Poi Cat';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,POI_CAT->FTR_CRY
--1.1.3
--1.3.1
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
		SELECT t4."ID",'''||tbl_nme_poi||''',''FTR_CRY'',t4."FTR_CRY"::text,''Poi’s Ftr_Cry does not match with Mtsr_Code in Poi Cat'',''1.1.3'' FROM (( SELECT "FTR_CRY"
		FROM '||sch_name||'."'||tbl_nme_poi||'" ) EXCEPT (SELECT "MSTR_CODE" FROM '|| mst_sch ||'."'||tbl_name_poi_cat||'" WHERE (COALESCE("MSTR_CODE",'''')<> '''')) ) As t1, '||sch_name||'."'||tbl_nme_poi||'" t4 WHERE 
	    t1."FTR_CRY" = t4."FTR_CRY"';
	    
		/*
		
			SELECT t4."ID",'DL_POI','FTR_CRY',t4."FTR_CRY"::text,'Poi’s Ftr_Cry does not match with Mtsr_Code in Poi Cat','1.1.3' FROM (( SELECT "FTR_CRY"
			FROM mmi_master."DL_POI" ) EXCEPT (SELECT "MSTR_CODE" FROM mmi_master."POI_CAT" WHERE (COALESCE("MSTR_CODE",'')<> '')) ) As t1, 
			mmi_master."DL_POI" t4 WHERE t1."FTR_CRY" = t4."FTR_CRY"
		
		*/
		
		RAISE WARNING '<-----------POI,POI_CAT->FTR_CRY';
		RAISE INFO '<-----------1.1.3';

		
		EXCEPTION 
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 19.1:%',f1;
		RAISE info 'error caught 19.2:%',f2;
	END;
	RAISE INFO 'Poi’s Ftr_Cry does not match with Mtsr_Code in Poi Cat';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
-----------------------------------------------------------------------------------------BRAND_LIST-----------------------------------------------------------------------------------------
IF tbl_nme_poi <> '' AND tbl_name_brand_list <> '' THEN
--1.1.51
--2.47.287
-- 31 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
		SELECT t."ID",'''||tbl_nme_poi||''',''BRAND_NME'',t."BRAND_NME"::text,''Brand_Nme must not be match with NAME, Poplr_Nme, Alias_1,2,3 and Address'',''1.1.51'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t WHERE  COALESCE(t."BRAND_NME",'''')<> '''' AND t."BRAND_NME" Not In (Select "BND_NAME" From '|| mst_sch ||'."'||tbl_name_brand_list||'") AND 
		t."BRAND_NME"=t."NAME" OR t."BRAND_NME"=t."POPLR_NME" OR t."BRAND_NME"=t."ALIAS_1" OR t."BRAND_NME"=t."ALIAS_2" OR t."BRAND_NME"=t."ALIAS_3" OR t."BRAND_NME"=t."ADDRESS" ';		

/*
	SELECT t."ID",'DL_POI','BRAND_NME',t."BRAND_NME"::text,'Brand_Nme must not be match with NAME, Poplr_Nme, Alias_1,2,3 and Address','2.47.287' 
	FROM mmi_master."DL_POI" As t WHERE  COALESCE(t."BRAND_NME",'')<> '' AND t."BRAND_NME" Not In (Select "BND_NAME" From mmi_master."BRAND_LIST") AND 
	t."BRAND_NME"=t."NAME" OR t."BRAND_NME"=t."POPLR_NME" OR t."BRAND_NME"=t."ALIAS_1" OR t."BRAND_NME"=t."ALIAS_2" OR t."BRAND_NME"=t."ALIAS_3" OR t."BRAND_NME"=t."ADDRESS"

*/




		RAISE WARNING '<-----------POI,BRAND_LIST->BRAND_NME';
		RAISE INFO '<-----------2.47.287';

		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 20.1:%',f1;
		RAISE info 'error caught 20.2:%',f2;
		
	END;
	RAISE INFO 'Brand_Nme must not be match with NAME, Poplr_Nme, Alias_1,2,3 and Address';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,BRAND_LIST->BRAND_NME
--1.1.5
--1.48.1
-- 32 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		(SELECT t."ID",'''||tbl_nme_poi||''',''BRAND_NME'',t."BRAND_NME"::text,''Poi’s Brand_Nme must match with Bnd_Nme maintained in latest Brand List'',''1.1.5'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t WHERE
		t."BRAND_NME" NOT IN (SELECT "BND_NAME" FROM '|| mst_sch ||'."'||tbl_name_brand_list||'" ) AND (COALESCE(t."BRAND_NME",'''')<> '''') )';
		
		/*
				SELECT t."ID",'DL_POI','BRAND_NME',t."BRAND_NME"::text,'Poi’s Brand_Nme must match with Bnd_Nme maintained in latest Brand List','1.48.1' 
				FROM mmi_master."DL_POI" As t WHERE
				t."BRAND_NME" NOT IN (SELECT "BND_NAME" FROM mmi_master."BRAND_LIST" ) AND (COALESCE(t."BRAND_NME",'')<> '')

		*/
		RAISE WARNING '<-----------POI,BRAND_LIST->BRAND_NME';
		RAISE INFO '<-----------1.1.5';

		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 20.1:%',f1;
		RAISE info 'error caught 20.2:%',f2;
	END;
	RAISE INFO 'Poi’s Brand_Nme must match with Bnd_Nme maintained in latest Brand List';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,BRAND_LIST->POPLR_NME
--1.1.6
--1.10.1
-- 47 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		(SELECT t."ID",'''||tbl_nme_poi||''',''POPLR_NME'',t."POPLR_NME"::text,''Poi’s Poplr_Nme must match with Bnd_Pop in Brand List'',''1.1.6'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t JOIN '|| mst_sch ||'."'||tbl_name_brand_list||'" As t1 ON (COALESCE(t."BRAND_NME",'''')<> '''') AND 
		(COALESCE(t."POPLR_NME",'''')<> '''') AND (COALESCE(t1."BND_NAME",'''')<> '''') AND t."BRAND_NME" = t1."BND_NAME" AND t."POPLR_NME" NOT IN (SELECT "BND_POP" 
		FROM '|| mst_sch ||'."BRAND_LIST" As t1 WHERE (COALESCE(t1."BND_POP",'''')<> '''')))';
		
		/*
			SELECT t."ID",'DL_POI','t.POPLR_NME',t."POPLR_NME"::text,'Poi’s Poplr_Nme must match with Bnd_Pop in Brand List','1.10.1' 
			FROM mmi_master."DL_POI" As t JOIN mmi_master."BRAND_LIST" As t1 ON (COALESCE(t."BRAND_NME",'')<> '') AND 
			(COALESCE(t."POPLR_NME",'')<> '') AND (COALESCE(t1."BND_NAME",'')<> '') AND t."BRAND_NME" = t1."BND_NAME" AND t."POPLR_NME" NOT IN (SELECT "BND_POP" 
			FROM mmi_master."BRAND_LIST" As t1 WHERE (COALESCE(t1."BND_POP",'')<> ''))
		*/
		
		RAISE WARNING '<-----------POI,BRAND_LIST->POPLR_NME';
		RAISE INFO '<-----------1.1.26';

		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 21.1:%',f1;
		RAISE info 'error caught 21.2:%',f2;
	END;
	RAISE INFO 'Poi’s Poplr_Nme must match with Bnd_Pop in Brand List';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,BRAND_LIST->BRAND_NME, NAME AND FTR_CRY1
-- 1.1.7
--1.48.2
-- 31 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT t."ID",'''||tbl_nme_poi||''',''BRAND_NME'',t."BRAND_NME"::text,''Poi’s Brand_Nme and Ftr_Cry does not match with Bnd_Nme and Ftr_Cry in Brand List'',''1.1.7'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t INNER JOIN '|| mst_sch ||'."'||tbl_name_brand_list||'" As t1 ON t."NAME" = t1."NAME" WHERE
		COALESCE(t."BRAND_NME",'''')<>'''' AND TRIM(t."BRAND_NME") <> TRIM(t1."BND_NAME") AND TRIM(t."FTR_CRY") <> TRIM(t1."FTR_CRY")';
	    
		/*
		SELECT t."ID",'DL_POI','BRAND_NME',t."BRAND_NME"::text,'Poi’s Brand_Nme and Ftr_Cry does not match with Bnd_Nme and Ftr_Cry in Brand List','1.1.7' 
		FROM mmi_master."DL_POI" As t INNER JOIN mmi_master."BRAND_LIST" As t1 ON t."NAME" = t1."BND_NAME" WHERE
		COALESCE(t."BRAND_NME",'')<>'' AND TRIM(t."BRAND_NME") <> TRIM(t1."BND_NAME") AND TRIM(t."FTR_CRY") <> TRIM(t1."FTR_CRY")
		*/
		RAISE WARNING '<-----------POI,BRAND_LIST->BRAND_NME, NAME AND FTR_CRY1';
		RAISE INFO '<-----------1.1.7';

		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 22.1:%',f1;
		RAISE info 'error caught 22.2:%',f2;
	END;
	RAISE INFO 'Poi’s Brand_Nme and Ftr_Cry does not match with Bnd_Nme and Ftr_Cry in Brand List';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,BRAND_LIST->BRAND_NME, NAME AND FTR_CRY2
--1.1.7
--1.48.2
-- 15 msec
	BEGIN
	EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
		SELECT t."ID",'''||tbl_nme_poi||''',''BRAND_NME'',t."BRAND_NME"::text,''Poi’s NAME and Ftr_Cry match but Brand_Nme does not match with Bnd_Nme in Brand List'',''1.1.7'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t INNER JOIN '|| mst_sch ||'."'||tbl_name_brand_list||'" As t1 ON t."NAME" = t1."NAME" WHERE 
		COALESCE(t."BRAND_NME",'''')<>'''' AND TRIM(t."BRAND_NME") <> TRIM(t1."BND_NAME") AND TRIM(t."FTR_CRY")=TRIM(t1."FTR_CRY")';
			  
			  /*
			    SELECT t."ID",'DL_POI','BRAND_NME',t."BRAND_NME"::text,'Poi’s NAME and Ftr_Cry match but Brand_Nme does not match with Bnd_Nme in Brand List','1.1.7'
				FROM mmi_master."DL_POI" As t INNER JOIN mmi_master."BRAND_LIST" As t1 ON t."NAME" = t1."NAME" WHERE 
				COALESCE(t."BRAND_NME",'')<>'' AND TRIM(t."BRAND_NME") <> TRIM(t1."BND_NAME") AND TRIM(t."FTR_CRY")=TRIM(t1."FTR_CRY")
			  */
		RAISE WARNING '<-----------POI,BRAND_LIST->BRAND_NME, NAME AND FTR_CRY2';
		RAISE INFO '<-----------1.1.7';

		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 22.1:%',f1;
		RAISE info 'error caught 22.2:%',f2;
	END;
	RAISE INFO 'Poi’s NAME and Ftr_Cry match but Brand_Nme does not match with Bnd_Nme in Brand List';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,BRAND_LIST->BRAND_NME, NAME AND FTR_CRY3
--1.1.9
--1.48.7
-- 31 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
		SELECT t."ID",'''||tbl_nme_poi||''',''BRAND_NME'',t."BRAND_NME"::text,''Poi’s Brand_Nme should not be blank if Poi’s NAME and Ftr_Cry match with NAME and Ftr_Cry in Brand List'',''1.1.9'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t INNER JOIN '|| mst_sch ||'."'||tbl_name_brand_list||'" As t1 ON t."NAME" = t1."NAME" WHERE 
		COALESCE(t."BRAND_NME",'''')='''' AND TRIM(t."FTR_CRY")=TRIM(t1."FTR_CRY") AND TRIM(t."SUB_CRY")=TRIM(t1."SUB_CRY")';
		
       /*
	    SELECT t."ID",'DL_POI','BRAND_NME',t."BRAND_NME"::text,'Poi’s Brand_Nme should not be blank if Poi’s NAME and Ftr_Cry match with Poi_Nme and Ftr_Cry in Brand List','1.48.7' 
		FROM mmi_master."DL_POI" As t INNER JOIN mmi_master."BRAND_LIST" As t1 ON t."NAME" = t1."POI_NME" WHERE 
		COALESCE(t."BRAND_NME",'')='' AND TRIM(t."FTR_CRY")=TRIM(t1."FTR_CRY")

	   */		
		RAISE WARNING '<-----------POI,BRAND_LIST->BRAND_NME, NAME AND FTR_CRY3';
		RAISE INFO '<-----------1.1.9';

		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 23.1:%',f1;
		RAISE info 'error caught 23.2:%',f2;
	END;
	RAISE INFO 'Poi’s Brand_Nme should not be blank if Poi’s NAME and Ftr_Cry match with Poi_Nme and Ftr_Cry in Brand List';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
--1.1.1.7
-- 31 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
		SELECT t1."ID",'''||tbl_nme_poi||''',''BRAND_NME'',t1."BRAND_NME"::text,''Poi’s name and brand_name equals to brand_list name and brand_nme but poplr_name is different from brand poplr_nme'',''1.1.1.7'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t1, '|| mst_sch ||'."'||tbl_name_brand_list||'" As t2
		where t1."NAME"=t2."NAME" AND t1."BRAND_NME"=t2."BND_NAME" AND t1."POPLR_NME"<> t2."BND_POP" ';
		
       /*
			SELECT t1."NAME",t1."BRAND_NME",t1."POPLR_NME",t2."BND_NAME",t2."BND_NAME",t2."BND_POP" from mmi_master."DL_POI" AS t1,mmi_master."BRAND_LIST" AS t2
			where t1."NAME"=t2."BND_NAME" AND t1."BRAND_NME"=t2."BND_NAME" AND t1."POPLR_NME"<> t2."BND_POP"

	   */		
		RAISE WARNING '<-----------POI,BRAND_LIST->BRAND_NME, NAME AND FTR_CRY3';
		RAISE INFO '<-----------1.1.1.7';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 23.1:%',f1;
		RAISE info 'error caught 23.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
--1.1.1.8
-- 31 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
		SELECT t1."ID",'''||tbl_nme_poi||''',''BRAND_NME'',t1."BRAND_NME"::text,''Poi’s name and brand_name equals to brand_list name and brand_nme but alias is different from brand alias'',''1.1.1.8'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t1, '|| mst_sch ||'."'||tbl_name_brand_list||'" As t2
		where t1."NAME"=t2."NAME" AND t1."BRAND_NME"=t2."BND_NAME" AND t1."ALIAS_1"<> t2."BND_ALIAS1"  ';
		
       /*
			SELECT t1."NAME",t1."BRAND_NME",t1."ALIAS_1",t2."BND_NAME",t2."BND_NAME",t2."BND_ALIAS1" from mmi_master."DL_POI" AS t1,mmi_master."BRAND_LIST" AS t2
			where t1."NAME"=t2."BND_NAME" AND t1."BRAND_NME"=t2."BND_NAME" AND t1."ALIAS_1"<> t2."BND_ALIAS1"
	 		
	   */		
		RAISE WARNING '<-----------POI,BRAND_LIST->BRAND_NME, NAME AND FTR_CRY3';
		RAISE INFO '<-----------1.1.1.8';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 23.1:%',f1;
		RAISE info 'error caught 23.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	
	
	
	
	
END IF;
----------------------------------------------------------------------------------------CITY_BOUNDARY---------------------------------------------------------------------------------------
IF tbl_nme_city <> '' AND tbl_nme_poi <> '' THEN
--1.1.58
--2.47.200
-- 47 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
		SELECT t1."ID",'''||tbl_nme_poi||''',''SP_GEOMETRY'', t1."SP_GEOMETRY",''Poi should be inside the city area according to city id'',''1.1.58'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t1, '|| mst_sch ||'."'||tbl_nme_city||'" As t2 
		WHERE t1."CITY_ID"=t2."ID" AND 
		ST_Within(t1."SP_GEOMETRY",t2."SP_GEOMETRY")=''f'' ';
		
-- 		SELECT t1."ID",'DL_POI','SP_GEOMETRY', t1."SP_GEOMETRY",'Poi should be inside the city area according to city id','1.1.58' 
-- 		FROM mmi_master."DL_POI" As t1, mmi_master."DL_CITY_BOUNDARY" As t2 
-- 		WHERE (t1.status NOT IN('0','5') OR COALESCE(t1.status,'')='') AND t1."CITY_ID"=t2."ID" AND 
-- 		ST_Within(t1."SP_GEOMETRY",t2."SP_GEOMETRY")='f'
	
		RAISE WARNING '<-----------POI,CITY_BOUNDARY->CITY_NME';
		RAISE INFO '<-----------1.1.58';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 24.1:%',f1;
		RAISE info 'error caught 24.2:%',f2;
	END;
	RAISE INFO 'Poi should be inside the city area according to city id';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.1.60
-- --2.47.261
-- -- 31 msec
	-- BEGIN
		-- EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
		-- SELECT t1."ID",'''||tbl_nme_poi||''',''LABEL_NME'', t1."LABEL_NME"::text,''Poi’s Label_Nme should not be equal to City Name ’''||t2."CITY_NME"||''’'',''1.1.60'' 
		-- FROM '||sch_name||'."'||tbl_nme_poi||'" As t1, '|| mst_sch ||'."'||tbl_nme_city||'" As t2 
		-- WHERE (COALESCE(t1."LABEL_NME",'''')<>'''') AND 
		-- (LOWER(TRIM(t1."LABEL_NME"))=LOWER(TRIM(t2."CITY_NME"))) ';

-- -- 		SELECT t1."ID",'DL_POI','LABEL_NME', t1."LABEL_NME"::text,'Poi’s Label_Nme should not be equal to City Name ’'||t2."CITY_NME"||'’','1.1.60' 
-- -- 		FROM mmi_master."DL_POI" As t1, mmi_master."DL_CITY_BOUNDARY" As t2 
-- -- 		WHERE (COALESCE(t1."LABEL_NME",'')<>'') AND 
-- -- 		(LOWER(TRIM(t1."LABEL_NME"))=LOWER(TRIM(t2."CITY_NME")))
		
		-- RAISE WARNING '<-----------POI,CITY_BOUNDARY->CITY_NME';
		--RAISE INFO '<-----------2.47.261';
		
		-- EXCEPTION
			-- WHEN OTHERS THEN
				-- GET STACKED DIAGNOSTICS 
				-- f1=MESSAGE_TEXT,
				-- f2=PG_EXCEPTION_CONTEXT; 
		
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		-- RAISE info 'error caught 24.1:%',f1;
		-- RAISE info 'error caught 24.2:%',f2;
	-- END;
	-- RAISE INFO 'Poi’s Label_Nme should not be equal to City Name';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,CITY_BOUNDARY->CITY_NME
--1.1.73
-- 1.4 sec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
		With tab1 As (select "ID","NAME"::text from '||sch_name||'."'||tbl_nme_poi||'" where "NAME" ~''[^ ]{16,}'')
		select "ID",'''||tbl_nme_poi||''',''NAME'', "NAME"::text,''NAME contain more than 16 Characters'',''1.1.73'' 
		from tab1  where "ID" not in (select "ID" from tab1,spatial_layer_functions.long_name_excp tab2 
		where (tab1."NAME" like ''% ||tab2.poi_name||'' OR tab1."NAME" 
		like ''% ||tab2.poi_name|| %'' OR tab1."NAME" like ''||tab2.poi_name|| %'' OR tab1."NAME" like ''||tab2.poi_name||'' OR tab1."NAME" like ''%||tab2.poi_name||%'') group by "ID")';
		
		-- With tab1 As 
		-- (select "ID","NAME"::text from mmi_master."DL_POI" 
		-- where "NAME" ~'[^ ]{16,}')
		-- select "ID",'DL_POI','NAME', "NAME"::text,'NAME contain more than 16 Characters','1.1.73' 
		-- from tab1  where "ID" not in (select "ID" from tab1,spatial_layer_functions.long_name_excp tab2 
		-- where (tab1."NAME" like '% '||tab2.poi_name||'' OR tab1."NAME" like '% '||tab2.poi_name||' %' 
		-- OR tab1."NAME" like ''||tab2.poi_name||' %' OR tab1."NAME" like ''||tab2.poi_name||'' 
		-- OR tab1."NAME" like '%'||tab2.poi_name||'%') group by "ID")
		
		/*
		  With tab1 As (select "ID",'DL_POI','NAME', "NAME"::text,'Poi’s NAME contain City Name ’''||t2."CITY_NME"||''’','1.1.10' from mmi_master."DL_POI" where "NAME" ~'[^ ]{16,}')
		  select "ID",'DL_POI','NAME', "NAME"::text,'Poi’s NAME contain City Name ’''||t2."CITY_NME"||''’','1.1.10' from tab1  where "ID" not in (select "ID" from tab1,spatial_layer_functions.long_name_excp tab2 
		  where (tab1."NAME" like '% '||tab2.poi_name||'' OR tab1."NAME" like '% '||tab2.poi_name||' %' OR tab1."NAME" like ''||tab2.poi_name||' %' OR tab1."NAME" like ''||tab2.poi_name||'' OR tab1."POI_NME" like '%'||tab2.poi_name||'%') group by "ID")

		*/
		
		RAISE WARNING '<-----------POI,LONG_NAME->POI_NME';
		RAISE INFO '<-----------1.1.73';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 24.1:%',f1;
		RAISE info 'error caught 24.2:%',f2;
	END;
	RAISE INFO 'Poi’s NAME More Than 16 Characters';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.1.10
--1.2.5
	 BEGIN
		-- EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
		-- SELECT t1."ID",'''||tbl_nme_poi||''',''NAME'', t1."NAME"::text,''Poi’s NAME contain City Name ’''||t2."CITY_NME"||''’'',''1.1.10'' 
		-- FROM '||sch_name||'."'||tbl_nme_poi||'" As t1, '|| mst_sch ||'."'||tbl_nme_city||'" As t2 
		-- WHERE (COALESCE(t1."NAME",'''')<>'''') AND (COALESCE(t2."CITY_NME",'''')<>'''') AND 
		-- (LOWER(TRIM(t1."NAME"))=LOWER(TRIM(t2."CITY_NME")) OR LOWER("NAME")~CONCAT(''[^\d\w]'',LOWER(t2."CITY_NME"),''[^\d\w]'') OR LOWER("NAME")~CONCAT(''[^\d\w]'',LOWER(t2."CITY_NME"),''$'') OR LOWER("NAME")~CONCAT(''^'',LOWER(t2."CITY_NME"),''[^\d\w]''))
		-- Group By t1."ID",t1."NAME",t2."CITY_NME"';
		
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
		SELECT t1."ID",'''||tbl_nme_poi||''',''NAME'', t1."NAME"::text,''Poi’s NAME contain City Name ’''||t2."CITY_NME"||''’'',''1.1.10'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t1, '|| mst_sch ||'."'||tbl_nme_city||'" As t2 
		WHERE (COALESCE(t1."NAME",'''')<>'''') AND (COALESCE(t2."CITY_NME",'''')<>'''') AND COALESCE(LOWER(t1."NAME"),'''')=COALESCE(LOWER(t2."CITY_NME"),'''')';
		
		RAISE WARNING '<-----------POI,CITY_BOUNDARY->CITY_NME';
		RAISE INFO '<-----------1.1.10';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 24.1:%',f1;
		RAISE info 'error caught 24.2:%',f2;
	END;
	RAISE INFO 'Poi’s NAME contain City Name';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,CITY_BOUNDARY->ADDRESS
--1.1.13
-- --1.15.3
	-- BEGIN
		-- EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
		-- SELECT t1."ID",'''||tbl_nme_poi||''',''ADDRESS'', t1."ADDRESS"::text,''Poi’s Address contain City Name ’''||t2."CITY_NME"||''’'',''1.1.13'' 
		-- FROM '||sch_name||'."'||tbl_nme_poi||'" As t1 INNER JOIN '|| mst_sch ||'."'||tbl_nme_city||'" As t2 ON (COALESCE(t2."CITY_NME",'''')<> '''') AND 
		-- (LOWER(TRIM(t1."ADDRESS"))=LOWER(TRIM(t2."CITY_NME")) OR LOWER("ADDRESS")~CONCAT(''[^\d\w]'',LOWER(t2."CITY_NME"),''[^\d\w]'') OR LOWER("ADDRESS")~CONCAT(''[^\d\w]'',LOWER(t2."CITY_NME"),''$'') OR LOWER("ADDRESS")~CONCAT(''^'',LOWER(t2."CITY_NME"),''[^\d\w]'')) ';
	    
       -- /*
	     -- INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
		-- SELECT t1."ID",'''||tbl_nme_poi||''',''ADDRESS'', t1."ADDRESS"::text,''Poi’s Address contain City Name'',''||t2."CITY_NME"||'',''1.1.13'' 
		-- FROM '||sch_name||'."'||tbl_nme_poi||'" As t1 INNER JOIN '|| mst_sch ||'."'||tbl_nme_city||'" As t2 ON (COALESCE(t2."CITY_NME",'''')<> '''') AND 
		-- (LOWER(TRIM(t1."ADDRESS"))=LOWER(TRIM(t2."CITY_NME")) OR LOWER("ADDRESS")~CONCAT(''[^\d\w]'',LOWER(t2."CITY_NME"),''[^\d\w]'') OR LOWER("ADDRESS")~CONCAT(''[^\d\w]'',LOWER(t2."CITY_NME"),''$'') OR LOWER("ADDRESS")~CONCAT(''^'',LOWER(t2."CITY_NME"),''[^\d\w]'')) ';

	   -- */
		-- RAISE WARNING '<-----------POI,CITY_BOUNDARY->ADDRESS';
		--RAISE INFO '<-----------1.1.13';
		
		-- EXCEPTION
			-- WHEN OTHERS THEN
				-- GET STACKED DIAGNOSTICS 
				-- f1=MESSAGE_TEXT,
				-- f2=PG_EXCEPTION_CONTEXT; 
		
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		-- RAISE info 'error caught 25.1:%',f1;
		-- RAISE info 'error caught 25.2:%',f2;
	-- END;
	-- RAISE INFO 'Poi’s Address contain City Name';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,CITY_BOUNDARY->VICIN_ID
--1.1.16(EXCEPT TOYOTA BRAND)
--1.41.3
-- 47 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		(SELECT t."ID",'''||tbl_nme_poi||''',''VICIN_ID'',t."VICIN_ID"::text,''Poi’s Vicin_Id does not match with its City Boundary Id'',''1.1.16'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t WHERE t."VICIN_ID"<>0 AND t."BRAND_NME" NOT ILIKE ''%TOYOTA%'' AND t."VICIN_ID" NOT IN 
		(SELECT "ID" FROM '|| mst_sch ||'."'||tbl_nme_city||'" As t1 WHERE t1."ID"<>0))';
		/*
	    SELECT t,"ID",'DL_POI','VICIN_ID',t."VICIN_ID"::text,'Poi’s Vicin_Id does not match with its City Boundary Id','1.41.3' 
		FROM mmi_master."DL_POI" As t WHERE t."VICIN_ID"<>0 AND t."BRAND_NME" NOT ILIKE '%TOYOTA%' AND t."VICIN_ID" NOT IN 
		(SELECT "ID" FROM mmi_master."DL_CITY_BOUNDARY" As t1 WHERE t1."ID"<>0)

		*/
		RAISE WARNING '<-----------POI,CITY_BOUNDARY->VICIN_ID';
		RAISE INFO '<-----------1.1.1.16';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 26.1:%',f1;
		RAISE info 'error caught 26.2:%',f2;
	END;
	RAISE INFO 'Poi’s Vicin_Id does not match with its City Boundary Id';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
--1.1.16.1(FOR TOYOTA BRAND)
--1.41.3
-- 47 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		(SELECT "ID",'''||tbl_nme_poi||''',''VICIN_ID'',"VICIN_ID"::text,''Poi’s Vicin_Id does not match with its City Boundary  and district boundary Id for toyota brand'',''1.1.16.1'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" WHERE "VICIN_ID"<>0 AND "BRAND_NME" ILIKE ''%TOYOTA%'' AND "VICIN_ID" NOT IN
		(SELECT "ID" FROM '|| mst_sch ||'."'||tbl_nme_city||'" union select "ID" from '|| mst_sch ||'."'||tbl_nme_dist||'"))';

		/*
	    select "ID","VICIN_ID" FROM mmi_master."DL_POI" WHERE "VICIN_ID"<>0 AND "BRAND_NME" ILIKE '%TOYOTA%' AND "VICIN_ID" NOT IN
		(SELECT "ID" FROM mmi_master."AS_CITY_BOUNDARY" as t union select "ID" from mmi_master."AS_DISTRICT_BOUNDARY" AS t2)

		*/
		RAISE WARNING '<-----------POI,CITY_BOUNDARY->VICIN_ID';
		RAISE INFO '<-----------1.1.16.1';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 26.1:%',f1;
		RAISE info 'error caught 26.2:%',f2;
	END;
	RAISE INFO 'Poi’s Vicin_Id does not match with its City Boundary  and district boundary Id for toyota brand';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,CITY_BOUNDARY->CITY_ID
--1.1.15
--1.8.1
--47 msec
	BEGIN
		EXECUTE'INSERT INTO '||error_table||'(  unquid, table_name, field_name, field_value, error_type , error_code )
		( SELECT t3.id,'''||tbl_nme_poi||''',''CITY_ID'',t3."CITY_ID"::text,''Poi’s City_Id does not match with its City Boundary Id'',''1.1.15'' 
		FROM (SELECT t2."ID" As ID, t2."CITY_ID", t2.ST_Within As geom FROM (SELECT t."ID", t."CITY_ID", ST_Within(t."SP_GEOMETRY",t1."SP_GEOMETRY") 
		FROM (SELECT * FROM '||sch_name||'."'||tbl_nme_poi||'" ) As t, 
		'|| mst_sch ||'."'||tbl_nme_city||'" As t1 WHERE t."CITY_ID"<>t1."ID") As t2 WHERE ST_Within=''t'') As t3)'; 
	    
        /*
		 SELECT t3.id,'DL_POI','CITY_ID',t3."CITY_ID"::text,'Poi’s City_Id does not match with its City Boundary Id','1.8.1' 
		FROM (SELECT t2."ID" As ID, t2."CITY_ID", t2.ST_Within As geom FROM (SELECT t."ID", t."CITY_ID", ST_Within(t."SP_GEOMETRY",t1."SP_GEOMETRY") 
		FROM (SELECT * FROM mmi_master."DL_POI" ) As t, 
		mmi_master."GA_CITY_BOUNDARY" As t1 WHERE t."CITY_ID"<>t1."ID" AND t1."ID"<>0 AND t."CITY_ID"<>0) As t2 WHERE ST_Within='t') As t3		
		*/		
		RAISE WARNING '<-----------POI,CITY_BOUNDARY->CITY_ID';
		RAISE INFO '<-----------1.1.15';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 37.1:%',f1;
		RAISE info 'error caught 37.2:%',f2;
	END;
	RAISE INFO 'Poi’s City_Id does not match with its City Boundary Id';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
---------------------------------------------------------------------------------------Locality_Boundary------------------------------------------------------------------------------------
-- IF tbl_nme_loc <> '' THEN
--1.1.60 
--2.47.261
--125 msec
-- 	BEGIN
-- 		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
-- 		SELECT t1."ID",'''||tbl_nme_poi||''',''LABEL_NME'', t1."LABEL_NME"::text,''Poi’s Label_Nme should not be equal to Locality Name ’''||t2."LOC_NME"||''’'',''1.1.60'' 
-- 		FROM '||sch_name||'."'||tbl_nme_poi||'" As t1, '||mst_sch||'."'||UPPER(tbl_nme_loc)||'" As t2 
-- 		WHERE (t1.status NOT IN(''0'',''5'') OR COALESCE(t1.status,'''')='''') AND (COALESCE(t1."LABEL_NME",'''')<>'''') AND 
-- 		(LOWER(TRIM(t1."LABEL_NME"))=LOWER(TRIM(t2."LOC_NME"))) ';
-- -- 	
-- -- --  SELECT t1."ID",'','LABEL_NME', t1."LABEL_NME"::text,'Poi’s Label_Nme should not be equal to Locality Name ’'||t2."LOC_NME"||'’','1.1.60' 
		--FROM mmi_v180."GA_POI" As t1, mmi_v180."GA_LOC_BOUNDARY" As t2 
		--WHERE (t1.status NOT IN('0','5') OR COALESCE(t1.status,'')='') AND (COALESCE(t1."LABEL_NME",'')<>'') AND 
		---(LOWER(TRIM(t1."LABEL_NME"))=LOWER(TRIM(t2."LOC_NME")))	

-- 		RAISE WARNING '<-----------POI,LOC_BOUNDARY->LOC_NME';
--      RAISE INFO '<-----------1.1.60';
		
-- 		EXCEPTION
-- 			WHEN OTHERS THEN
-- 				GET STACKED DIAGNOSTICS 
-- 				f1=MESSAGE_TEXT,
-- 				f2=PG_EXCEPTION_CONTEXT; 
		
-- 		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
-- 		RAISE info 'error caught 27.1:%',f1;
-- 		RAISE info 'error caught 27.2:%',f2;
-- 	END;
-- --POI,LOC_BOUNDARY->LOC_NME
-- 	BEGIN
-- 		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
-- 		SELECT t1."ID",'''||tbl_nme_poi||''',''POI_NME'', t1."POI_NME"::text,''Poi’s Poi_Nme contain Locality Name ’''||t2."LOC_NME"||''’'',''1.2.5'' 
-- 		FROM '||sch_name||'."'||tbl_nme_poi||'" As t1, '||mst_sch||'."'||UPPER(tbl_nme_loc)||'" As t2 
-- 		WHERE (t1.status NOT IN(''0'',''5'') OR COALESCE(t1.status,'''')='''') AND (COALESCE(t1."POI_NME",'''')<>'''') AND (COALESCE(t2."LOC_NME",'''')<>'''') AND 
-- 		(LOWER(TRIM(t1."POI_NME"))=LOWER(TRIM(t2."LOC_NME")) OR LOWER("POI_NME")~CONCAT(''[^\d\w]'',LOWER(t2."LOC_NME"),''[^\d\w]'') OR LOWER("POI_NME")~CONCAT(''[^\d\w]'',LOWER(t2."LOC_NME"),''$'') OR LOWER("POI_NME")~CONCAT(''^'',LOWER(t2."LOC_NME"),''[^\d\w]'')) 
-- 		Group By t1."ID",t1."POI_NME",t2."LOC_NME"';
		
-- 		RAISE WARNING '<-----------POI,LOC_BOUNDARY->LOC_NME';
--      RAISE INFO '<-----------1.2.5';
		
-- 		EXCEPTION
-- 			WHEN OTHERS THEN
-- 				GET STACKED DIAGNOSTICS 
-- 				f1=MESSAGE_TEXT,
-- 				f2=PG_EXCEPTION_CONTEXT; 
		
-- 		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
-- 		RAISE info 'error caught 28.1:%',f1;
-- 		RAISE info 'error caught 28.2:%',f2;
-- 	END;
-- END IF;
-----------------------------------------------------------------------------------------STATE_ABBR-----------------------------------------------------------------------------------------
IF tbl_nme_poi <> '' AND tbl_name_state_abbr <> '' THEN
-- --1.1.60
-- --2.47.261
-- -- 31 msec
	-- BEGIN
		-- EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
		-- SELECT t1."ID",'''||tbl_nme_poi||''',''LABEL_NME'', t1."LABEL_NME"::text,''Poi’s Address contain State Name ’''||t2."STT_NME"||''’'',''1.1.60'' 
		-- FROM '||sch_name||'."'||tbl_nme_poi||'" As t1, '|| mst_sch ||'."'||tbl_name_state_abbr||'" As t2 
		-- WHERE (COALESCE(t1."LABEL_NME",'''')<>'''') AND 
		-- (LOWER(TRIM(t1."LABEL_NME"))=LOWER(TRIM(t2."STT_NME")))';
		-- /*
		-- SELECT t1."ID",'DL_POI','LABEL_NME', t1."LABEL_NME"::text,'Poi’s Label_Nme should not be equal to Locality Name',t2."LOC_NME",'1.1.60' 
		-- FROM mmi_master."DL_POI" As t1, mmi_master."_LOC_CENTRE" As t2 
		-- WHERE (COALESCE(t1."LABEL_NME",'')<>'') AND 
		-- LOWER(TRIM(t1."LABEL_NME"))=LOWER(TRIM(t2."LOC_NME"))
		-- */
-- ----------------------------------Error: commas and inverted commas near t2.loc_name------------------------------------------

-- -- 		SELECT t1."ID",'DL_POI','LABEL_NME', t1."LABEL_NME"::text,'Poi’s Label_Nme should not be equal to State Name ’'||t2."STT_NME"||'’','2.47.261' 
-- -- 		FROM mmi_master."DL_POI" As t1, mmi_master."STATE_ABBR" As t2 
-- -- 		WHERE (t1.status NOT IN('0','5') OR COALESCE(t1.status,'')='') AND (COALESCE(t1."LABEL_NME",'')<>'') AND 
-- -- 		(LOWER(TRIM(t1."LABEL_NME"))=LOWER(TRIM(t2."STT_NME")))
		
		-- RAISE WARNING '<-----------POI,STATE_ABBR->STT_NME';
		--RAISE INFO '<-----------1.1.60';

		-- EXCEPTION
			-- WHEN OTHERS THEN
				-- GET STACKED DIAGNOSTICS 
				-- f1=MESSAGE_TEXT,
				-- f2=PG_EXCEPTION_CONTEXT; 
		
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		-- RAISE info 'error caught 28.1:%',f1;
		-- RAISE info 'error caught 28.2:%',f2;
	-- END;
	-- RAISE INFO 'Poi’s Address contain State Name';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,STATE_ABBR->STT_NME
--1.1.12
--1.15.3
-- 1.6 min
	BEGIN
	    sqlQuery = 'WITH state_name AS (SELECT "STT_NME" FROM '||sch_name||'."STATE_ABBR" WHERE "STT_CODE" = '||stat_code||')
		INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
		SELECT "ID",'''||tbl_nme_poi||''',''ADDRESS'', "ADDRESS",''Poi’s Address contain State Name '',''1.1.12'' 
		FROM(Select t1."ID",REPLACE(t1."ADDRESS", '' '','''') AS "ADDRESS",t2."STT_NME" 
		FROM mmi_master."DL_POI" As t1, state_name As t2  
		WHERE (COALESCE("ADDRESS",'''')<>'''') AND "ADDRESS" like ''%,'||t2."STT_NME"||''' OR "ADDRESS" like '''||t2."STT_NME"||',%'' OR "ADDRESS" like ''%,'||t2."STT_NME"||'%'') t3 
		where "ADDRESS" ~ (''\y''||"STT_NME"||''\y'') ';
		/*
		WITH state_name AS (SELECT "STT_NME" FROM mmi_master."STATE_ABBR" WHERE "STT_CODE" = 'DL')
		Select * From (Select t1."ID",REPLACE(t1."ADDRESS", ' ','') AS "ADDRESS",t2."STT_NME" 
		FROM mmi_master."DL_POI" As t1, state_name As t2  
		WHERE (COALESCE("ADDRESS",'')<>'') AND TRIM("ADDRESS", ' ') like '%,'||t2."STT_NME"||'' OR TRIM("ADDRESS", ' ') like ''||t2."STT_NME"||',%' OR TRIM("ADDRESS", ' ') like '%,'||t2."STT_NME"||'%') t3 
		where "ADDRESS" ~ ('\y'||"STT_NME"||'\y')
		*/
		
		
		----------------------------------Error: commas and inverted commas near t2.loc_name------------------------------------------
		RAISE WARNING '<-----------POI,STATE_ABBR->STT_NME';
		RAISE INFO '<-----------1.1.12';
		
		EXECUTE sqlQuery;
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 28.1:%',f1;
		RAISE info 'error caught 28.2:%',f2;
	END;
	RAISE INFO 'Poi’s Address contain State Name';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
---------------------------------------------------------------------------------------Pincode_Boundary-------------------------------------------------------------------------------------
IF tbl_nme_poi <> '' AND tbl_name_pincode <> '' THEN
--POI,PINCODE_BOUNDARY->PIN_CODE
--1.1.14
--1.15.3
--31 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )  
		SELECT t2."ID",'''||tbl_nme_poi||''',''ADDRESS'',t2."ADDRESS"::text,''Poi’s Address contain Pin Code '',''1.1.14''
		FROM (SELECT "ID",UNNEST(STRING_TO_ARRAY("ADDRESS", '' '')) As address FROM '||sch_name||'."'||tbl_nme_poi||'" WHERE "ADDRESS" ~ ''[1-9][0-9]{5}'' 
	    ) As t, '||sch_name||'."'||tbl_nme_poi||'" As t2
		WHERE t.address LIKE ANY(SELECT "PINCODE" FROM '|| mst_sch ||'."'||tbl_name_pincode||'" ) AND t."ID"=t2."ID"';
		
        /*
		 SELECT t2."ID",'DL_POI','ADDRESS',t2."ADDRESS"::text,'Poi’s Address contain Pin Code ','1.1.14'
		FROM (SELECT "ID",UNNEST(STRING_TO_ARRAY("ADDRESS", ' ')) As address FROM mmi_master."DL_POI" WHERE "ADDRESS" ~ '[1-9][0-9]{5}' 
	    ) As t, mmi_master."DL_POI" As t2
		WHERE t.address LIKE ANY(SELECT "PINCODE" FROM mmi_master."PINCODE_BOUNDARY" ) AND t."ID"=t2."ID"
		*/		
		
		RAISE WARNING '<-----------POI,PINCODE_BOUNDARY->PIN_CODE';
		RAISE INFO '<-----------1.1.14';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 29.1:%',f1;
		RAISE info 'error caught 29.2:%',f2;
	END;
	RAISE INFO 'Poi’s Address contain Pin Code';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
-----------------------------------------------------------------------------------------Address_Point----------------------------------------------------------------------------------------
-- IF tbl_nme_poi <> '' AND tbl_nme_addr_point <> '' THEN
-- --POI,ADDR_POINT->PIB_ID
-- --1.1.17
-- --1.34.1
-- --31 msec
	-- BEGIN
		-- EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		-- SELECT t1."ID",'''||tbl_nme_poi||''',''PIB_ID'',t1."PIB_ID"::text,''PIB_ID Must match with Addr_Point ID'',''1.1.17''
		-- FROM ((select "PIB_ID" FROM  '||sch_name||'."'||tbl_nme_poi||'" where "PIB_ID"<> 0) Except 
		-- (SELECT "ID" FROM '||tbl_nme_addr_point||' where "ID"<>0)) AS t , '||sch_name||'."'||tbl_nme_poi||'" AS t1 where 
		-- t."PIB_ID"=t1."PIB_ID"';
		
		-- /*
		-- SELECT t1."ID",'DL_POI','PIB_ID',t1."PIB_ID"::text,'PIB_ID Must match with Addr_Point ID','1.1.17'
		-- FROM ((select "PIB_ID" FROM mmi_master."DL_POI" where "PIB_ID"<> 0) Except 
	    -- (SELECT "ID" FROM mmi_master."DL_ADDR_ADMIN_P" where "ID"<>0)) AS t , mmi_master."DL_POI" AS t1 where 
		-- t."PIB_ID"=t1."PIB_ID"
		-- */
		-- RAISE WARNING '<-----------POI,ADDR_POINT->PIB_ID';
		--RAISE INFO '<-----------1.1.17';
		
		-- EXCEPTION
			-- WHEN OTHERS THEN
			-- GET STACKED DIAGNOSTICS 
				-- f1=MESSAGE_TEXT,
				-- f2=PG_EXCEPTION_CONTEXT; 
		
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		-- RAISE info 'error caught 30.1:%',f1;
		-- RAISE info 'error caught 30.2:%',f2;
	-- END;
	-- RAISE INFO 'PIB_ID Must match with Addr_Point ID';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.1.53	
-- --2.47.219
-- -- 31 msec
	-- BEGIN
		-- EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		-- SELECT a."ID" As "ID",'''||tbl_nme_poi||''',''PIB_ID'',a."PIB_ID"::text As "PIB_ID",''Geometry of Poi must be within the same state as Addr_Point'',''1.1.53''
		-- FROM '||sch_name||'."'||tbl_nme_poi||'" As a, '||tbl_nme_addr_point||' As b WHERE a."PIB_ID"=b."ID" AND b."ID"<>0 AND a."STT_ID"<>b."STT_ID" ';

        -- /*
		 -- SELECT a."ID" As "ID",'tbl_nme_poi','PIB_ID',a."PIB_ID"::text As "PIB_ID",'Geometry of Poi must be within the same state as Addr_Point','1.1.53'
         -- FROM mmi_master."DL_POI" As a, mmi_master."DL_ADDR_POINT" As b WHERE a."PIB_ID"=b."ID" AND b."ID"<>0 AND a."STT_ID"<>b."STT_ID"
		-- */ 
		-- RAISE WARNING '<-----------POI,ADDR_POINT->PIB_ID';
		-- RAISE INFO '<-----------1.1.53';
		
		-- EXCEPTION
			-- WHEN OTHERS THEN
			-- GET STACKED DIAGNOSTICS 
				-- f1=MESSAGE_TEXT,
				-- f2=PG_EXCEPTION_CONTEXT; 
		
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		-- RAISE info 'error caught 30.1:%',f1;
		-- RAISE info 'error caught 30.2:%',f2;
	-- END;
	-- RAISE INFO 'Geometry of Poi must be within the same state as Addr_Point';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-- END IF;
----------------------------------------------------------------------------------------Admin_Boundary--------------------------------------------------------------------------------------
IF tbl_nme_poi <> '' AND tbl_nme_addr_r <> '' THEN
--1.1.58
--2.47.200
--31 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
		SELECT t1."ID",'''||tbl_nme_poi||''',''SP_GEOMETRY'', t1."SP_GEOMETRY",''Poi should be inside the Admin area according to Admin id'',''1.1.58'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As t1, '|| mst_sch ||'."'||UPPER(tbl_nme_addr_r)||'" As t2 
		WHERE t1."ADMIN_ID"=t2."ID" AND 
		ST_Within(t1."SP_GEOMETRY",t2."SP_GEOMETRY")=''f'' ';

-- 		SELECT t1."ID",'DL_POI','SP_GEOMETRY', t1."SP_GEOMETRY",'Poi should be inside the Admin area according to Admin id','1.1.58' 
-- 		FROM mmi_master."DL_POI" As t1, mmi_master."DL_ADDR_ADMIN_R" As t2 
-- 		WHERE (t1.status NOT IN('0','5') OR COALESCE(t1.status,'')='') AND t1."ADMIN_ID"=t2."ID" AND 
-- 		ST_Within(t1."SP_GEOMETRY",t2."SP_GEOMETRY")='f'
	
		RAISE WARNING '<-----------POI,CITY_BOUNDARY->CITY_NME';
		RAISE INFO '<-----------1.1.58';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 24.1:%',f1;
		RAISE info 'error caught 24.2:%',f2;
	END;
	RAISE INFO 'Poi should be inside the Admin area according to Admin id';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,ADDR_ADMIN_R->ADMIN_ID1
--1.1.18
--1.7.1
-- 62 msec
	BEGIN
		EXECUTE'INSERT INTO '||error_table||'(  unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT a."ID",'''||tbl_nme_poi||''',''ADMIN_ID'',a."ADMIN_ID"::text,''Poi’s Admin_Id does not match with its Admin Boundary Id'',''1.1.18'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" a,'|| mst_sch ||'."'|| UPPER(tbl_nme_addr_r) ||'" b WHERE ST_Within(a."SP_GEOMETRY",b."SP_GEOMETRY")=''t'' AND 
		a."ADMIN_ID"<>b."ID"';
		/*
		  SELECT a."ID",'DL_POI','ADMIN_ID',a."ADMIN_ID"::text,'Poi’s Admin_Id does not match with its Admin Boundary Id','1.1.18' 
		FROM mmi_master."DL_POI" a, mmi_master."DL_ADDR_ADMIN_R" b WHERE ST_Within(a."SP_GEOMETRY",b."SP_GEOMETRY")='t' AND 
		a."ADMIN_ID"<>b."ID" AND a."ADMIN_ID"<>0
		*/
		RAISE WARNING '<-----------POI,ADDR_ADMIN_R->ADMIN_ID1';
		RAISE INFO '<-----------1.1.18';
		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 30.1:%',f1;
		RAISE info 'error caught 30.2:%',f2;
	END;
	RAISE INFO 'Poi’s Admin_Id does not match with its Admin Boundary Id';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,ADDR_ADMIN_R->ADMIN_ID 2
--1.1.19
--1.7.1
--172 msec
	BEGIN
		
		EXECUTE'INSERT INTO '||error_table||'(  unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT a."ID",'''||tbl_nme_poi||''',''ADMIN_ID'',a."ADMIN_ID"::text,''Poi’s Admin_Id should be 0 if Poi does not fall within its Admin Boundary'',''1.1.19'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" a,'|| mst_sch ||'."'|| UPPER(stat_code) ||'_ADDR_ADMIN_R" b WHERE ST_Within(a."SP_GEOMETRY",b."SP_GEOMETRY")=''f'' AND 
		a."ADMIN_ID"=b."ID" AND a."ADMIN_ID"<>0';	
		
		/*
		  SELECT a."ID",'DL_POI','ADMIN_ID',a."ADMIN_ID"::text,'Poi’s Admin_Id should be 0 if Poi does not fall within its Admin Boundary','1.1.19' 
		FROM mmi_master."DL_POI" a, mmi_master."DL_ADDR_ADMIN_R" b WHERE ST_Within(a."SP_GEOMETRY",b."SP_GEOMETRY")='f' AND 
		a."ADMIN_ID"=b."ID" AND a."ADMIN_ID"<>0	
		*/
		
		RAISE WARNING '<-----------POI,ADDR_ADMIN_R->ADMIN_ID2';
		RAISE INFO '<-----------1.1.19';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 33.1:%',f1;
		RAISE info 'error caught 33.2:%',f2;
	END;
	RAISE INFO 'Poi’s Admin_Id should be 0 if Poi does not fall within its Admin Boundary';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,ADDR_ADMIN_R->CITY_ID
--1.1.20
--1.7.2
-- 31 msec
	BEGIN
		EXECUTE'INSERT INTO '||error_table||'(  unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT a."ID",'''||tbl_nme_poi||''',''CITY_ID'',a."CITY_ID"::text,''Poi’s City_Id does not match with its Admin Boundary City_Id'',''1.1.20'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" a,'|| mst_sch ||'."'|| UPPER(stat_code) ||'_ADDR_ADMIN_R" b WHERE ST_Within(a."SP_GEOMETRY",b."SP_GEOMETRY")=''t'' AND 
		a."CITY_ID"<>b."CITY_ID" AND a."CITY_ID"<>0 AND b."CITY_ID"<>0';
		
		/*  
        SELECT a."ID",'DL_POI','CITY_ID',a."CITY_ID"::text,'Poi’s City_Id does not match with its Admin Boundary City_Id','1.1.20' 
		FROM mmi_master."DL_POI" a, mmi_master."DL_ADDR_ADMIN_R" b WHERE ST_Within(a."SP_GEOMETRY",b."SP_GEOMETRY")='t' AND 
		a."CITY_ID"<>b."CITY_ID" AND a."CITY_ID"<>0 AND b."CITY_ID"<>0
		*/
		
		RAISE WARNING '<-----------POI,ADDR_ADMIN_R->CITY_ID';
		RAISE INFO '<-----------1.1.20';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 34.1:%',f1;
		RAISE info 'error caught 34.2:%',f2;
	END;
	RAISE INFO 'Poi’s City_Id does not match with its Admin Boundary City_Id';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,ADDR_ADMIN_R->STT_ID
--1.1.21
--1.7.2
--- 31 msec
	BEGIN
		EXECUTE'INSERT INTO '||error_table||'(  unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT a."ID",'''||tbl_nme_poi||''',''STT_ID'',a."STT_ID"::text,''Poi’s Stt_Id does not match with its Admin Boundary Stt_Id'',''1.1.21'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" a,'|| mst_sch ||'."'|| UPPER(stat_code) ||'_ADDR_ADMIN_R" b WHERE ST_Within(a."SP_GEOMETRY",b."SP_GEOMETRY")=''t'' AND 
		a."STT_ID"<>b."STT_ID" AND a."STT_ID"<>0 AND b."STT_ID"<>0';
        /*  
        SELECT a."ID",'DL_POI','STT_ID',a."STT_ID"::text,'Poi’s Stt_Id does not match with its Admin Boundary Stt_Id','1.1.21' 
		FROM mmi_master."DL_POI" a, mmi_master."DL_ADDR_ADMIN_R" b WHERE ST_Within(a."SP_GEOMETRY",b."SP_GEOMETRY")='t' AND 
		a."STT_ID"<>b."STT_ID" AND a."STT_ID"<>0 AND b."STT_ID"<>0
		*/		 
		RAISE WARNING '<-----------POI,ADDR_ADMIN_R->STT_ID';
		RAISE INFO '<-----------1.1.21';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 35.1:%',f1;
		RAISE info 'error caught 35.2:%',f2;
	END;
	RAISE INFO 'Poi’s Stt_Id does not match with its Admin Boundary Stt_Id';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
----------------------------------------------------------------------------------------Admin_Point_P--------------------------------------------------------------------------------------
IF tbl_nme_poi <> '' AND tbl_nme_addr_p <> '' THEN
--1.1.54
--2.47.174
-- 31 msec
	BEGIN
		EXECUTE'INSERT INTO '||error_table||'(  unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT a."ID",'''||tbl_nme_poi||''',''ADMIN_ID'',a."ADMIN_ID"::text,''Admin_Id, City_Id, Stt_Id combination not found in Addr_Admin_P'',''1.1.54'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" a,'|| mst_sch ||'."'|| UPPER(stat_code) ||'_ADDR_ADMIN_P" b WHERE 
		(a."ADMIN_ID"<>0 AND a."ADMIN_ID"=b."ADRADMN_ID" AND a."CITY_ID"<>b."CITY_ID" AND a."STT_ID"<>b."STT_ID")';
		
-- 		SELECT a."ID",'DL_POI','ADMIN_ID',a."ADMIN_ID"::text,'Admin_Id, City_Id, Stt_Id combination not found in Addr_Admin_P','1.1.54' 
-- 		FROM mmi_master."DL_POI" a,mmi_master."DL_ADDR_ADMIN_P" b WHERE (a.status NOT IN ('0','5') OR (COALESCE(a.status,'')='') ) AND 
-- 		(a."ADMIN_ID"<>0 AND a."ADMIN_ID"=b."ADRADMN_ID" AND a."CITY_ID"<>b."CITY_ID" AND a."STT_ID"<>b."STT_ID") 

		RAISE WARNING '<-----------POI,ADDR_ADMIN_R->CITY_ID';
		RAISE INFO '<-----------2.47.174';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 34.1:%',f1;
		RAISE info 'error caught 34.2:%',f2;
	END;
	RAISE INFO 'Admin_Id, City_Id, Stt_Id combination not found in Addr_Admin_P';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
----------------------------------------------------------------------------------------State_Boundary--------------------------------------------------------------------------------------
IF tbl_nme_state <> '' THEN
--POI,STATE_BOUNDARY->STT_ID
--1.1.40
--No error Code
-- 31 msec
	BEGIN 
		EXECUTE'INSERT INTO '||error_table||'(  unquid, table_name, field_name, field_value, error_type , error_code )
		( SELECT t3.id,'''||tbl_nme_poi||''',''STT_ID'',t3."STT_ID"::text,''Poi’s Stt_Id does not match with its State Boundary Stt_Id'',''1.1.40'' 
		FROM (SELECT t2."ID" As ID, t2."STT_ID", t2.ST_Within As geom FROM (SELECT t."ID", t."STT_ID", ST_Within(t."SP_GEOMETRY",t1."SP_GEOMETRY") 
		FROM (SELECT * FROM '||sch_name||'."'||tbl_nme_poi||'") As t, 
		'|| mst_sch ||'."'|| UPPER(tbl_nme_state) ||'" As t1 WHERE t."STT_ID"<>t1."ID") As t2 WHERE ST_Within= ''t'') As t3) ';
		
		/*
		  SELECT t3.id,'DL_POI','STT_ID',t3."STT_ID"::text,'Poi’s Stt_Id does not match with its State Boundary Stt_Id','1.1.40' 
		FROM (SELECT t2."ID" As ID, t2."STT_ID", t2.ST_Within As geom FROM (SELECT t."ID", t."STT_ID", ST_Within(t."SP_GEOMETRY",t1."SP_GEOMETRY") 
		FROM (SELECT * FROM mmi_master."DL_POI") As t, 
		mmi_master."DL_STATE_BOUNDARY" As t1 WHERE t."STT_ID"<>t1."ID") As t2 WHERE ST_Within= 't') As t3
		*/
		RAISE WARNING '<-----------POI,STATE_BOUNDARY->STT_ID';
		RAISE INFO '<-----------1.1.40';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 36.1:%',f1;
		RAISE info 'error caught 36.2:%',f2;
	END;
	RAISE INFO 'Poi’s Stt_Id does not match with its State Boundary Stt_Id';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
--------------------------------------------------------------------------------------------EXCP--------------------------------------------------------------------------------------------
IF tbl_nme_poi <> '' AND tbl_name_water <> '' THEN
--POI,NATIONAL_LUSE_WATER->POI FALLIN OR INTERSECTS
--1.1.43
--No error code
-- 313 sec
	BEGIN 
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT a."ID",'''||tbl_nme_poi||''',''EXCP'',a."EXCP",''If Poi falling or intersecting with water, then maintain ’WAY’ in EXCP'',''1.1.43'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As a, '|| mst_sch ||'."'||tbl_name_water||'" As b
		WHERE (ST_WITHIN(a."SP_GEOMETRY",b."SP_GEOMETRY")=true) AND COALESCE(a."EXCP",'''') NOT LIKE ''%WAY%'' GROUP BY a."ID",a."EXCP"';
		
        /*
		  SELECT a."ID",'DL_POI','EXCP',a."EXCP",'If Poi falling or intersecting with water, then maintain ’WAY’ in EXCP','1.1.43' 
		FROM mmi_master."DL_POI" As a, mmi_master."DL_NATIONAL_LUSE_WATER" As b
		WHERE (ST_WITHIN(a."SP_GEOMETRY",b."SP_GEOMETRY")=true) AND COALESCE(a."EXCP",'') NOT LIKE '%WAY%' GROUP BY a."ID",a."EXCP"

		*/		
		RAISE WARNING '<-----------POI,NATIONAL_LUSE_WATER->POI FALLIN OR INTERSECTS';
		RAISE INFO '<-----------1.1.43';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE INFO 'If Poi falling or intersecting with water, then maintain ’WAY’ in EXCP';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.1.55
--2.47.293
--4.9 sec
	BEGIN 
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT a."ID",'''||tbl_nme_poi||''',''EXCP'',a."EXCP",''Must be match with Id from Water layer according to Reflr_Typ'',''1.1.55''
		From '||sch_name||'."'||tbl_nme_poi||'" As a, (Select "REFLR_ID" As rid From '||sch_name||'."'||tbl_nme_poi||'"
		Where "REFLR_ID"<>0 AND "REFLR_TYP"=''W'' Except Select "ID" From '|| mst_sch ||'."'||tbl_name_water||'") As b Where a."REFLR_ID"=b.rid ';

-- 		SELECT a."ID",'DL_POI','EXCP',a."EXCP",'Must be match with Id from Water layer according to Reflr_Typ','1.1.55' 
	  --FROM mmi_master."DL_POI" As a, mmi_master."DL_NATIONAL_LUSE_WATER" As b
	  --WHERE a."REFLR_TYP"='W' AND a."REFLR_ID"<>b."ID" AND a."REFLR_ID"<>0
		
		RAISE WARNING '<-----------POI,NATIONAL_LUSE_WATER->POI FALLIN OR INTERSECTS';
		RAISE INFO '<-----------1.1.55';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE INFO 'Must be match with Id from Water layer according to Reflr_Typ';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
IF tbl_nme_poi <> '' AND tbl_name_other <> '' THEN
--1.1.55
--2.47.293
--31 msec
	BEGIN 
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT a."ID",'''||tbl_nme_poi||''',''EXCP'',a."EXCP",''Must be match with Id from Other layer according to Reflr_Typ'',''1.1.55''
		From '||sch_name||'."'||tbl_nme_poi||'" As a, (Select "REFLR_ID" As rid From '||sch_name||'."'||tbl_nme_poi||'"
		Where "REFLR_ID"<>0 AND "REFLR_TYP"=''O'' Except Select "ID" From '|| mst_sch ||'."'||tbl_name_other||'") As b Where a."REFLR_ID"=b.rid ';
		/*
				SELECT a."ID",'DL_POI','EXCP',a."EXCP",'Must be match with Id from Green layer according to Reflr_Typ','1.1.55'
				From mmi_master."DL_POI" As a, (Select "REFLR_ID" As rid From mmi_master."DL_POI"
				Where "REFLR_ID"<>0 AND "REFLR_TYP"='G' Except Select "ID" From mmi_master."DL_NATIONAL_LUSE_GREEN") As b Where a."REFLR_ID"=b.rid
		*/
		RAISE WARNING '<-----------POI,NATIONAL_LUSE_WATER->POI FALLIN OR INTERSECTS';
		RAISE INFO '<-----------1.1.73';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE INFO 'Must be match with Id from Other layer according to Reflr_Typ';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
IF tbl_nme_poi <> '' AND tbl_name_green <> '' THEN
--1.1.55
--2.47.293
--125 msec
	BEGIN 
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT a."ID",'''||tbl_nme_poi||''',''EXCP'',a."EXCP",''Must be match with Id from Green layer according to Reflr_Typ'',''1.1.55''
		From '||sch_name||'."'||tbl_nme_poi||'" As a, (Select "REFLR_ID" As rid From '||sch_name||'."'||tbl_nme_poi||'"
		Where "REFLR_ID"<>0 AND "REFLR_TYP"=''G'' Except Select "ID" From '|| mst_sch ||'."'||tbl_name_green||'") As b Where a."REFLR_ID"=b.rid ';
        /*
			SELECT a."ID",'DL_POI','EXCP',a."EXCP",'Must be match with Id from Green layer according to Reflr_Typ','1.1.55'
			From mmi_master."DL_POI" As a, (Select "REFLR_ID" As rid From mmi_master."DL_POI"
			Where "REFLR_ID"<>0 AND "REFLR_TYP"='G' Except Select "ID" From mmi_master."DL_NATIONAL_LUSE_GREEN") As b Where a."REFLR_ID"=b.rid
		*/
-- 		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
-- 		SELECT a."ID",'''||tbl_nme_poi||''',''EXCP'',a."EXCP",''Must be match with Id from Green layer according to Reflr_Typ'',''NO ERROR CODE'' 
-- 		FROM '||sch_name||'."'||tbl_nme_poi||'" As a, '|| mst_sch ||'."'||tbl_name_green||'" As b
-- 		WHERE (a.status NOT IN (''0'',''5'') OR COALESCE(a.status,'''')='''') AND a."REFLR_TYP"=''G'' AND a."REFLR_ID"<>b."ID" AND a."REFLR_ID"<>0';
		
		RAISE WARNING '<-----------POI,NATIONAL_LUSE_WATER->POI FALLIN OR INTERSECTS';
		RAISE INFO '<-----------1.1.55';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE INFO 'Must be match with Id from Green layer according to Reflr_Typ';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
IF tbl_nme_poi <> '' AND tbl_name_junction <> '' THEN
--1.1.55
--2.47.293
--- 47 msec
	BEGIN 
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT a."ID",'''||tbl_nme_poi||''',''EXCP'',a."EXCP",''Must be match with Id from Junctioin layer according to Reflr_Typ'',''1.1.55''
		From '||sch_name||'."'||tbl_nme_poi||'" As a, (Select "REFLR_ID" As rid From '||sch_name||'."'||tbl_nme_poi||'"
		Where "REFLR_ID"<>0 AND "REFLR_TYP"=''J'' Except Select "JNC_ID" From '|| mst_sch ||'."'||tbl_name_junction||'") As b Where a."REFLR_ID"=b.rid ';
        /*
		
			SELECT a."ID",'DL_POI','EXCP',a."EXCP",'Must be match with Id from Junctioin layer according to Reflr_Typ','1.1.55'
			From mmi_master."DL_POI" As a, (Select "REFLR_ID" As rid From mmi_master."DL_POI"
			Where "REFLR_ID"<>0 AND "REFLR_TYP"='J' Except Select "JNC_ID" From mmi_master."DL_CITY_JN") As b Where a."REFLR_ID"=b.rid
		*/
-- 		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
-- 		SELECT a."ID",'''||tbl_nme_poi||''',''EXCP'',a."EXCP",''Must be match with Id from Junctioin layer according to Reflr_Typ'',''NO ERROR CODE'' 
-- 		FROM '||sch_name||'."'||tbl_nme_poi||'" As a, '|| mst_sch ||'."'||tbl_name_junction||'" As b
-- 		WHERE (a.status NOT IN (''0'',''5'') OR COALESCE(a.status,'''')='''') AND a."REFLR_TYP"=''J'' AND a."REFLR_ID"<>b."JNC_ID" AND a."REFLR_ID"<>0 ';
		
		RAISE WARNING '<-----------POI,NATIONAL_LUSE_WATER->POI FALLIN OR INTERSECTS';
		RAISE INFO '<-----------1.1.55';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE INFO 'Must be match with Id from Junctioin layer according to Reflr_Typ';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
IF tbl_nme_poi <> '' AND tbl_name_rail <> '' THEN
--POI,RAIL_NETWORK->INTERSECTION
--1.1.47
--No error Code
-- 47 msec
	BEGIN 
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT a."ID",'''||UPPER(tbl_nme_edgeline)||''',''EXCP'',a."EXCP"::text,''If Poi Edgeline intersects with Rail Network, then maintain ’RLY’ in EXCP'',''1.1.47'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" As a, '|| mst_sch ||'."'||tbl_name_rail||'" As b WHERE (ST_Intersects(a."SP_GEOMETRY",b."SP_GEOMETRY")=true) AND 
		(COALESCE(a."EXCP",'''') NOT LIKE ''%RLY%'' OR COALESCE(a."EXCP",'''') NOT LIKE ''%MTY%'') AND COALESCE(a."EXCP",'''') NOT LIKE ''%RLY%'' GROUP BY a."ID",a."EXCP"';
		
		/*
		
		SELECT a."ID",'DL_POI_EDGELINE','EXCP',a."EXCP"::text,'If Poi Edgeline intersects with Rail Network, then maintain ’RLY’ in EXCP','1.1.47' 
		FROM mmi_master."DL_POI" As a, mmi_master."DL_RAIL_NETWORK" As b WHERE (ST_Intersects(a."SP_GEOMETRY",b."SP_GEOMETRY")=true) AND 
		(COALESCE(a."EXCP",'') NOT LIKE '%RLY%' OR COALESCE(a."EXCP",'') NOT LIKE '%MTY%') AND COALESCE(a."EXCP",'') NOT LIKE '%RLY%' GROUP BY a."ID",a."EXCP"								
								
		*/
		RAISE WARNING '<-----------POI,RAIL_NETWORK->INTERSECTION';
		RAISE INFO '<-----------1.1.47';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE INFO 'If Poi Edgeline intersects with Rail Network, then maintain ’RLY’ in EXCP';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
IF tbl_nme_road <> '' AND tbl_nme_poi <> '' AND tbl_nme_edgeline <> '' THEN
--POI,ROAD_NETWORK->POI FALLIN BETWEEN MULTI-DIGITIZED ROADS
--1.1.41
--No error code
-- 1.31 min
	BEGIN
			-- EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		-- SELECT "ID",'''||tbl_nme_poi||''',''EXCP'',"EXCP"::text,''If Poi falling between Double digitize Road or Road direction is same, then maintain ’MDY’ in EXCP'',''1.1.41''
		-- FROM '||sch_name||'."'||tbl_nme_poi||'" As p INNER JOIN (SELECT "ID" As e_id FROM '||sch_name||'."'||UPPER(tbl_nme_edgeline)||'" As a, '||tbl_nme_road||' As b WHERE b."MD"=1 AND a."SIDE"=''R'' AND  
		-- ST_Intersects(a."SP_GEOMETRY"::GEOGRAPHY, b."SP_GEOMETRY"::GEOGRAPHY)=''t'') As e ON p."ID"=e.e_id AND COALESCE(p."EXCP",'''') NOT LIKE ''%MDY%''';
	    
		/*
								
			SELECT "ID",'DL_POI','EXCP',"EXCP"::text,'If Poi falling between Double digitize Road or Road direction is same, then maintain ’MDY’ in EXCP','1.1.41'
			FROM mmi_master."DL_POI" As p INNER JOIN (SELECT "ID" As e_id FROM mmi_master."DL_POI_EDGELINE" As a, mmi_master."DL_ROAD_NETWORK" As b WHERE b."MD"=1 AND a."SIDE"='R' AND  
			ST_Intersects(a."SP_GEOMETRY"::GEOGRAPHY, b."SP_GEOMETRY"::GEOGRAPHY)='t') As e ON p."ID"=e.e_id AND COALESCE(p."EXCP",'') NOT LIKE '%MDY%'

							
		*/
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT p."ID",'''||tbl_nme_poi||''',''EXCP'',"EXCP"::text,''If Poi falling between Double digitize Road or Road direction is same, then maintain ’MDY’ in EXCP'',''1.1.41''
		FROM '||sch_name||'."'||tbl_nme_poi||'" As p INNER JOIN (SELECT t."ID" from (select b."ID",b."EDGE_ID",a."EDGE_ID" FROM '||sch_name||'."'||UPPER(tbl_nme_edgeline)||'" As b, '||tbl_nme_road||' As a WHERE b."EDGE_ID" = a."EDGE_ID" and a."MD"=1 AND b."SIDE" Like ''R'') t)e
		ON p."ID"=e."ID" AND COALESCE(p."EXCP",'''') NOT LIKE ''%MDY%''';
		
		RAISE WARNING '<-----------POI,ROAD_NETWORK->POI FALLIN BETWEEN MULTI-DIGITIZED ROADS';
		RAISE INFO '<-----------1.1.41';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE INFO 'If Poi falling between Double digitize Road or Road direction is same, then maintain MDY in EXCP';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,POI_EDGELINE, ROAD_NETWORK->POI_EDGELINE CROSSING MULTI EDGE ROAD NETWORK
--1.1.61
--new add by ashu
--5242ms
	BEGIN
		
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT C."ID",'''||tbl_nme_edgeline||''',''EXCP'',"EXCP"::text,''If POI_EDGELINE CROSSING MULTIPLE EDGE OF ROAD NETWORK ,then maintain ’MLY’ in EXCP'',''1.1.61''
		FROM '||sch_name||'."'||tbl_nme_poi||'" C INNER JOIN (select t."ID",count(t."ID") from ( select b."ID",a."EDGE_ID" from '||tbl_nme_road||' a ,
		'||sch_name||'."'||UPPER(tbl_nme_edgeline)||'" b where st_crosses(b."SP_GEOMETRY" ,a."SP_GEOMETRY") and 
		COALESCE(a."FTR_CRY",'''') NOT LIKE ''NMR'') t group by t."ID" having count(t."ID") >1) e on e."ID"=c."ID" and COALESCE(c."EXCP",'''') NOT LIKE ''%MLY%''';
		
	/*	
	select c."ID" from mmi_master."DL_POI" c  INNER JOIN  (select t."ID",count(t."ID") from (
	select b."ID",a."EDGE_ID" from mmi_master."DL_ROAD_NETWORK" a,mmi_master."DL_POI_EDGELINE" b where st_crosses(b."SP_GEOMETRY" ,a."SP_GEOMETRY") and COALESCE(a."FTR_CRY",'') NOT LIKE 'NMR') t  
	group by t."ID" having count(t."ID") >1) e on e."ID"=c."ID"  and COALESCE(c."EXCP",'') NOT LIKE '%MLY%'								
								
	*/			
	
		RAISE WARNING '<-----------POI,POI_EDGELINE, ROAD_NETWORK->POI_EDGELINE CROSSING MULTI EDGE ROAD NETWORK';
		RAISE INFO '<-----------1.1.61';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;	
	RAISE INFO 'POI,POI_EDGELINE, ROAD_NETWORK->POI_EDGELINE CROSSING MULTI EDGE ROAD NETWORK';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--If edgeline connected with MD roads then edgeline side should be L
--1.1.69, UPDATED BY GOLDY(22/07/2019)
--47 msec 
	BEGIN
		EXECUTE 'with res as (
		select "ID","EXCP" FROM mmi_master."DL_POI" WHERE "EXCP" LIKE ''MDY'')
		INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		(SELECT t2."ID",'''||tbl_nme_edgeline||''',''SIDE'',t2."SIDE",''If edgeline connected with MD roads then edgeline side should be "L"'',''1.1.69'' 
		FROM (SELECT t."ID", t."SIDE" FROM '||sch_name||'."'||tbl_nme_edgeline||'" AS t JOIN '||tbl_nme_road||' 
        AS t1 ON t."EDGE_ID" = t1."EDGE_ID" AND t1."MD" = 1 AND t."SIDE" = ''R'' and t."ID" NOT IN (SELECT "ID" FROM res)) AS t2 ) WHERE t."EXCP" <> ''MDY'' ';
	    
		/*
		with res as (select "ID","EXCP" FROM mmi_master."DL_POI" WHERE "EXCP" LIKE 'MDY')
		SELECT t."ID", t."SIDE" FROM mmi_master."DL_POI_EDGELINE" AS t JOIN mmi_master."DL_ROAD_NETWORK" 
		AS t1 ON t."EDGE_ID" = t1."EDGE_ID" AND t1."MD" = 1 AND t."SIDE" = 'R' and t."ID" NOT IN (SELECT "ID" FROM res) WHERE t."EXCP" <> 'MDY'
       */
		
		RAISE WARNING '<-----------POI,ROAD_NETWORK->POI edgeline side should be "L"';
		RAISE INFO '<-----------1.1.69';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE INFO 'If edgeline connected with MD roads then edgeline side should be L';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;

--If Poi State Id Mismatch
--2.47.29
--47 msec 
IF tbl_nme_state <> '' THEN
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		(SELECT t2."ID",'''||tbl_nme_poi||''',''STT_ID'',t2."STT_ID",''STT_ID Not Match With Its State Boundary'',''2.47.29'' 
		FROM (SELECT t."ID", t."STT_ID" FROM '||sch_name||'."'||tbl_nme_poi||'" AS t LEFT JOIN '||mst_sch||'."'||tbl_nme_state||'" 
         AS t1 ON t."STT_ID" = t1."ID" AND ST_Contains(t1."SP_GEOMETRY",t."SP_GEOMETRY") WHERE t1."ID" IS NULL) AS t2 )';
	    
		
		-- SELECT t."STT_ID",t1."ID" FROM upload."PB_CN001788_18022019_POI_EDT" as t 
		-- LEFT JOIN mmi_master."DL_STATE_BOUNDARY" as t1
		-- ON t."STT_ID"=t1."ID" AND ST_Contains(t1."SP_GEOMETRY",t."SP_GEOMETRY") WHERE t1."ID" IS NULL
		
		
		RAISE WARNING '<-----------2.47.29';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE INFO 'If edgeline connected with MD roads then edgeline side should be L';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;

	-- --2.47.370.1
	-- -- ADDED BY GOLDY 03/04/2019
	-- if tbl_nme_poi_addr_regn <>'' then
	-- BEGIN
		
		
		-- EXECUTE ' INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
				 -- SELECT tab1."ID",'''||tbl_nme_poi||''',''FP_ID'',tab1."FP_ID"::text, ''If not intersecting with Addr_Region layer then FP_ID must be from intersecting Footprint '',''2.47.370.1''
				 -- FROM '||sch_name||'."'|| UPPER(tbl_nme_poi) ||'" AS tab1 LEFT JOIN '||tbl_nme_poi_addr_regn||' as tab2
				 -- on tab1."FP_ID" <> tab2."ID" where (ST_INTERSECTS(tab1."SP_GEOMETRY",tab2."SP_GEOMETRY") = true) and tab1."FP_ID" <> 0 ';

		-- -- select tab1."ID",tab1."FP_ID" 
		-- -- FROM mmi_master."DL_POI" AS tab1 left join mmi_master."DL_ADDR_REGION" as tab2 
		-- -- on tab1."FP_ID" <> tab2."ID" where (ST_INTERSECTS(tab1."SP_GEOMETRY",tab2."SP_GEOMETRY") = true) and tab1."FP_ID" <> 0

		
		-- RAISE INFO '<-----------2.47.370.1';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	-- END IF;

	
	--2.47.370.2
	-- ADDED BY GOLDY 03/04/2019
	if tbl_nme_poi_addr_regn <>'' then
	BEGIN
		EXECUTE ' With Sel As 
				(select tab1."ID" FROM '||sch_name||'."'|| UPPER(tbl_nme_poi) ||'"  AS tab1 left join '||tbl_nme_poi_addr_regn||' as tab2  on (ST_INTERSECTS(tab1."SP_GEOMETRY",tab2."SP_GEOMETRY") = true))
				 INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
				 SELECT t1."ID",'''||tbl_nme_poi||''',''FP_ID'',t1."FP_ID", ''If not intersecting with Addr_Region layer then FP_ID must be 0 '',''2.47.370.2''
				 From '||sch_name||'."'|| UPPER(tbl_nme_poi) ||'" as t1 left join Sel t2
				 On t1."ID"=t2."ID" where t2."ID" is null and t1."FP_ID"<>0 ';

		-- Select * From mmi_master."DL_POI" t1
		-- where "ID" NOT IN (select tab1."ID" FROM mmi_master."DL_POI" AS tab1 left join mmi_master."DL_ADDR_REGION" as tab2  on 
		-- (ST_INTERSECTS(tab1."SP_GEOMETRY",tab2."SP_GEOMETRY") = true)) AND "FP_ID"<>0
			
		-- With Sel As (select tab1."ID" FROM upload_final."UP_CE00067413_17062019_PACKING_POI" AS tab1 left join manual_upd."UP_ADDR_REGION" as tab2  on (ST_INTERSECTS(tab1."SP_GEOMETRY",tab2."SP_GEOMETRY") = true))
		 --  Select t1."ID",t2."ID" From upload_final."UP_CE00067413_17062019_PACKING_POI" t1 Left Join Sel t2 On t1."ID"=t2."ID" where t2."ID" is null and t1."FP_ID"<>0																						   																																	   

	
			
		
		RAISE INFO '<-----------2.47.370.2';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END IF;
	
	--2.60.34
	-- ADDED BY GOLDY 03/04/2019
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
				 SELECT "ID",'''||tbl_nme_edgeline||''',''MAN_ENTRY'',"MAN_ENTRY"::text, ''Only 0 or 1 values are accepted in this column'',''2.60.34''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme_edgeline) ||'"
				 WHERE "MAN_ENTRY" NOT IN (''0'',''1'') ';

		-- SELECT "ID","MAN_ENTRY",'tbl_nme_edgeline','ID'::text, 'Only 0 or 1 values are accepted in this column','2.60.34'
		-- FROM  mmi_master."DL_POI_EDGELINE"
		-- WHERE "MAN_ENTRY" NOT IN ('0','1')

		
		RAISE INFO '<-----------2.60.34';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	-- --2.60.37
	-- -- ADDED BY GOLDY 03/04/2019
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
				 -- SELECT "ID",'''||tbl_nme_edgeline||''',''PERSON'',"PERSON"::text, ''NumEric values must not be present'',''2.60.37''
				 -- FROM '||sch_name||'."'|| UPPER(tbl_nme_edgeline) ||'"
				 -- WHERE "PERSON" ~''[0-9]'' ';

		-- -- SELECT "ID","PERSON",'DL_POI'::text, 'NumEric values must not be present','2.60.37'
		-- -- FROM  mmi_master."DL_POI_EDGELINE"
		-- -- WHERE "PERSON" ~'[0-9]'

		
		-- RAISE INFO '<-----------2.60.37';
		
	-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;

	--2.60.35
	-- ADDED BY GOLDY 03/04/2019
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
				 SELECT "ID",'''||tbl_nme_edgeline||''',''DT_SRCMVD'',"DT_SRCMVD"::text, ''If available then must be 6 numeric digit'',''2.60.35''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme_edgeline) ||'"
				 WHERE COALESCE("DT_SRCMVD",'''') <> '''' AND "DT_SRCMVD" ~''^\d{6}$'' = FALSE  ';

		--  SELECT "ID","DT_SRCMVD",'DL_POI'::text, 'If available then must be 6 numeric digit','2.60.35'
		 -- FROM  mmi_master."DL_POI_EDGELINE"
		 -- WHERE "DT_SRCMVD" ~'^\d{6}$' = FALSE 

		
		RAISE INFO '<-----------2.60.35';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	
	--2.60.36
	-- ADDED BY GOLDY 03/04/2019
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
				 SELECT "ID",'''||tbl_nme_edgeline||''',''SRCMVD'',"SRCMVD"::text, ''If avaialble then Dt_SrcMvd must be present and vice versa'',''2.60.36''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme_edgeline) ||'"
				 WHERE COALESCE("SRCMVD",'''') = '''' and  COALESCE("DT_SRCMVD",'''') <>'''' ';

		-- SELECT "ID","DT_SRCMVD","SRCMVD",'DL_POI'::text, 'If avaialble then Dt_SrcMvd must be present and vice versa','2.60.36'
		-- FROM  mmi_master."DL_POI_EDGELINE"
		-- WHERE COALESCE("SRCMVD",'') = '' and  COALESCE("DT_SRCMVD",'') <>''

		
		
		RAISE INFO '<-----------2.60.36';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
		
	--2.60.38
	-- ADDED BY GOLDY 03/04/2019
	if tbl_nme_road <>'' then
	BEGIN	
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
				 SELECT tab1."ID",'''||tbl_nme_poi||''',''FP_ID'',tab1."FP_ID"::text, ''Must not connected with roads where Fow_Prev in FL BR SU FO TN EM RM '',''2.60.38''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme_poi) ||'" AS tab1 , '||tbl_nme_road||' as tab2
				 WHERE ST_INTERSECTS(tab1."SP_GEOMETRY",tab2."SP_GEOMETRY") = TRUE AND tab2."FOW_PREV" IN (''FL'', ''BR'', ''SU'', ''FO'', ''TN'', ''EM'', ''RM'') ';

		-- SELECT tab1."ID",tab1."EDGE_ID",tab2."EDGE_ID",tab2."FOW_PREV" FROM mmi_master."DL_POI" tab1 ,mmi_master."DL_ROAD_NETWORK" tab2 
		--WHERE ST_INTERSECTS(tab1."SP_GEOMETRY",tab2."SP_GEOMETRY") = TRUE AND "FOW_PREV" IN ('FL', 'BR', 'SU', 'FO', 'TN', 'EM', 'RM')

			
		
		RAISE INFO '<-----------2.60.38';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END IF;
	
	--2.47.371
	-- ADDED BY GOLDY 04/04/2019
	if tbl_nme_road <>'' then
	BEGIN	
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
				 SELECT tab1."ID",'''||tbl_nme_poi||''',''ID'',tab1."ID"::text, ''POI must not intersects with Road '',''2.47.371''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme_poi) ||'" AS tab1 , '||tbl_nme_road||' as tab2
				 where ST_INTERSECTS(tab1."SP_GEOMETRY",tab2."SP_GEOMETRY") = true ';

		-- select tab1."ID",tab2."EDGE_ID" FROM mmi_master."DL_POI" tab1,mmi_master."DL_ROAD_NETWORK" tab2 WHERE 
		-- ST_INTERSECTS(tab1."SP_GEOMETRY",tab2."SP_GEOMETRY") = true
			
		
		RAISE INFO '<-----------2.47.371';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END IF;
	
	--1.1.1.01
	-- ADDED BY GOLDY 04/04/2019
	if tbl_nme_addr_point <>'' then
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
				 SELECT "ID",'''||tbl_nme_poi||''',''PIP_TYP'',"PIP_TYP"::text, ''PIP_ID MUST BE FROM ADDR LAYER WHERE PIP_TYP = 3 '',''1.1.1.01''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme_poi) ||'" 
				 WHERE  "PIP_TYP"=3 AND "PIP_ID" NOT IN (SELECT "ID" FROM '||tbl_nme_addr_point||') ';

		-- select "ID","PIP_TYP" FROM mmi_master."DL_POI" WHERE "PIP_TYP"=3 AND "PIP_ID" NOT IN (SELECT "ID" FROM mmi_master."DL_ADDR_POINT") 
			
		
		RAISE INFO '<-----------2.47.371';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END IF;

	--1.1.1.03
	-- ADDED BY GOLDY 05/06/2019
	if tbl_nme_addr_point <>'' then
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
				 SELECT tab1."ID",'''||tbl_nme_poi||''',''PIP_TYP'',tab1."PIP_TYP", ''PIP_ID MUST BE FROM ADDR LAYER WHERE PIP_TYP = 3 '',''1.1.1.03''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme_poi) ||'"  as tab1 LEFT JOIN '||sch_name||'."'|| UPPER(tbl_nme_poi) ||'"  as tab2
				 ON tab1."ID" = tab2."ID" WHERE tab2."ID" IS NULL AND tab1."ID"  IN (SELECT "ID" FROM '||tbl_nme_addr_point||') AND tab1."PIP_TYP" not in (1,2)  ';

		-- SELECT tab1."ID" from mmi_master."DL_POI" as tab1 LEFT JOIN mmi_master."DL_POI" AS tab2 ON tab1."ID" = tab2."ID" WHERE tab2."ID" IS NULL
		-- AND tab1."ID"  IN (SELECT "ID" FROM mmi_master."DL_P1_ADDR_POINT") AND tab1."PIP_TYP" not in (1,2)
			
		
		RAISE INFO '<-----------1.1.1.03';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END IF;

---CHECK FOR REPEATED UPLOADED RECORDS
---Added By Abhinav 
RAISE INFO 'FINAL UPLOADED TABLE: %',final_uploaded_tbl_poi;
IF final_uploaded_tbl_poi <> '' THEN
	BEGIN

		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code ) 
		SELECT t1."ID",'''||tbl_nme_poi||''',''ID'',t1."ID",''This Record is already uploaded into this version, please compare it'',''1.1.14'' 
		FROM '||sch_name||'."'||tbl_nme_poi||'" AS t1 INNER JOIN '||final_uploaded_tbl_poi||' 
		AS t2 ON t1."ID" = t2."ID" ';
	    
		-- SELECT t1."ID",'DL_POI','ID',t1."ID",'This Record is already uploaded into this version, please compare it','1.1.14' 
		---FROM mmi_master."DL_POI AS t1 INNER JOIN '||final_uploaded_schema||'."'||final_uploaded_tbl_poi||'" 
		---AS t2 ON t1."ID" = t2."ID"
		
		
		RAISE WARNING '<-----------1.1.1.03';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE INFO 'CHECK FOR REPEATED UPLOADED RECORDS';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
	
--1.1.1.04
	-- ADDED BY GOLDY 29/07/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
				 SELECT "ID",'''||tbl_nme_poi||''',''EXCP'',"EXCP", ''WRONG EXCEPTION (THIS IS EDGELINE EXCEPTION)'',''1.1.1.03''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme_poi) ||'"  
				 WHERE "EXCP" IN (SELECT code FROM spatial_layer_functions.excp_code where layer_name LIKE ''EDGELINE'') ';

		-- SELECT "ID","EXCP" FROM mmi_master."DL_POI"
		-- WHERE "EXCP" IN (SELECT code FROM spatial_layer_functions.excp_code where layer_name LIKE 'EDGELINE')

			
		
		RAISE INFO '<-----------1.1.1.04';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
--1.1.1.05
-- ADDED BY GOLDY 29/07/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
				 SELECT "ID",'''||tbl_nme_edgeline||''',''EXCP'',"EXCP", ''WRONG EXCEPTION (THIS IS POI EXCEPTION)'',''1.1.1.05''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme_edgeline) ||'"  
				 WHERE "EXCP" IN (SELECT code FROM spatial_layer_functions.excp_code where layer_name LIKE ''POI'') ';

		-- SELECT "ID","EXCP" FROM mmi_master."DL_POI_EDGELINE"
		-- WHERE "EXCP" IN (SELECT code FROM spatial_layer_functions.excp_code where layer_name LIKE 'POI')
			
		
		RAISE INFO '<-----------1.1.1.05';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

	
	-- -- 2.47.106.1
	-- -- ADDED BY GOLDY 11/04/2019
	-- IF master_tbl_poi <> '' THEN 
	-- BEGIN
		-- EXECUTE 'INSERT INTO qa.'||user_id||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 -- SELECT tab1."ID",tab1."NAME",'''||tbl_nme_poi||''',''PIP_ID'',tab1."PIP_ID"::text, ''PIP_Id must exist as ID in POI or Addr_Point (Building) Layer'',''2.47.106''
				 -- FROM '||sch_name||'."'|| UPPER(tbl_nme_poi) ||'" tab1 left join '||master_tbl_poi||' tab2 on tab1."PIP_ID" = tab2."ID"
				 -- WHERE tab2."ID" IS NULL AND tab1."PIP_ID" <> 0  ';

		-- -- SELECT tab1."ID",tab1."PIP_ID",tab2."ID"
	    -- -- FROM upload."GJ_CE00075615_07062019_POI_EDT" tab1 LEFT join upload."GJ_CE00075615_07062019_POI_EDT" tab2 on tab1."PIP_ID" = tab2."ID"
	    -- -- WHERE tab2."ID" IS NULL AND tab1."PIP_ID" <> 0

		
		-- RAISE INFO '<-----------2.47.106.1';
		
	-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into qa.attriberror (message, context) values('''||f1||''','''||f2||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	-- END IF;
	
--1.1.1.02
-- 32 msec
	BEGIN
		EXECUTE ' with res as 
		(SELECT tab1."ID",tab1."PIP_ID" 
		FROM '||sch_name||'."'|| UPPER(tbl_nme_poi) ||'" tab1 LEFT join '||sch_name||'."'|| UPPER(tbl_nme_poi) ||'" tab2 on tab1."PIP_ID" = tab2."ID"
		WHERE tab2."ID" IS NULL AND tab1."PIP_ID" <> 0 AND tab1."PIP_TYP" IN (1,2)) 
		INSERT INTO '||error_table||'( unquid, table_name, field_name, field_value, error_type , error_code )
		SELECT t1."ID",'''||tbl_nme_poi||''',''PIP_ID'',t1."PIP_ID", ''PIP_ID MUST BE FROM MASTER LAYER WHERE PIP_TYP = 1 OR 2'',''1.1.1.02'' 
		FROM res t1 LEFT join '||master_tbl_poi||' t2 on t1."PIP_ID" = t2."ID"
		WHERE t2."ID" IS NULL AND t1."PIP_ID" <> 0 AND "PIP_TYP" IN (1,2)   ';
		 
		 /*
		  with res as 
		(SELECT tab1."ID",tab1."PIP_ID"
		FROM mmi_master."DL_POI" tab1 LEFT join mmi_master."DL_POI" tab2 on tab1."PIP_ID" = tab2."ID"
		WHERE tab2."ID" IS NULL AND tab1."PIP_ID" <> 0 AND tab1."PIP_TYP" IN (1,2)) 
		 SELECT t1."ID",t1."PIP_ID"
		 FROM res t1 LEFT join mmi_master."DL_POI" t2 on t1."PIP_ID" = t2."ID"
		 WHERE t2."ID" IS NULL AND t1."PIP_ID" <> 0 AND "PIP_TYP" IN (1,2)
		 */
		 
		 RAISE INFO '<-----------1.1.1.02';
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'PIP_TYP should be 0 AND 1';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	
	-- -- 2.47.106.2
	-- -- ADDED BY GOLDY 11/04/2019
	-- if tbl_nme_addr_point <>'' then
	-- BEGIN
		-- EXECUTE 'INSERT INTO qa.'||user_id||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 -- SELECT tab1."ID",tab1."NAME",'''||tbl_nme_poi||''',''PIP_ID'',tab1."PIP_ID"::text, ''PIP_Id must exist as ID IN Addr_Point (Building) Layer'',''2.47.106''
				 -- FROM '||sch_name||'."'|| UPPER(tbl_nme_poi) ||'" tab1 left join '||tbl_nme_addr_point||' tab2 on tab1."PIP_ID" = tab2."ID"
				 -- WHERE tab2."ID" IS NULL AND tab1."PIP_ID" <> 0  ';

		-- -- SELECT tab1."ID",tab1."PIP_ID",tab2."ID"
	    -- -- FROM upload."GJ_CE00075615_07062019_POI_EDT" tab1 LEFT join upload."GJ_CE00075615_07062019_POI_EDT" tab2 on tab1."PIP_ID" = tab2."ID"
	    -- -- WHERE tab2."ID" IS NULL AND tab1."PIP_ID" <> 0

		
		-- RAISE INFO '<-----------2.47.106.2';
		
	-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into qa.attriberror (message, context) values('''||f1||''','''||f2||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	-- END IF;
	
END IF;
--IGNORE ERRORS FROM EXCEPTION TABLE 
if(upper(user_type)= 'USER' or upper(user_type) = 'PACKING' or upper(user_type) = 'ADMIN') then 	
	BEGIN
		EXECUTE 'select count(table_name) from information_schema.tables where table_schema=''mmi_lock'' and table_name=''explog''' into count;

		IF count=1 THEN
			-- EXECUTE 'DELETE FROM qa.'||user_id||'_attobj a WHERE EXISTS (select * FROM mmi_lock.explog b WHERE a.unquid=b.un_id and coalesce(a.field_name,'''')=coalesce(b.field_name,'''') and coalesce(a.field_value,'''')=coalesce(b.field_value,'''') and coalesce(a.error_type,'''')=coalesce(b.error_type,'''') and coalesce(a.error_code,'''')=coalesce(b.error_code,'''') and coalesce(b.user_id,'''')='''||UPPER(user_id)||''')';
			EXECUTE 'DELETE FROM '||error_table||' a WHERE EXISTS (select * FROM mmi_lock.explog b WHERE a.unquid=b.un_id and coalesce(TRIM(a.field_name),'''')=coalesce(TRIM(b.field_name),'''') and coalesce(TRIM(a.field_value),'''')=coalesce(TRIM(b.field_value),'''') and coalesce(TRIM(a.error_type),'''')=coalesce(TRIM(b.error_type),'''') and coalesce(TRIM(a.error_code),'''')=coalesce(TRIM(b.error_code),'''') and TRIM(b.user_id)='''||UPPER(user_id)||''')';
		END IF;

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'IGNORE ERRORS FROM EXCEPTION TABLE';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END IF;
	
END;

$BODY$;








    
