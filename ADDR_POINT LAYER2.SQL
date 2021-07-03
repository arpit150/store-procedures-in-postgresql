-- FUNCTION: qaupload.qc_addr_point_object(character varying, character varying, character varying, character varying, character varying, character varying, character varying, text)

-- DROP FUNCTION qaupload.qc_addr_point_object(character varying, character varying, character varying, character varying, character varying, character varying, character varying, text);

CREATE OR REPLACE FUNCTION qaupload.qc_addr_point_object(
	sch_name character varying,
	tbname_addr character varying,
	tbname_addr_edge character varying,
	tbname_entry_shift character varying,
	tbname_entrynon_shift character varying,
	user_id character varying,
	stat_code character varying,
	error_tab_name text DEFAULT 'obj'::text)
    RETURNS integer
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$

DECLARE 
f1 text; f2 text;
t1 text; t2 text;
DECLARE RETURNVAL integer;

DECLARE mst_sch text;
declare sqlQuery text;

DECLARE qaerrortablelogtabname text;
DECLARE qauploadlogtabname text;
DECLARE qauploadlogschema text;
DECLARE t timestamptz := clock_timestamp();

DECLARE qaerrorschema text;
DECLARE qaerrortabname text;
DECLARE functionerrortabname text;

DECLARE errortablecount integer;

DECLARE i integer;
DECLARE r record;
DECLARE tablename varchar(100);
DECLARE count integer;
DECLARE arr text []; 
DECLARE conquery text;
DECLARE j integer;
DECLARE conquery1 text;
DECLARE tbname_addr_road text;
DECLARE tbname_addr_p text;
DECLARE tbname_addr_point text;
DECLARE tbname_addr_r text;
DECLARE tbname_addr_loc text;
DECLARE tbname_addr_city text;
DECLARE tbname_addr_state text;
DECLARE tbl_name_brand_list text;
DECLARE tbl_name_state_abbr text;
DECLARE tbl_name_rail text;
DECLARE tbl_name_water text;
DECLARE tbl_name_poi_cat text;
DECLARE tbl_name_pincode text;
DECLARE tbl_name_junction text;
DECLARE tbl_name_other text;
DECLARE tbl_name_green text;
DECLARE tbname_addr_poi_addr_regn text;
declare master_tbl_poi character varying(50);
declare master_tbl_edgeline character varying(50);

BEGIN   
	
	mst_sch = 'mmi_master';
	
	qaerrorschema = 'qa';
	IF(error_tab_name='obj') THEN
		qaerrortabname = qaerrorschema||'.'||user_id||'_'||error_tab_name;
		qaerrortabname = lower(qaerrortabname);
	ELSE
		qaerrortabname = qaerrorschema||'.'||error_tab_name;
		qaerrortabname = lower(qaerrortabname);
	END IF;
	
	functionerrortabname = qaerrorschema||'.attribobjerror';

	qauploadlogschema = 'uploadlog';
	qaerrortablelogtabname = qauploadlogschema||'.qaerrortable';
	qauploadlogtabname = qauploadlogschema||'.qauploadlog';

	--DROP ERROR TABLE IF ALREADY EXIST
	EXECUTE FORMAT('DROP TABLE IF EXISTS %1$s',qaerrortabname);

	--CREATE ERROR TABLE 
	EXECUTE FORMAT('CREATE TABLE if not exists %1$s (id serial, addr_id integer,table_name text, field_name text,field_value text, error_type text,error_code text )',qaerrortabname);

	--CREATE FUNCTION EXCEPTION ERROR TABLE
	EXECUTE FORMAT('CREATE TABLE if not exists %1$s (id serial,user_id text,layer_nme text, message text,context text,db_edit_datetime timestamp without time zone DEFAULT now())',functionerrortabname);
