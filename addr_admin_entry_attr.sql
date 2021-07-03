-- FUNCTION: upload.addr_admin_entry_attr(character varying, character varying, character varying, character varying, character varying, character varying, character varying)

-- DROP FUNCTION upload.addr_admin_entry_attr(character varying, character varying, character varying, character varying, character varying, character varying, character varying);

CREATE OR REPLACE FUNCTION upload.addr_admin_entry_attr(
	tbl_addr_admin_entrynonshift character varying,
	tbl_addr_admin_p character varying,
	tbl_addr_admin_edge character varying,
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
	
	error_table = 'qa.'||user_id||'_addr_admin_entrynonshift_attr';
	attrib_error= 'qa.attriberror';
	raise info 'tab %',error_table;
	raise info 'tab %',attrib_error;
	
	EXECUTE 'DROP TABLE IF EXISTS '||error_table||''; 
	EXECUTE 'CREATE TABLE if not exists '||error_table||' (poi_id serial, table_name text, field_name text, 
	field_value text, error_type text,error_code text )';
	EXECUTE 'CREATE TABLE if not exists '||attrib_error||' (poi_id serial,user_id text,layer_nme text, message text,context text,db_edit_datetime timestamp without time zone DEFAULT now())';

---------------------------------------------------------------------ID-----------------------------------------------------------------------------------------------------------------
--2.77.9
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID",'''||tbl_admin_entry||''',''ID'', "ID", ''Must be match from ADDR_Admin_Edge layer'',''2.77.9'' 
		FROM '||sch_name||'."'|| UPPER(tbl_admin_entry) ||'" WHERE "ID" NOT IN (SELECT "ID" FROM '||sch_name||'."'|| UPPER(tbl_addr_admin_edge) ||'") ';
         
		--SELECT "ID" FROM mmi_master."DL_ADDR_ADMIN_ENTRYNONSHIFT" WHERE "ID" NOT IN (SELECT "ID" FROM mmi_master."DL_ADDR_ADMIN_EDGE")
		
		RAISE INFO '<-----------2.77.9';
		
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
	
--2.77.8
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID",'''||tbl_admin_entry||''',''ID'', "ID", ''Must be match from ADDR_Admin_P layer and vice versa'',''2.78.8'' 
		FROM '||sch_name||'."'|| UPPER(tbl_admin_entry) ||'" WHERE "ID" NOT IN (SELECT "ID" FROM '||sch_name||'."'|| UPPER(tbl_addr_admin_edge) ||'") ';
         
		--SELECT "ID" FROM mmi_master."DL_ADDR_ADMIN_ENTRY" WHERE "ID" NOT IN (SELECT "ID" FROM mmi_master."DL_ADDR_ADMIN_EDGE")
		
		RAISE INFO '<-----------2.78.8';
		
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
	
