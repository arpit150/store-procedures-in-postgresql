-- FUNCTION: upload.addr_admin_entry_obj(character varying, character varying, character varying, character varying, character varying, character varying, character varying)

-- DROP FUNCTION upload.addr_admin_entry_obj(character varying, character varying, character varying, character varying, character varying, character varying, character varying);

CREATE OR REPLACE FUNCTION upload.addr_admin_entry_obj(
	tbl_addr_admin_entrynonshift character varying,
	tbl_addr_admin_p character varying,
	tbl_admin_edge character varying,
	tbl_admin_entry character varying,
	sch_name character varying,
	user_id character varying,
	user_type character varying)
    RETURNS TABLE(poi_id integer, table_name character varying, field_name character varying, field_value character varying, error_type character varying, error_code character varying) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$

DECLARE tbl_nme_road CHARACTER VARYING(50);
DECLARE t timestamptz := clock_timestamp();

DECLARE
i integer;
j integer;
r record;
count integer;
tablename CHARACTER VARYING(50);
arr text []; 

DECLARE attrib_error character varying;
DECLARE error_table CHARACTER VARYING(50);
DECLARE SqlQuery text; 

DECLARE
conquery text;
conquery1 text;
f1 text; f2 text;
t1 text; t2 text;
stat_code text;
yyyy_mm varchar(254);

BEGIN   
	stat_code= UPPER(left(UPPER(tbl_admin_entry),2));
		RAISE WARNING 'STATE %',stat_code;
	yyyy_mm = to_char(now(),'yyyymmddhh24miss');
	RAISE WARNING 'yyyy_mm % AA :%',yyyy_mm,'';
-----------------------------------------------------------------error table----------------------------------------------------------------------------------------------------------
	
	error_table = 'qa.'||user_id||'_addr_admin_entrynonshift';
	attrib_error= 'qa.attriberror';
	raise info 'tab %',error_table;
	raise info 'tab %',attrib_error;
	
	EXECUTE 'DROP TABLE IF EXISTS '||error_table||''; 
	EXECUTE 'CREATE TABLE if not exists '||error_table||' (poi_id serial, table_name text, field_name text, 
	field_value text, error_type text,error_code text )';
	EXECUTE 'CREATE TABLE if not exists '||attrib_error||' (poi_id serial,user_id text,layer_nme text, message text,context text,db_edit_datetime timestamp without time zone DEFAULT now())';