----------------------------------------------------------------------------Road_Network--------------------------------------------------------------------------------------------
        BEGIN
		i=0;
		j=0;

		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____ROAD_NETWORK'' AND TABLE_SCHEMA ='''||mst_sch||'''' into count;

		IF count > 1 THEN 
			-- tbname_addr_road=''|| UPPER(stat_code) ||'_ROAD_NETWORK';
			FOR r IN EXECUTE FORMAT('SELECT table_name FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____ROAD_NETWORK'' AND TABLE_SCHEMA ='''||mst_sch||''' ') 
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
			
			EXECUTE'drop table if exists '|| UPPER(stat_code) ||'_ROAD_NETWORK';
			EXECUTE'create temp table '|| UPPER(stat_code) ||'_ROAD_NETWORK As ('|| conquery||')';
			tbname_addr_road=''|| UPPER(stat_code) ||'_ROAD_NETWORK';

		ELSE
			EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_ROAD_NETWORK'' AND TABLE_SCHEMA ='''||mst_sch||'''' into count;
			
			IF count = 1 THEN
				tbname_addr_road = ''||mst_sch||'."'||UPPER(stat_code)||'_ROAD_NETWORK"';
			ELSE
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_ROAD_NETWORK DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||functionerrortabname||'(message) values('''||UPPER(stat_code)||'_ROAD_NETWORK Table Does not Exists in '||mst_sch||' Schema'')';
				tbname_addr_road = '';
			END IF;
		END IF;
		RAISE INFO 'check for road network';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
------------------------------------------------------------------------------Checking for Addr_Admin_R-------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_ADDR_ADMIN_R'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbname_addr_r=''|| UPPER(stat_code) ||'_ADDR_ADMIN_R';
		ELSE
			tbname_addr_r = '';
			IF tbname_addr_r = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_ADDR_ADMIN_R DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||functionerrortabname||'(message) values('''||UPPER(stat_code)||'_ADDR_ADMIN_R Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'checking for Addr_Addin_R';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
------------------------------------------------------------------------------Checking for Addr_Admin_P-------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_ADDR_ADMIN_R'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbname_addr_p=''|| UPPER(stat_code) ||'_ADDR_ADMIN_P';
		ELSE
			tbname_addr_p = '';
			IF tbname_addr_p = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_ADDR_ADMIN_P DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||functionerrortabname||'(message) values('''||UPPER(stat_code)||'_ADDR_ADMIN_P Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'Cheking for Addr_Admin_P';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
----------------------------------------------------------------------------Checking for Locality Boundary----------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_LOC_BOUNDARY'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbname_addr_loc=''|| UPPER(stat_code) ||'_LOC_BOUNDARY';
-- RAISE WARNING 'LOC_BOUNDARY % AA :%',tbname_addr_loc,'';
		ELSE
			tbname_addr_loc = '';
			IF tbname_addr_loc = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_LOC_BOUNDARY DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||functionerrortabname||'(message) values('''||UPPER(stat_code)||'_LOC_BOUNDARY Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'Checking for locality Boundary';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
------------------------------------------------------------------------------Checking for State Boundary-----------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_STATE_BOUNDARY'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbname_addr_state=''|| UPPER(stat_code) ||'_STATE_BOUNDARY';
		ELSE
			tbname_addr_state = '';
			IF tbname_addr_state = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_STATE_BOUNDARY DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||functionerrortabname||'(message) values('''||UPPER(stat_code)||'_STATE_BOUNDARY Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'Checking for State Boundary';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
------------------------------------------------------------------------------Checking for City Boundary------------------------------------------------------------------------------------
	
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_CITY_BOUNDARY'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbname_addr_city=''|| UPPER(stat_code) ||'_CITY_BOUNDARY';
		ELSE
			tbname_addr_city = '';
			IF tbname_addr_city = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_CITY_BOUNDARY DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||functionerrortabname||'(message) values('''||UPPER(stat_code)||'_CITY_BOUNDARY Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'Checking for CITY Boundary';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;	
	--PROCESS START FOR ATTRIBUTE VALIDATION
------------------------------------------------------------------ID----------------------------------------------------------------------	
--2.62.13
if tbname_entry_shift <>'' then
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID",'''||tbname_addr||''',''ID'',"ID"::text, ''All Ids should be avaialable in ADDR_Entry layer'',''2.62.13''
				 FROM '||sch_name||'."'|| UPPER(tbname_addr) ||'" 
				 where "ID" NOT IN (SELECT "ID" FROM '||mst_sch||'."'|| UPPER(tbname_entry_shift) ||'" ) ';

		 -- SELECT "ID","ID"::text, 'All Ids should be avaialable in ADDR_Entry layer','2.62.13' 
		 -- FROM mmi_master."DL_P1_ADDR_POINT"
		 -- WHERE "ID" NOT IN (SELECT "ID" FROM mmi_master."DL_ADDR_ENTRY")
			
		
		RAISE INFO '<----------2.62.13';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	end if;	
	
--2.62.14
if tbname_addr_edge <>'' then
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID",'''||tbname_addr||''',''ID'',"ID"::text, ''All Ids should be avaialable in ADDR_Edge layer'',''2.62.14''
				 FROM '||sch_name||'."'|| UPPER(tbname_addr) ||'" 
				 where "ID" NOT IN (SELECT "ID" FROM '||mst_sch||'."'|| UPPER(tbname_addr_edge) ||'" ) ';

		 -- SELECT "ID","ID"::text, 'All Ids should be avaialable in ADDR_Edge layer','2.62.14' 
		 -- FROM mmi_master."DL_P1_ADDR_POINT"
		 -- WHERE "ID" NOT IN (SELECT "ID" FROM mmi_master."DL_ADDR_EDGE")
			
		
		RAISE INFO '<----------2.62.14';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	end if;		
	
--2.62.15
if tbname_entrynon_shift <>'' then
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID",'''||tbname_addr||''',''ID'',"ID"::text, ''All Ids should be avaialable in ADDR_EntryNonShift  layer'',''2.62.15''
				 FROM '||sch_name||'."'|| UPPER(tbname_addr) ||'" 
				 where "ID" NOT IN (SELECT "ID" FROM '||mst_sch||'."'|| UPPER(tbname_entrynon_shift) ||'" ) ';

		 -- SELECT "ID","ID"::text, 'All Ids should be avaialable in ADDR_EntryNonShift  layer','2.62.15' 
		 -- FROM mmi_master."DL_P1_ADDR_POINT"
		 -- WHERE "ID" NOT IN (SELECT "ID" FROM mmi_master."DL_ADDR_EDGE")
			
		
		RAISE INFO '<----------2.62.15';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	End if;			

--2.62.21
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID",'''||tbname_addr||''',''NAME'',"NAME"::text, ''Name should be in Proper case'',''2.62.21''
				 FROM '||sch_name||'."'|| UPPER(tbname_addr) ||'"
				 WHERE COALESCE("NAME",'''') <> '''' AND "NAME" <> INITCAP("NAME") AND "NAME" <>UPPER("NAME") AND "NAME" NOT IN (SELECT "NAME" FROM '||mst_sch||'."NAMEEXCP_LIST" WHERE "TYPE"=''BLD'' OR "TYPE" = ''POI'')	';

		 -- SELECT tab1."ADMIN_ID" , tab1."NAME" , tab2."ID" , tab2."LOC_NME",tab2."SUBL_NME"::text, 'Name should be in Proper case','2.62.21' 
		 -- FROM mmi_master."DL_P1_ADDR_POINT"
		 -- WHERE COALESCE("NAME",'') <> '' AND "NAME" <> INITCAP("NAME") AND "NAME" <>UPPER("NAME")
		 --  AND "NAME" NOT IN (SELECT "NAME" FROM mmi_master."NAMEEXCP_LIST" WHERE "TYPE"='BLD' OR "TYPE" = 'POI')
			
		-- SELECT "ID","NAME" FROM mmi_master."DL_P1_ADDR_POINT" WHERE COALESCE("NAME",'') <> '' AND "NAME" <> INITCAP("NAME") AND "NAME" <>UPPER("NAME")
		-- AND "NAME" NOT IN (SELECT "NAME" FROM mmi_master."NAMEEXCP_LIST" WHERE "TYPE"='BLD' OR "TYPE" = 'POI')
			
			
		
		RAISE INFO '<----------2.62.21';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--------------------------------------------------------------------FTR_CRY-----------------------------------------------------------------------
--2.62.160
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID",'''||tbname_addr||''',''FTR_CRY'',"FTR_CRY"::text, ''Must be match with MSTR_CODE in POI_CAT layer'',''2.62.160''
				 FROM '||sch_name||'."'|| UPPER(tbname_addr) ||'"
				 WHERE "FTR_CRY" NOT IN (SELECT "MSTR_CODE" FROM '||mst_sch||'."POI_CAT")	';

		 -- SELECT "ID","FTR_CRY"::text, 'Must be match with MSTR_CODE in POI_CAT layer','2.62.160' 
		 -- FROM mmi_master."DL_P1_ADDR_POINT"
		 -- WHERE "FTR_CRY" NOT IN (SELECT "MSTR_CODE" FROM mmi_master."POI_CAT")
			
	
		
		RAISE INFO '<----------2.62.160';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.164
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID",'''||tbname_addr||''',''FTR_CRY'',"FTR_CRY"::text, ''Must be match with MSTR_CODE in POI_CAT layer'',''2.62.164''
				 FROM '||sch_name||'."'|| UPPER(tbname_addr) ||'"
				 WHERE (COALESCE("FTR_CRY",'''') ||''_''|| COALESCE("SUB_CRY",'''')) NOT IN (SELECT (COALESCE("MSTR_CODE",'''') ||''_''|| COALESCE("MTR_SUBCOD",'''')) FROM '||mst_sch||'."POI_CAT" )	';

		 -- SELECT "ID","FTR_CRY"::text, 'Must be match with MSTR_CODE in POI_CAT layer','2.62.164' 
		 -- FROM mmi_master."DL_P1_ADDR_POINT"
		 -- WHERE (COALESCE("FTR_CRY",'') ||'_'|| COALESCE("SUB_CRY",'')) NOT IN (SELECT (COALESCE("MSTR_CODE",'') ||'_'|| COALESCE("MTR_SUBCOD",'')) FROM mmi_master."POI_CAT" )
			
			-- SELECT "ID",(COALESCE("FTR_CRY",'') ||'_'|| COALESCE("SUB_CRY",'')) FROM mmi_master."DL_P1_ADDR_POINT" WHERE (COALESCE("FTR_CRY",'') ||'_'|| COALESCE("SUB_CRY",''))
			-- NOT IN (SELECT (COALESCE("MSTR_CODE",'') ||'_'|| COALESCE("MTR_SUBCOD",'')) FROM mmi_master."POI_CAT" )

		
		RAISE INFO '<----------2.62.164';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
------------------------------------------------------------------------SUB_CRY----------------------------------------------------------
--2.62.165
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID",'''||tbname_addr||''',''SUB_CRY'',"SUB_CRY"::text, ''Must be match with MTR_SUBCOD in POI_CAT layer'',''2.62.165''
				 FROM '||sch_name||'."'|| UPPER(tbname_addr) ||'"
				 WHERE "SUB_CRY" NOT IN (SELECT "MTR_SUBCOD" FROM '||mst_sch||'."POI_CAT")	';

		 -- SELECT "ID","SUB_CRY"::text, 'Must be match with MTR_SUBCOD in POI_CAT layer','2.62.165' 
		 -- FROM mmi_master."DL_P1_ADDR_POINT"
		 -- WHERE "SUB_CRY" NOT IN (SELECT "MTR_SUBCOD" FROM mmi_master."POI_CAT")
			
	
		
		RAISE INFO '<----------2.62.165';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

	
----------------------------------------------------------------------------EDGE_SIDE--------------------------------------------------------------
--2.62.49
if tbname_addr_edge<>'' then
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT tab1."ID",'''||tbname_addr||''',''EDGE_SIDE'',tab1."EDGE_SIDE"::text, ''must match with ADDR_Edge side w.r.t ID'',''2.62.49''
				 FROM '||sch_name||'."'|| UPPER(tbname_addr) ||'" tab1,'||mst_sch||'."'|| UPPER(tbname_addr_edge) ||'" tab2
				 WHERE tab1."ID"=tab2."ID" AND tab1."EDGE_SIDE"<> tab2."SIDE"	';

		 -- SELECT  tab1."ID", tab1."EDGE_SIDE"::text, 'must match with ADDR_Edge side w.r.t ID','2.62.49' 
		 -- FROM mmi_master."DL_P1_ADDR_POINT" tab1,mmi_master."DL_ADDR_EDGE" tab2
		 -- WHERE tab1."ID"=tab2."ID" AND tab1."EDGE_SIDE"<> tab2."SIDE"
			
	-- select tab1."ID",tab1."EDGE_SIDE",tab2."ID",tab2."SIDE" FROM mmi_master."DL_P1_ADDR_POINT" tab1,mmi_master."DL_ADDR_EDGE" tab2
	-- WHERE tab1."ID"=tab2."ID" AND tab1."EDGE_SIDE"<> tab2."SIDE"
		
		RAISE INFO '<----------2.62.49';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
end if;

--2.62.53
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT tab1."ID",'''||tbname_addr||''',''EDGE_ID'',tab1."EDGE_ID", ''EDGE_ID MUST MATCH WITH EDGE TABLE EDGE_ID'',''2.62.53''
				 FROM '||sch_name||'."'|| UPPER(tbname_addr) ||'" as tab1,'||sch_name||'."'|| UPPER(tbname_addr_edge) ||'" as tab2
				 where tab1."ID"= tab2."ID" AND tab1."EDGE_ID"<> tab2."EDGE_ID" ';

		 -- SELECT tab1."ID",tab1."EDGE_ID" FROM mmi_master."DL_P1_ADDR_POINT" AS tab1,mmi_master."DL_ADDR_EDGE" AS tab2
		--  where tab1."ID"= tab2."ID" AND tab1."EDGE_ID"<> tab2."EDGE_ID"
		
		RAISE INFO '<----------2.62.53';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

------------------------------------checks from poi object--------------------------------------------------------------------------------
-- 1.1.32
-- No error code
-- 31 msec
	BEGIN
		EXECUTE'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		( SELECT t3.id,'''||tbname_addr||''',''Geometry'',t3.geom,''Geometry of Poi should be point'',''1.1.23'' 
		FROM (SELECT t1."ID" id, t1.ST_GeometryType geom FROM (SELECT "ID", ST_GeometryType(t."SP_GEOMETRY") 
		FROM '||sch_name||'."'||tbname_addr||'" As t ) As t1 WHERE t1.ST_GeometryType NOT LIKE ''%ST_Point%'') As t3)';
		
	    --------SELECT t3.id,'GA_POI','Geometry',t3.geom,'Geometry of Poi should be point','1.1.23' FROM (SELECT t1."ID" id, t1.ST_GeometryType geom FROM (SELECT "ID", ST_GeometryType(t."SP_GEOMETRY") 
		--------FROM mmi_v180."GA_POI" As t ) As t1 WHERE t1.ST_GeometryType NOT LIKE '%ST_Point%') As t3
		
		RAISE INFO '<----------1.1.32';
		
		EXCEPTION 
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||attrib_error||'(message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 31.1:%',f1;
		RAISE info 'error caught 31.2:%',f2;
	END;
	RAISE INFO 'Geometry of Poi should be point';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

--------------------------------------------------------------------------------------Edgeline----------------------------------------------------------------------------------------------
IF tbname_addr_edge <> '' THEN
--EDGELINE->GEOMETRY
--1.1.33
--No error code
-- 4.3 sec
	BEGIN
	EXECUTE'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		( SELECT t3.id,'''||tbname_addr_edge||''',''Geometry'',t3.geom As GEOM_TYPE,''Geometry of edgeline should be line or polyline'',''1.1.33''
		FROM (SELECT t1."ID" id, t1.ST_GeometryType geom FROM (SELECT "ID", ST_GeometryType(t."SP_GEOMETRY") 
		FROM '||sch_name||'."'||UPPER(tbname_addr_edge)||'"  As t ) As t1 
		WHERE t1.ST_GeometryType NOT LIKE ''%ST_LineString%'') As t3)';
		
		-----SELECT t3.id,'GA_POI','Geometry',t3.geom As GEOM_TYPE,'Geometry of edgeline should be line or polyline','NO ERROR CODE'
		-----FROM (SELECT t1."ID" id, t1.ST_GeometryType geom FROM (SELECT "ID", ST_GeometryType(t."SP_GEOMETRY") 
		-----FROM mmi_v180."GA_POI"  As t ) As t1 
		-----WHERE t1.ST_GeometryType NOT LIKE '%ST_LineString%') As t3
	
		RAISE INFO '<----------1.1.33';
		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
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
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT a."ID",'''||tbname_addr_edge||''',''EXCP'',a."EXCP"::text,''If Poi Edgeline greater than or equal to one kilometer, then maintain ’1KY’ in EXCP'',''1.1.57'' 
		FROM '||sch_name||'."'||UPPER(tbname_addr_edge)||'" As a WHERE ST_Length(a."SP_GEOMETRY"::GEOGRAPHY)>=1000 AND COALESCE(a."EXCP",'''') NOT LIKE ''%1KY%'' ';	
		
       ----- SELECT a."ID",'GA_POI','EXCP',a."EXCP"::text,'If Poi Edgeline greater than or equal to one kilometer, then maintain ’1KY’ in EXCP','1.1.57' 
	   ----- FROM mmi_v180."GA_POI" As a WHERE ST_Length(a."SP_GEOMETRY"::GEOGRAPHY)>=1000 AND COALESCE(a."EXCP",'') NOT LIKE '%1KY%'
	   
		RAISE INFO '<----------1.1.57';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE INFO 'If Poi Edgeline greater than or equal to one kilometer, then maintain ’1KY’ in EXCPt';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
------------------------------------------------------------------------------------Poi-Edgeline--------------------------------------------------------------------------------------------
IF tbname_addr_edge <> '' AND tbname_addr <> '' THEN 
--POI,EDGELINE->ID
--1.1.23
--1.37.3
-- 47 msec
	BEGIN
	EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		( SELECT t."ID",'''||tbname_addr||''',''ID'',t."ID"::text,''Poi and its edgeline id does not match'',''1.1.23''
		FROM ( SELECT "ID" FROM '||sch_name||'."'||tbname_addr||'" EXCEPT SELECT "ID" FROM '||sch_name||'."'||UPPER(tbname_addr_edge)||'" ) As t, '||sch_name||'."'||tbname_addr||'" As t1  
		WHERE t."ID" = t1."ID")';	
		
       ----- SELECT t."ID",'GA_POI','ID',t."ID"::text,'Poi and its edgeline id does not match','1.1.23'
	   ----- FROM ( SELECT "ID" FROM mmi_v180."GA_POI" EXCEPT SELECT "ID" FROM mmi_v180."GA_POI_EDGELINE" ) As t, mmi_v180."GA_POI" As t1  
	   ----- WHERE t."ID" = t1."ID"			
		
		RAISE INFO '<----------1.1.23';
		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
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
	EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		( SELECT t."ID",'''||tbname_addr||''',''EDGE_ID'',t."EDGE_ID"::text,''Poi and its edgeline edge_id does not match'',''1.1.23''            
		FROM '||sch_name||'."'||tbname_addr||'" As t JOIN  '||sch_name||'."'||UPPER(tbname_addr_edge)||'" As t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" AND 
	    t."EDGE_ID" <> t1."EDGE_ID" )';
		
		---- SELECT t."ID",'GA_POI','EDGE_ID',t."EDGE_ID"::text,'Poi and its edgeline edge_id does not match','1.1.23'            
		---- FROM mmi_v180."GA_POI" As t JOIN mmi_v180."GA_POI_EDGELINE" As t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" AND 
	    ---- t."EDGE_ID" <> t1."EDGE_ID"
		
		RAISE INFO '<----------1.1.23';
		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
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
	EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		( SELECT t3.id,'''||tbname_addr||''',''Intersection'',''OBJECT'',''Poi does not intersects with edgeline or Edgeline wrong digrection digitize'',''1.1.34'' FROM (SELECT t2."ID" As ID, 
		t2.ST_Intersects As geom FROM (SELECT t."ID", ST_Intersects(t."SP_GEOMETRY", ST_StartPoint(t1."SP_GEOMETRY")) FROM '||sch_name||'."'||tbname_addr||'" As t 
		INNER JOIN '||sch_name||'."'||UPPER(tbname_addr_edge)||'" As t1 ON t."ID" = t1."ID" ) t2 WHERE ST_Intersects=''f'') As t3)';
		
        /*
		  SELECT t3.id,'GA_POI','Intersection',t3.geom,'Poi does not intersects with edgeline','1.1.34' FROM (SELECT t2."ID" As ID, 
		t2.ST_Intersects As geom FROM (SELECT t."ID", ST_Intersects(t."SP_GEOMETRY", ST_StartPoint(t1."SP_GEOMETRY")) FROM mmi_v180."GA_POI" As t 
		INNER JOIN mmi_v180."GA_POI_EDGELINE" As t1 ON t."ID" = t1."ID" ) t2 WHERE ST_Intersects='f') As t3
		
		*/		
		RAISE INFO '<----------1.1.34';
		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
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
	EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		( SELECT t2."ID",'''||tbname_addr||''',''EDGE_SIDE'',t2."EDGE_SIDE"::text,''Poi and its edgeline side does not match'',''1.1.29'' 
		FROM (SELECT t."ID", t."EDGE_SIDE" FROM '||sch_name||'."'||tbname_addr||'" As t JOIN '||sch_name||'."'||UPPER(tbname_addr_edge)||'"
		AS t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" AND t."EDGE_ID"=t1."EDGE_ID" AND t."EDGE_SIDE"<>t1."SIDE" ) As t2)';
		
       /*
	     SELECT t2."ID",'GA_POI','EDGE_SIDE',t2."EDGE_SIDE"::text,'Poi and its edgeline side does not match','1.1.29' 
		FROM (SELECT t."ID", t."EDGE_SIDE" FROM mmi_v180."GA_POI" As t JOIN mmi_v180."GA_POI_EDGELINE"
		AS t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" AND t."EDGE_ID"=t1."EDGE_ID" AND t."EDGE_SIDE"<>t1."SIDE" ) As t2
	   */		
		RAISE INFO '<----------1.1.29';
		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 6.1:%',f1;
		RAISE info 'error caught 6.2:%',f2;
	END;
	RAISE INFO 'Poi and its edgeline side does not match';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

-------POI, Edgeline should not have more than 2 nodes
----1.1.66
---- 32 msec
    BEGIN
	EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		  SELECT t1."ID", '''||tbname_addr||''',''Polyline'',''OBJECT'',''Edgeline should not have more then 2 nodes'',''1.1.66''
	     FROM '||sch_name||'."'||tbname_addr_edge||'" AS t1 where ST_npoints("SP_GEOMETRY")>2 ';

	   /*
	    SELECT t1."ID", 'GA_POI','EXCP','Edgeline should not have more then 2 nodes
       ','1.1.66' FROM mmi_v180."GA_POI_EDGELINE" AS t1 where ST_npoints("SP_GEOMETRY")>2	
      */
	  
	  RAISE INFO '<----------1.1.66';
	  
	  EXCEPTION
	       WHEN OTHERS THEN
		   GET STACKED DIAGNOSTICS
		   f1=MESSAGE_TEXT,
		   f2=PG_EXCEPTION_CONTEXT;
		   
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 11.1:%',f1;
		RAISE info 'error caught 11.2:%',f2;
	END;
	RAISE INFO 'Edgeline should not have more then 2 nodes';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
-------POI, Poi not intersect with edge_line END point
----1.1.63, ABHINAV
---- 32 msec
    BEGIN
	EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		  select t1."ID", '''||tbname_addr||''',''EXCP'',''t1."EDGE_ID"'',''Addr not intersect with edge_line END point'',''1.1.63'' from '||sch_name||'."'||tbname_addr||'" t1, '||sch_name||'."'||tbname_addr_edge||'" AS t2 
       where t1."EDGE_ID" = t2."EDGE_ID" and ST_Intersects(t1."SP_GEOMETRY",ST_Endpoint(t2."SP_GEOMETRY")) = TRUE ';

	    /*
	    select t1."ID", 'GA_POI','EXCP','Poi not intersect with edge_line END point
        ','1.1.63' from mmi_v180."GA_POI" t1,mmi_v180."GA_POI_EDGELINE" AS t2 
         where t1."EDGE_ID" = t2."EDGE_ID" and ST_Intersects(t1."SP_GEOMETRY",ST_Endpoint(t2."SP_GEOMETRY")) = TRUE  
        */
	  
	 RAISE INFO '<----------1.1.63';
	  
	  EXCEPTION
	       WHEN OTHERS THEN
		   GET STACKED DIAGNOSTICS
		   f1=MESSAGE_TEXT,
		   f2=PG_EXCEPTION_CONTEXT;
		   
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 11.1:%',f1;
		RAISE info 'error caught 11.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	

	
END IF;
------------------------------------------------------------------------------------Poi and Non_Entryshift----------------------------------------------------------------------------------
IF tbname_addr <> '' AND tbname_entrynon_shift <> '' THEN
--POI,ENTRYNONSHIFT->EDGE_ID
--1.1.25
--1.37.2
--32 sec
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		( SELECT t1."ID",'''||tbname_addr||''',''EDGE_ID'',t."EDGE_ID"::text,''Addr and its non-shift entry edge_id does not match'',''1.1.25''            
		FROM '||sch_name||'."'||tbname_addr||'" As t JOIN '||sch_name||'."'|| UPPER(tbname_entrynon_shift) ||'" As t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" 		
		AND t."EDGE_ID" <> t1."EDGE_ID" )';
		
		/*
        SELECT t1."ID",'GA_POI','EDGE_ID',t."EDGE_ID"::text,'Poi and its non-shift entry edge_id does not match','1.1.25'            
		FROM mmi_v180."GA_POI" As t JOIN mmi_v180."GA_POI_ENTRYNONSHIFT" As t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" 		
		AND t."EDGE_ID" <> t1."EDGE_ID"  		
 		*/
		
		
		RAISE INFO '<----------1.1.25';
		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 11.1:%',f1;
		RAISE info 'error caught 11.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,ENTRYNONSHIFT->ID
--1.1.39
--No Error Code
-- 31 msec
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		( SELECT t."ID",'''||tbname_addr||''',''ID'',t."ID"::text,''Addr and its non-shift entry id does not match'',''1.1.39''
		FROM ( SELECT "ID" FROM '||sch_name||'."'||tbname_addr||'" EXCEPT SELECT "ID" FROM '||sch_name||'."'|| UPPER(tbname_entrynon_shift) ||'" ) As t,
		 '||sch_name||'."'||tbname_addr||'" As t1 WHERE t."ID" = t1."ID" )';
		 
		 /*
		  
         SELECT t."ID",'GA_POI','ID',t."ID"::text,'Poi and its non-shift entry id does not match','1.1.39'
		FROM ( SELECT "ID" FROM mmi_v180."GA_POI" EXCEPT SELECT "ID" FROM mmi_v180."GA_POI_ENTRYNONSHIFT" ) As t,
		 mmi_v180."GA_POI" As t1 WHERE t."ID" = t1."ID"
		 */
		RAISE INFO '<----------1.1.39';
		 
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 12.1:%',f1;
		RAISE info 'error caught 12.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
--------------------------------------------------------------------------------------Poi and Entryshift------------------------------------------------------------------------------------
IF tbname_addr <> '' AND tbname_entry_shift <> '' THEN
--POI,ENTRYSHIFT->EDGE_ID
--1.1.24
--1.37.2
--31 msec
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		( SELECT t1."ID",'''||tbname_addr||''',''EDGE_ID'',t."EDGE_ID"::text,''Addr and its shift entry edge_id does not match'',''1.1.24''            
		FROM '||sch_name||'."'||tbname_addr||'" As t JOIN '||sch_name||'."'|| UPPER(tbname_entry_shift) ||'" As t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" 
		AND t."EDGE_ID" <> t1."EDGE_ID" )';
		
		/*
		  SELECT t1."ID",'GA_POI','EDGE_ID',t."EDGE_ID"::text,'Poi and its shift entry edge_id does not match','1.1.24'            
		FROM mmi_v180."GA_POI" As t JOIN mmi_v180."GA_POI_ENTRYSHIFT" As t1 ON t."EDGE_ID"<>0 AND t."ID"=t1."ID" 
		AND t."EDGE_ID" <> t1."EDGE_ID"	
		*/
		
		RAISE INFO '<----------1.1.24';
		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 8.1:%',f1;
		RAISE info 'error caught 8.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,ENTRYSHIFT->ID
--1.1.63
--32 msec
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		( SELECT t."ID",'''||tbname_addr||''',''ID'',t."ID"::text,''Addr and its shift entry id does not match'',''1.1.38''
		FROM ( SELECT "ID" FROM '||sch_name||'."'||tbname_addr||'" EXCEPT SELECT "ID" FROM '||sch_name||'."'|| UPPER(tbname_entry_shift) ||'" ) As t, '||sch_name||'."'||tbname_addr||'" As t1 
		WHERE t."ID" = t1."ID")';
		
		/*
		  SELECT t."ID",'GA_POI','ID',t."ID"::text,'Poi and its shift entry id does not match','1.1.38'
		FROM ( SELECT "ID" FROM mmi_v180."GA_POI" EXCEPT SELECT "ID" FROM mmi_v180."GA_POI_ENTRYSHIFT" ) As t, mmi_v180."GA_POI" As t1 
		WHERE t."ID" = t1."ID"
		*/
		
		RAISE INFO '<----------1.1.63';
		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 9.1:%',f1;
		RAISE info 'error caught 9.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

----POI,ID mismatch in Shift and Non-Shift Entry
----1.1.72
---47 msec
    BEGIN
        EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				SELECT t1."ID",'''||tbname_addr||''',''ID'',t1."ID"::text,''ID mismatch in Shift and Non-Shift Entry'',''1.1.72'' FROM 
                ( SELECT "ID" FROM '||sch_name||'."'||tbname_entry_shift||'" EXCEPT (SELECT "ID" FROM '||sch_name||'."'||tbname_entrynon_shift||'" )) As t, '||sch_name||'."'||tbname_addr||'" As t1 
		         WHERE t."ID" <> t1."ID"';		 
				 /*
				  SELECT t1."ID",'GA_POI','ID',t1."ID"::text,'ID mismatch in Shift and Non-Shift Entry','1.1.72' FROM 
                  ( SELECT "ID" FROM mmi_v180."GA_POI_ENTRYNONSHIFT" EXCEPT (SELECT "ID" FROM mmi_v180."GA_POI_ENTRYNONSHIFT" )) As t, mmi_v180."GA_POI" As t1 
		           WHERE t."ID" <> t1."ID"
				 */
				 
		RAISE INFO '<----------1.1.72';
		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 9.1:%',f1;
		RAISE info 'error caught 9.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;		 
	
END IF;
-----------------------------------------------------------------------------------EdgeLine AND ENTRYNONSHIFT-------------------------------------------------------------------------------
IF tbname_entrynon_shift <> '' AND tbname_addr_edge <> '' THEN
--ENTRYNONSHIFT,EDGELINE->INTERSECTION
--1.1.36
-- No error code
---797 msec
 	BEGIN 
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		( SELECT t3.id,'''||tbname_entrynon_shift||''',''Intersection'',''OBJECT'',''Non-shift entry point should be intersects with end node of Edgeline'',''1.1.36'' 
		FROM (SELECT t2."ID" As ID, t2.ST_Intersects As geom FROM (SELECT t."ID", ST_Intersects(t."SP_GEOMETRY", ST_EndPoint(t1."SP_GEOMETRY")) FROM '||sch_name||'."'|| UPPER(tbname_entrynon_shift) ||'" As t 
		INNER JOIN '||sch_name||'."'||UPPER(tbname_addr_edge)||'" As t1 ON t."ID" = t1."ID") t2 WHERE ST_Intersects=''f'') As t3)';
		
        /*
         SELECT t3.id,'GA_POI','Intersection',t3.geom,'Non-shift entry point should be intersects with end node of Edgeline','1.1.36' 
		FROM (SELECT t2."ID" As ID, t2.ST_Intersects As geom FROM (SELECT t."ID", ST_Intersects(t."SP_GEOMETRY", ST_EndPoint(t1."SP_GEOMETRY")) FROM mmi_v180."GA_POI_ENTRYNONSHIFT" As t 
		INNER JOIN mmi_v180."GA_POI_EDGELINE" As t1 ON t."ID" = t1."ID") t2 WHERE ST_Intersects='f') As t3 
		*/		
		RAISE INFO '<----------1.1.36';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 38.1:%',f1;
		RAISE info 'error caught 38.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
------------------------------------------------------------------------------------EdgeLine AND ENTRYSHIFT---------------------------------------------------------------------------------
IF tbname_entry_shift <> '' AND tbname_addr_edge <> '' THEN
--ENTRYSHIFT,EDGELINE->LOCATION ENTRYSHIFT POINT
--1.1.35
--No error code
-- 7.2 sec
	BEGIN 
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT t."ID",'''||tbname_entry_shift||''',''ID'',t."ID"::text,''Shift entry point should be near end node of Edgeline between 0.4m and 0.6m range'',''1.1.35'' 
		FROM (SELECT a."ID",ST_Intersects(ST_Buffer(b."SP_GEOMETRY",0.000001),a."SP_GEOMETRY"), ST_Distance(a."SP_GEOMETRY", ST_EndPoint(b."SP_GEOMETRY"),true) 
		FROM '||sch_name||'."'|| UPPER(tbname_entry_shift) ||'" a, '||sch_name||'."'||UPPER(tbname_addr_edge)||'" b WHERE a."ID"=b."ID") As t WHERE t.ST_Distance NOT BETWEEN 0.4 AND 0.6 AND ST_Intersects=''f'' ';
		
		/*
		--SELECT t."ID",'GA_POI','ID',t."ID"::text,'Shift entry point should be near end node of Edgeline between 0.4m and 0.6m range','1.1.35' 
		--FROM (SELECT a."ID",ST_Intersects(ST_Buffer(b."SP_GEOMETRY",0.000001),a."SP_GEOMETRY"), ST_Distance(a."SP_GEOMETRY", ST_EndPoint(b."SP_GEOMETRY"),true) 
		--FROM mmi_v180."GA_POI_ENTRYSHIFT" a, mmi_v180."GA_POI_EDGELINE" b WHERE a."ID"=b."ID") As t WHERE t.ST_Distance NOT BETWEEN 0.4 AND 0.6 AND ST_                 ='f'
		*/
		RAISE INFO '<----------1.1.35';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 39.1:%',f1;
		RAISE info 'error caught 39.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;

IF tbname_addr <> '' AND tbl_name_poi_cat <> '' THEN
--POI,POI_CAT->SUB_CRY1
--1.1.1
--1.5.1
--16 msec
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT t1."ID",'''||tbname_addr||''',''SUB_CRY'',t1."SUB_CRY"::text,''Addr Sub_Cry does not match with Mtr_Subcod in Poi Cat'',''1.1.1''
		FROM ( (SELECT "SUB_CRY" FROM '||sch_name||'."'||tbname_addr||'" WHERE (COALESCE("SUB_CRY",'''')<> '''') ) EXCEPT
		(SELECT "MTR_SUBCOD" FROM '|| mst_sch ||'."'||tbl_name_poi_cat||'" WHERE (COALESCE("MTR_SUBCOD",'''')<> '''') ) ) As t, '||sch_name||'."'||tbname_addr||'" As t1 WHERE 
		t."SUB_CRY"=t1."SUB_CRY" ';
		
		--SELECT t1."ID",'GA_POI','SUB_CRY',t1."SUB_CRY"::text,'Poi’s Sub_Cry does not match with Mtr_Subcod in Poi Cat','1.5.1'
		--FROM ( (SELECT "SUB_CRY" FROM mmi_v180."GA_POI" WHERE (COALESCE("SUB_CRY",'')<> '') ) EXCEPT
		--(SELECT "MTR_SUBCOD" FROM mmi_v180."POI_CAT" WHERE (COALESCE("MTR_SUBCOD",'')<> '') ) ) As t, mmi_v180."GA_POI" As t1 WHERE 
		--t."SUB_CRY"=t1."SUB_CRY"
		
		RAISE INFO '<----------1.1.1';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 18.1:%',f1;
		RAISE info 'error caught 18.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
--POI,POI_CAT->FTR_CRY,SUB_CRY COMBINATION
--1.1.91
--16 msec
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbname_addr||''',''FTR_CRY_SUB_CRY'',ftrcrycom::text,''FTR_CRY and SUB_CRY Combination Not Match With POI_CAT'',''1.1.91''
		FROM (SELECT "ID",(COALESCE("FTR_CRY",'''') ||''_''|| COALESCE("SUB_CRY",'''')) as ftrcrycom 
		FROM '||sch_name||'."'||tbname_addr||'" WHERE (COALESCE("FTR_CRY",'''') ||''_''|| COALESCE("SUB_CRY",''''))
		NOT IN (SELECT (COALESCE("MSTR_CODE",'''') ||''_''|| COALESCE("MTR_SUBCOD",'''')) FROM '|| mst_sch ||'."'||tbl_name_poi_cat||'" )) as t1 ';
		
		
		-- SELECT "ID",(COALESCE("FTR_CRY",'') ||'_'|| COALESCE("SUB_CRY",'')) FROM mmi_v180."PB_POI" WHERE (COALESCE("FTR_CRY",'') ||'_'|| COALESCE("SUB_CRY",''))
		-- NOT IN (SELECT (COALESCE("MSTR_CODE",'') ||'_'|| COALESCE("MTR_SUBCOD",'')) FROM mmi_v180."POI_CAT" )
		
		--SELECT t1."ID",'GA_POI','SUB_CRY',t1."SUB_CRY"::text,'Poi’s Sub_Cry does not match with Mtr_Subcod in Poi Cat','1.5.1'
		--FROM ( (SELECT "SUB_CRY" FROM mmi_v180."GA_POI" WHERE (COALESCE("SUB_CRY",'')<> '') ) EXCEPT
		--(SELECT "MTR_SUBCOD" FROM mmi_v180."POI_CAT" WHERE (COALESCE("MTR_SUBCOD",'')<> '') ) ) As t, mmi_v180."GA_POI" As t1 WHERE 
		--t."SUB_CRY"=t1."SUB_CRY"
		
		RAISE INFO '<----------1.1.91';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 18.1:%',f1;
		RAISE info 'error caught 18.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,POI_CAT->SUB_CRY2
--1.1.2
--1.5.4
--16 msec
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		(SELECT t."ID",'''||tbname_addr||''',''SUB_CRY'',t."SUB_CRY"::text,''Addr Sub_Cry must be part of Mtr_Subcod group in Poi Cat'',''1.1.2''
		FROM '||sch_name||'."'||tbname_addr||'" As t WHERE  t."SUB_CRY" NOT IN ( 
		SELECT "MTR_SUBCOD" FROM '|| mst_sch ||'."'||tbl_name_poi_cat||'" WHERE (COALESCE("MTR_SUBCOD",'''')<> '''')) AND t."SUB_CRY" IN ( 
		SELECT "MTR_SUBCOD" FROM '|| mst_sch ||'."'||tbl_name_poi_cat||'" WHERE (COALESCE("MTR_SUBCOD",'''')<> '''')))';
	    
		--SELECT t."ID",'''||tbname_addr||''',''SUB_CRY'',t."SUB_CRY"::text,''Poi’s Sub_Cry must be part of Mtr_Subcod group in Poi Cat'',''1.5.4''
		--FROM '||sch_name||'."'||tbname_addr||'" As t WHERE  t."SUB_CRY" NOT IN ( 
		--SELECT "MTR_SUBCOD" FROM '|| mst_sch ||'."'||tbl_name_poi_cat||'" WHERE (COALESCE("MTR_SUBCOD",'''')<> '''')) AND t."SUB_CRY" IN ( 
		--SELECT "MTR_SUBCOD" FROM '|| mst_sch ||'."'||tbl_name_poi_cat||'" WHERE (COALESCE("MTR_SUBCOD",'''')<> ''''))
		
		RAISE INFO '<----------1.1.2';
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
		f1=MESSAGE_TEXT,
		f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 19.1:%',f1;
		RAISE info 'error caught 19.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,POI_CAT->FTR_CRY
--1.1.3
--1.3.1
--31 msec
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT t4."ID",'''||tbname_addr||''',''FTR_CRY'',t4."FTR_CRY",''Addr Ftr_Cry does not match with Mtsr_Code in Poi Cat'',''1.1.3'' FROM (( SELECT "FTR_CRY"
		FROM '||sch_name||'."'||tbname_addr||'" ) EXCEPT (SELECT "MSTR_CODE" FROM '|| mst_sch ||'."'||tbl_name_poi_cat||'" 
		WHERE (COALESCE("MSTR_CODE",'''')<> '''')) ) As t1, '||sch_name||'."'||tbname_addr||'" t4 WHERE t1."FTR_CRY" = t4."FTR_CRY"';
	    
		--SELECT t4."ID",'GA_POI','FTR_CRY',t4."FTR_CRY"::text,'Poi’s Ftr_Cry does not match with Mtsr_Code in Poi Cat','1.1.3' FROM (( SELECT "FTR_CRY"
		--FROM mmi_v180."GA_POI" ) EXCEPT (SELECT "MSTR_CODE" FROM mmi_v180."POI_CAT" WHERE (COALESCE("MSTR_CODE",'')<> '')) ) As t1, mmi_v180."GA_POI" t4 WHERE 
	    --t1."FTR_CRY" = t4."FTR_CRY"
		
		RAISE INFO '<----------1.1.3';
		
		EXCEPTION 
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 19.1:%',f1;
		RAISE info 'error caught 19.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
--2.62.38
	BEGIN	
		 sqlQuery='INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT tab1."ID",'''||tbname_addr||''',''ROAD_NME'',tab1."ROAD_NME", ''If Road_Nme available then it must be match from Road_Name of Road table with reference to Edge_Id'',''2.62.38''
				 FROM '||sch_name||'."'|| UPPER(tbname_addr) ||'" as tab1,'||tbname_addr_road||' as tab2
				 WHERE COALESCE(tab1."ROAD_NME",'''')<>'''' AND tab1."EDGE_ID" = tab2."EDGE_ID" AND tab1."ROAD_NME" <> tab2."ROAD_NME"	';
			raise info 'query %',sqlQuery;
			EXECUTE(sqlQuery);
		 -- SELECT tab1."ID",tab2."ROAD_NME",tab1."ROAD_NME",tab1."EDGE_ID",tab2."EDGE_ID" FROM mmi_master."DL_P1_ADDR_POINT"  tab1,mmi_master."DL_ROAD_NETWORK" AS tab2
		 -- WHERE COALESCE(tab1."ROAD_NME",'')<>'' AND tab1."EDGE_ID" = tab2."EDGE_ID" AND tab1."ROAD_NME" <> tab2."ROAD_NME"

		
		RAISE INFO '<----------2.62.38';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

--2.62.46
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID",'''||tbname_addr||''',''EDGE_ID'',"EDGE_ID", ''EDGE_ID MUST MATCH WITH ROAD TABLE EDGE_ID'',''2.62.46''
				 FROM '||sch_name||'."'|| UPPER(tbname_addr) ||'"
				 WHERE "EDGE_ID" NOT IN (SELECT "EDGE_ID" FROM '||tbname_addr_road||')	';

		 -- SELECT "ID","EDGE_ID" FROM mmi_master."DL_P1_ADDR_POINT" WHERE "EDGE_ID" NOT IN (SELECT "EDGE_ID" FROM mmi_master."DL_ROAD_NETWORK")
		
		RAISE INFO '<----------2.62.46';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
--2.62.47
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID",'''||tbname_addr||''',''EDGE_ID'',"EDGE_ID", ''Building Should not be attached with PZ and WW and non Motorable roads'',''2.62.47''
				 FROM '||sch_name||'."'|| UPPER(tbname_addr) ||'"
				 WHERE "DLV"=''Y'' AND "EDGE_ID" IN (SELECT "EDGE_ID" FROM '||tbname_addr_road||' WHERE "FOW_PREV" IN (''PZ'',''WW'') AND "PUBVSPVT"<>1)';

		 -- SELECT "ID","EDGE_ID","DLV" FROM mmi_master."DL_P1_ADDR_POINT"
		 -- WHERE "DLV"='Y' AND "EDGE_ID" IN (SELECT "EDGE_ID" FROM mmi_master."DL_ROAD_NETWORK" WHERE "FOW_PREV" IN ('PZ','WW') AND "PUBVSPVT"<>1)

		
		RAISE INFO '<----------2.62.47';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
--2.62.48
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID",'''||tbname_addr||''',''EDGE_ID'',"EDGE_ID", ''Building Should not be attached with Ferry roads'',''2.62.48''
				 FROM '||sch_name||'."'|| UPPER(tbname_addr) ||'"
				 WHERE "DLV"=''Y'' AND "EDGE_ID" IN (SELECT "EDGE_ID" FROM '||tbname_addr_road||' WHERE "FT"=1)';

		 -- SELECT "ID","EDGE_ID","DLV" FROM mmi_master."DL_P1_ADDR_POINT"
		 -- WHERE "DLV"='Y' AND "EDGE_ID" IN (SELECT "EDGE_ID" FROM mmi_master."DL_ROAD_NETWORK" WHERE "FT"=1)

		
		RAISE INFO '<----------2.62.48';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
--2.62.135
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT tab1."ID",'''||tbname_addr||''',''EDGE_ID'',tab1."EDGE_ID", ''Must not have Ftr_Cry = NMR in Road layer'',''2.62.135''
				 FROM '||sch_name||'."'|| UPPER(tbname_addr) ||'" tab1,'||tbname_addr_road||' tab2
				 where tab1."EDGE_ID"= tab2."EDGE_ID"  AND tab1."FTR_CRY"=''NMR'' ';

		 -- SELECT tab1."ID",tab1."EDGE_ID" FROM mmi_master."DL_P1_ADDR_POINT" as tab1,mmi_master."DL_ROAD_NETWORK" AS tab2 
		 -- where tab1."EDGE_ID"= tab2."EDGE_ID"  AND tab1."FTR_CRY"='NMR'

		
		RAISE INFO '<----------2.62.135';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	----------------------------------------------------------------EDGID_ADR------------------------------------------------------------------------------
--2.62.103
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID",'''||tbname_addr||''',''EDGID_ADR'',"EDGID_ADR"::text, ''If available than must be match from road table'',''2.62.103''
				 FROM '||sch_name||'."'|| UPPER(tbname_addr) ||'" 
				 WHERE "EDGID_ADR" IS NOT NULL AND "EDGID_ADR"<>0 AND "EDGID_ADR" NOT IN (SELECT "EDGE_ID" FROM '||tbname_addr_road||')  '; 

		 -- SELECT "ID","EDGID_ADR"
		 -- FROM mmi_master."DL_P1_ADDR_POINT" AS tab1
		 -- WHERE "EDGID_ADR" IS NOT NULL AND "EDGID_ADR"<>0 AND "EDGID_ADR" NOT IN (SELECT "EDGE_ID" FROM mmi_master."DL_ROAD_NETWORK") 

		-- select "ID","EDGID_ADR" FROM mmi_master."DL_P1_ADDR_POINT" WHERE "EDGID_ADR" IS NOT NULL AND "EDGID_ADR"<>0 AND 
		-- "EDGID_ADR" NOT IN (SELECT "EDGE_ID" FROM mmi_master."DL_ROAD_NETWORK") 
		 
		
		RAISE INFO '<----------2.62.103';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

	
--2.62.106
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT tab1."ID",'''||tbname_addr||''',''EDGID_ADR'',tab1."EDGID_ADR"::text, ''These ids must have road name in road table'',''2.62.106''
				 FROM '||sch_name||'."'|| UPPER(tbname_addr) ||'"  tab1,'||tbname_addr_road||' tab2
				 where tab1."EDGID_ADR" is not null and tab1."EDGID_ADR" <> 0 and COALESCE(tab2."ROAD_NME",'''')='''' AND tab1."EDGID_ADR"=tab2."EDGE_ID" '; 

		 -- SELECT "ID","EDGID_ADR"
		 -- FROM mmi_master."DL_P1_ADDR_POINT" AS tab1
		 -- WHERE "EDGID_ADR" IS NOT NULL AND "EDGID_ADR"<>0 AND "EDGID_ADR" NOT IN (SELECT "EDGE_ID" FROM mmi_master."DL_ROAD_NETWORK") 

		-- select tab1."ID",tab1."EDGID_ADR",tab2."EDGE_ID",tab2."ROAD_NME" FROM mmi_master."DL_P1_ADDR_POINT" tab1,mmi_master."DL_ROAD_NETWORK" AS tab2
		-- where tab1."EDGID_ADR" is not null and tab1."EDGID_ADR" <> 0 and COALESCE(tab2."ROAD_NME",'')='' AND tab1."EDGID_ADR"=tab2."EDGE_ID"

		RAISE INFO '<----------2.62.106';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

---------------------------------------------------------------RDNME_ADDR--------------------------------------------------------------------
--2.62.111
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT tab1."ID",'''||tbname_addr||''',''RDNME_ADDR'',tab1."RDNME_ADDR"::text, ''Road name addr should match with Road Name according to Edge_Id_Addr with reference to road layer'',''2.62.111''
				 FROM '||sch_name||'."'|| UPPER(tbname_addr) ||'"  tab1,'||tbname_addr_road||' tab2
				 where tab1."EDGID_ADR" is not null and tab1."EDGID_ADR" <> 0 and COALESCE(tab1."RDNME_ADDR",'''') <> COALESCE(tab2."ROAD_NME",'''') AND tab1."EDGID_ADR"=tab2."EDGE_ID"'; 

		-- select tab1."ID",tab1."EDGID_ADR",tab2."EDGE_ID",tab2."ROAD_NME"
		-- FROM mmi_master."DL_P1_ADDR_POINT" tab1,mmi_master."DL_ROAD_NETWORK" AS tab2
		-- where tab1."EDGID_ADR" is not null and tab1."EDGID_ADR" <> 0 and COALESCE(tab1."RDNME_ADDR",'') <> COALESCE(tab2."ROAD_NME",'') AND tab1."EDGID_ADR"=tab2."EDGE_ID"

		
		RAISE INFO '<----------2.62.111';
		
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;		
------------------------------------------------------from poi obj----------------------------------------------------------------
IF tbname_addr_road <> '' AND tbname_addr <> '' THEN
--1.1.50
--1.47.182
--- 47 msec	
--to be review with 1.1.45 both qa is same like
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		( SELECT t."ID",'''||tbname_addr||''',''EDGE_ID'',t."EDGE_ID",''Addr should not be attached with Walkway & Pedastrian or foot over bridge'',''1.1.50''            
		FROM '||sch_name||'."'||tbname_addr||'" As t JOIN '||tbname_addr_road||' As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND (t1."FOW_PREV"=''WW'' OR t1."FOW_PREV"=''PZ'' OR t1."FOW_PREV"=''FO'' ))';

		
-- 		( SELECT t."ID",'tbname_addr','EDGE_ID',t."EDGE_ID"::text,'Poi should not be attached with Walkway & Pedastrian','1.47.182'            
-- 		FROM mmi."GJ_POI" As t JOIN GJ_ROAD_NETWORK As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND
-- 		(t1."PJ"<>'' OR t1."FOW_PREV"='WW') )
		
		RAISE INFO '<----------1.1.50';
		
		EXCEPTION
			WHEN OTHERS THEN    
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 14.1:%',f1;
		RAISE info 'error caught 14.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.1.26
--1.37.4
-- 32 msec	
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		( SELECT t."ID",'''||tbname_addr||''',''EDGE_ID'',t."EDGE_ID"::text,''Addr should not be attached with ’NMR’ roads in Road Network'',''1.1.26''            
		FROM '||sch_name||'."'||tbname_addr||'" As t JOIN '||tbname_addr_road||' As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND t1."FTR_CRY"=''NMR'')';
        /*
		  SELECT t."ID",'GA_POI','EDGE_ID',t."EDGE_ID"::text,'Poi should not be attached with ’NMR’ roads in Road Network','1.37.4'            
		FROM mmi_v180."GA_POI" As t JOIN mmi_v180."GA_ROAD_NETWORK" As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND t1."FTR_CRY"='NMR'
		*/
		
		RAISE INFO '<----------1.1.26';
		
		EXCEPTION
			WHEN OTHERS THEN    
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 14.1:%',f1;
		RAISE info 'error caught 14.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--ADDR,ROAD_NETWORK>INTERSECTION, FT=1 OR FT=2
--1.1.27
--1.37.6
--47 msec
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		(SELECT t."ID",'''||tbname_addr||''',''EDGE_ID'',t."EDGE_ID"::text,''Addr point should not be attached with ferry roads'',''1.1.27''            
		FROM '||sch_name||'."'||tbname_addr||'" As t JOIN '||tbname_addr_road||'  As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND t1."FT"=1)';
		
       /*
        SELECT t."ID",'GA_POI','EDGE_ID',t."EDGE_ID"::text,'Poi point should not be attached with ferry roads','1.1.27'            
		FROM mmi_v180."GA_POI" As t JOIN mmi_v180."GA_ROAD_NETWORK"  As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND t1."FT"=1
	   */		
	   
	   RAISE INFO '<----------1.1.27';
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 15.1:%',f1;
		RAISE info 'error caught 15.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--ADDR,ROAD_NETWORK->STT_ID
--1.1.28
--1.37.5
-- 31 msec
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		( SELECT t."ID",'''||tbname_addr||''',''EDGE_ID'',t."EDGE_ID"::text,''Addr Stt_Id does not match with its Road Network Stt_Id'',''1.1.28''            
		FROM '||sch_name||'."'||tbname_addr||'" As t JOIN '||tbname_addr_road||'  As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND t."STT_ID"<>t1."STT_ID" 
		)';
		
		/*
		  SELECT t."ID",'GA_POI','EDGE_ID',t."EDGE_ID"::text,'Poi’s Stt_Id does not match with its Road Network Stt_Id','1.1.28'            
		FROM mmi_v180."GA_POI" As t JOIN mmi_v180."GA_ROAD_NETWORK"  As t1 ON t."EDGE_ID"<>0 AND t."EDGE_ID"=t1."EDGE_ID" AND t."STT_ID"<>t1."STT_ID"
		*/
		
		RAISE INFO '<----------1.1.28';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 16.1:%',f1;
		RAISE info 'error caught 16.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--ADDR,ROAD_NETWORK->EDGE_ID
--1.1.22
--1.37.1
-- 47 msec
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT t1."ID",'''||tbname_addr||''',''EDGE_ID'',t1."EDGE_ID"::text,''Addr Edge_Id does not match with its Road Network Edge_Id'',''1.1.22''
		FROM (SELECT "EDGE_ID" FROM '||sch_name||'."'||tbname_addr||'" EXCEPT (SELECT "EDGE_ID" FROM '||tbname_addr_road||' )) As t , '||sch_name||'."'||tbname_addr||'"  
		AS t1 WHERE t."EDGE_ID" = t1."EDGE_ID" ';
		
		/*
		SELECT t1."ID",'GA_POI','EDGE_ID',t1."EDGE_ID"::text,'Poi’s Edge_Id does not match with its Road Network Edge_Id','1.37.1'
		FROM (SELECT "EDGE_ID" FROM mmi_v180."GA_POI" EXCEPT (SELECT "EDGE_ID" FROM mmi_v180."GA_ROAD_NETWORK" )) As t , mmi_v180."GA_POI"  
		AS t1 WHERE t."EDGE_ID" = t1."EDGE_ID"	
		*/
		
		RAISE INFO '<----------1.1.22';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 17.1:%',f1;
		RAISE info 'error caught 17.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--ADDR,ROAD_NETWORK->INTERSECTION
--1.1.44
-- no error code
	BEGIN 
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT a."ID",'''||tbname_addr||''',''EXCP'',a."EXCP"::text,''If Addr attached with Bridge, then maintain ’BRY’ in EXCP'',''1.1.44'' 
		FROM '||sch_name||'."'||tbname_addr||'" As a, '||tbname_addr_road||' As b WHERE (ST_Intersects(a."SP_GEOMETRY",b."SP_GEOMETRY")=true) AND COALESCE(a."EXCP",'''') NOT LIKE ''%BRY%'' AND 
		b."FOW_PREV"=''BR'' GROUP BY a."ID",a."EXCP"';
		
		/*
		  SELECT a."ID",'GA_POI','EXCP',a."EXCP"::text,'If Poi attached with Bridge, then maintain ’BRY’ in EXCP','NO ERROR CODE' 
		FROM mmi_v180."GA_POI" As a ,mmi_v180."GA_ROAD_NETWORK" As b WHERE (ST_Intersects(a."SP_GEOMETRY",b."SP_GEOMETRY")=true) AND COALESCE(a."EXCP",'') NOT LIKE '%BRY%' AND 
		b."FOW_PREV"='BR' GROUP BY a."ID",a."EXCP"
		*/
	
		RAISE INFO '<----------1.1.44';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--POI,ROAD_NETWORK->POI ATTACHED WITH FLYOVERS, RAMPS, SUBWAYS
--1.1.45
-- No error code
-- 31 msec
---to be review with 1.1.50 both qa is same like
	BEGIN 
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT a."ID",'''||tbname_addr||''',''EXCP'',a."EXCP"::text,''If Addr attached with Flyovers, Ramps, Subways etc, then maintain ’ELY’ in EXCP'',''1.1.45'' 
		FROM '||sch_name||'."'||tbname_addr||'" As a, '||tbname_addr_road||' As b WHERE (ST_Intersects(a."SP_GEOMETRY",b."SP_GEOMETRY")=true) AND 
		COALESCE(a."EXCP",'''') NOT LIKE ''%ELY%'' AND (b."FOW_PREV"=''SU'' OR b."FOW_PREV"=''FL'' OR "FOW_PREV"=''RM'' OR b."FOW_PREV"=''BR'') GROUP BY a."ID",a."EXCP"';
		
		/*
		SELECT a."ID",'GA_POI','EXCP',a."EXCP"::text,'If Poi attached with Ferry, then maintain ’FTY’ in EXCP','NO ERROR CODE' 
		FROM mmi_v180."GA_POI" As a, mmi_v180."GA_ROAD_NETWORK" As b WHERE (ST_Intersects(a."SP_GEOMETRY",b."SP_GEOMETRY")=true) AND COALESCE(a."EXCP",'') NOT LIKE '%FTY%' AND 
		(b."FT"=1 OR b."FT"=2) GROUP BY a."ID",a."EXCP"	
		*/
		RAISE INFO '<----------1.1.45';
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
end if;
----1.1.0
---47 msec
if tbname_entry_shift<>'' and tbname_entrynon_shift<>'' then
    BEGIN
        EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				SELECT tab1."ID",'''||tbname_entry_shift||''',''ID'',tab1."ID",''overlapping point(entry and non_entry)'',''1.1.0'' 
				FROM '||sch_name||'."'||tbname_entry_shift||'" AS tab1,'||sch_name||'."'||tbname_entrynon_shift||'"
                where tab1."ID"=tab2."ID" AND tab1."SP_GEOMETRY" =tab2."SP_GEOMETRY"';
				 /*
				  select tab1."ID",tab1."SP_GEOMETRY",tab2."ID" FROM mmi_master."DL_ADDR_ENTRY" AS tab1,mmi_master."DL_ADDR_ENTRYNONSHIFT" as tab2
				  where tab1."ID"=tab2."ID" AND tab1."SP_GEOMETRY" =tab2."SP_GEOMETRY"
				 */
				 
		RAISE INFO '<----------1.1.0';
		
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 9.1:%',f1;
		RAISE info 'error caught 9.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
end if;	
--IGNORE ERRORS FROM EXCEPTION TABLE 	
	BEGIN
		EXECUTE 'select count(table_name) from information_schema.tables where table_schema=''mmi_lock'' and table_name=''explog''' into count;

		IF count=1 THEN
			-- EXECUTE 'DELETE FROM qa.'||user_id||'_attobj a WHERE EXISTS (select * FROM mmi_lock.explog b WHERE a.unquid=b.un_id and coalesce(a.field_name,'''')=coalesce(b.field_name,'''') and coalesce(a.field_value,'''')=coalesce(b.field_value,'''') and coalesce(a.error_type,'''')=coalesce(b.error_type,'''') and coalesce(a.error_code,'''')=coalesce(b.error_code,'''') and coalesce(b.user_id,'''')='''||UPPER(user_id)||''')';
			EXECUTE 'DELETE FROM '||qaerrortabname||' a WHERE EXISTS (select * FROM addr_features_lock.explog b WHERE a.addr_id=b.un_id and coalesce(TRIM(a.field_name),'''')=coalesce(TRIM(b.field_name),'''') and coalesce(TRIM(a.field_value),'''')=coalesce(TRIM(b.field_value),'''') and coalesce(TRIM(a.error_type),'''')=coalesce(TRIM(b.error_type),'''') and coalesce(TRIM(a.error_code),'''')=coalesce(TRIM(b.error_code),'''') and TRIM(b.user_id)='''||UPPER(user_id)||''')';
		END IF;

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbname_addr||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'IGNORE ERRORS FROM EXCEPTION TABLE';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

	EXECUTE FORMAT('SELECT count(*) FROM %1$s',qaerrortabname) INTO errortablecount;
	IF(errortablecount IS NOT NULL) THEN

		EXECUTE FORMAT('UPDATE %1$s SET err_geom_count=%2$s,err_attrib_error_tabname=''%3$s'' WHERE id in (select max(id) from %1$s where edt_table_name=''%4$s'')',qauploadlogtabname,errortablecount,qaerrortabname,tbname_addr);
		EXECUTE FORMAT('UPDATE %1$s SET error_count=%2$s WHERE error_tab_name=''%3$s''',qaerrortablelogtabname,errortablecount,qaerrortablelogtabname);
		RETURNVAL = errortablecount;
	END IF;	
	
	RETURN RETURNVAL;
	
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
		EXECUTE FORMAT('DROP TABLE IF EXISTS %1$s',qaerrortabname);
		RAISE info 'error caught 41.1:%',f1;
		RAISE info 'error caught 41.2:%',f2;
		RETURNVAL = -1;
	RETURN RETURNVAL;
	
END;	

$BODY$;

ALTER FUNCTION qaupload.qc_addr_point_object(character varying, character varying, character varying, character varying, character varying, character varying, character varying, text)
    OWNER TO postgres;