--2.77.10
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID",'''||tbl_admin_entry||''',''ID'', "ID", ''Must not be zero 0'',''2.77.10'' 
		FROM '||sch_name||'."'|| UPPER(tbl_admin_entry) ||'" WHERE COALESCE("ID"::TEXT, '''') = ''0'' ';
         
		--SELECT "ID" FROM mmi_master."DL_ADDR_ADMIN_ENTRY" WHERE COALESCE("ID"::TEXT, '') = '0'
		
		RAISE INFO '<-----------2.77.10';
		
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
	
--2.77.11	
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,table_name,field_name,field_value,error_type,error_code) 
		SELECT tab."ID",'''||tbl_admin_entry||''',''ID'', tab."ID", ''Must not be duplicate'',''2.77.11'' 
		FROM (SELECT "ID", COUNT(*) OVER (PARTITION BY "ID") AS ct FROM '||sch_name||'."'|| UPPER(tbl_admin_entry) ||'") AS tab
		WHERE tab.ct > 1 ';
         
		--SELECT tab."ID"  FROM 
		-- (SELECT "ID", COUNT(*) OVER (PARTITION BY "ID") AS ct FROM mmi_master."DL_ADDR_ADMIN_ENTRY") AS tab
		-- WHERE tab.ct > 1
		
		RAISE INFO '<-----------2.77.11';
		
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
	
---------------------------------------------------------------------EDGE_ID--------------------------------------------------------------------------------------------------------------------------
	
--2.77.13
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID",'''||tbl_admin_entry||''',''EDGE_ID'', "EDGE_ID", ''Must not be zero 0'',''2.77.13'' 
		FROM '||sch_name||'."'|| UPPER(tbl_admin_entry) ||'" WHERE COALESCE("EDGE_ID"::TEXT, '''') = ''0'' ';
         
		--SELECT "ID", "EDGE_ID" FROM mmi_master."DL_ADDR_ADMIN_ENTRY" WHERE COALESCE("EDGE_ID"::TEXT, '') = '0'

		RAISE INFO '<-----------2.77.13';
		
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
	
--2.77.14
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,table_name,field_name,field_value,error_type,error_code) 
		SELECT t1."ID",'''||tbl_admin_entry||''',''EDGE_ID'', t1."EDGE_ID", ''Must match with ADDR_ADMIN_P Edge Id WRT Id'',''2.77.14'' 
		FROM '||sch_name||'."'|| UPPER(tbl_admin_entry) ||'" t1 INNER JOIN '||sch_name||'."'|| UPPER(tbl_addr_admin_p) ||'" t2 ON t1."ID" = t2."ID" 
		WHERE t1."EDGE_ID" <> t2."EDGE_ID" ';
         
		--SELECT t1."ID" ,t1."EDGE_ID" 
		-- FROM mmi_master."DL_ADDR_ADMIN_ENTRY" t1 INNER JOIN mmi_master."DL_ADDR_ADMIN_P" t2 ON t1."ID" = t2."ID"
		-- WHERE t1."EDGE_ID" <> t2."EDGE_ID"

		
		RAISE INFO '<-----------2.77.14';
		
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

--2.77.18
	BEGIN
		sqlQuery = ' INSERT INTO '||error_table||' ( table_name,field_name,error_type,error_code) 
		SELECT '''||tbl_admin_entry||''',''Count'', ''Count of ADDR_Admin_Entry and ADDR_Admin_Edge should be same'',''2.77.18'' FROM
		(SELECT ct2, ct1, COUNT("ID") AS ct FROM
		(SELECT ct2 ,COUNT("ID")  AS ct1 FROM
		(SELECT COUNT("ID")  AS ct2 FROM '||sch_name||'."'|| UPPER(tbl_admin_entry) ||'" ) AS tab, '||sch_name||'."'|| UPPER(tbl_addr_admin_entrynonshift) ||'" AS tab1 GROUP BY ct2) AS tab2, '||sch_name||'."'|| UPPER(tbl_addr_admin_edge) ||'" AS tab3 WHERE ct1 != ct2 GROUP BY ct2, ct1) AS tab4
		WHERE ct != ct1 AND ct != ct2 ';
         
		--SELECT * FROM 
		-- (SELECT ct2, ct1, COUNT("ID") AS ct FROM 
		-- (SELECT ct2 ,COUNT("ID")  AS ct1 FROM
		-- (SELECT COUNT("ID")  AS ct2 FROM mmi_master."DL_ADDR_ADMIN_ENTRY" ) AS tab, mmi_master."DL_ADDR_ADMIN_ENTRY" AS tab1 GROUP BY ct2) AS tab2, mmi_master."DL_ADDR_ADMIN_EDGE" AS tab3 WHERE ct1 != ct2 GROUP BY ct2, ct1) AS tab4
		-- WHERE ct != ct1 AND ct != ct2

		--raise info 'sql-->%',sqlQuery;
		execute sqlQuery;
		RAISE INFO '<-----------2.77.18';
		
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

ALTER FUNCTION upload.addr_admin_entry_attr(character varying, character varying, character varying, character varying, character varying, character varying, character varying)
    OWNER TO postgres;