----------------------------------------------------------------Road_Network--------------------------------------------------------------------------------------------
	BEGIN
		i=0;
		j=0;

		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____ROAD_NETWORK'' AND TABLE_SCHEMA ='''||sch_name||'''' into count;

		IF count > 1 THEN 
			-- tbl_nme_road=''|| UPPER(stat_code) ||'_ROAD_NETWORK';
			FOR r IN EXECUTE FORMAT('SELECT table_name FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____ROAD_NETWORK'' AND TABLE_SCHEMA ='''||sch_name||''' ') 
			LOOP
				  tablename = UPPER(r.table_name);
				  arr[i]=tablename;
				  -- RAISE WARNING 'Count % AA :%',arr[i],'';
				  i:=i+1;
			END LOOP;
			i=i-1;
			conquery=' SELECT * FROM '||sch_name||'."'||arr[0]||'" ';
			LOOP 
				EXIT WHEN i=0;
				conquery1='union all  SELECT * FROM '||sch_name||'."'||arr[i]||'" ';
				conquery = CONCAT(conquery,  conquery1);
				i=i-1;
				-- RAISE WARNING 'QUERY % QUERY %',conquery,'';
			END LOOP;
			
			EXECUTE'drop table if exists '|| UPPER(stat_code) ||'_ROAD_NETWORK';
			EXECUTE'create temp table '|| UPPER(stat_code) ||'_ROAD_NETWORK As ('|| conquery||')';
			tbl_nme_road=''|| UPPER(stat_code) ||'_ROAD_NETWORK';

		ELSE
			EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_ROAD_NETWORK'' AND TABLE_SCHEMA ='''||sch_name||'''' into count;
			
			IF count = 1 THEN
				tbl_nme_road = ''||sch_name||'."'||UPPER(stat_code)||'_ROAD_NETWORK"';
			ELSE
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_ROAD_NETWORK DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_ROAD_NETWORK Table Does not Exists in '||sch_name||' Schema'')';
				tbl_nme_road = '';
			END IF;
		END IF;
		RAISE INFO 'check for road network';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;	

------------------------------------------------------------------SP_GEOMTRY-----------------------------------------------------------------------------------------------------

--2.77.2
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,table_name,field_name,field_value,error_type,error_code) 
		SELECT t1."ID",'''||tbl_admin_entry||''',''SP_GEOMETRY'', t1."SP_GEOMETRY", ''Should be intersects from ADDR_Admin_Edge Line using .2 meter buffer with same id'',''2.77.2'' 
		FROM '||sch_name||'."'|| UPPER(tbl_admin_entry) ||'" t1 INNER JOIN '||sch_name||'."'|| UPPER(tbl_admin_edge) ||'" t2 ON t1."EDGE_ID" = t2."EDGE_ID"  
		WHERE (ST_INTERSECTS(ST_Buffer(t1."SP_GEOMETRY"::GEOGRAPHY, 0.2), t2."SP_GEOMETRY") = FALSE)';
         
		--SELECT t1."ID" ,t1."EDGE_ID" 
		-- FROM mmi_master."DL_ADDR_ADMIN_ENTRY" t1 INNER JOIN mmi_master."DL_ADDR_ADMIN_EDGE" t2 ON t1."EDGE_ID" = t2."EDGE_ID" 
		-- WHERE (ST_INTERSECTS(ST_Buffer(t1."SP_GEOMETRY"::GEOGRAPHY, 0.2), t2."SP_GEOMETRY") = FALSE)
		
		RAISE INFO '<-----------2.77.2';
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_admin_entry||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;


--2.77.3
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID",'''||tbl_admin_entry||''',''SP_GEOMETRY'',"SP_GEOMETRY", ''Not objects must not be present'',''2.77.3'' 
		FROM '||sch_name||'."'|| UPPER(tbl_admin_entry) ||'" WHERE COALESCE("SP_GEOMETRY"::TEXT, '''') = '''' ';
         
		--SELECT "ID", "SP_GEOMETRY" FROM mmi_master."DL_ADDR_ADMIN_ENTRY" WHERE COALESCE("SP_GEOMETRY"::TEXT, '') = ''
		
		RAISE INFO '<-----------2.77.3';
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_admin_entry||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

--2.77.4
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID",'''||tbl_admin_entry||''',''SP_GEOMETRY'',"SP_GEOMETRY", ''layer must have Point geometry, (Line and Polyline are not accepted), (Line and Polyline are not accepted)'',''2.77.4'' 
		FROM '||sch_name||'."'|| UPPER(tbl_admin_entry) ||'" WHERE ST_GeometryType("SP_GEOMETRY") NOT LIKE ''%ST_Point%'' ';
         
		--SELECT "ID", "SP_GEOMETRY" FROM mmi_master."DL_ADDR_ADMIN_ENTRY" WHERE ST_GeometryType("SP_GEOMETRY") NOT LIKE '%ST_Point%'
		
		RAISE INFO '<-----------2.77.4';
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_admin_entry||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

--2.77.5
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,table_name,field_name,field_value,error_type,error_code) 
		SELECT t1."ID",'''||tbl_admin_entry||''',''SP_GEOMETRY'', t1."SP_GEOMETRY", ''should be intersects with one road except few exception'',''2.77.5'' 
		FROM '||sch_name||'."'|| UPPER(tbl_admin_entry) ||'" t1 INNER JOIN '||tbl_nme_road||' t2 ON t1."EDGE_ID" = t2."EDGE_ID" 
		WHERE ST_INTERSECTS(t1."SP_GEOMETRY", t2."SP_GEOMETRY") = TRUE ';
         
		--SELECT t1."ID", t1."SP_GEOMETRY" FROM mmi_master."DL_ADDR_ADMIN_ENTRY" t1 INNER JOIN mmi_master."DL_ROAD_NETWORK" t2 ON t1."EDGE_ID" = t2."EDGE_ID" 
		--WHERE ST_INTERSECTS(t1."SP_GEOMETRY", t2."SP_GEOMETRY") = TRUE
		
		RAISE INFO '<-----------2.77.5';
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_admin_entry||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	

--2.77.12
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,table_name,field_name,field_value,error_type,error_code) 
		SELECT t1."ID",'''||tbl_admin_entry||''',''EDGE_ID'', t1."EDGE_ID", ''Must be match from Road table'',''2.77.12'' 
		FROM '||sch_name||'."'|| UPPER(tbl_admin_entry) ||'" t1 WHERE "EDGE_ID" NOT IN (SELECT "EDGE_ID" FROM '||tbl_nme_road||') ';
         
		--SELECT t1."ID", t1."EDGE_ID" FROM mmi_master."DL_ADDR_ADMIN_ENTRY" t1 WHERE "EDGE_ID" NOT IN (SELECT "EDGE_ID" FROM mmi_master."DL_ROAD_NETWORK")

		RAISE INFO '<-----------2.77.12';
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_admin_entry||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

	
--2.77.22
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,table_name,field_name,field_value,error_type,error_code) 
		SELECT t1."ID",'''||tbl_admin_entry||''',''SP_GEOMETRY'', t1."SP_GEOMETRY", ''ADDR_Admin_Entrynonshift point must not intersect with ADDR_ADMIN_P'',''2.77.22'' 
		FROM '||sch_name||'."'|| UPPER(tbl_admin_entry) ||'" t1 INNER JOIN '||sch_name||'."'|| UPPER(tbl_addr_admin_p) ||'" t2 ON t1."ID" = t2."ID" 
		WHERE ST_INTERSECTS(t1."SP_GEOMETRY", t2."SP_GEOMETRY") = TRUE ';
         
		--SELECT t1."ID", t1."SP_GEOMETRY" FROM mmi_master."DL_ADDR_ADMIN_ENTRY" t1 INNER JOIN mmi_master."DL_ADDR_ADMIN_P" t2 ON t1."ID" = t2."ID" 
		--WHERE ST_INTERSECTS(t1."SP_GEOMETRY", t2."SP_GEOMETRY") = TRUE
		
		RAISE INFO '<-----------2.77.22';
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_admin_entry||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	
	
END;

$BODY$;

ALTER FUNCTION upload.addr_admin_entry_obj(character varying, character varying, character varying, character varying, character varying, character varying, character varying)
    OWNER TO postgres;
