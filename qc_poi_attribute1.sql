CREATE OR REPLACE FUNCTION upload.qc_poi_attribute(
	sch_name character varying,
	tbl_nme character varying,
	user_id character varying,
	user_type character varying)
    RETURNS TABLE(poi_id integer, name character varying, table_name text, field_name text, field_value text, error_type text, error_code text) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$

declare attrib_error character varying;
DECLARE error_table CHARACTER VARYING(50);
declare SqlQuery text;
declare master_tbl_poi_tpd character varying(50);
DECLARE t timestamptz := clock_timestamp();
DECLARE master_tbl_admin_p CHARACTER VARYING(50);
DECLARE tbl_nme_point CHARACTER VARYING(50);
DECLARE i integer;
DECLARE j integer;
DECLARE r record;
DECLARE tablename text;
DECLARE conquery text;
DECLARE conquery1 text;
DECLARE arr text [];
DECLARE 
f1 text; f2 text;
t1 text; t2 text;
mst_sch text;
stat_code text;
yyyy_mm varchar(254);
DECLARE count integer;
BEGIN   
	mst_sch = 'mmi_master';
	stat_code= UPPER(left(UPPER(tbl_nme),2));
        RAISE WARNING 'STATE %',stat_code;
	yyyy_mm = to_char(now(),'yyyymmddhh24miss');
	RAISE WARNING 'yyyy_mm % AA :%',yyyy_mm,'';
------------------------------------------------------error table for poi-------------------------------------------------	
	if(upper(user_type)= 'USER' or user_type = 'PACKING' or user_type = 'ADMIN' or user_type = 'MASTER') then 
		error_table = 'qa.'||user_id||'';
		attrib_error= 'qa.attriberror';
		raise info 'tab %',error_table;
		raise info 'tab %',attrib_error;
	end if;
------------------------------------------------------error table for de------------------------------------------------------	
	if(upper(user_type)= 'DE') then 
	
		error_table = 'de_qa.'||user_id||'';
		attrib_error= 'de_qa.attriberror';
		raise info 'tab %',error_table;
		raise info 'tab %',attrib_error;

	end if;
--------------------------------------------------------------------------------------------------------------------------------	
	EXECUTE 'DROP TABLE IF EXISTS '||error_table||''; 
	EXECUTE 'CREATE TABLE if not exists '||error_table||' (id serial, poi_id integer,NAME varchar(254), table_name text, field_name text, 
	field_value text, error_type text,error_code text )';
	EXECUTE 'CREATE TABLE if not exists '||attrib_error||' (id serial,user_id text,layer_nme text, message text,context text,db_edit_datetime timestamp without time zone DEFAULT now())';
	
	------------------------------------------------------------------------------Checking for _POI_TPD-------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_POI_TPD'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			master_tbl_poi_tpd=''|| UPPER(stat_code) ||'_POI_TPD';
		ELSE
			master_tbl_poi_tpd = '';
			IF master_tbl_poi_tpd = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_POI_TPD DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_POI_TPD Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'checking for _POI_TPD';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;
	
	------------------------------------------------------------------------------Checking for _ADDR_ADMIN_P-------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'_ADDR_ADMIN_P'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			master_tbl_admin_p = ''|| UPPER(stat_code) ||'_ADDR_ADMIN_P';
		ELSE
			master_tbl_admin_p = '';
			IF master_tbl_admin_p = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%_ADDR_ADMIN_P DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
				EXECUTE'insert into '||attrib_error||'(message) values('''||UPPER(stat_code)||'_ADDR_ADMIN_P Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
		RAISE INFO 'checking for _POI_TPD';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END;

----------------------------------------------------------------------------_ADDR_POINT--------------------------------------------------------------------------------------------
			BEGIN
				i=0;
				j=0;

				EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____ADDR_POINT'' AND TABLE_SCHEMA ='''||mst_sch||'''' into count;

				IF count > 1 THEN 
					-- tbl_nme_point=''|| UPPER(stat_code) ||'_ROAD_NETWORK';
					FOR r IN EXECUTE FORMAT('SELECT table_name FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____ADDR_POINT'' AND TABLE_SCHEMA ='''||mst_sch||''' ') 
					LOOP
						  tablename = UPPER(r.table_name);
						  --RAISE INFO 'tableName%',tablename;
						  arr[i]=tablename;
						  --RAISE WARNING 'Count % AA :%',arr[i],'';
						  i=i+1;
					END LOOP;
					i=i-1;  
					conquery=' SELECT * FROM '||mst_sch||'."'||arr[0]||'" ';
					LOOP 
						EXIT WHEN i=0;
						conquery1='union all  SELECT * FROM '||mst_sch||'."'||arr[i]||'" ';
						conquery = CONCAT(conquery,  conquery1);
						i=i-1;
						--RAISE WARNING 'QUERY % QUERY %',conquery,'';
					END LOOP;
					
					EXECUTE'drop table if exists '|| UPPER(stat_code) ||'____ADDR_POINT';
					EXECUTE'create temp table '|| UPPER(stat_code) ||'____ADDR_POINT As ('|| conquery||')';
					tbl_nme_point =''|| UPPER(stat_code) ||'____ADDR_POINT';

				ELSE
					SqlQuery = 'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE '''||UPPER(stat_code)||'____ADDR_POINT'' AND TABLE_SCHEMA ='''||mst_sch||'''';
					--RAISE INFO 'sql -> %', SqlQuery;
					EXECUTE SqlQuery into count;
					
					IF count = 1 THEN
						tbl_nme_point = ''||mst_sch||'."'||UPPER(stat_code)||'____ADDR_POINT"';
					ELSE
						RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>%____ADDR_POINT DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>',UPPER(stat_code);
						EXECUTE'insert into qa.attriberror_attobj(message) values('''||UPPER(stat_code)||'____ADDR_POINT Table Does not Exists in '||mst_sch||' Schema'')';
						tbl_nme_point = '';
					END IF;
				END IF;
				RAISE INFO 'check for road network';
				RAISE NOTICE 'time spent =%', clock_timestamp() - t;
			END;	

	
	-------------------------------------------------------------------------------------------------ID-----------------------------------------------------------------------------------------------------------------------------------------------
--1.1.2
-- 1 sec 695 msec
	BEGIN
		 EXECUTE 'INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''ID'',"ID"::text, 
		''POI_ID should be integer and unique'',''1.1.2'' FROM ( SELECT "ID","NAME", COUNT(*) OVER (PARTITION By "ID") As ct FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" ) 
		sub WHERE ct>1';
		
		/*
            SELECT "ID","NAME",'DL_POI','ID',"ID"::text,'POI_ID should be integer and unique','1.1.2'
            FROM ( SELECT "ID","NAME", COUNT(*) OVER (PARTITION By "ID") As ct FROM mmi_master."DL_POI") sub WHERE ct>1
			
		*/
 
              RAISE INFO '<-----------1.1.2';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
--1.1.8
--52 msec
IF UPPER(tbl_nme) LIKE '%_POI_EDT' THEN 
	IF master_tbl_poi_tpd <> '' THEN
		BEGIN
			sqlQuery = ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
			SELECT tab1."ID",tab1."NAME",'''||tbl_nme||''',''ID'',tab1."ID",''POI_ID CONTAIN IN MASTER TPD LAYER'',''1.1.8'' 
			FROM  '||sch_name||'."'|| UPPER(tbl_nme) ||'" tab1 inner join '||mst_sch||'."'||master_tbl_poi_tpd||'" tab2
			ON tab1."ID"=tab2."ID" ';
			RAISE info 'sqlQuery 1.1.2:%',sqlQuery;
			
			EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
			SELECT tab1."ID",tab1."NAME",'''||tbl_nme||''',''ID'',tab1."ID",''POI_ID CONTAIN IN MASTER TPD LAYER'',''1.1.8'' 
			FROM  '||sch_name||'."'|| UPPER(tbl_nme) ||'" tab1 inner join '||mst_sch||'."'||master_tbl_poi_tpd||'" tab2
			ON tab1."ID"=tab2."ID" ';
 
          /*			
			SELECT tab1."ID",tab1."NAME",'DL_POI','ID',tab1."ID",'POI_ID CONTAIN IN MASTER TPD LAYER','1.1.8'
            FROM  mmi_master."DL_POI"  tab1 inner join  mmi_master."DL_POI_TPD" tab2 ON tab1."ID"=tab2."ID" 
			
		 */	
			
			        RAISE INFO '<-----------1.1.8';

			
		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
					
			EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
			RAISE info 'error caught 2.1:%',f1;
			RAISE info 'error caught 2.2:%',f2;
		END;
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	END IF;
END IF;
		
	
--1.1.9
--635 msec
IF (UPPER(tbl_nme) LIKE '%_POI_TPD_EDT') THEN 
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT tab1."ID",tab1."NAME",'''||tbl_nme||''',''ID'',tab1."ID",''POI_ID MOVE TO MASTER MUST BE UPLOADED IN MASTER'',''1.1.9'' 
		FROM  '||sch_name||'."'|| UPPER(tbl_nme) ||'" tab1 inner join mmi_lock.tpdtopoilog tab2 
		ON tab1."ID"=tab2.table_id ';

		--SELECT tab1."ID",tab2.table_id FROM upload."UP_CN001658_14062019_POI_TPD_EDT" tab1 INNER JOIN mmi_lock.tpdtopoilog tab2 ON tab1."ID"=tab2.table_id
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||f2||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
END IF;
		
--1.1.3
--31 msec

BEGIN
	EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''ID'',"ID"::text, 
	''POI_ID should be extracted FROM MMI Portal only and should not be 0'',''1.1.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
	WHERE "ID"  NOT BETWEEN 43100001 AND 63100000 AND "ID"  NOT BETWEEN 195338001 AND 199000000 and "ID" NOT BETWEEN 23100001 and 43100000 AND "ID" NOT BETWEEN 199000001 and 203000000 AND "ID" NOT BETWEEN 350000001 and 380000000';

    --SELECT "ID","GA_POI",'GA_POI','ID',"ID"::text, 
    -- 'POI_ID should be extracted FROM MMI Portal only and should not be 0','1.1.3' FROM mmi_v180."GA_POI" WHERE "ID"  NOT BETWEEN 43100001 AND 63100000 
    --AND "ID"  NOT BETWEEN 195338001 AND 199000000
	 
	EXCEPTION
	WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS 
		f1=MESSAGE_TEXT,
		f2=PG_EXCEPTION_CONTEXT; 
			
	EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
					  
	RAISE info 'error caught 2.1:%',f1;
	RAISE info 'error caught 2.2:%',f2;
END;
RAISE INFO 'POI_ID should be extracted FROM MMI Portal only and should not be 0';
RAISE NOTICE 'time spent =%', clock_timestamp() - t;

--1.1.4
if(user_type <> 'de') then 
		
		if(user_type='ADMIN') THEN
			BEGIN
				EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
					SELECT "ID","NAME",'''||tbl_nme||''',''ID'',"ID"::text, 
					''MASTER POI RECORD should be Locked'',''1.1.4'' FROM (SELECT * FROM (SELECT A."ID",A."NAME" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" AS A,uniqueid_log.master_unq_id AS B 
					WHERE A."ID"=B.col_id AND B.state_code LIKE LEFT('''||UPPER(tbl_nme)||''',2)) AS C LEFT JOIN uniqueid_log.idlog D ON C."ID"=D.munid WHERE D.munid IS NULL) AS E LEFT JOIN mmi_lock.userlock F ON E."ID"=F.table_id WHERE F.table_id IS NULL';

				
				--SELECT "ID","NAME",'tbl_nme','ID',"ID"::text, 
				--'POI_ID should be extracted FROM MMI Portal only and should not be 0','1.1.3' FROM mmi_v161."DL_POI" WHERE "ID"  NOT BETWEEN 43100001 AND 63100000 
				--AND "ID"  NOT BETWEEN 195338001 AND 199000000 AND ( status NOT IN ('0','5') OR (COALESCE(status,'')='') )
				 
				EXCEPTION
				WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
					f1=MESSAGE_TEXT,
					f2=PG_EXCEPTION_CONTEXT; 
						
				EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
				RAISE info 'error caught 2.1:%',f1;
				RAISE info 'error caught 2.2:%',f2;
			END;
			RAISE INFO 'MASTER POI RECORD should be Locked';
			RAISE NOTICE 'time spent =%', clock_timestamp() - t;
		END IF;
	
		if(user_type='USER' OR user_type='PACKING') THEN
			
			
			BEGIN
				EXECUTE 'INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
				SELECT "ID","NAME",'''||tbl_nme||''',''ID'',"ID"::text, 
				''ID Found Into DPO Records'',''1.1.4'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "ID" in (Select table_id from mmi_lock.deletedpoi)';

				 
				EXCEPTION
				WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
					f1=MESSAGE_TEXT,
					f2=PG_EXCEPTION_CONTEXT; 
						
				EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
				RAISE info 'error caught 2.1:%',f1;
				RAISE info 'error caught 2.2:%',f2;
			END;
			RAISE INFO 'MASTER POI RECORD should be Locked';
			RAISE NOTICE 'time spent =%', clock_timestamp() - t;
			
			
			BEGIN
				EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
				SELECT "ID","NAME",'''||tbl_nme||''',''ID'',"ID"::text, 
				''MASTER POI RECORD should be Locked'',''1.1.4'' FROM (SELECT A."ID",A."NAME" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" AS A,uniqueid_log.master_unq_id AS B 
				WHERE A."ID"=B.col_id AND B.state_code LIKE LEFT('''||UPPER(tbl_nme)||''',2)) AS C WHERE C."ID"
				NOT IN (SELECT TABLE_ID FROM mmi_lock.userlock WHERE user_id='''||UPPER(user_id)||''')';

				--SELECT "ID","NAME",'GA_POI','ID',"ID"::text, 
				--'MASTER POI RECORD should be Locked','1.1.4' FROM (SELECT A."ID",A."NAME" FROM mmi_v180."GA_POI" AS A,uniqueid_log.master_unq_id AS B 
				--WHERE A."ID"=B.col_id AND B.state_code LIKE LEFT('GA_POI',2)) AS C WHERE C."ID"
				--NOT IN (SELECT TABLE_ID FROM mmi_lock.userlock WHERE user_id='CN002733')
				 
				EXCEPTION
				WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
					f1=MESSAGE_TEXT,
					f2=PG_EXCEPTION_CONTEXT; 
						
				EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
				RAISE info 'error caught 2.1:%',f1;
				RAISE info 'error caught 2.2:%',f2;
			END;
			RAISE INFO 'MASTER POI RECORD should be Locked';
			RAISE NOTICE 'time spent =%', clock_timestamp() - t;
		
		    -- 1.1.10
		    -- ADDED BY GOLDY 18/06/2019
			BEGIN
				SqlQuery = 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
						 SELECT "ID",user_name,'''||tbl_nme||''',''ID'',"ID",''User_Name:''''''||user_name||'''''' and Status:''''''||status||'''''''',''1.1.10''
						 FROM 
						 (select res1."ID",t1.user_name,CASE when t1.status=5 THEN ''LOCKED'' WHEN t1.status=3 THEN ''DELETED'' WHEN t1.status=9 THEN ''LOCKED TPD TO MASTER MOVE'' WHEN t1.status=1 THEN ''LOCKED ADMIN PENDING'' WHEN t1.status=2 THEN ''LOCKED PACKING PENDING'' END AS status FROM (
						 SELECT tab1."ID" from '||sch_name||'."'|| UPPER(tbl_nme) ||'" tab1 INNER JOIN uniqueid_log.master_unq_id as tab2 on tab1."ID" = tab2.col_id) AS res1
						 inner join mmi_lock.userlock as t1 on res1."ID"= t1.table_id where upper(t1.user_id)<>'''||upper(user_id)||''') AS res2 ';
				
				EXECUTE SqlQuery;
						 
				-- SELECT res2."ID",res2.user_name,res2.status FROM (
				-- select res1."ID",t1.user_name,CASE when t1.status=5 THEN 'LOCKED' WHEN t1.status=3 THEN 'DELETED' WHEN t1.status=9 THEN 'LOCKED TPD TO MASTER MOVE' WHEN t1.status=1 THEN 'LOCKED ADMIN PENDING' WHEN t1.status=2 THEN 'LOCKED PACKING PENDING' END AS status FROM (
				-- SELECT tab1."ID" from mmi_master."MH_P1_POI" tab1 INNER JOIN uniqueid_log.master_unq_id as tab2 on tab1."ID" = tab2.col_id) AS res1
				-- inner join mmi_lock.userlock as t1 on res1."ID"= t1.table_id where t1.user_id<>'CE00075615') AS res2
				
						
				RAISE INFO '<-----------1.1.10';
				
			EXCEPTION
				WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
					f1=MESSAGE_TEXT,
					f2=PG_EXCEPTION_CONTEXT; 
						
				EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
				RAISE info 'error caught 2.1:%',f1;
				RAISE info 'error caught 2.2:%',f2;
			END;
			RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
		END IF;
-- --1.1.4
		-- BEGIN
			-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
			-- SELECT "ID","NAME",'''||tbl_nme||''',''ID'',"ID"::text, 
			-- ''MASTER POI RECORD should be Locked'',''1.1.4'' FROM (SELECT A."ID",A."NAME" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" AS A,uniqueid_log.master_unq_id AS B 
			-- WHERE A."ID"=B.col_id AND B.stat_code LIKE LEFT('''||UPPER(tbl_nme)||''',2)) AS C WHERE C."ID"
			-- NOT IN (SELECT TABLE_ID FROM mmi_lock.userlock)';

			-- --SELECT "ID","NAME",'GA_POI','ID',"ID"::text, 
			-- --'MASTER POI RECORD should be Locked','1.1.4' FROM (SELECT A."ID",A."NAME" FROM mmi_v180."GA_POI" AS A,uniqueid_log.master_unq_id AS B 
			-- --WHERE A."ID"=B.col_id AND B.stat_code LIKE LEFT('GA_POI',2)) AS C WHERE C."ID"
			-- --NOT IN (SELECT TABLE_ID FROM mmi_lock.userlock WHERE user_id='CN002733')
			 
			-- EXCEPTION
			-- WHEN OTHERS THEN
			-- GET STACKED DIAGNOSTICS 
				-- f1=MESSAGE_TEXT,
				-- f2=PG_EXCEPTION_CONTEXT; 
					
			-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
			-- RAISE info 'error caught 2.1:%',f1;
			-- RAISE info 'error caught 2.2:%',f2;
		-- END;
		-- RAISE INFO 'MASTER POI RECORD should be Locked';
		-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;

	--1.1.5
	--63 msec
		BEGIN
			EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
			SELECT A."ID",A."NAME",'''||tbl_nme||''',''ID'',A."ID"::text, 
			''DUPLICATE ID FOUND INTO STATE ''||B.state_code,''1.1.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" A,uniqueid_log.master_unq_id B 
			WHERE A."ID"=B.col_id AND B.state_code NOT LIKE LEFT('''||UPPER(tbl_nme)||''',2)';
			
			--SELECT A."ID",A."NAME",'GA_POI','ID',A."ID"::text, 
			--'DUPLICATE ID FOUND INTO STATE' ,B.stat_code,'1.1.5' FROM mmi_v180."GA_POI" A,uniqueid_log.master_unq_id B 
			--WHERE A."ID"=B.col_id AND B.stat_code NOT LIKE LEFT('GA_POI',2)
			 
			EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
					
			EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
			RAISE info 'error caught 2.1:%',f1;
			RAISE info 'error caught 2.2:%',f2;
		END;
		RAISE INFO 'DUPLICATE ID FOUND INTO STATE';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	--1.1.6
	-- 123 msec

		BEGIN
			EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
			SELECT C."ID",C."NAME",'''||tbl_nme||''',''ID'',C."ID"::text,''RECORD NOT FOUND INTO NEWLY ADDED OR MASTER TABLE'',''1.1.6'' 
			FROM (SELECT A."ID",A."NAME" FROM (Select "ID","NAME" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
			WHERE "ID"  BETWEEN 43100001 AND 63100000 OR "ID"  BETWEEN 195338001 AND 199000000) 
			AS A LEFT JOIN uniqueid_log.master_unq_id AS B ON A."ID"=B.col_id WHERE B.col_id IS NULL)
			AS C LEFT JOIN uniqueid_log.idlog AS D ON C."ID"=D.munid WHERE D.munid IS NULL';
			
			/*
	        SELECT C."ID",C."NAME",'GA_POI','ID',C."ID"::text,'RECORD NOT FOUND INTO NEWLY ADDED OR MASTER TABLE','1.1.6' 
			FROM (SELECT A."ID",A."NAME" FROM (Select "ID","NAME" FROM mmi_v180."GA_POI" 
			WHERE "ID"  BETWEEN 43100001 AND 63100000 OR "ID"  BETWEEN 195338001 AND 199000000) 
			AS A LEFT JOIN uniqueid_log.master_unq_id AS B ON A."ID"=B.col_id WHERE B.col_id IS NULL)
			AS C LEFT JOIN uniqueid_log.idlog AS D ON C."ID"=D.munid WHERE D.munid IS NULL
			*/
			--SELECT "ID","NAME",'tbl_nme','ID',"ID"::text, 
			--'POI_ID should be extracted FROM MMI Portal only and should not be 0','1.1.3' FROM mmi_v161."DL_POI" WHERE "ID"  NOT BETWEEN 43100001 AND 63100000 
			--AND "ID"  NOT BETWEEN 195338001 AND 199000000 AND ( status NOT IN ('0','5') OR (COALESCE(status,'')='') )
			 
			EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
					
			EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
			RAISE info 'error caught 2.1:%',f1;
			RAISE info 'error caught 2.2:%',f2;
		END;
		RAISE INFO 'RECORD NOT FOUND INTO NEWLY ADDED OR MASTER TABLE';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	--1.1.7
	--63 msec
		BEGIN
			EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
			SELECT A."ID",A."NAME",'''||tbl_nme||''',''ID'',A."ID"::text, 
			''DUPLICATE NEW ADD ID FOUND INTO STATE ''||LEFT(B.editable_table_name,2),''1.1.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" A,uniqueid_log.idlog B 
			WHERE A."ID"=B.munid AND B.stt_id<>A."STT_ID"';
			
			EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
					
			EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
			RAISE info 'error caught 2.1:%',f1;
			RAISE info 'error caught 2.2:%',f2;
		END;
		RAISE INFO 'DUPLICATE NEW ADD ID FOUND INTO STATE';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
end if;

------------------------------------------------------------------------------------------------NAME-------------------------------------------------------------------------------------------------------------------------------------------------
--2.47.297
-- 63 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",''NAME must not be in Upper Case'',''2.47.297'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		-- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND (UPPER("NAME")=("NAME"))';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",''NAME must not be in Upper Case'',''2.47.297'' 
		From (Select "ID","NAME" From '||sch_name||'."'|| UPPER(tbl_nme) ||'" Where (COALESCE("NAME",'''')<>'''')) As A 
		Where A."NAME" Not In (Select "BND_NAME" From '||mst_sch||'."BRAND_LIST") AND UPPER( A."NAME")=A."NAME" AND A."NAME"~''[^\d]'' Order By A."ID" ';
        
		--- SELECT "ID","NAME",'GA_POI','NAME',"NAME",'NAME must not be in Upper Case','2.47.297' 
		--- From (Select "ID","NAME" From mmi_v180."GA_POI" Where (COALESCE("NAME",'')<>'')) As A 
		--- Where A."NAME" Not In (Select "NAME" From mmi_v180."BRAND_LIST") AND UPPER( A."NAME")=A."NAME" AND A."NAME"~'[^\d]' Order By A."ID" 
			
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'NAME must not be in Upper Case';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
--2.47.298
-- 47 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",''All characters must not be in lower case'',''2.47.298'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		-- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND (LOWER("NAME")=("NAME"))';
		--added bipin
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",''All characters must not be in lower case'',''2.47.298'' 
		From(Select * From (Select "ID","NAME","BRAND_NME" From '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "NAME" IS NOT NULL) As A Where A."NAME" Not In (Select "BND_NAME" From '||mst_sch||'."BRAND_LIST")) As B Where LOWER(B."NAME")=(B."NAME") AND B."NAME"~''[^0-9]'' ';	
		
		--- SELECT "ID","NAME",'GA_POI','NAME',"NAME",'All characters must not be in lower case','2.47.298' 
		---From(Select * From (Select "ID","NAME","BRAND_NME" From mmi_v180."GA_POI" WHERE "NAME" IS NOT NULL )As A Where A."NAME" Not In (Select "NAME" From mmi_v180."BRAND_LIST")) As B Where LOWER(B."NAME")=(B."NAME") AND B."NAME"~'[^0-9]'
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'All characters must not be in lower case';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.299
--172 msec
	BEGIN
		sqlQuery = ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",''NAME must not be start with lower case'',''2.47.299'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t1,(Select "NAME" As NAME From '||sch_name||'."'|| UPPER(tbl_nme) ||'" Where(COALESCE("NAME",'''')<>'''')
		Except Select "BND_NAME" From '||mst_sch||'."BRAND_LIST") As t2 Where t1."NAME"=t2.NAME AND SUBSTRING(t2.NAME from 1 For 1) = LOWER(SUBSTRING(TRIM(t2.NAME) from 1 For 1)) AND SUBSTRING(TRIM(t2.NAME) from 1 For 1)~''[^\d]'' AND SUBSTRING(TRIM(t2.NAME) from 1 For 1)~''[a-z]''';	
		
		/*  
        SELECT "ID","NAME",'GA_POI','NAME',"NAME",'NAME must not be start with lower case','2.47.299' 
		FROM mmi_v180."GA_POI" As t1,(Select "NAME" As NAME From mmi_v180."GA_POI" Where(COALESCE("NAME",'')<>'')
		Except Select "NAME" From mmi_v180."BRAND_LIST") As t2 Where t1."NAME"=t2.NAME AND SUBSTRING(t2.NAME from 1 For 1) = LOWER(SUBSTRING(TRIM(t2.NAME) from 1 For 1)) AND SUBSTRING(TRIM(t2.NAME) from 1 For 1)~'[^\d]' AND SUBSTRING(TRIM(t2.NAME) from 1 For 1)~'[a-z]'
		*/
		--RAISE INFO 'sqlQuery->%',sqlQuery;
		EXECUTE sqlQuery;
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'NAME must not be start with lower case';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.247
-- 47 msec 
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", ''Must not have repetitive special character like ’&&’ and ’''''’'',''2.47.247'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		WHERE t."NAME" IS NOT NULL AND t."NAME"~''['''']{2,}|[&]{2,}'' ';
         
		 /*
		 SELECT "ID","NAME",'GA_POI','NAME',"NAME", 'Must not have repetitive special character like ’&&’ and ’''''’','2.47.247' FROM mmi_v180."GA_POI" As t 
		 WHERE t."NAME" IS NOT NULL AND t."NAME"~'['']{2,}|[&]{2,}'
		 */
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Must not have repetitive special character like ’&&’';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.11
-- 47 msec
	BEGIN
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", ''NAME must not have special character except ’&’ and single quote'',''2.47.11'' 
		FROM (Select "ID","NAME" From '||sch_name||'."'|| UPPER(tbl_nme) ||'" Where (COALESCE("NAME",'''')<>'''') ) As A 
		Where A."NAME" Not In (Select "BND_NAME" From '||mst_sch||'."BRAND_LIST") AND (TRIM(A."NAME")~''[^\s\w&'''' +]'' ) ';
		/*
		 SELECT "ID","NAME",'GA_POI','NAME',"NAME", 'NAME must not have special character except ’&’ and single quote','2.47.11' 
		FROM (Select "ID","NAME" From mmi_v180."GA_POI" Where (COALESCE("NAME",'')<>'') ) As A 
		Where A."NAME" Not In (Select "NAME" From mmi_v180."BRAND_LIST") AND (TRIM(A."NAME")~'[^\s\w&'' +]' )
		*/
		
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		-- SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", ''NAME must not have special character except ’&’ and single quote'',''2.47.11'' 
		-- FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t1,(Select "NAME" As p_nme From '||sch_name||'."'|| UPPER(tbl_nme) ||'" Where (COALESCE("NAME",'''')<>'''') 
		-- Except Select "NAME" From '||mst_sch||'."BRAND_LIST") As t2 Where t1."NAME"=t2.p_nme AND (TRIM(t1."NAME")~''[^\s\w&'''' +]'' )';

-- 		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
-- 		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", ''NAME must not have special character except ’&’ and single quote'',''2.47.11'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
-- 		 WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND t."NAME" IS NOT NULL AND (t."NAME"~''[^&\s\w-]'') ';

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'NAME must not have special character except ’&’ and single quote';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.273
-- 47 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", ''Special character must not present at start and End of name'',''2.47.273'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ("NAME" IS NOT NULL) AND
		-- "NAME" LIKE ''&%'' OR "NAME" LIKE ''%&'' OR "NAME" LIKE ''''''%'' OR "NAME" like ''%'''''' ';	
		--ADDED BIPIN
		sqlQuery = ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", ''NAME should not start and end with special character '',''2.47.273'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t1, (Select "NAME" As NAME FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE ("NAME" IS NOT NULL) 
		Except Select "BND_NAME" FROM '||mst_sch||'."BRAND_LIST") As t2 WHERE t1."NAME"=t2.NAME AND (SUBSTRING(t2.NAME from 1 For 1)~''[^0-9A-Za-z]'' AND Right("NAME",1)~''[^0-9A-Za-z]'') ';
		
		---SELECT "ID","NAME",'GA_POI','NAME',"NAME", 'NAME should not start and end with special character', '2.47.273' 
		---FROM mmi_v180."GA_POI" As t1, (Select "NAME" As NAME FROM mmi_v180."GA_POI" WHERE (status NOT IN ('0','5') OR (COALESCE(status,'')='') ) AND ("NAME" IS NOT NULL) 
		---Except Select "NAME" FROM mmi_v180."BRAND_LIST") As t2 WHERE t1."NAME"=t2.NAME AND (SUBSTRING(t2.NAME from 1 For 1)~'[^0-9A-Za-z]' AND Right("NAME",1)~'[^0-9A-Za-z]')
		--RAISE INFO 'sqlQuery ->%',sqlQuery;
		EXECUTE sqlQuery;
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'NAME should not start and end with special character';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.1
--2.47.344
--391 msec
--of", "for" ,"and", "by", "to", "or" must be in lower case add this review check
	BEGIN
		EXECUTE ' With sel1 As (Select "NAME" as mname, unnest(string_to_array(replace(replace(replace(replace(replace("NAME",'' of '','' ''),'' and '','' ''),'' for '','' ''),'' By '','' ''),'' to '','' ''),'' OR '','' '')) as name,"ID" as id 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "NAME" NOT IN (SELECT "BND_NAME" FROM '||mst_sch||'."BRAND_LIST"))
		INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT id,mname,'''||tbl_nme||''',''NAME'',mname,''NAME Not In Proper Case'',''2.47.344'' 
		FROM sel1 WHERE name<>INITCAP(name) and name<>upper(name) ';
		 
		 /* NEW QUERY
		 
		 With sel1 As (Select "NAME" as mname, unnest(string_to_array(replace(replace(replace(replace(replace(replace(replace(replace("NAME",' of ',' '),' and ',' '),' for ',' '),' by ',' '),' to ',' '),' in ',' '),' OR ',' '),' at ',' '),' ')) as name,"ID" as id 
		 FROM mmi_master."DL_POI" WHERE "NAME" NOT IN (SELECT "NAME" FROM mmi_master."BRAND_LIST"))
		SELECT id,mname,'NAME Not In Proper Case:'||name FROM sel1 WHERE name<>INITCAP(name) and name<>upper(name)
		 
			OLD QUERY
		   SELECT t1."ID",t1."NAME",'GA_POI','NAME',t1."NAME", 
		'NAME must be in proper case AND Keywords of, for , and , to, by, at should be lowercase in NAME','1.2.1' FROM 
		( SELECT replace(replace(replace(replace(replace(replace(replace(replace(t."NAME",' of ',' '),' and ',' '),' for ',' '),' By ',' '),' to ',' '),' in ',' '),' OR ',' '),' at ',' '), t.* As NAME 
		 FROM ( SELECT * FROM mmi_v180."GA_POI" WHERE "NAME"<>INITCAP("NAME") AND "NAME" NOT IN ( SELECT "NAME" FROM mmi_v180."BRAND_LIST"))AS t ) t1  
		 WHERE t1.replace<>INITCAP(t1.replace);
		 */ 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'NAME must be in proper case AND Keywords of, for , and , to, by, at should be lowercase in NAME';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-------------------------------------------------	NAME WITH POPLR_NME-----------------------------------------------------------------
--1.2.18
--328 msec
	BEGIN
		--ADED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME", ''NAME should not contain Poplr_Nme'',''1.2.18'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE ((COALESCE("NAME",'''')<>'''') AND (LOWER(TRIM("NAME")) LIKE LOWER(TRIM("POPLR_NME")) ))';

		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME", 
		-- ''NAME should not contain POPLR_NME, ALIAS_1, ALIAS_2 & ALIAS_3 '',''1.2.18'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
                	
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ((COALESCE("NAME",'''')<>'''') AND (LOWER(TRIM("NAME")) LIKE ''%''||LOWER(TRIM("POPLR_NME"))||''%'' ))';

		--SELECT "ID","NAME",'tbl_nme','POPLR_NME',"POPLR_NME",status, 
		--'NAME should not contain POPLR_NME, ALIAS_1, ALIAS_2 & ALIAS_3 ','1.2.18' FROM mmi_v180."DL_POI" 	
		-- WHERE (status NOT IN ('0','5') OR (COALESCE(status,'')='') ) AND ((COALESCE("NAME",'')<>'') AND (LOWER(TRIM("NAME")) LIKE '%'||LOWER(TRIM("POPLR_NME"))||'%' ))
		 
				
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'NAME should not contain POPLR_NME, ALIAS_1, ALIAS_2 & ALIAS_3';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-------------------------------------------------	NAME WITH ALIAS_1-----------------------------------------------------------------
--1.2.18
-- 500 msec
	BEGIN
		--ADED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''','''',"ALIAS_1", ''NAME should not contain Alias_1'',''1.2.18'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE ((COALESCE("ALIAS_1",'''')<>'''') AND (LOWER(TRIM("NAME")) LIKE LOWER(TRIM("ALIAS_1")) ))';
		
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1", 
		-- ''NAME should not contain POPLR_NME, ALIAS_1, ALIAS_2 & ALIAS_3 '',''1.2.18'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
                	
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ((COALESCE("NAME",'''')<>'''') AND (LOWER(TRIM("NAME")) LIKE ''%''||LOWER(TRIM("ALIAS_1"))||''%'' ))';

		 --SELECT "ID","NAME",'tbl_nme','ALIAS_1',"ALIAS_1", 
		--'NAME should not contain POPLR_NME, ALIAS_1, ALIAS_2 & ALIAS_3 ','1.2.18' FROM mmi_v161."DL_POI"                 	
		 --WHERE ((COALESCE("NAME",'')<>'') AND (LOWER(TRIM("NAME")) LIKE '%'||LOWER(TRIM("ALIAS_1"))||'%' ))
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'NAME should not contain Alias_1';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-------------------------------------------------	NAME WITH ALIAS_2-----------------------------------------------------------------
--1.2.18
--485 msec
	BEGIN
		--ADED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2", ''NAME should not contain Alias_2'',''1.2.18'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE ((COALESCE("ALIAS_2",'''')<>'''') AND (LOWER(TRIM("NAME")) LIKE LOWER(TRIM("ALIAS_2")) ))';

		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2", 
		-- ''NAME should not contain POPLR_NME, ALIAS_1, ALIAS_2 & ALIAS_3 '',''1.2.18'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"                 	
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ((COALESCE("NAME",'''')<>'''') AND (LOWER(TRIM("NAME")) LIKE ''%''||LOWER(TRIM("ALIAS_2"))||''%'' ))';

		--SELECT "ID","NAME",'tbl_nme','ALIAS_2',"ALIAS_2", 
		--'NAME should not contain POPLR_NME, ALIAS_1, ALIAS_2 & ALIAS_3 ','1.2.18' FROM mmi_v180."DL_POI" 
		-- WHERE ((COALESCE("NAME",'')<>'') AND (LOWER(TRIM("NAME")) LIKE '%'||LOWER(TRIM("ALIAS_2"))||'%' ))
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'NAME should not contain POPLR_NME, ALIAS_1, ALIAS_2 & ALIAS_3';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-------------------------------------------------	NAME WITH ALIAS_3-----------------------------------------------------------------
--1.2.18
--484 msec
	BEGIN	
		--ADED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3", ''NAME should not contain Alias_3'',''1.2.18'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE ((COALESCE("ALIAS_3",'''')<>'''') AND (LOWER(TRIM("NAME")) LIKE LOWER(TRIM("ALIAS_3")) ))';
		
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3", 
		-- ''NAME should not contain POPLR_NME, ALIAS_1, ALIAS_2 & ALIAS_3 '',''1.2.18'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"                 	
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ((COALESCE("NAME",'''')<>'''') AND (LOWER(TRIM("NAME")) LIKE ''%''||LOWER(TRIM("ALIAS_3"))||''%'' ))';

		-- SELECT "ID","NAME",'tbl_nme','ALIAS_3',"ALIAS_3", 
		--'NAME should not contain POPLR_NME, ALIAS_1, ALIAS_2 & ALIAS_3 ','1.2.18' FROM mmi_v180."DL_POI"                 	
		-- WHERE ((COALESCE("NAME",'')<>'') AND (LOWER(TRIM("NAME")) LIKE '%'||LOWER(TRIM("ALIAS_3"))||'%' ))
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'NAME should not contain POPLR_NME, ALIAS_1, ALIAS_2 & ALIAS_3';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
-----------------------------------------------------------------------NAME WITH BRANCH_NME------------------------------------------------	
--1.2.18
--484 msec
	BEGIN	
		--ADED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", ''NAME should not contain BRANCH_NME'',''1.2.18'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE ((COALESCE("BRANCH_NME",'''')<>'''') AND (LOWER(TRIM("NAME")) LIKE LOWER(TRIM("BRANCH_NME")) ))';
		
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3", 
		-- ''NAME should not contain POPLR_NME, ALIAS_1, ALIAS_2 & ALIAS_3 '',''1.2.18'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"                 	
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ((COALESCE("NAME",'''')<>'''') AND (LOWER(TRIM("NAME")) LIKE ''%''||LOWER(TRIM("ALIAS_3"))||''%'' ))';

		-- SELECT "ID","NAME",'tbl_nme','ALIAS_3',"ALIAS_3", 
		--'NAME should not contain POPLR_NME, ALIAS_1, ALIAS_2 & ALIAS_3 ','1.2.18' FROM mmi_v180."DL_POI"                 	
		-- WHERE ((COALESCE("NAME",'')<>'') AND (LOWER(TRIM("NAME")) LIKE '%'||LOWER(TRIM("ALIAS_3"))||'%' ))
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'NAME should not contain POPLR_NME, ALIAS_1, ALIAS_2 & ALIAS_3';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

-------------------------------------------------	NAME WITH ADDRESS-----------------------------------------------------------------
--1.2.19
--735
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",''NAME should not contain ADDRESS'',''1.2.19'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE (COALESCE("NAME",'''')<>'''' AND COALESCE("ADDRESS",'''')<>'''') AND (lower(trim("NAME")) LIKE ''||lower(trim("ADDRESS"))||'' )';

		-- SELECT "ID","NAME",'tbl_nme','NAME',"NAME", 
		--'NAME should not contain ADDRESS','1.2.19' FROM mmi_v180."DL_POI" WHERE 
		--  (lower(trim("NAME")) ILIKE ''||lower(trim("ADDRESS"))||'' )
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'NAME should not contain ADDRESS';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	
	
----------------------------------------------------NAME------------------------------------------------------------------
--1.2.20
-- 78 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		''Private Ltd should be written As Pvt Ltd'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER("NAME") LIKE ''% private ltd'' OR 
		LOWER("NAME") LIKE ''% private ltd % '' OR LOWER("NAME") LIKE ''private ltd %'') ';

		--SELECT "ID","NAME",'GA_POI','NAME',"NAME", 
		--'Private Ltd should be written As Pvt Ltd','1.2.20' FROM mmi_v180."GA_POI" WHERE (LOWER("NAME") LIKE '% private ltd' OR 
		--LOWER("NAME") LIKE '% private ltd % ' OR LOWER("NAME") LIKE 'private ltd %')

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Private Ltd should be written As Pvt Ltd';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.20
--985 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
             SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		     ''Govt should be written As Government'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER("NAME") LIKE ''% govt'' 
		      OR LOWER("NAME") LIKE ''% govt %'' OR LOWER("NAME") LIKE ''govt %'') ';

		-- SELECT "ID","NAME",'tbl_nme','NAME',"NAME", 
		--'Govt should be written As Government','1.2.20' FROM mmi_v180."DL_POI" WHERE (LOWER("NAME") LIKE '% govt' 
		-- OR LOWER("NAME") LIKE '% govt %' OR LOWER("NAME") LIKE 'govt %')

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Govt should be written As Governmen';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.20
--1 sec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
                 SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		        ''Govt should be written As Government'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER("NAME") LIKE ''% govt'' 
		        OR LOWER("NAME") LIKE ''% govt %'' OR LOWER("NAME") LIKE ''govt %'') ';

		-- SELECT "ID","NAME",'tbl_nme','NAME',"NAME", 
		--'Govt should be written As Government','1.2.20' FROM mmi_v180."DL_POI" WHERE (LOWER("NAME") LIKE '% govt' 
		-- OR LOWER("NAME") LIKE '% govt %' OR LOWER("NAME") LIKE 'govt %')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Govt should be written As Government';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.20
-- 78 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		-- ''Sr Sec should be written As Seni OR Secondary'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND (LOWER("NAME") LIKE ''% sr sec'' 
		 -- OR LOWER("NAME") LIKE ''% sr sec %'' OR LOWER("NAME") LIKE ''sr sec %'') ';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		''Sr Sec should be written As Senior Secondary'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER("NAME") LIKE ''% sr sec'' 
		 OR LOWER("NAME") LIKE ''% sr sec %'' OR LOWER("NAME") LIKE ''sr sec %'') ';
		 
		 /*
		 SELECT "ID","NAME",'GA_POI','NAME',"NAME", 
		'Sr Sec should be written As Senior Secondary','1.2.20' FROM mmi_v180."GA_POI" WHERE (LOWER("NAME") LIKE '% sr sec' 
		 OR LOWER("NAME") LIKE '% sr sec %' OR LOWER("NAME") LIKE 'sr sec %')
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Sr Sec should be written As Senior Secondary';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.20
--94 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		''Bldg should be written As Building'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER("NAME") LIKE ''% bldg''  
		 OR LOWER("NAME") LIKE ''% bldg %'' OR LOWER("NAME") LIKE ''bldg %'') ';
		 
		 /*
		   SELECT "ID","NAME",'GA_POI','NAME',"NAME", 
		'Bldg should be written As Building','1.2.20' FROM mmi_v180."GA_POI" WHERE (LOWER("NAME") LIKE '% bldg'  
		 OR LOWER("NAME") LIKE '% bldg %' OR LOWER("NAME") LIKE 'bldg %')
		 */
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Bldg should be written As Building';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.20
-- 78 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
				SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
				''Co-op should be written As Cooperative'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER("NAME") LIKE ''% co-op'' 
				OR LOWER("NAME") LIKE ''% co-op %'' OR LOWER("NAME") LIKE ''co-op %'') ';
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Co-op should be written As Cooperative';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.20
--78 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		''Coop should be written As Cooperative'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER("NAME") LIKE ''% coop'' 
		 OR LOWER("NAME") LIKE ''% coop %'' OR LOWER("NAME") LIKE ''coop %'') ';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','NAME',"NAME", 
		'Co-op should be written As Cooperative','1.2.20' FROM mmi_v180."GA_POI" WHERE (LOWER("NAME") LIKE '% co-op' 
		 OR LOWER("NAME") LIKE '% co-op %' OR LOWER("NAME") LIKE 'co-op %')
		 */
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Co-op should be written As Cooperative';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.20
--984 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		''Corporation Housing Society should be written As Cooperative Housing Society'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE (LOWER("NAME") LIKE ''% corporation housing society'' OR LOWER("NAME") 
		LIKE ''% corporation housing society %'' OR LOWER("NAME") LIKE ''corporation housing society %'') ';

		--SELECT "ID","NAME",'tbl_nme','NAME',"NAME", 
		--'Corporation Housing Society should be written As Cooperative Housing Society','1.2.20' FROM mmi_v161."DL_POI" 
		-- WHERE (LOWER("NAME") LIKE '% corporation housing society' OR LOWER("NAME") 
		--LIKE '% corporation housing society %' OR LOWER("NAME") LIKE 'corporation housing society %')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Corporation Housing Society should be written As Cooperative Housing Society';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.20
--93 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)

		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		''Ind should be written As Industrial'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER("NAME") LIKE ''% ind %'' 
		 OR LOWER("NAME") LIKE ''ind %'' OR LOWER("NAME") LIKE ''% ind'') ';
		 
		 -- SELECT "ID","NAME",'GA_POI','NAME',"NAME", 
		 -- 'Ind should be written As Industrial','1.2.20' FROM mmi_v180."GA_POI" WHERE (LOWER("NAME") LIKE '% ind %' 
		 -- OR LOWER("NAME") LIKE 'ind %' OR LOWER("NAME") LIKE '% ind')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Ind should be written As Industrial';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.20
--94 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		''Intn should be written As International'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER("NAME") LIKE ''% intn'' 
		 OR LOWER("NAME") LIKE ''% intn %'' OR LOWER("NAME") LIKE ''intn %'') ';
		 
		 -- SELECT "ID","NAME",'GA_POI','NAME',"NAME", 
		 -- 'Intn should be written As International','1.2.20' FROM mmi_v180."GA_POI" WHERE (LOWER("NAME") LIKE '% intn' 
		 -- OR LOWER("NAME") LIKE '% intn %' OR LOWER("NAME") LIKE 'intn %')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Intn should be written As International';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.20
--78 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		''Coll should be written As College'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER("NAME") LIKE ''% coll'' 
		 OR LOWER("NAME") LIKE ''% coll %'' OR LOWER("NAME") LIKE ''coll %'') ';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','NAME',"NAME", 
		  'Coll should be written As College','1.2.20' FROM mmi_v180."GA_POI" WHERE (LOWER("NAME") LIKE '% coll' 
		  OR LOWER("NAME") LIKE '% coll %' OR LOWER("NAME") LIKE 'coll %')
		 */
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Coll should be written As College';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.20
-- 78 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		''Engg should be written As Engineering'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER("NAME") LIKE ''engg %'' 
		 OR LOWER("NAME") LIKE ''% engg %'' OR LOWER("NAME") LIKE ''% engg'') ';
		 
		---SELECT "ID","NAME",'GA_POI','NAME',"NAME", 
		---'Engg should be written As Engineering','1.2.20' FROM mmi_v180."GA_POI" WHERE (LOWER("NAME") LIKE 'engg %' 
		--- OR LOWER("NAME") LIKE '% engg %' OR LOWER("NAME") LIKE '% engg') 
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Engg should be written As Engineering';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-- --1.2.20
-- --- 78 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		
		-- SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		-- ''Bazar should be written As Bazaar'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER("NAME") LIKE ''bazar %'' 
		 -- OR LOWER("NAME") LIKE ''% bazar %'' OR LOWER("NAME") LIKE ''% bazar'') ';
		 
		 -- --SELECT "ID","NAME",'GA_POI','NAME',"NAME", 
		 -- --'Bazar should be written As Bazaar','1.2.20' FROM mmi_v180."GA_POI" WHERE (LOWER("NAME") LIKE 'bazar %' 
		 -- --OR LOWER("NAME") LIKE '% bazar %' OR LOWER("NAME") LIKE '% bazar')
		 
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'Bazar should be written As Bazaar';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.20
-- 78 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		''Bharat Gas should be written As Bharatgas'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER("NAME") LIKE ''bharat gas %'' 
		 OR LOWER("NAME") LIKE ''% bharat gas %'' OR LOWER("NAME") LIKE ''% bharat gas'') ';
		/*
		 SELECT "ID","NAME",'GA_POI','NAME',"NAME", 
		'Bharat Gas should be written As Bharatgas','1.2.20' FROM mmi_v180."GA_POI" WHERE (LOWER("NAME") LIKE 'bharat gas %' 
		 OR LOWER("NAME") LIKE '% bharat gas %' OR LOWER("NAME") LIKE '% bharat gas')
		*/
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Bharat Gas should be written As Bharatgas';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.20
--78 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		''Photostate should be written As Photostat'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER("NAME") LIKE ''photostate %'' 
		 OR LOWER("NAME") LIKE ''% photostate %'' OR LOWER("NAME") LIKE ''% photostate'') ';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','NAME',"NAME", 
		'Photostate should be written As Photostat','1.2.20' FROM mmi_v180."GA_POI" WHERE (LOWER("NAME") LIKE 'photostate %' 
		 OR LOWER("NAME") LIKE '% photostate %' OR LOWER("NAME") LIKE '% photostate')
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Photostate should be written As Photostat';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.20
-- 78 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		''Icecream should be written As Ice Cream'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t WHERE (LOWER("NAME") LIKE ''icecream %'' 
		 OR LOWER("NAME") LIKE ''% icecream %'' OR LOWER("NAME") LIKE ''% icecream'') ';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','NAME',"NAME", 
		'Icecream should be written As Ice Cream','1.2.20' FROM mmi_v180."GA_POI" As t WHERE (LOWER("NAME") LIKE 'icecream %' 
		 OR LOWER("NAME") LIKE '% icecream %' OR LOWER("NAME") LIKE '% icecream')
		 */
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Icecream should be written As Ice Cream';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.20
-- 93 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		''Xray should be written As X Ray'',''1.2.20'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t WHERE (LOWER("NAME") LIKE ''xray %'' OR LOWER("NAME") LIKE ''% xray %''  
		 OR LOWER("NAME") LIKE ''% xray'') ';
		 /*
		 SELECT "ID","NAME",'GA_POI','NAME',"NAME", 
		'Xray should be written As X Ray','1.2.20' FROM mmi_v180."GA_POI" As t WHERE (LOWER("NAME") LIKE 'xray %' OR LOWER("NAME") LIKE '% xray %'  
		 OR LOWER("NAME") LIKE '% xray')
		 */
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Xray should be written As X Ray';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

-- --1.2.24
-- --156 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		-- SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",''NAME must not contain Showroom and Dealer words'',''1.2.24''
		-- FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		-- WHERE COALESCE("BRAND_NME",'''')<>'''' AND "FTR_CRY" IN (''SHPRTC'',''SHPAUT'',''SHPREP'') AND ( (LOWER("NAME") LIKE ''showroom %'' 
		 -- OR LOWER("NAME") LIKE ''% showroom'' OR  LOWER("NAME") LIKE ''% dealer %'' 
		 -- OR LOWER("NAME") LIKE ''% dealer'')) '; 
         -- /*
		 -- (FTR_CRY SHPRTC,SHPAUT,SHPREP) AND  BRAND_NAME <>''(MODIFIED PART)
		 -- SELECT "ID","NAME",'GA_POI','NAME',"NAME", 
		-- 'NAME must not contain Showroom and Dealer words','1.2.24' FROM mmi_v180."GA_POI" WHERE (LOWER("NAME") LIKE 'showroom %' 
		 -- OR LOWER("NAME") LIKE '% showroom' OR LOWER("NAME") LIKE '% showroom %' OR LOWER("NAME") LIKE 'dealer %' OR LOWER("NAME") LIKE '% dealer %' 
		 -- OR LOWER("NAME") LIKE '% dealer')
		 -- */
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'NAME must not contain Showroom and Dealer words';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-----------------------------------------------------NAME WITH FTR_CRY --------------------------------------------------------------------------------------
--1.2.25
--1.3.5 --MAPINFO QC
-- 63 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''FTR_CRY'',"FTR_CRY", ''NAME ending with ‘Service Centre’ and ‘Service Centre and Spare Parts’ should be in ‘SHPREP‘ or ‘REPBMW‘ categories'',''1.2.25'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE COALESCE("NAME",'''')<>'''' AND ((LOWER("NAME")~*''.+Service Centre$'' OR LOWER("NAME")~*''.+Service Centre and Spare Parts$'') AND (UPPER("FTR_CRY") NOT  IN (''SHPREP'',''SHPRTC'')) ) ';
        
		/*
		 SELECT * FROM mmi_master."DL_POI"
		 WHERE "NAME" IS NOT NULL AND ((LOWER("NAME")~*'.+Service Centre$' OR LOWER("NAME")~*'.+Service Centre and Spare Parts$') AND (UPPER("FTR_CRY")NOT  IN ('SHPREP','SHPRTC')) 
		AND UPPER("SUB_CRY") NOT IN ('STRSRV'))
		*/
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'NAME ending with ‘Service Centre’ and ‘Service Centre and Spare Parts’ should be in ‘SHPREP‘ or ‘REPBMW‘ categories';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-----------------------------------------------------NAME WITH SUB_CRY --------------------------------------------------------------------------------------
--1.2.26
--453 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''SUB_CRY'',"SUB_CRY", 
		''If NAME ends with Charging Station then its sub-category should be TRNECS OR CGSBMW'',''1.2.26'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE ((LOWER("NAME") LIKE ''% charging station'') AND (COALESCE("SUB_CRY",'''')<>''TRNECS'' AND COALESCE("SUB_CRY",'''')<>''CGSBMW''))';

		-- SELECT "ID","NAME",'tbl_nme','SUB_CRY',"SUB_CRY", 
		-- 'If NAME ends with Charging Station then its sub-category should be TRNECS OR CGSBMW','1.2.26' 
		-- FROM mmi_master."DL_POI" 
		-- WHERE ((LOWER("NAME") LIKE '% charging station') AND (COALESCE("SUB_CRY",'')<>'TRNECS' AND COALESCE("SUB_CRY")<>'CGSBMW' ))		 
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If NAME ends with Charging Station then its sub-category should be TRNECS OR CGSBMW';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

--1.2.27
--312 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''SUB_CRY'',"SUB_CRY", 
		''If NAME contains BMW then its sub-category must be filled with one of these categories: AUTBMW, REPBMW, PWNBMW, CGSBMW and BIKBMW'',''1.2.27'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((LOWER("NAME") LIKE ''% bmw %'') OR (LOWER("NAME") LIKE ''bmw %'') OR (LOWER("NAME") LIKE ''% bmw'')) AND (("SUB_CRY"<>''AUTBMW'') AND ("SUB_CRY"<>''REPBMW'') 
		 AND ("SUB_CRY"<>''PWNBMW'') AND ("SUB_CRY"<>''CGSBMW'') AND ("SUB_CRY"<>''BIKBMW''))';

		-- SELECT "ID","NAME",'tbl_nme','SUB_CRY',"SUB_CRY", 
		--'If NAME contains BMW then its sub-category must be filled with one of these categories: AUTBMW, REPBMW, PWNBMW, CGSBMW and BIKBMW','1.2.27' FROM mmi_v161."DL_POI" 
		-- WHERE (status NOT IN ('0','5') OR (COALESCE(status,'')='') ) AND ((LOWER("NAME") LIKE '% bmw %') OR (LOWER("NAME") LIKE 'bmw %') OR (LOWER("NAME") LIKE '% bmw')) AND (("SUB_CRY"<>'AUTBMW') AND ("SUB_CRY"<>'REPBMW') 
		-- AND ("SUB_CRY"<>'PWNBMW') AND ("SUB_CRY"<>'CGSBMW') AND ("SUB_CRY"<>'BIKBMW'))
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If NAME contains BMW then its sub-category must be filled with one of these categories: AUTBMW, REPBMW, PWNBMW, CGSBMW and BIKBMW';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-----------------------------------------------------NAME WITH FTR_CRY --------------------------------------------------------------------------------------
--1.2.28
-- 829 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''FTR_CRY'',"FTR_CRY", 
		''If NAME ends with Tyre OR Tyres then its main category should be SHPSTR'',''1.2.28'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((LOWER("NAME") LIKE ''% tyre'' OR LOWER("NAME") LIKE ''% tyres'') AND ("FTR_CRY"<>''SHPSTR''))';

		-- SELECT "ID","NAME",'tbl_nme','FTR_CRY',"FTR_CRY", 
		--'If NAME ends with Tyre OR Tyres then its main category should be SHPSTR','1.2.28' FROM mmi_v161."DL_POI" 
		-- WHERE ((LOWER("NAME") LIKE '% tyre' OR LOWER("NAME") LIKE '% tyres') AND ("FTR_CRY"<>'SHPSTR'))
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If NAME ends with Tyre OR Tyres then its main category should be SHPSTR';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-------------------------------------------------------NAME --------------------------------------------------------------------------------------
--1.2.3
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", 
		''Double Spaces are not allowed'',''1.2.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE ("NAME" LIKE ''%  %'') ';
		/*
		 SELECT "ID","NAME",'GA_POI','NAME',"NAME", 
		'Double Spaces are not allowed','1.2.3' FROM mmi_v180."GA_POI" WHERE ("NAME" LIKE '%  %')
		*/
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Double Spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.32
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",
		''Start spaces and end spaces are not allowed'',''1.2.32'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "NAME" LIKE ''% '' OR "NAME" LIKE '' %'' ';
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Start spaces and end spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
--1.2.3
--31 msec
---2.47.239
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", ''Extract the records where charecter length is greater then 95. reveiw the name for these records.'',''2.47.239'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE COALESCE("NAME",'''') <> '''' AND LENGTH("NAME")>95 ';
		
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Double Spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	
---2.47.244
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", ''Extract the records where charecter length is greater then 245 including Name, Poplr_Nme, Alias_1, Alias_2, Alias_3. reveiw the name for these records'',''2.47.244'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE LENGTH(COALESCE("NAME",'''')||COALESCE("POPLR_NME",'''')||COALESCE("ALIAS_1",'''')||COALESCE("ALIAS_2",'''') ||COALESCE("ALIAS_3",''''))>245 ';
		
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Double Spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;		
	
-------------------------------------------------NAME WITH SUB_CRY --------------------------------------------------------------------------------------
--1.2.33
---109 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''SUB_CRY'',"SUB_CRY", 
		''If NAME contains ATM then SUB_CRY should be FINATM'',''1.2.33'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((LOWER("NAME")=''atm'' OR LOWER("NAME") LIKE ''% atm %'' OR LOWER("NAME") LIKE ''atm %'' OR LOWER("NAME") LIKE ''% atm'') AND LOWER("SUB_CRY")<>''finatm'') ';
		/*
		SELECT "ID","NAME",'GA_POI','SUB_CRY',"SUB_CRY", 
		'If NAME contains ATM then SUB_CRY should be FINATM','1.2.33' FROM mmi_v180."GA_POI" 
		 WHERE ((LOWER("NAME")='atm' OR LOWER("NAME") LIKE '% atm %' OR LOWER("NAME") LIKE 'atm %' OR LOWER("NAME") LIKE '% atm') AND LOWER("SUB_CRY")<>'finatm')
		*/
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If NAME contains ATM then SUB_CRY should be FINATM';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.33
-- 110 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''SUB_CRY'',"SUB_CRY", 
		''If NAME does not contain ATM then SUB_CRY should not be FINATM'',''1.2.33'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((LOWER("NAME")<>''atm'' AND LOWER("NAME") NOT LIKE ''% atm %'' AND LOWER("NAME") NOT LIKE ''atm %'' AND LOWER("NAME") NOT LIKE ''% atm'') AND LOWER("SUB_CRY")=''finatm'') ';
		
		--SELECT "ID","NAME",'GA_POI','SUB_CRY',"SUB_CRY", 
		--'If NAME does not contain ATM then SUB_CRY should not be FINATM','1.2.33' FROM mmi_v180."GA_POI" 
		--- WHERE ((LOWER("NAME")<>'atm' AND LOWER("NAME") NOT LIKE '% atm %' AND LOWER("NAME") NOT LIKE 'atm %' AND LOWER("NAME") NOT LIKE '% atm') AND LOWER("SUB_CRY")='finatm');
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If NAME does not contain ATM then SUB_CRY should not be FINATM';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-------------------------------------------------------NAME --------------------------------------------------------------------------------------	
---2.47.339
--- ADDED ASHU Occurance of Same character thrice and more than thrice is not allowed
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",
		''Occurance of Same character thrice and more than thrice is not allowed'',''2.47.339'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE regexp_replace("NAME",''[0-9/, ]'','''')~''(.)\1{2}'' AND "NAME"~''(.)\1{2}'' ';
		
		--SELECT "ID","NAME" FROM mmi_v180."DL_POI" WHERE regexp_replace("NAME",'[0-9/, ]','')~'(.)\1{2}' AND "NAME"~'(.)\1{2}'
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'NAME Occurance of Same character thrice and more than thrice is not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
-----2.47.288	
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT tab1."ID",tab1."NAME",'''||tbl_nme||''',''NAME'',tab1."NAME",''Multiple records at same location'',''2.47.288'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" tab1,'||sch_name||'."'|| UPPER(tbl_nme) ||'" tab2
		 where coalesce(tab2."ALIAS_1",'''') <> '''' AND tab1."NAME" = tab2."ALIAS_1" AND tab1."SP_GEOMETRY" = tab2."SP_GEOMETRY" ';
		
		-- SELECT tab1."ID",tab1."NAME",tab1."ALIAS_1" FROM mmi_master."DL_POI" AS tab1,mmi_master."DL_POI" as tab2 where coalesce(tab2."ALIAS_1",'') <> ''
		-- AND tab1."NAME" = tab2."ALIAS_1" AND tab1."SP_GEOMETRY" = tab2."SP_GEOMETRY"

		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
		
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Start spaces and end spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	
-----2.47.288	
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT tab1."ID",tab1."NAME",'''||tbl_nme||''',''NAME'',tab1."NAME",''Multiple records at same location'',''2.47.288'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" tab1,'||sch_name||'."'|| UPPER(tbl_nme) ||'" tab2
		where coalesce(tab2."ALIAS_2",'''') <> '''' AND tab1."NAME" = tab2."ALIAS_2" AND tab1."SP_GEOMETRY" = tab2."SP_GEOMETRY" ';
		
		-- SELECT tab1."ID",tab1."NAME",tab1."ALIAS_1" FROM mmi_master."DL_POI" AS tab1,mmi_master."DL_POI" as tab2 where coalesce(tab2."ALIAS_1",'') <> ''
		-- AND tab1."NAME" = tab2."ALIAS_1" AND tab1."SP_GEOMETRY" = tab2."SP_GEOMETRY"

		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
		
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Start spaces and end spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;		
	
-----2.47.288	
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT tab1."ID",tab1."NAME",'''||tbl_nme||''',''NAME'',tab1."NAME",''Multiple records at same location'',''2.47.288'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" tab1,'||sch_name||'."'|| UPPER(tbl_nme) ||'" tab2
		 where coalesce(tab2."ALIAS_3",'''') <> '''' AND tab1."NAME" = tab2."ALIAS_3" AND tab1."SP_GEOMETRY" = tab2."SP_GEOMETRY" ';
		
		-- SELECT tab1."ID",tab1."NAME",tab1."ALIAS_1" FROM mmi_master."DL_POI" AS tab1,mmi_master."DL_POI" as tab2 where coalesce(tab2."ALIAS_1",'') <> ''
		-- AND tab1."NAME" = tab2."ALIAS_1" AND tab1."SP_GEOMETRY" = tab2."SP_GEOMETRY"

		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
		
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Start spaces and end spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
-----2.47.288	
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT tab1."ID",tab1."NAME",'''||tbl_nme||''',''NAME'',tab1."NAME",''Multiple records at same location'',''2.47.288'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" tab1,'||sch_name||'."'|| UPPER(tbl_nme) ||'" tab2
		 where coalesce(tab2."POPLR_NME",'''') <> '''' AND tab1."NAME" = tab2."POPLR_NME" AND tab1."SP_GEOMETRY" = tab2."SP_GEOMETRY" ';
		
		-- SELECT tab1."ID",tab1."NAME",tab1."ALIAS_1" FROM mmi_master."DL_POI" AS tab1,mmi_master."DL_POI" as tab2 where coalesce(tab2."POPLR_NME",'') <> ''
		-- AND tab1."NAME" = tab2."POPLR_NME" AND tab1."SP_GEOMETRY" = tab2."SP_GEOMETRY"

		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
		
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Start spaces and end spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	
	
	
----------------------------------------------------------------------------------------------POPLR_NME-----------------------------------------------------------------------------------------------------------------------------------------------
--2.47.300
-- 110 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",''POPLR_NME must not be in Upper Case'',''2.47.300'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (UPPER("POPLR_NME")=("POPLR_NME"))';
		 
		 /*
		  
			SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME",'POPLR_NME must not be in Upper Case','2.47.300' FROM mmi_v180."GA_POI" As t 
		  WHERE (UPPER("POPLR_NME")=("POPLR_NME"))
		 */
		 
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	
-- --2.47.300
-- -- 63 msec
	-- BEGIN
		-- -- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- -- SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",''NAME must not be in Upper Case'',''2.47.297'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND (UPPER("NAME")=("NAME"))';
		-- --ADDED BIPIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",''NAME must not be in PROPER Case'',''2.47.300'' 
		-- From (Select "ID","NAME" From '||sch_name||'."'|| UPPER(tbl_nme) ||'" Where (COALESCE("NAME",'''')<>'''')) As A 
		-- Where A."NAME" Not In (Select "NAME" From '||mst_sch||'."BRAND_LIST") AND UPPER( A."NAME")=A."NAME" AND A."NAME"~''[^\d]'' Order By A."ID" ';
        
		-- --- SELECT "ID","NAME",'GA_POI','NAME',"NAME",'NAME must not be in Upper Case','2.47.297' 
		-- --- From (Select "ID","NAME" From mmi_v180."GA_POI" Where (COALESCE("NAME",'')<>'')) As A 
		-- --- Where A."NAME" Not In (Select "NAME" From mmi_v180."BRAND_LIST") AND UPPER( A."NAME")=A."NAME" AND A."NAME"~'[^\d]' Order By A."ID" 
			
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'NAME must not be in Upper Case';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	
	
--2.47.37
--62 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 		
		-- SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",''POPLR_NME must be in Proper Case'',''2.47.37'' FROM  
		-- (SELECT "ID","NAME","POPLR_NME",REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("POPLR_NME",'' of '','' ''),'' and '','' ''),'' for '','' ''),'' By '','' ''),'' to '','' ''),'' in '','' ''),'' OR '','' ''),'' at '','' '')
		-- FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "POPLR_NME"~''[^MDCLXVI]+$'') As t WHERE replace<>INITCAP(replace) ';
         /*
		  SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME",'POPLR_NME must be in Proper Case','2.47.37' FROM  
		 (SELECT "ID","NAME","POPLR_NME",REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("POPLR_NME",' of ',' '),' and ',' '),' for ',' '),' By ',' '),' to ',' '),' in ',' '),' OR ',' '),' at ',' ')
	         FROM mmi_v180."GA_POI" WHERE "POPLR_NME"~'[^MDCLXVI]+$') As t WHERE replace<>INITCAP(replace)
		 */
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--2.47.301
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",''All characters must not be in lower case'',''2.47.301'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE (LOWER("POPLR_NME")=("POPLR_NME"))';
		 /*
		  SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME",'All characters must not be in lower case','2.47.301' FROM mmi_v180."GA_POI" As t 
		 WHERE (LOWER("POPLR_NME")=("POPLR_NME"))
		 */
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'All characters must not be in lower case';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.302
--31 msec
	BEGIN
		sqlQuery = ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",''Poplr_nme must not be start with lower case'',''2.47.302'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t1, (Select "POPLR_NME" As poplr_nme From '||sch_name||'."'|| UPPER(tbl_nme) ||'" Where (COALESCE("POPLR_NME",'''')<>'''')
		Except Select "BND_NAME" From '||mst_sch||'."BRAND_LIST") As t2 Where t1."POPLR_NME"=t2.poplr_nme AND SUBSTRING(t2.poplr_nme from 1 For 1) = LOWER(SUBSTRING(TRIM(t2.poplr_nme) from 1 For 1)) AND SUBSTRING(TRIM(t2.poplr_nme) from 1 For 1)~''[^\d]'' AND SUBSTRING(TRIM(t2.poplr_nme) from 1 For 1)~''[a-z]''';	
		
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",''Must not be start with lower case'',''2.47.302'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND 
		-- SUBSTRING("POPLR_NME" from 1 For 1) = LOWER(SUBSTRING(TRIM("POPLR_NME") from 1 For 1)) AND SUBSTRING(TRIM("POPLR_NME") from 1 For 1)~''[^\d]'' ';
		--ADDED BY BIPIN
		
		--SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME",'Must not be start with lower case','2.47.302' FROM mmi_v180."GA_POI" As t 
		--WHERE SUBSTRING("POPLR_NME" from 1 For 1) = LOWER(SUBSTRING(TRIM("POPLR_NME") from 1 For 1)) AND SUBSTRING(TRIM("POPLR_NME") from 1 For 1)~'[^\d]'
		--RAISE INFO 'sqlQuery->%',sqlQuery;
		EXECUTE sqlQuery;
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Poplr_nme must not be start with lower case';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.248
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME", ''Must not have repetitive special character like ’&&’ and ’''''’'',''2.47.248'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."POPLR_NME" IS NOT NULL AND t."POPLR_NME"~''['''']{2,}|[&]{2,}'' ';
        
		-- SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME", 'Must not have repetitive special character like ’&&’ and ’''''’'',''2.47.248' FROM mmi_v180."GA_POI" As t 
		-- WHERE t."POPLR_NME" IS NOT NULL AND t."POPLR_NME"~'['']{2,}|[&]{2,}';
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Must not have repetitive special character like ’&&’';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.274
--16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME", ''Special character must not present at start and End of name'',''2.47.274'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE "POPLR_NME" IS NOT NULL AND "POPLR_NME" like ''&%'' OR "POPLR_NME" like ''%&'' OR "POPLR_NME" like ''''''%'' OR "POPLR_NME" like ''%'''''' ';
        /*
		 SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME", 'Special character must not present at start and End of name','2.47.274' FROM mmi_v180."GA_POI" 
		 WHERE "POPLR_NME" IS NOT NULL AND "POPLR_NME" like '&%' OR "POPLR_NME" like '%&' OR "POPLR_NME" like '''''%' OR "POPLR_NME" like '%'''''
		*/
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Special character must not present at start and End of name';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.10.4
--140 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME", 
		''POPLR_NME must not have special character except ’&’ and single quotes'',''1.10.4'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t WHERE (t."POPLR_NME"~''[^A-Za-z0-9\s&'''']'') ';

		--SELECT "ID","NAME",'tbl_nme','POPLR_NME',"POPLR_NME", 
		--'POPLR_NME must not have special character except ’&’ and single quotes','1.10.4' FROM mmi_v180."DL_POI" As t WHERE (status NOT IN ('0','5') OR (COALESCE(status,'')='') ) AND (t."POPLR_NME"~'[^A-Za-z0-9\s&'']')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'POPLR_NME must not have special character except ’&’ and single quotes';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.10.5
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME", 
		''Double Spaces are not allowed'',''1.10.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE ("POPLR_NME" LIKE ''%  %'') ';
		
		--SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME", 
	    ---'Double Spaces are not allowed','1.10.5' FROM mmi_v180."GA_POI" WHERE ("POPLR_NME" LIKE '%  %')				 
		 	       	 				 					
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Double Spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.10.6
--31 msec
	BEGIN
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",''Poplr_Nme should not contain NAME'',''1.10.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("POPLR_NME",'''')<>'''') AND (LOWER(TRIM("POPLR_NME")) LIKE LOWER(TRIM("NAME")) ))';
		 
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",''POPLR_NME should not contain NAME & ALIAS'',''1.10.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND 
		 -- ((COALESCE("POPLR_NME",'''')<>'''') AND (LOWER(TRIM("POPLR_NME")) LIKE ''%''||LOWER(TRIM("NAME"))||''%'' ))';

		-- SELECT "ID","NAME",'tbl_nme','NAME',"NAME",'POPLR_NME should not contain NAME & ALIAS','1.10.6' FROM mmi_v180."DL_POI" 
		-- WHERE (status NOT IN ('0','5') OR (COALESCE(status,'')='') ) AND 
		-- ((COALESCE("POPLR_NME",'')<>'') AND (LOWER(TRIM("POPLR_NME")) LIKE '%'||LOWER(TRIM("NAME"))||'%' ))

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'POPLR_NME should not contain NAME & ALIAS';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.10.6
--32 msec
	BEGIN
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1", 
		''Poplr_Nme should not contain Alias_1'',''1.10.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("POPLR_NME",'''')<>'''') AND (LOWER(TRIM("POPLR_NME")) LIKE LOWER(TRIM("ALIAS_1")) ))';
        
		/*
		 SELECT "ID","NAME",'GA_POI','ALIAS_1',"ALIAS_1", 
		'Poplr_Nme should not contain Alias_1','1.10.6' FROM mmi_v180."GA_POI" 
		 WHERE ((COALESCE("POPLR_NME",'')<>'') AND (LOWER(TRIM("POPLR_NME")) LIKE LOWER(TRIM("ALIAS_1")) ))
		*/
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1", 
		-- ''POPLR_NME should not contain NAME & ALIAS'',''1.10.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 

		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ((COALESCE("POPLR_NME",'''')<>'''') AND (LOWER(TRIM("POPLR_NME")) LIKE ''%''||LOWER(TRIM("ALIAS_1"))||''%'' ))';

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Poplr_Nme should not contain Alias_1';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.10.6
--31 msec
	BEGIN
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2", 
		''Poplr_Nme should not contain Alias_2'',''1.10.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("POPLR_NME",'''')<>'''') AND (LOWER(TRIM("POPLR_NME")) LIKE LOWER(TRIM("ALIAS_2")) ))';

		-- SELECT "ID","NAME",'GA_POI','ALIAS_2',"ALIAS_2", 
	    --'Poplr_Nme should not contain Alias_2','1.10.6' FROM mmi_v180."GA_POI" 
	    --WHERE ((COALESCE("POPLR_NME",'')<>'') AND (LOWER(TRIM("POPLR_NME")) LIKE LOWER(TRIM("ALIAS_2")) ))
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Poplr_Nme should not contain Alias_2';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.10.6
--15 msec
	BEGIN
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3", 
		''Poplr_Nme should not contain Alias_3'',''1.10.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE
		((COALESCE("POPLR_NME",'''')<>'''') AND (LOWER(TRIM("POPLR_NME")) LIKE LOWER(TRIM("ALIAS_3")) ))';
		
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3", 
		-- ''POPLR_NME should not contain NAME & ALIAS'',''1.10.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- ((COALESCE("POPLR_NME",'''')<>'''') AND (LOWER(TRIM("POPLR_NME")) LIKE ''%''||LOWER(TRIM("ALIAS_3"))||''%'' ))';
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Poplr_Nme should not contain Alias_3';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.10.7
--31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME", 
		-- ''Head Office in POPLR_NME must be As HO'',''1.10.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		-- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND 
		-- (LOWER(TRIM("POPLR_NME")) = ''head office'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''% head office %'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''head office %'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''% head office'')';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME", 
		''Head Office in POPLR_NME must be As HO'',''1.10.7'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER(TRIM("POPLR_NME")) LIKE ''% head office'')';
		
		-- SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME", 
	    -- 'Head Office in POPLR_NME must be As HO','1.10.7' 
	    -- FROM mmi_v180."GA_POI" WHERE (LOWER(TRIM("POPLR_NME")) LIKE '% head office')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Head Office in POPLR_NME must be As HO';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.10.7
--31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME", 
		-- ''Zonal Office in POPLR_NME must be As ZO'',''1.10.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		-- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND 
		-- (LOWER(TRIM("POPLR_NME")) = ''zonal office'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''% zonal office %'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''zonal office %'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''% zonal office'')';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME", ''Zonal Office in POPLR_NME must be As ZO'',''1.10.7'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER(TRIM("POPLR_NME")) LIKE ''% zonal office'')'; 
		
		/*
		SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME", 'Zonal Office in POPLR_NME must be As ZO','1.10.7' 
		FROM mmi_v180."GA_POI" WHERE (LOWER(TRIM("POPLR_NME")) LIKE '% zonal office') 
		
		*/
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Zonal Office in POPLR_NME must be As ZO';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.10.7
-- 31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",''Branch Office in POPLR_NME must be As BO'',''1.10.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		-- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND 
		-- (LOWER(TRIM("POPLR_NME")) = ''branch office'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''% branch office %'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''branch office %'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''% branch office'')';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",''Branch Office in POPLR_NME must be As BO'',''1.10.7'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER(TRIM("POPLR_NME")) LIKE ''% branch office'')'; 
		/*
		 SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",''Branch Office in POPLR_NME must be As BO'',''1.10.7'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER(TRIM("POPLR_NME")) LIKE ''% branch office'')'; 
		*/
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Branch Office in POPLR_NME must be As BO';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.10.7
--15 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",''Registered Office in POPLR_NME must be As RO'',''1.10.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		-- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND 
		-- (LOWER(TRIM("POPLR_NME")) = ''registered office'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''% registered office %'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''registered office %'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''% registered office'')';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",''Registered Office in POPLR_NME must be As RO'',''1.10.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE (LOWER(TRIM("POPLR_NME")) LIKE ''% registered office'')'; 
		 
		 /*
		 SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME",'Registered Office in POPLR_NME must be As RO','1.10.7' FROM mmi_v180."GA_POI" 
		 WHERE (LOWER(TRIM("POPLR_NME")) LIKE '% registered office')
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Registered Office in POPLR_NME must be As RO';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.10.7
-- 16 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",''Corporate Office in POPLR_NME must be As CO'',''1.10.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		-- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND 
		-- (LOWER(TRIM("POPLR_NME")) = ''corporate office'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''% corporate office %'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''corporate office %'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''% corporate office'')';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",''Corporate Office in POPLR_NME must be As CO'',''1.10.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE (LOWER(TRIM("POPLR_NME")) LIKE ''% corporate office'')'; 
		 
		 --SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME",'Corporate Office in POPLR_NME must be As CO','1.10.7' FROM mmi_v180."GA_POI" 
		 --WHERE (LOWER(TRIM("POPLR_NME")) LIKE '% corporate office')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Corporate Office in POPLR_NME must be As CO';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.10.7
--31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",''Research & Development Centre in POPLR_NME must be As R&D Centre'',''1.10.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		-- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND 
		-- (LOWER(TRIM("POPLR_NME")) = ''research & development centre'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''% research & development centre %'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''research & development centre %'') OR (LOWER(TRIM("POPLR_NME")) LIKE ''% research & development centre'')';
		--ADDED BY BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",''Research & Development Centre in POPLR_NME must be As R&D Centre'',''1.10.7'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LOWER(TRIM("POPLR_NME")) LIKE ''% research & development centre'')'; 
		
		-- SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME",'Research & Development Centre in POPLR_NME must be As R&D Centre','1.10.7' 
		-- FROM mmi_v180."GA_POI" WHERE  (LOWER(TRIM("POPLR_NME")) LIKE '% research & development centre')	
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Research & Development Centre in POPLR_NME must be As R&D Centre';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.10.8
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",
		''POPLR_NME should not start with space'',''1.10.8'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ("POPLR_NME" LIKE '' %'') ';
		 
		 -- SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME", 'POPLR_NME should not start with space','1.10.8' 
         -- FROM mmi_v180."GA_POI"  WHERE ("POPLR_NME" LIKE ' % ')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'POPLR_NME should not start with space';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.10.9
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",
		''POPLR_NME should not equal to ADDRESS'',''1.10.9'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((LOWER("POPLR_NME") = LOWER("ADDRESS")))';
		 
		 -- SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME",
		 -- 'POPLR_NME should not equal to ADDRESS','1.10.9' FROM mmi_v180."GA_POI" 
		 -- WHERE ((LOWER("POPLR_NME") = LOWER("ADDRESS")))
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'POPLR_NME should not equal to ADDRESS';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
------------------------------------------------------------------------------------------------ALIAS_1-----------------------------------------------------------------------------------------------------------------------------------------------          
--2.47.303
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1",''ALIAS_1 must not be in Upper Case'',''2.47.303'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND (UPPER("ALIAS_1")=("ALIAS_1"))';
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--2.47.46
-- 94 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1",''ALIAS_1 must be in Proper Case'',''2.47.46'' FROM  
		(SELECT "ID","NAME","ALIAS_1",REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("ALIAS_1",'' of '','' ''),'' and '','' ''),'' for '','' ''),'' By '','' ''),'' to '','' ''),'' in '','' ''),'' OR '','' ''),'' at '','' '')
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE  "ALIAS_1"~''[^MDCLXVI]+$'') As t WHERE replace<>INITCAP(replace) ';
        
        ---SELECT "ID","NAME",'GA_POI','ALIAS_1',"ALIAS_1",'ALIAS_1 must be in Proper Case','2.47.46' FROM  
		---(SELECT "ID","NAME","ALIAS_1",REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("ALIAS_1",' of ',' '),' and ',' '),' for ',' '),' By ',' '),' to ',' '),' in ',' '),' OR ',' '),' at ',' ')
		---FROM mmi_v180."GA_POI" WHERE  "ALIAS_1"~'[^MDCLXVI]+$') As t WHERE replace<>INITCAP(replace)	
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ALIAS_1 must be in Proper Case';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.304
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1",''All characters must not be in lower case'',''2.47.304'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE (LOWER("ALIAS_1")=("ALIAS_1"))';
		 
		 --SELECT "ID","NAME",'GA_POI','ALIAS_1',"ALIAS_1",'All characters must not be in lower case','2.47.304' FROM mmi_v180."GA_POI" As t 
		 --WHERE (LOWER("ALIAS_1")=("ALIAS_1"))	
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'All characters must not be in lower case';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.305
-- 32 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1",''Must not be start with lower case'',''2.47.305'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND 
		-- SUBSTRING("ALIAS_1" from 1 For 1) = LOWER(SUBSTRING(TRIM("ALIAS_1") from 1 For 1)) AND SUBSTRING(TRIM("ALIAS_1") from 1 For 1)~''[^\d]'' ';
		--ADDED BY BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1",''Alias_1 must not be start with lower case'',''2.47.305'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t1,(Select "ALIAS_1" As alias1 From '||sch_name||'."'|| UPPER(tbl_nme) ||'" Where (COALESCE("ALIAS_1",'''')<>'''')
		AND UPPER("ALIAS_1") LIKE ANY(ARRAY(SELECT UPPER("BND_ALIAS1") FROM '||sch_name||'."BRAND_LIST"))= FALSE) As t2 Where t1."ALIAS_1"=t2.alias1 AND SUBSTRING(t2.alias1 from 1 For 1) = LOWER(SUBSTRING(TRIM(t2.alias1) from 1 For 1)) AND SUBSTRING(TRIM(t2.alias1) from 1 For 1)~''[^\d]'' AND SUBSTRING(TRIM(t2.alias1) from 1 For 1)~''[a-z]''';	
		
		---	SELECT "ID","NAME",'GA_POI','ALIAS_1',"ALIAS_1",'Alias_1 must not be start with lower case','2.47.305'
		--- FROM mmi_v180."GA_POI" As t1,(Select "ALIAS_1" As alias1 From mmi_v180."GA_POI" Where (COALESCE("ALIAS_1",'')<>'')
		--- AND UPPER("ALIAS_1") LIKE ANY(ARRAY(SELECT UPPER("BND_ALIAS1") FROM '||sch_name||'."BRAND_LIST"))= FALSE) As t2 Where t1."ALIAS_1"=t2.alias1 AND SUBSTRING(t2.alias1 from 1 For 1) = LOWER(SUBSTRING(TRIM(t2.alias1) from 1 For 1)) AND SUBSTRING(TRIM(t2.alias1) from 1 For 1)~''[^\d]'' AND SUBSTRING(TRIM(t2.alias1) from 1 For 1)~'[a-z]'
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_1 must not be start with lower case';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.249
--32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1", ''Must not have repetitive special character like ’&&’ and ’''''’'',''2.47.249'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		WHERE t."ALIAS_1" IS NOT NULL AND (t."ALIAS_1" LIKE (''%&&%'') OR t."ALIAS_1" LIKE (''%''''''''%'') or t."ALIAS_1" LIKE (''%&''''%'')) ';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','ALIAS_1',"ALIAS_1", 'Must not have repetitive special character like ’&&’ and ’''''’','2.47.249' FROM mmi_v180."GA_POI" As t 
		  WHERE t."ALIAS_1" IS NOT NULL AND (t."ALIAS_1" LIKE ('%&&%') OR t."ALIAS_1" LIKE ('%''''%'))
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Must not have repetitive special character like ’&&’';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.276
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1", ''Special character must not present at start and end of name'',''2.47.276'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."ALIAS_1" IS NOT NULL AND (t."ALIAS_1" like ''&%'' OR t."ALIAS_1" like ''%&'' OR t."ALIAS_1" like ''''''%'' OR t."ALIAS_1" like ''%'''''') ';
        /*
		SELECT "ID","NAME",'GA_POI','ALIAS_1',"ALIAS_1", 'Special character must not present at start and end of name','2.47.276' FROM mmi_v180."GA_POI" As t 
		 WHERE t."ALIAS_1" IS NOT NULL AND (t."ALIAS_1" like '&%' OR t."ALIAS_1" like '%&' OR t."ALIAS_1" like '''''%' OR t."ALIAS_1" like '%''''')
		*/
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Special character must not present at start and end of name';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.11.1
--31 msec
	BEGIN
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",
		''Alias_1 should not contain NAME'',''1.11.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("ALIAS_1",'''')<>'''') AND (LOWER(TRIM("ALIAS_1")) LIKE LOWER(TRIM("NAME")) ))';
		
		-- SELECT "ID","NAME",'GA_POI','NAME',"NAME",
		--'Alias_1 should not contain NAME','1.11.1' FROM mmi_v180."GA_POI" 
		-- WHERE ((COALESCE("ALIAS_1",'')<>'') AND (LOWER(TRIM("ALIAS_1")) LIKE LOWER(TRIM("NAME")) ))
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_1 should not contain NAME';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.11.1
-- 31 msec
	BEGIN
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",
		''Alias_1 should not contain Poplr_Nme'',''1.11.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("ALIAS_1",'''')<>'''') AND (LOWER(TRIM("ALIAS_1")) LIKE LOWER(TRIM("POPLR_NME")) ))';
		
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",
		-- ''ALIAS_1 should not contain NAME & Other Alternate Names'',''1.11.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 

		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ((COALESCE("ALIAS_1",'''')<>'''') AND (LOWER(TRIM("ALIAS_1")) LIKE ''%''||LOWER(TRIM("POPLR_NME"))||''%'' ))';
		/*
		  SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME",
		'Alias_1 should not contain Poplr_Nme','1.11.1' FROM mmi_v180."GA_POI" 
		 WHERE ((COALESCE("ALIAS_1",'')<>'') AND (LOWER(TRIM("ALIAS_1")) LIKE LOWER(TRIM("POPLR_NME")) ))
		*/
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_1 should not contain Poplr_Nme';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.11.1
-- 32 msec
	BEGIN
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2",
		''Alias_1 should not contain Alias_2'',''1.11.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("ALIAS_1",'''')<>'''') AND (LOWER(TRIM("ALIAS_1")) LIKE LOWER(TRIM("ALIAS_2")) ))';
		
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2",
		-- ''ALIAS_1 should not contain NAME & Other Alternate Names'',''1.11.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 

		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ((COALESCE("ALIAS_1",'''')<>'''') AND (LOWER(TRIM("ALIAS_1")) LIKE ''%''||LOWER(TRIM("ALIAS_2"))||''%'' ))';
		/*
		  SELECT "ID","NAME",'GA_POI','ALIAS_2',"ALIAS_2",
		'Alias_1 should not contain Alias_2','1.11.1' FROM mmi_v180."GA_POI" 
		 WHERE ((COALESCE("ALIAS_1",'')<>'') AND (LOWER(TRIM("ALIAS_1")) LIKE LOWER(TRIM("ALIAS_2")) ))
		*/
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_1 should not contain Alias_2';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.11.1
--15 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",
		-- ''ALIAS_1 should not contain NAME & Other Alternate Names'',''1.11.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 

		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ((COALESCE("ALIAS_1",'''')<>'''') AND (LOWER(TRIM("ALIAS_1")) LIKE ''%''||LOWER(TRIM("ALIAS_3"))||''%'' ))';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",
		''Alias_1 should not contain Alias_3'',''1.11.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("ALIAS_1",'''')<>'''') AND (LOWER(TRIM("ALIAS_1")) LIKE LOWER(TRIM("ALIAS_3")) ))';
		 
		 --SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3",
		 --'Alias_1 should not contain Alias_3','1.11.1' FROM mmi_v180."GA_POI" 
		 --WHERE ((COALESCE("ALIAS_1",'')<>'') AND (LOWER(TRIM("ALIAS_1")) LIKE LOWER(TRIM("ALIAS_3")) ))
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_1 should not contain Alias_3';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
--1.11.1
--15 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1",
		''Alias_1 should not contain BRANCH_NME'',''1.11.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("ALIAS_1",'''')<>'''') AND (LOWER(TRIM("ALIAS_1")) LIKE LOWER(TRIM("BRANCH_NME")) ))';
		 
		 --SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3",
		 --'Alias_1 should not contain Alias_3','1.11.1' FROM mmi_v180."GA_POI" 
		 --WHERE ((COALESCE("ALIAS_1",'')<>'') AND (LOWER(TRIM("ALIAS_1")) LIKE LOWER(TRIM("BRANCH_NME")) ))
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_1 should not contain Alias_3';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	
--1.11.3
--32 msec
	BEGIN
		sqlQuery = ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT B."ID",B."NAME",'''||tbl_nme||''',''ALIAS_1'',B."ALIAS_1",
		''Must not have special character except  single quotes'',''1.11.3'' FROM (SELECT "ID", "NAME", "ALIAS_1", "BRAND_NME" 
		FROM (SELECT "ID", "NAME", "ALIAS_1", "BRAND_NME" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" t WHERE (t."ALIAS_1"~''[^A-Za-z0-9\s&]'' AND (COALESCE("ALIAS_1",'''')<>''''))) AS A 
		WHERE UPPER(A."BRAND_NME") LIKE ANY(ARRAY(SELECT UPPER("BND_NAME") FROM '||sch_name||'."BRAND_LIST"))= FALSE) AS B ';
		 
		 /*
		 SELECT A."ID", A."NAME", A."ALIAS_1", A."BRAND_NME" FROM
		 (SELECT "ID", "NAME", "ALIAS_1", "BRAND_NME" FROM mmi_master."GA_POI" t WHERE (t."ALIAS_1"~'[^A-Za-z0-9\s&'']' AND (COALESCE("ALIAS_1",'')<>''))) AS A
		 WHERE UPPER(A."BRAND_NME") LIKE ANY(ARRAY(SELECT UPPER("BND_NAME") FROM mmi_master."BRAND_LIST"))= FALSE
		 */
		--RAISE INFO 'sqlQuery->%',sqlQuery;
		EXECUTE sqlQuery;
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Must not have special character except ’&’ and single quotes';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.11.4
---31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1",
		''ALIAS_1 should not start with space'',''1.11.4'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ("ALIAS_1" LIKE '' %'')';
		 
		 -- SELECT "ID","NAME",'GA_POI','ALIAS_1',"ALIAS_1",
		 -- 'ALIAS_1 should not start with space','1.11.4' FROM mmi_v180."GA_POI" 
		 -- WHERE ("ALIAS_1" LIKE ' %')
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ALIAS_1 should not start with space';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.11.5
-- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1",
		''Double Spaces are not allowed'',''1.11.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE  ("ALIAS_1" LIKE ''%  %'') ';
		 /*
		 SELECT "ID","NAME",'GA_POI','ALIAS_1',"ALIAS_1",
		'Double Spaces are not allowed','1.11.5' FROM mmi_v180."GA_POI" 
		 WHERE  ("ALIAS_1" LIKE '%  %')
		 */
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Double Spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.11.6
-- 32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1",
		''ALIAS_1 should not equal to ADDRESS'',''1.11.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ( LOWER(TRIM("ALIAS_1")) = LOWER(TRIM("ADDRESS")) AND (COALESCE("ALIAS_1",'''')<>'''') )';
		 
		 --SELECT "ID","NAME",'GA_POI','ALIAS_1',"ALIAS_1",
		 --'ALIAS_1 should not equal to ADDRESS','1.11.6' FROM mmi_v180."GA_POI" 
		 --WHERE ( LOWER(TRIM("ALIAS_1")) = LOWER(TRIM("ADDRESS")) AND (COALESCE("ALIAS_1",'')<>'') )
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ALIAS_1 should not equal to ADDRESS';
	RAISE NOTICE 'time spent =%', clock_timestamp();
------------------------------------------------------------------------------------------------ALIAS_2-----------------------------------------------------------------------------------------------------------------------------------------------
--2.47.306
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2",''ALIAS_2 must not be in Upper Case'',''2.47.306'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (UPPER("ALIAS_2")=("ALIAS_2"))';
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--2.47.53
-- 62 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2",''ALIAS_2 must be in Proper Case'',''2.47.53'' FROM  
		(SELECT "ID","NAME","ALIAS_2",REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("ALIAS_2",'' of '','' ''),'' and '','' ''),'' for '','' ''),'' By '','' ''),'' to '','' ''),'' in '','' ''),'' OR '','' ''),'' at '','' '')
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "ALIAS_2"~''[^MDCLXVI]+$'' AND UPPER("ALIAS_2") LIKE ANY(ARRAY(SELECT UPPER("BND_ALIAS1") FROM '||sch_name||'."BRAND_LIST"))= FALSE) As t WHERE replace<>INITCAP(replace) ';
        /*
		SELECT "ID","NAME",'GA_POI','ALIAS_2',"ALIAS_2",'ALIAS_2 must be in Proper Case','2.47.53' FROM  
		(SELECT "ID","NAME","ALIAS_2",REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("ALIAS_2",' of ',' '),' and ',' '),' for ',' '),' By ',' '),' to ',' '),' in ',' '),' OR ',' '),' at ',' ')
		FROM mmi_v180."GA_POI" WHERE "ALIAS_2"~'[^MDCLXVI]+$') As t WHERE replace<>INITCAP(replace)
		*/
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ALIAS_2 must be in Proper Case';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--2.47.307
---31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2",''All characters must not be in lower case'',''2.47.307'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE (LOWER("ALIAS_2")=("ALIAS_2"))';
		 
		 --SELECT "ID","NAME",'GA_POI','ALIAS_2',"ALIAS_2",'All characters must not be in lower case','2.47.307' FROM mmi_v180."GA_POI" As t 
		 --WHERE (LOWER("ALIAS_2")=("ALIAS_2"))
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'All characters must not be in lower case';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--2.47.308
-- 32 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2",''Must not be start with lower case'',''2.47.308'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		-- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND 
		-- SUBSTRING("ALIAS_2" from 1 For 1) = LOWER(SUBSTRING(TRIM("ALIAS_2") from 1 For 1)) AND SUBSTRING(TRIM("ALIAS_2") from 1 For 1)~''[^\d]'' ';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2",''Alias_2 must not be start with lower case'',''2.47.308'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t1,(Select "ALIAS_2" As alias2 From '||sch_name||'."'|| UPPER(tbl_nme) ||'" Where  (COALESCE("ALIAS_2",'''')<>'''')
		Except Select "BND_NAME" From '||mst_sch||'."BRAND_LIST") As t2 Where t1."ALIAS_2"=t2.alias2 AND SUBSTRING(t2.alias2 from 1 For 1) = LOWER(SUBSTRING(TRIM(t2.alias2) from 1 For 1)) AND SUBSTRING(TRIM(t2.alias2) from 1 For 1)~''[^\d]'' AND SUBSTRING(TRIM(t2.alias2) from 1 For 1)~''[a-z]''';	
		/*
		 SELECT "ID","NAME",'GA_POI','ALIAS_2',"ALIAS_2",'Alias_2 must not be start with lower case','2.47.308' 
		FROM mmi_v180."GA_POI" As t1,(Select "ALIAS_2" As alias2 From mmi_v180."GA_POI" Where  (COALESCE("ALIAS_2",'')<>'')
		Except Select "NAME" From mmi_v180."BRAND_LIST") As t2 Where t1."ALIAS_2"=t2.alias2 AND SUBSTRING(t2.alias2 from 1 For 1) = LOWER(SUBSTRING(TRIM(t2.alias2) from 1 For 1)) AND SUBSTRING(TRIM(t2.alias2) from 1 For 1)~'[^\d]' AND SUBSTRING(TRIM(t2.alias2) from 1 For 1)~'[a-z]'
		*/
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_2 must not be start with lower case';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--2.47.250
-- 32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2", ''Must not have repetitive special character like ’&&’ and ’''''’'',''2.47.250'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."ALIAS_2" IS NOT NULL AND (t."ALIAS_2" LIKE (''%&&%'') OR t."ALIAS_2" LIKE (''%''''%'')) ';
        
		--SELECT "ID","NAME",'GA_POI','ALIAS_2',"ALIAS_2", 'Must not have repetitive special character like ’&&’ and ’''''’','2.47.250' FROM mmi_v180."GA_POI" As t 
		--WHERE t."ALIAS_2" IS NOT NULL AND (t."ALIAS_2" LIKE ('%&&%') OR t."ALIAS_2" LIKE ('%''%'))
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Must not have repetitive special character like ’&&’';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--2.47.276
-- 32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2", ''Special character must not present at start and end of name'',''2.47.276'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."ALIAS_2" IS NOT NULL AND (t."ALIAS_2" like ''&%'' OR t."ALIAS_2" like ''%&'' OR t."ALIAS_2" like ''''''%'' OR t."ALIAS_2" like ''%'''''') ';
         /*
		  SELECT "ID","NAME",'GA_POI','ALIAS_2',"ALIAS_2", 'Special character must not present at start and end of name','2.47.276' FROM mmi_v180."GA_POI" As t 
		 WHERE t."ALIAS_2" IS NOT NULL AND (t."ALIAS_2" like '&%' OR t."ALIAS_2" like '%&' OR t."ALIAS_2" like '''''%' OR t."ALIAS_2" like '%''''')
		 */
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Special character must not present at start and end of name';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.12.1
-- 31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",
		-- ''ALIAS_2 should not contain NAME & Other Alternate Names'',''1.12.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 

		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ((COALESCE("ALIAS_2",'''')<>'''') AND (LOWER(TRIM("ALIAS_2")) LIKE ''%''||LOWER(TRIM("NAME"))||''%'' ))';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",
		''Alias_2 should not contain NAME'',''1.12.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("ALIAS_2",'''')<>'''') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("NAME")) ))';
		
		--- SELECT "ID","NAME",'GA_POI','NAME',"NAME",
		--- 'Alias_2 should not contain NAME','1.12.1' FROM mmi_v180."GA_POI" 
		--- WHERE ((COALESCE("ALIAS_2",'')<>'') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("NAME")) )) 
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_2 should not contain NAME';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.12.1
--31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",
		-- ''ALIAS_2 should not contain NAME & Other Alternate Names'',''1.12.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		-- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ((COALESCE("ALIAS_2",'''')<>'''') AND (LOWER(TRIM("ALIAS_2")) LIKE ''%''||LOWER(TRIM("POPLR_NME"))||''%'' ))';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",
		''Alias_2 should not contain Poplr_Nme'',''1.12.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("ALIAS_2",'''')<>'''') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("POPLR_NME")) ))';
		 
		 /*
		   SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME",
		'Alias_2 should not contain Poplr_Nme','1.12.1' FROM mmi_v180."GA_POI" 
		 WHERE ((COALESCE("ALIAS_2",'')<>'') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("POPLR_NME")) ))
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_2 should not contain Poplr_Nme';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.12.1
-- 31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1",
		-- ''ALIAS_2 should not contain NAME & Other Alternate Names'',''1.12.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 

		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ((COALESCE("ALIAS_2",'''')<>'''') AND (LOWER(TRIM("ALIAS_2")) LIKE ''%''||LOWER(TRIM("ALIAS_1"))||''%'' ))';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1",
		''Alias_2 should not contain Alias_1'',''1.12.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("ALIAS_2",'''')<>'''') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("ALIAS_1")) ))';
		 
		 /*
		 SELECT "ID","NAME",'GA_POI','ALIAS_1',"ALIAS_1",
		'Alias_2 should not contain Alias_1','1.12.1' FROM mmi_v180."GA_POI" 
		 WHERE ((COALESCE("ALIAS_2",'')<>'') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("ALIAS_1")) ))
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_2 should not contain Alias_1';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.12.1
--31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",
		-- ''ALIAS_2 should not contain NAME & Other Alternate Names'',''1.12.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 

		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ((COALESCE("ALIAS_2",'''')<>'''') AND (LOWER(TRIM("ALIAS_2")) LIKE ''%''||LOWER(TRIM("ALIAS_3"))||''%'' ))';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",
		''Alias_2 should not contain Alias_3'',''1.12.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("ALIAS_2",'''')<>'''') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("ALIAS_3"))))';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3",
		'Alias_2 should not contain Alias_3','1.12.1' FROM mmi_v180."GA_POI" 
		 WHERE ((COALESCE("ALIAS_2",'')<>'') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("ALIAS_3"))))
		 */
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_2 should not contain Alias_3';
	RAISE NOTICE 'time spent =%', clock_timestamp();
	
--1.12.1
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",
		''Alias_2 should not contain BRANCH_NME'',''1.12.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("ALIAS_2",'''')<>'''') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("BRANCH_NME"))))';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3",
		'Alias_2 should not contain Alias_3','1.12.1' FROM mmi_v180."GA_POI" 
		 WHERE ((COALESCE("ALIAS_2",'')<>'') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("ALIAS_3"))))
		 */
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_2 should not contain Alias_3';
	RAISE NOTICE 'time spent =%', clock_timestamp();	
	
	
	
--1.12.3
-- 32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2",
		''Must not have special character except ’&’ and single quotes'',''1.12.3'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE (t."ALIAS_2"~''[^A-Za-z0-9\s\&]'' AND (COALESCE("ALIAS_2",'''')<>''''))';
		 
		 --SELECT "ID","NAME",'GA_POI','ALIAS_2',"ALIAS_2",
		 --'Must not have special character except ’&’ and single quotes','1.12.3' FROM mmi_v180."GA_POI" As t 
		 --WHERE (t."ALIAS_2"~'[^A-Za-z0-9\s]' AND (COALESCE("ALIAS_2",'')<>''))

		 EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Must not have special character except ’&’ and single quotes';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.12.4
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2",
		''ALIAS_2 should not start with space'',''1.12.4'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ("ALIAS_2" LIKE '' %'')';
		 
		 /*
		 SELECT "ID","NAME",'GA_POI','ALIAS_2',"ALIAS_2",
		'ALIAS_2 should not start with space','1.12.4' FROM mmi_v180."GA_POI" 
		 WHERE ("ALIAS_2" LIKE ' %')
		 */
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ALIAS_2 should not start with space';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.12.5
--16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2",
		''Double Spaces are not allowed'',''1.12.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ("ALIAS_2" LIKE ''%  %'')';
		 /*
		 SELECT "ID","NAME",'GA_POI','ALIAS_2',"ALIAS_2",
		'Double Spaces are not allowed','1.12.5' FROM mmi_v180."GA_POI" 
		 WHERE ("ALIAS_2" LIKE '%  %')
		 */
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ALIAS_2 should not start with space';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.12.6
--16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2",
		''If ALIAS_1 is blank then ALIAS_2 also should be blank'',''1.12.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("ALIAS_1",'''')='''') AND (COALESCE("ALIAS_2",'''')<>''''))';
		 
		--SELECT "ID","NAME",'GA_POI','ALIAS_2',"ALIAS_2",
		--'If ALIAS_1 is blank then ALIAS_2 also should be blank','1.12.6' FROM mmi_v180."GA_POI" 
		--WHERE ((COALESCE("ALIAS_1",'')='') AND (COALESCE("ALIAS_2",'')<>''))	
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If ALIAS_1 is blank then ALIAS_2 also should be blank';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.12.7
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2",
		''ALIAS_2 should not equal to ADDRESS'',''1.12.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ( LOWER(TRIM("ALIAS_2")) = LOWER(TRIM("ADDRESS")) AND (COALESCE("ALIAS_2",'''')<>'''') )';
		 /*
		 SELECT "ID","NAME",'GA_POI','ALIAS_2',"ALIAS_2",
		'ALIAS_2 should not equal to ADDRESS','1.12.7' FROM mmi_v180."GA_POI" 
		 WHERE ( LOWER(TRIM("ALIAS_2")) = LOWER(TRIM("ADDRESS")) AND (COALESCE("ALIAS_2",'')<>'') )
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ALIAS_2 should not equal to ADDRESS';
	RAISE NOTICE 'time spent =%', clock_timestamp();
------------------------------------------------------------------------------------------------ALIAS_3-----------------------------------------------------------------------------------------------------------------------------------------------
--2.47.309
--31 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",''ALIAS_3 must not be in Upper Case'',''2.47.309'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (UPPER("ALIAS_3")=("ALIAS_3"))';
		 /*
		   SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3",'ALIAS_3 must not be in Upper Case','2.47.309' FROM mmi_v180."GA_POI" As t 
		  WHERE (UPPER("ALIAS_3")=("ALIAS_3"))
		 */

		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--2.47.60
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",''ALIAS_3 must be in Proper Case'',''2.47.60'' FROM  
		(SELECT "ID","NAME","ALIAS_3",REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("ALIAS_3",'' of '','' ''),'' and '','' ''),'' for '','' ''),'' By '','' ''),'' to '','' ''),'' in '','' ''),'' OR '','' ''),'' at '','' '')
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "ALIAS_3"~''[^MDCLXVI]+$'' AND "ALIAS_3" NOT IN (SELECT "BND_NAME" FROM '||mst_sch||'."BRAND_LIST")) As t 
		WHERE replace<>INITCAP(replace) AND UPPER("ALIAS_3") LIKE ANY(ARRAY(SELECT UPPER("BND_ALIAS1") FROM '||sch_name||'."BRAND_LIST"))= FALSE';

       /*
	     SELECT "ID","NAME",'tbl_nme','ALIAS_3',"ALIAS_3",'ALIAS_3 must be in Proper Case','2.47.60' FROM  
 		(SELECT "ID","NAME","ALIAS_3",REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("ALIAS_3",' of ',' '),' and ',' '),' for ',' '),' By ',' '),' to ',' '),' in ',' '),' OR ',' '),' at ',' ')
		FROM mmi_v180."GA_POI" WHERE "ALIAS_3"~'[^MDCLXVI]+$') As t WHERE replace<>INITCAP(replace) AND UPPER("ALIAS_3") LIKE ANY(ARRAY(SELECT UPPER("BND_ALIAS1") FROM mmi_master."BRAND_LIST"))= FALSE
	   */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ALIAS_3 must be in Proper Case';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--2.47.310
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",''All characters must not be in lower case'',''2.47.310'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE (LOWER("ALIAS_3")=("ALIAS_3"))';
		 
		 /*
		   SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3",'All characters must not be in lower case','2.47.310' FROM mmi_v180."GA_POI" As t 
		 WHERE (LOWER("ALIAS_3")=("ALIAS_3"))
		 */
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'All characters must not be in lower case';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--2.47.311
-- 32 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",''Must not be start with lower case'',''2.47.311'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND 
		-- SUBSTRING("ALIAS_3" from 1 For 1) = LOWER(SUBSTRING(TRIM("ALIAS_3") from 1 For 1)) AND SUBSTRING(TRIM("ALIAS_3") from 1 For 1)~''[^\d]'' ';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",''Alias_3 must not be start with lower case'',''2.47.311'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t1,(Select "ALIAS_3" As alias3 From '||sch_name||'."'|| UPPER(tbl_nme) ||'" Where (COALESCE("ALIAS_3",'''')<>'''')
		Except Select "BND_NAME" From '||mst_sch||'."BRAND_LIST") As t2 Where t1."ALIAS_3"=t2.alias3 AND SUBSTRING(t2.alias3 from 1 For 1) = LOWER(SUBSTRING(TRIM(t2.alias3) from 1 For 1)) AND SUBSTRING(TRIM(t2.alias3) from 1 For 1)~''[^\d]'' AND SUBSTRING(TRIM(t2.alias3) from 1 For 1)~''[a-z]''';	
		
		/*
		  SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3",'Alias_3 must not be start with lower case','2.47.311' 
		FROM mmi_v180."GA_POI" As t1,(Select "ALIAS_3" As alias3 From mmi_v180."GA_POI" Where (COALESCE("ALIAS_3",'')<>'')
		Except Select "NAME" From mmi_v180."BRAND_LIST") As t2 Where t1."ALIAS_3"=t2.alias3 AND SUBSTRING(t2.alias3 from 1 For 1) = LOWER(SUBSTRING(TRIM(t2.alias3) from 1 For 1)) AND SUBSTRING(TRIM(t2.alias3) from 1 For 1)~'[^\d]' AND SUBSTRING(TRIM(t2.alias3) from 1 For 1)~'[a-z]'	

		*/
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_3 must not be start with lower case';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--2.47.251
-- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3", ''Must not have repetitive special character like ’&&’ and ’''''’'',''2.47.251'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."ALIAS_3" IS NOT NULL AND (t."ALIAS_3" LIKE (''%&&%'') OR t."ALIAS_3" LIKE (''%''''%'')) ';
		 
		 /*
		 SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3", 'Must not have repetitive special character like ’&&’ and ’''''’','2.47.251' FROM mmi_v180."GA_POI" As t 
		 WHERE t."ALIAS_3" IS NOT NULL AND (t."ALIAS_3" LIKE ('%&&%') OR t."ALIAS_3" LIKE ('%''%'))
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Must not have repetitive special character like ’&&’';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--2.47.277
-- 32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3", ''Special character must not present be at start and end of name'',''2.47.277'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."ALIAS_3" IS NOT NULL AND (t."ALIAS_3" like ''&%'' OR t."ALIAS_3" like ''%&'' OR t."ALIAS_3" like ''''''%'' OR t."ALIAS_3" like ''%'''''') ';
         
		 /*
		   SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3", 'Special character must not present be at start and end of name','2.47.277' FROM mmi_v180."GA_POI" As t 
		 WHERE t."ALIAS_3" IS NOT NULL AND (t."ALIAS_3" like '&%' OR t."ALIAS_3" like '%&' OR t."ALIAS_3" like '''''%' OR t."ALIAS_3" like '%''''')
		 */
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Special character must not present be at start and end of name';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.13.1
--16 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",
		-- ''ALIAS_3 should not contain NAME & Other Alternate Names'',''1.13.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 

		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ((COALESCE("ALIAS_3",'''')<>'''') AND (LOWER(TRIM("ALIAS_3")) LIKE ''%''||LOWER(TRIM("NAME"))||''%'' ))';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",
		''Alias_3 should not contain NAME'',''1.13.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("ALIAS_3",'''')<>'''') AND (LOWER(TRIM("ALIAS_3")) LIKE LOWER(TRIM("NAME")) ))';
		 
		 /*
		   SELECT "ID","NAME",'GA_POI','NAME',"NAME",
		'Alias_3 should not contain NAME','1.13.1' FROM mmi_v180."GA_POI" 
		 WHERE ((COALESCE("ALIAS_3",'')<>'') AND (LOWER(TRIM("ALIAS_3")) LIKE LOWER(TRIM("NAME")) ))
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_3 should not contain NAME';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.13.1
-- 15 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",
		-- ''ALIAS_3 should not contain NAME & Other Alternate Names'',''1.13.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 

		 -- WHERE ((COALESCE("ALIAS_3",'''')<>'''') AND (LOWER(TRIM("ALIAS_3")) LIKE ''%''||LOWER(TRIM("POPLR_NME"))||''%'' ))';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",
		''Alias_3 should not contain Poplr_Nme'',''1.13.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("ALIAS_3",'''')<>'''') AND (LOWER(TRIM("ALIAS_3")) LIKE LOWER(TRIM("POPLR_NME")) ))';
		 /*
		  SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME",
		'Alias_3 should not contain Poplr_Nme','1.13.1' FROM mmi_v180."GA_POI" 
		 WHERE ((COALESCE("ALIAS_3",'')<>'') AND (LOWER(TRIM("ALIAS_3")) LIKE LOWER(TRIM("POPLR_NME")) ))
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_3 should not contain Poplr_Nme';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.13.1
-- 31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1",
		-- ''ALIAS_3 should not contain NAME & Other Alternate Names'',''1.13.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 

		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ((COALESCE("ALIAS_3",'''')<>'''') AND (LOWER(TRIM("ALIAS_3")) LIKE ''%''||LOWER(TRIM("ALIAS_1"))||''%'' ))';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1",
		''Alias_3 should not contain Alias_1'',''1.13.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("ALIAS_3",'''')<>'''') AND (LOWER(TRIM("ALIAS_3")) LIKE LOWER(TRIM("ALIAS_1")) ))';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','ALIAS_1',"ALIAS_1",
		'Alias_3 should not contain Alias_1','1.13.1' FROM mmi_v180."GA_POI" 
		 WHERE ((COALESCE("ALIAS_3",'')<>'') AND (LOWER(TRIM("ALIAS_3")) LIKE LOWER(TRIM("ALIAS_1")) ))
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_3 should not contain Alias_1';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.13.1
-- 31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2",
		-- ''ALIAS_3 should not contain NAME & Other Alternate Names'',''1.13.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ((COALESCE("ALIAS_3",'''')<>'''') AND (LOWER(TRIM("ALIAS_3")) LIKE ''%''||LOWER(TRIM("ALIAS_2"))||''%'' ))';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",
		''Alias_3 should not contain Alias_2'',''1.13.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("ALIAS_3",'''')<>'''') AND (LOWER(TRIM("ALIAS_3")) LIKE LOWER(TRIM("ALIAS_2")) ))';
		 /*
		  SELECT "ID","NAME",'GA_POI','ALIAS_2',"ALIAS_2",
		'Alias_3 should not contain Alias_2','1.13.1' FROM mmi_v180."GA_POI" 
		 WHERE ((COALESCE("ALIAS_3",'')<>'') AND (LOWER(TRIM("ALIAS_3")) LIKE LOWER(TRIM("ALIAS_2")) ))
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_3 should not contain Alias_2';
	RAISE NOTICE 'time spent =%', clock_timestamp();
	
--1.13.1
-- 31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2",
		-- ''ALIAS_3 should not contain NAME & Other Alternate Names'',''1.13.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 

		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ((COALESCE("ALIAS_3",'''')<>'''') AND (LOWER(TRIM("ALIAS_3")) LIKE ''%''||LOWER(TRIM("ALIAS_2"))||''%'' ))';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",
		''Alias_3 should not contain Alias_2'',''1.13.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("ALIAS_3",'''')<>'''') AND (LOWER(TRIM("ALIAS_3")) LIKE LOWER(TRIM("BRANCH_NME")) ))';
		 /*
		  SELECT "ID","NAME",'GA_POI','ALIAS_2',"ALIAS_2",
		'Alias_3 should not contain Alias_2','1.13.1' FROM mmi_v180."GA_POI" 
		 WHERE ((COALESCE("ALIAS_3",'')<>'') AND (LOWER(TRIM("ALIAS_3")) LIKE LOWER(TRIM("ALIAS_2")) ))
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Alias_3 should not contain Alias_2';
	RAISE NOTICE 'time spent =%', clock_timestamp();
	
	
	
--1.13.3
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",
		''Must not have special character except ’&’ and single quotes'',''1.13.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE (t."ALIAS_3"~''[^A-Za-z0-9\s]'' AND (COALESCE("ALIAS_3",'''')<>''''))';
		 /*
		  SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3",
		'Must not have special character except ’&’ and single quotes','1.13.3' FROM mmi_v180."GA_POI" As t 
		 WHERE (t."ALIAS_3"~'[^A-Za-z0-9\s]' AND (COALESCE("ALIAS_3",'')<>''))
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Must not have special character except ’&’ and single quotes';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.13.4
-- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",
		''ALIAS_3 should not start with space'',''1.13.4'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ("ALIAS_3" LIKE '' %'')';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3",
		'ALIAS_3 should not start with space','1.13.4' FROM mmi_v180."GA_POI" 
		 WHERE ("ALIAS_3" LIKE ' %')
		 */
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ALIAS_3 should not start with space';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.13.5
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",
		''Double Spaces are not allowed'',''1.13.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ("ALIAS_3" LIKE ''%  %'')';
		 /*
		  SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3",
		'Double Spaces are not allowed','1.13.5' FROM mmi_v180."GA_POI" 
		 WHERE ("ALIAS_3" LIKE '%  %')
		 */
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Double Spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.13.6
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",
		''If ALIAS_1 and ALIAS_2 is blank then ALIAS_3 also should be blank'',''1.13.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ( (COALESCE("ALIAS_1",'''')='''') AND (COALESCE("ALIAS_2",'''')='''') AND (COALESCE("ALIAS_3",'''')<>'''') )';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3",
		'If ALIAS_1 and ALIAS_2 is blank then ALIAS_3 also should be blank','1.13.6' FROM mmi_v180."GA_POI" 
		 WHERE ( (COALESCE("ALIAS_1",'')='') AND (COALESCE("ALIAS_2",'')='') AND (COALESCE("ALIAS_3",'')<>'') )	
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If ALIAS_1 and ALIAS_2 is blank then ALIAS_3 also should be blank';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.13.7
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",
		''ALIAS_3 should not equal to ADDRESS'',''1.13.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE	( LOWER(TRIM("ALIAS_3")) = LOWER(TRIM("ADDRESS")) AND (COALESCE("ALIAS_3",'''')<>'''') )';
		 /*
		  SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3",
		'ALIAS_3 should not equal to ADDRESS','1.13.7' FROM mmi_v180."GA_POI" 
		 WHERE	( LOWER(TRIM("ALIAS_3")) = LOWER(TRIM("ADDRESS")) AND (COALESCE("ALIAS_3",'')<>'') )
		 */
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ALIAS_3 should not equal to ADDRESS';
	RAISE NOTICE 'time spent =%', clock_timestamp();
	
-----------------------------------------------------------------------BRAND_NME--------------------------------------------------------------
--2.47.287
--ADDED BY GOLDY
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''BRAND_NME'',"BRAND_NME",''BRAND_NME should not equal to BRANCH_NME'',''2.47.287'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE( LOWER(TRIM("BRAND_NME")) = LOWER(TRIM("BRANCH_NME")) AND (COALESCE("BRAND_NME",'''')<>'''') )';
		 /*
		  SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3",
		'ALIAS_3 should not equal to ADDRESS','1.13.7' FROM mmi_v180."GA_POI" 
		 WHERE	( LOWER(TRIM("ALIAS_3")) = LOWER(TRIM("ADDRESS")) AND (COALESCE("ALIAS_3",'')<>'') )
		 */
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ALIAS_3 should not equal to ADDRESS';
	RAISE NOTICE 'time spent =%', clock_timestamp();

	
------------------------------------------------------------------------------------------------ADDRESS----------------------------------------------------------------------------------------------------------------------------------------------
--2.47.286
--ADDED BY GOLDY
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''BRAND_NME'',"BRAND_NME",''BRAND_NME should not equal to ADDRESS'',''2.47.286'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE( LOWER(TRIM("BRAND_NME")) = LOWER(TRIM("ADDRESS")) AND (COALESCE("BRAND_NME",'''')<>'''') )';
		 /*
		  SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3",
		'ALIAS_3 should not equal to ADDRESS','1.13.7' FROM mmi_v180."GA_POI" 
		 WHERE	( LOWER(TRIM("ALIAS_3")) = LOWER(TRIM("ADDRESS")) AND (COALESCE("ALIAS_3",'')<>'') )
		 */
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ALIAS_3 should not equal to ADDRESS';
	RAISE NOTICE 'time spent =%', clock_timestamp();

--2.47.64
-- 203 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS",''ADDRESS must be in Proper Case'',''2.47.64'' FROM  
		(SELECT "ID","NAME","ADDRESS",REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("ADDRESS",'' of '','' ''),'' and '','' ''),'' for '','' ''),'' By '','' ''),'' to '','' ''),'' in '','' ''),'' OR '','' ''),'' at '','' '')
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "ADDRESS"~''[^MDCLXVI]+$'') As t WHERE replace<>INITCAP(replace) ';

-- 		SELECT "ID","NAME",'tbl_nme','ADDRESS',"ADDRESS",'ADDRESS must be in Proper Case','1.2.1' FROM 
-- 		(SELECT "ID","NAME","ADDRESS",REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("ADDRESS",' of ',' '),' and ',' '),' for ',' '),' By ',' '),' to ',' '),' in ',' '),' OR ',' '),' at ',' ')
-- 		FROM mmi."DL_POI" WHERE (status NOT IN ('0','5') OR COALESCE(status,'')='') AND "ADDRESS"~'[^MDCLXVI]+$') As t WHERE replace<>INITCAP(replace) 

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ADDRESS must be in Proper Case';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--2.47.312
-- 47msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS",''All characters must not be in Upper case'',''2.47.312'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"  
		WHERE (UPPER("ADDRESS")=("ADDRESS")) AND "ADDRESS" is not null AND "ADDRESS"~''[a-zA-Z]+'' ';
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS",''All characters must not be in Upper case'',''2.47.312'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (UPPER("ADDRESS")=("ADDRESS"))';
		 /*
		  SELECT "ID","NAME",'GA_POI','ADDRESS',"ADDRESS",'All characters must not be in Upper case','2.47.312' FROM mmi_v180."GA_POI" As t 
		 WHERE (UPPER("ADDRESS")=("ADDRESS"))
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'All characters must not be in Upper case';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--2.47.313
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS",''All characters must not be in lower case'',''2.47.313'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		WHERE (LOWER("ADDRESS")=("ADDRESS")) AND (LOWER("ADDRESS") !~ ''^[0-9]'')	';
		 
		 --SELECT "ID","NAME",'GA_POI','ADDRESS',"ADDRESS",'All characters must not be in lower case','2.47.313' FROM mmi_v180."GA_POI" As t 
		 -- WHERE (LOWER("ADDRESS")=("ADDRESS")) AND (LOWER("ADDRESS") !~ '^[0-9]')	
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'All characters must not be in lower case';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--2.47.246 
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS", ''Must not have repetitive special character like ’&&’ and ’''''’'',''2.47.246'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."ADDRESS" IS NOT NULL AND t."ADDRESS"~''[/]{2,}|[-]{2,}|[,]{2,}|[&]{2,}'' ';
		
		--SELECT "ID","NAME",'GA_POI','ADDRESS',"ADDRESS", 'Must not have repetitive special character like ’&&’ and ’''''’','2.47.246' FROM mmi_v180."GA_POI" As t 
		--WHERE t."ADDRESS" IS NOT NULL AND t."ADDRESS"~'[/]{2,}|[-]{2,}|[,]{2,}|[&]{2,}' 
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Must not have repetitive special character like ’&&’';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.15.2
--235 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS",
		''ADDRESS should not contain any special characters'',''1.15.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE (t."ADDRESS"~''[^A-Za-z0-9\s,/&\-.()]'' AND (COALESCE("ADDRESS",'''')<>'''')) OR t."ADDRESS"~''^.*?\((?!.*\))[^\]]*$'' ';

		--SELECT "ID","NAME",'tbl_nme','ADDRESS',"ADDRESS",
		--'ADDRESS should not contain any special characters','1.15.2' FROM mmi_v180."DL_POI" As t 
		---WHERE (status NOT IN ('0','5') OR (COALESCE(status,'')='') ) AND 
		--(t."ADDRESS"~'[^A-Za-z0-9\s,/&\-.()]' AND (COALESCE("ADDRESS",'')<>'')) OR t."ADDRESS"~'^.*?\((?!.*\))[^\]]*$'
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ADDRESS should not contain any special characters';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.15.3
-- 218 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS",
		''ADDRESS should not contain India'',''1.15.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE ((LOWER(TRIM("ADDRESS")) = ''india'') OR (LOWER(TRIM("ADDRESS")) LIKE ''% india %'') OR (LOWER(TRIM("ADDRESS")) LIKE ''india %'') OR (LOWER(TRIM("ADDRESS")) LIKE ''% india'')) AND (COALESCE("ADDRESS",'''')<>'''')';

		--SELECT "ID","NAME",'tbl_nme','ADDRESS',"ADDRESS",
		--'ADDRESS should not contain India','1.15.3' FROM mmi_v180."DL_POI" As t 
		-- WHERE (status NOT IN ('0','5') OR (COALESCE(status,'')='') ) AND 
		--((LOWER(TRIM("ADDRESS")) = 'india') OR (LOWER(TRIM("ADDRESS")) LIKE '% india %') OR (LOWER(TRIM("ADDRESS")) LIKE 'india %') OR (LOWER(TRIM("ADDRESS")) LIKE '% india')) AND (COALESCE("ADDRESS",'')<>'')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ADDRESS should not contain India';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.15.3
-- 1.3 sec 
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS",
		''ADDRESS should not contain NAME'',''1.15.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE (LOWER(TRIM("ADDRESS")) LIKE ''% ''||LOWER(TRIM("NAME"))||'' %'' OR LOWER(TRIM("ADDRESS")) LIKE ''''||LOWER(TRIM("NAME"))||'' %'' OR LOWER(TRIM("ADDRESS")) LIKE ''% ''||LOWER(TRIM("NAME"))||'''') AND (COALESCE("ADDRESS",'''')<>'''')';

		--SELECT "ID","NAME",'tbl_nme','ADDRESS',"ADDRESS",
		--'ADDRESS should not contain NAME','1.15.3' FROM mmi_v180."DL_POI" As t WHERE
		--(LOWER(TRIM("ADDRESS")) LIKE '% '||LOWER(TRIM("NAME"))||' %' OR LOWER(TRIM("ADDRESS")) 
		--LIKE ''||LOWER(TRIM("NAME"))||' %' OR LOWER(TRIM("ADDRESS")) LIKE '% '||LOWER(TRIM("NAME"))||'') AND (COALESCE("ADDRESS",'')<>'')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ADDRESS should not contain NAME';
	RAISE NOTICE 'time spent =%', clock_timestamp();
-- --1.15.8
-- --156 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		-- SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS",
		-- ''ADDRESS should not start with space'',''1.15.8'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE ("ADDRESS" LIKE '' %'') ';

		-- --SELECT "ID","NAME",'tbl_nme','ADDRESS',"ADDRESS",
		-- --'ADDRESS should not start with space','1.15.8' FROM mmi_v180."DL_POI" As t 
		-- --WHERE ("ADDRESS" LIKE ' %')
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'ADDRESS should not start with space';
	-- RAISE NOTICE 'time spent =%', clock_timestamp();
--1.15.9
-- 180 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS",
		''Double Spaces are not allowed'',''1.15.9'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE ("ADDRESS" LIKE ''%  %'')';

		--SELECT "ID","NAME",'tbl_nme','ADDRESS',"ADDRESS",
		--'ADDRESS should not contain double spaces','1.15.9' FROM mmi_v180."DL_POI" As t 
		-- WHERE (status NOT IN ('0','5') OR (COALESCE(status,'')='') ) AND ("ADDRESS" LIKE '%  %')

		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ADDRESS should not contain double spaces';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.15.10
-- 31 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		-- SELECT t."ID",t."NAME",'''||tbl_nme||''',''ADDRESS'',t."ADDRESS",
		-- ''Special character must not present at Start and End of ADDRESS'',''1.15.10'' FROM ( SELECT "ID","NAME", substring("ADDRESS", char_length("ADDRESS")-0) enstring, "ADDRESS" 
		 -- FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"  ) As t WHERE t.enstring ~''[^A-Za-z0-9]'' ';

		-- --SELECT t."ID",t."NAME",'GA_POI','ADDRESS',t."ADDRESS",
		-- --'Special character must not present at Start and End of ADDRESS','1.15.10' FROM ( SELECT "ID","NAME", substring("ADDRESS", char_length("ADDRESS")-0) enstring, "ADDRESS" 
		-- --FROM mmi_v180."GA_POI" ) As t WHERE t.enstring ~'[^A-Za-z0-9]'	
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'Special character must not present at Start and End of ADDRESS';
	-- RAISE NOTICE 'time spent =%', clock_timestamp();
--1.15.11
-- 125 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT child."ID",t."NAME",'''||tbl_nme||''',''ADDRESS'',child."ADDRESS",''Child Poi’s address does not contains its Parent Poi’s NAME'',''1.15.11'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As child,
		(SELECT "ID","NAME","PIP_ID","ADDRESS","SEC_STA","FTR_CRY" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE "ID" IN (SELECT "PIP_ID" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "PIP_ID"<>0)) As t WHERE child."PIP_ID"=t."ID"  AND 
		child."FTR_CRY" NOT IN (''SHPAUT'',''SHPREP'',''SHPPWN'') AND LOWER(TRIM(child."ADDRESS")) NOT LIKE  ''%''||LOWER(TRIM(t."NAME"))||''%'' ';

		--SELECT child."ID",t."NAME",'GA_POI','ADDRESS',child."ADDRESS",'Child Poi’s address does not contains its Parent Poi’s NAME','1.15.11' FROM mmi_v180."GA_POI" As child,
		--(SELECT "ID","NAME","PIP_ID","ADDRESS","SEC_STA","FTR_CRY" FROM mmi_v180."GA_POI" 
		--WHERE "ID" IN (SELECT "PIP_ID" FROM mmi_v180."GA_POI" WHERE "PIP_ID"<>0)) As t WHERE child."PIP_ID"=t."ID" AND 
		--child."FTR_CRY" NOT IN ('SHPAUT','SHPREP','SHPPWN') AND LOWER(TRIM(child."ADDRESS")) NOT LIKE  '%'||LOWER(TRIM(t."NAME"))||'%'
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Child Poi’s address does not contains its Parent Poi’s NAME';
	RAISE NOTICE 'time spent =%', clock_timestamp();
	
-----2.47.333
-- ADDED BY GOLDY	
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS",''Combination of Name and Branch_Nme must not be equal to Address'',''2.47.333'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" tab1
		WHERE (COALESCE("NAME",'''') <> '''' AND COALESCE("BRANCH_NME",'''')<>'''') AND UPPER(COALESCE("NAME",'''')||'' ''||COALESCE("BRANCH_NME",'''')) = UPPER(COALESCE("ADDRESS"))   ';
		
		-- SELECT "ID","NAME" FROM mmi_master."DL_POI" WHERE (COALESCE("NAME") <> '' AND COALESCE("BRANCH_NME",'')<>'') AND 
		-- UPPER(COALESCE("NAME",'')||' '||COALESCE("BRANCH_NME",'')) = UPPER(COALESCE("ADDRESS"))

		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
		
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Combination of Name and Branch_Nme must not be equal to Address';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	
-----2.47.334
-- ADDED BY GOLDY	13/06/2019
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS",''Combination of ALIAS_1 and Branch_Nme must not be equal to Address'',''2.47.334'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" tab1
		WHERE (COALESCE("ALIAS_1",'''') <> '''' AND COALESCE("BRANCH_NME",'''')<>'''') AND UPPER(COALESCE("ALIAS_1",'''')||'' ''||COALESCE("BRANCH_NME",'''')) = UPPER(COALESCE("ADDRESS"))   ';
		
		-- SELECT "ID","NAME" FROM mmi_master."DL_POI" WHERE (COALESCE("NAME") <> '' AND COALESCE("BRANCH_NME",'')<>'') AND 
		-- UPPER(COALESCE("NAME",'')||' '||COALESCE("BRANCH_NME",'')) = UPPER(COALESCE("ADDRESS"))

		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
		
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Combination of ALIAS_1 and Branch_Nme must not be equal to Address';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	
-----2.47.335
-- ADDED BY GOLDY	13/06/2019
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS",''Combination of ALIAS_2 and Branch_Nme must not be equal to Address'',''2.47.335'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" tab1
		WHERE (COALESCE("ALIAS_2",'''') <> '''' AND COALESCE("BRANCH_NME",'''')<>'''') AND UPPER(COALESCE("ALIAS_2",'''')||'' ''||COALESCE("BRANCH_NME",'''')) = UPPER(COALESCE("ADDRESS"))   ';
		
		-- SELECT "ID","NAME" FROM mmi_master."DL_POI" WHERE (COALESCE("NAME") <> '' AND COALESCE("BRANCH_NME",'')<>'') AND 
		-- UPPER(COALESCE("NAME",'')||' '||COALESCE("BRANCH_NME",'')) = UPPER(COALESCE("ADDRESS"))

		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
		
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Combination of ALIAS_2 and Branch_Nme must not be equal to Address';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	
-----2.47.336
-- ADDED BY GOLDY	13/06/2019
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS",''Combination of ALIAS_3 and Branch_Nme must not be equal to Address'',''2.47.336'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" tab1
		WHERE (COALESCE("ALIAS_3",'''') <> '''' AND COALESCE("BRANCH_NME",'''')<>'''') AND UPPER(COALESCE("ALIAS_3",'''')||'' ''||COALESCE("BRANCH_NME",'''')) = UPPER(COALESCE("ADDRESS"))   ';
		
		-- SELECT "ID","NAME" FROM mmi_master."DL_POI" WHERE (COALESCE("NAME") <> '' AND COALESCE("BRANCH_NME",'')<>'') AND 
		-- UPPER(COALESCE("NAME",'')||' '||COALESCE("BRANCH_NME",'')) = UPPER(COALESCE("ADDRESS"))

		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
		
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Combination of ALIAS_3 and Branch_Nme must not be equal to Address';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	
-----2.47.337
-- ADDED BY GOLDY	13/06/2019
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS",''Combination of POPLR_NME and Branch_Nme must not be equal to Address'',''2.47.337'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" tab1
		WHERE (COALESCE("POPLR_NME",'''') <> '''' AND COALESCE("BRANCH_NME",'''')<>'''') AND UPPER(COALESCE("POPLR_NME",'''')||'' ''||COALESCE("BRANCH_NME",'''')) = UPPER(COALESCE("ADDRESS"))   ';
		
		-- SELECT "ID","NAME" FROM mmi_master."DL_POI" WHERE (COALESCE("NAME") <> '' AND COALESCE("BRANCH_NME",'')<>'') AND 
		-- UPPER(COALESCE("NAME",'')||' '||COALESCE("BRANCH_NME",'')) = UPPER(COALESCE("ADDRESS"))

		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
		
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Combination of POPLR_NME and Branch_Nme must not be equal to Address';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	
-------------------BRANCH_NME-----------	
-----2.47.280
-- ADDED BY GOLDY	14/06/2019
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''BRANCH_NME'',"BRANCH_NME",''Special charecter must not present at start and End of name'',''2.47.280'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" tab1
		WHERE "BRANCH_NME" like ''&%'' or "BRANCH_NME" like ''%&'' or "BRANCH_NME" like ''%-'' or "BRANCH_NME" like ''-%'' or "BRANCH_NME" like ''%  %'' or "BRANCH_NME" like '' %'' ';
		
		-- SELECT "ID","BRANCH_NME" FROM mmi_master."DL_POI" 
		-- WHERE "BRANCH_NME" like '&%' or "BRANCH_NME" like '%&' or "BRANCH_NME" like '%-' or "BRANCH_NME" like '-%' or "BRANCH_NME" like '%  %' or "BRANCH_NME" like ' %'
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
		
		
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Combination of POPLR_NME and Branch_Nme must not be equal to Address';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	
----------------------------------------------------------------------------------------------FTR_CRY------------------------------------------------------------------------------------------------------------------------------------------------
--- -- -1.3.2
	-- BEGIN
-- 		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''FTR_CRY'',"FTR_CRY",
-- 		''FTR_CRY must be in UPPER Case'',''1.3.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
-- 		 WHERE (UPPER("FTR_CRY") <> "FTR_CRY")';
-- 		EXCEPTION
-- 		WHEN OTHERS THEN
-- 		GET STACKED DIAGNOSTICS 
-- 			f1=MESSAGE_TEXT,
-- 			f2=PG_EXCEPTION_CONTEXT; 
-- 				
-- 		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
-- 		RAISE info 'error caught 2.1:%',f1;
-- 		RAISE info 'error caught 2.2:%',f2;
-- 	END;
--1.3.3
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''FTR_CRY'',"FTR_CRY",
		''FTR_CRY should not be blank'',''1.3.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE (COALESCE("FTR_CRY",'''')='''')'; 
		 /*
		  SELECT "ID","NAME",'GA_POI','FTR_CRY',"FTR_CRY",
		'FTR_CRY should not be blank','1.3.3' FROM mmi_v180."GA_POI" As t 
		 WHERE (COALESCE("FTR_CRY",'')='')
		 */
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'FTR_CRY should not be blank';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.3.4
	-- BEGIN
-- 		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''FTR_CRY'',"FTR_CRY",
-- 		''FTR_CRY length must be equal to 6'',''1.3.4'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
-- 		 WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND LENGTH("FTR_CRY")<>6';
-- 		EXCEPTION
-- 		WHEN OTHERS THEN
-- 		GET STACKED DIAGNOSTICS 
-- 			f1=MESSAGE_TEXT,
-- 			f2=PG_EXCEPTION_CONTEXT; 
-- 				
-- 		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
-- 		RAISE info 'error caught 2.1:%',f1;
-- 		RAISE info 'error caught 2.2:%',f2;
-- 	END;
--1.3.6
-- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",
		''If FTR_CRY=STRPUN then NAME should contain Puncture word'',''1.3.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."FTR_CRY" LIKE ''STRPUN'' AND COALESCE(t."DE_IMGPATH",'''')=''''  AND LOWER("NAME") NOT LIKE ''% puncture %'' AND LOWER("NAME") NOT LIKE ''puncture %'' AND LOWER("NAME") NOT LIKE ''% puncture'' ';
         
		--SELECT "ID","NAME",'GA_POI','NAME',"NAME",
		--'If FTR_CRY=STRPUN then NAME should contain Puncture word','1.3.6' FROM mmi_v180."GA_POI" As t 
		--WHERE t."FTR_CRY" LIKE 'STRPUN' AND LOWER("NAME") NOT LIKE '% puncture %' AND LOWER("NAME") NOT LIKE 'puncture %' AND LOWER("NAME") NOT LIKE '% puncture' 
		 
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If FTR_CRY=STRPUN then NAME should contain Puncture word';
	RAISE NOTICE 'time spent =%', clock_timestamp();
	
--1.3.7
-- 31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''IMP_POI'',"IMP_POI",
		-- ''If FTR_CRY=HOTPRE then IMP_POI should be IMP_'',''1.3.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND t."FTR_CRY" LIKE ''HOTPRE'' AND t."IMP_POI" NOT LIKE ''IMP_%'' ';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''IMP_POI'',"IMP_POI",
		''If FTR_CRY=HOTPRE then IMP_POI should be IMP%'',''1.3.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."FTR_CRY" LIKE ''HOTPRE'' AND t."IMP_POI" NOT LIKE ''IMP%'' ';
		 
		 --SELECT "ID","NAME",'GA_POI','IMP_POI',"IMP_POI",
		 --'If FTR_CRY=HOTPRE then IMP_POI should be IMP%','1.3.7' FROM mmi_v180."GA_POI" As t 
		 --WHERE t."FTR_CRY" LIKE 'HOTPRE' AND t."IMP_POI" NOT LIKE 'IMP%'

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
    RAISE INFO 'HOTPRE then IMP_POI should be IMP';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.3.8
--47 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''FTR_CRY'',"FTR_CRY",
		''FTR_CRY should be in proper form that is : it can be OTH OR 6 alphabets all in capitals with no special character or number'',''1.3.8'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."FTR_CRY"!~''^[A-Z]{6}$'' AND t."FTR_CRY"!=''OTH'' ';

		-- SELECT "ID","NAME",'tbl_nme','FTR_CRY',"FTR_CRY",
		--'FTR_CRY should be in proper form that is : it can be OTH OR 6 alphabets all in capitals with no special character or number','1.3.8' FROM mmi_v161."DL_POI" As t 
		-- WHERE (status NOT IN ('0','5') OR (COALESCE(status,'')='') ) AND t."FTR_CRY"!~'^[A-Z]{6}$' AND t."FTR_CRY"!='OTH'
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'FTR_CRY should be in proper form that is : it can be OTH OR 6 alphabets all in capitals with no special character or number';
	RAISE NOTICE 'time spent =%', clock_timestamp();
	
--2.47.380
--480 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''FTR_CRY'',"FTR_CRY",
		''Where MSTRCODETYP="B" in Poi_Cat layer, then these category must not be available in Poi Layer'',''2.47.380'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "FTR_CRY" IN (SELECT "MSTR_CODE" FROM '||sch_name||'."POI_CAT" WHERE "MstrCodTyp" = ''B'') ';

		-- SELECT "ID","FTR_CRY" FROM mmi_master."DL_POI" WHERE "FTR_CRY" IN (SELECT "MSTR_CODE" FROM mmi_master."POI_CAT" WHERE "MstrCodTyp" = 'B')

		RAISE INFO '<---------2.47.380';	
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'FTR_CRY should be in proper form that is : it can be OTH OR 6 alphabets all in capitals with no special character or number';
	RAISE NOTICE 'time spent =%', clock_timestamp();	
-----------------------------------------------------------------------------------------------SUB_CRY-----------------------------------------------------------------------------------------------------------------------------------------------
--1.5.2
	-- BEGIN
-- 		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''SUB_CRY'',"SUB_CRY",
-- 		''SUB_CRY Have Less THEN 6 Character'',''1.5.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
-- 		 WHERE LENGTH("SUB_CRY") <> 6';
-- 
-- 		EXCEPTION
-- 		WHEN OTHERS THEN
-- 		GET STACKED DIAGNOSTICS 
-- 			f1=MESSAGE_TEXT,
-- 			f2=PG_EXCEPTION_CONTEXT; 
-- 				
-- 		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
-- 		RAISE info 'error caught 2.1:%',f1;
-- 		RAISE info 'error caught 2.2:%',f2;
-- 	END;
--1.5.2
	-- BEGIN
-- 		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''SUB_CRY'',"SUB_CRY",
-- 		''SUB_CRY Must Be In UPPER Case'',''1.5.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
-- 		 WHERE UPPER("SUB_CRY") <> ("SUB_CRY")';
-- 
-- 		EXCEPTION
-- 		WHEN OTHERS THEN
-- 		GET STACKED DIAGNOSTICS 
-- 			f1=MESSAGE_TEXT,
-- 			f2=PG_EXCEPTION_CONTEXT; 
-- 				
-- 		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
-- 		RAISE info 'error caught 2.1:%',f1;
-- 		RAISE info 'error caught 2.2:%',f2;
-- 	END;

--1.5.2
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
  		 SELECT "ID","NAME",'''||tbl_nme||''',''SUB_CRY'',"SUB_CRY",
		''SUB_CRY must be in proper form that is : 6 alphabets all in capitals with no special character or number '',''1.5.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE "SUB_CRY"!~''^[A-Z0-9]{6}$'' ';
		 
		 ---SELECT "ID","NAME",'GA_POI','SUB_CRY',"SUB_CRY",
		 --'SUB_CRY must be in proper form that is : 6 alphabets all in capitals with no special character or number','1.5.2' FROM mmi_v180."GA_POI" As t 
		 --WHERE "SUB_CRY"!~'^[A-Z]{6}$'

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
    RAISE INFO 'SUB_CRY must be in proper form that is : 6 alphabets all in capitals with no special character or number';
	RAISE NOTICE 'time spent =%', clock_timestamp(); 	
-----------------------------------------------------------------------------------------------CODE_NME----------------------------------------------------------------------------------------------------------------------------------------------
--1.14.1
-- 31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''CODE_NME'',"CODE_NME",
		-- ''CODE_NME should not contain numeric values'',''1.14.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND (t."CODE_NME"~''[0-9]'' AND (COALESCE("CODE_NME",'''')<>''''))';

		-- SELECT "ID","NAME",'tbl_nme','CODE_NME',"CODE_NME",
		--'CODE_NME should not contain numeric values','1.14.1' FROM mmi_v161."DL_POI" As t 
		-- WHERE (status NOT IN ('0','5') OR (COALESCE(status,'')='') ) AND (t."CODE_NME"~'[0-9]' AND (COALESCE("CODE_NME",'')<>''))
		--ADDED BY BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
				SELECT "ID","NAME",'''||tbl_nme||''',''CODE_NME'',"CODE_NME",''VALUE MUST NOT BE EQUAL TO ONE WORD'',''1.14.1'' 
				FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
				WHERE COALESCE("CODE_NME",'''')<>'''' AND LENGTH(TRIM("CODE_NME"))=1';
		 
		---SELECT "ID","NAME",'GA_POI','CODE_NME',"CODE_NME",
		---'Only Numeric & Alphabtes(Capital) values are accepted','1.14.1' 
		---FROM mmi_v180."GA_POI" As t 
		---WHERE (t."CODE_NME"~'[^0-9A-Z]' AND (COALESCE("CODE_NME",'')<>'')) 
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Only Numeric & Alphabtes(Capital) values are accepted';
	RAISE NOTICE 'time spent =%', clock_timestamp(); 
--1.14.2
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME",''CODE_NME should not contain NAME, POPLR_NME & ALIAS'',''1.14.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("CODE_NME",'''')<>'''') AND (LOWER(TRIM("CODE_NME")) LIKE ''%''||LOWER(TRIM("NAME"))||''%'' ))';
		
		--SELECT "ID","NAME",'GA_POI','NAME',"NAME",'CODE_NME should not contain NAME, POPLR_NME & ALIAS','1.14.2' FROM mmi_v180."GA_POI" 
		-- WHERE ((COALESCE("CODE_NME",'')<>'') AND (LOWER(TRIM("CODE_NME")) LIKE '%'||LOWER(TRIM("NAME"))||'%' ))	
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'CODE_NME should not contain NAME';
	RAISE NOTICE 'time spent =%', clock_timestamp(); 
--1.14.2
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",
		''CODE_NME should not contain NAME, POPLR_NME & ALIAS'',''1.14.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
         WHERE ((COALESCE("CODE_NME",'''')<>'''') AND (LOWER(TRIM("CODE_NME")) LIKE ''%''||LOWER(TRIM("POPLR_NME"))||''%'' ))';
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'CODE_NME should not contain NAME, POPLR_NME & ALIAS';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.14.2
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1",
		''CODE_NME should not contain NAME, POPLR_NME & ALIAS'',''1.14.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ((COALESCE("CODE_NME",'''')<>'''') AND (LOWER(TRIM("CODE_NME")) LIKE ''%''||LOWER(TRIM("ALIAS_1"))||''%'' ))';
		
		--SELECT "ID","NAME",'GA_POI','ALIAS_1',"ALIAS_1",
		--'CODE_NME should not contain NAME, POPLR_NME & ALIAS','1.14.2' FROM mmi_v180."GA_POI" 
		--WHERE ((COALESCE("CODE_NME",'')<>'') AND (LOWER(TRIM("CODE_NME")) LIKE '%'||LOWER(TRIM("ALIAS_1"))||'%' ))
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'CODE_NME should not contain NAME, POPLR_NME & ALIAS';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.14.2
-- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2",
		''CODE_NME should not contain NAME, POPLR_NME & ALIAS'',''1.14.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
		 WHERE ((COALESCE("CODE_NME",'''')<>'''') AND (LOWER(TRIM("CODE_NME")) LIKE ''%''||LOWER(TRIM("ALIAS_2"))||''%'' ))';
	
	    --SELECT "ID","NAME",'GA_POI','ALIAS_2',"ALIAS_2",
		--'CODE_NME should not contain NAME, POPLR_NME & ALIAS','1.14.2' FROM mmi_v180."GA_POI"
		--WHERE ((COALESCE("CODE_NME",'')<>'') AND (LOWER(TRIM("CODE_NME")) LIKE '%'||LOWER(TRIM("ALIAS_2"))||'%' ))
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'CODE_NME should not contain NAME, POPLR_NME & ALIAS';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.14.2
-- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3",
		''CODE_NME should not contain NAME, POPLR_NME & ALIAS'',''1.14.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 

		 WHERE ((COALESCE("CODE_NME",'''')<>'''') AND (LOWER(TRIM("CODE_NME")) LIKE ''%''||LOWER(TRIM("ALIAS_3"))||''%'' ))';
		 
		 /*
		 SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3",
		'CODE_NME should not contain NAME, POPLR_NME & ALIAS','1.14.2' FROM mmi_v180."GA_POI" 
		 WHERE ((COALESCE("CODE_NME",'')<>'') AND (LOWER(TRIM("CODE_NME")) LIKE '%'||LOWER(TRIM("ALIAS_3"))||'%' ))
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'CODE_NME should not contain NAME, POPLR_NME & ALIAS';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.14.3
---31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''CODE_NME'',"CODE_NME",
		''CODE_NME must be in UPPER Case'',''1.14.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE (UPPER("CODE_NME")<>("CODE_NME"))';
		 
		 /*
		   SELECT "ID","NAME",'GA_POI','CODE_NME',"CODE_NME",
		'CODE_NME must be in UPPER Case','1.14.3' FROM mmi_v180."GA_POI" As t 
		 WHERE (UPPER("CODE_NME")<>("CODE_NME"))
		 */
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'CODE_NME must be in UPPER Case';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.14.4
--16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''CODE_NME'',"CODE_NME",
		''CODE_NME should not contain any special characters'',''1.14.4'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE (t."CODE_NME"~''[^A-Za-z0-9\s]'' AND (COALESCE("CODE_NME",'''')<>''''))';
		 /*
		  SELECT "ID","NAME",'GA_POI','CODE_NME',"CODE_NME",
		'CODE_NME should not contain any special characters','1.14.4' FROM mmi_v180."GA_POI" As t 
		 WHERE (t."CODE_NME"~'[^A-Za-z0-9\s]' AND (COALESCE("CODE_NME",'')<>''))
		 */
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'CODE_NME should not contain any special characters';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--------------------------------------------------------------------------------------------------TEL------------------------------------------------------------------------------------------------------------------------------------------------
--1.16.1
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''TEL'',"TEL",''TEL length should be 13 OR 28 OR 43'',''1.16.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND (LENGTH("TEL")<> 13 AND LENGTH("TEL")<> 28 AND LENGTH("TEL")<> 43)';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.16.7
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''TEL'',"TEL",''TEL should not contain any special characters Except + and ,'',''1.16.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND t."TEL"~''[^0-9\s+,]'' AND (COALESCE("TEL",'''')<>'''')';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.16.8
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''TEL'',"TEL",''Double Spaces are not allowed'',''1.16.8'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND ("TEL" LIKE ''%  %'')';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.16.9
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		 -- SELECT t7."ID",t7."NAME",'''||tbl_nme||''',''TEL'',t7."TEL"::text,''TEL should not be repeated or duplicate'',''1.16.9''
		 -- FROM ( SELECT t."ID",t."NAME",t."TEL",t.CONCAT,COUNT(*) OVER (PARTITION By t.CONCAT) As ct 
		 -- FROM ( SELECT "ID","NAME","TEL",unnest(String_To_Array(replace("TEL",'','',''''), '' '')) As TEL, CONCAT("ID",'' '',unnest(String_To_Array(replace("TEL",'','',''''), '' ''))) 
		 -- FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND 
		 -- (TRIM("TEL") ~ ''[0-9][,][\s][0-9]'' OR TRIM("TEL")~''[0-9][\s][0-9]'' OR TRIM("TEL") ~ ''[0-9][,][\s][0-9][,][\s][0-9]'' OR TRIM("TEL") ~ ''[0-9][,][\s][0-9]][\s][0-9]'' OR TRIM("TEL") ~ ''[0-9][\s][0-9][\s][0-9]'' OR TRIM("TEL") ~ ''[0-9][\s][0-9][,][\s][0-9]'' )) As t) As t7 WHERE ct>1 
		 -- AND (COALESCE(t7.CONCAT,'''')<>'''') GROUP By  t7."ID",t7."NAME",t7."TEL",t7.CONCAT ';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;

--1.16.10
-- 375 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''TEL'',"TEL",''TEL should not contain 0 after +91 and should be in proper form'',''1.16.10'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE ("TEL"!~''^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$''  
		 OR "TEL"!~''[+]{1}[9]{1}[1]{1}[1-9]{1}[0-9]{9}'') ';

		--SELECT "ID","NAME",'tbl_nme','TEL',"TEL",
		--'TEL should not contain 0 after +91 and should be in proper form','1.16.10' FROM mmi_v161."DL_POI" AS t WHERE 
		-- (t."TEL"!~'^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$' OR t."TEL"!~'[+]{1}[9]{1}[1]{1}[1-9]{1}[0-9]{9}')
	

		EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
				
			EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
			RAISE info 'error caugth 2.1:%',f1;
			RAISE info 'error caugth 2.2:%',f2;

	END;		
    RAISE INFO 'TEL should not contain 0 after +91 and should be in proper form';
	RAISE NOTICE 'time spent =%', clock_timestamp();
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--1.16.1
--15 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''TEL'',"TEL",
		''Double Spaces are not allowed'',''1.16.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE  ("TEL" LIKE ''%  %'')';

		--SELECT "ID","NAME",'tbl_nme||','TEL',"TEL",
		--'Double Spaces are not allowed','1.16.1' FROM mmi_v180."GA_POI" WHERE (status NOT IN ('0','5') OR (COALESCE(status,'')='') ) AND ("TEL" LIKE '%  %')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'Double Spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.16.7
-- 15 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''TEL'',"TEL",
		''TEL length should be 13 or 28 or 43'',''1.16.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (LENGTH("TEL")<> 13 and LENGTH("TEL")<> 28 and LENGTH("TEL")<> 43)';

		--SELECT "ID","NAME",'tbl_nme','TEL',"TEL",
		--'TEL length should be 13 or 28 or 43','1.16.7' FROM mmi_v180."GA_POI" WHERE (LENGTH("TEL")<> 13 and LENGTH("TEL")<> 28 and LENGTH("TEL")<> 43)

		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'TEL length should be 13 or 28 or 43';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.16.8
-- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''TEL'',"TEL",
		''TEL should not contain any special characters Except + and ,'',''1.16.8'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" AS t WHERE t."TEL"~''[^0-9\s+,]'' AND (COALESCE("TEL",'''')<>'''')';

		--SELECT "ID","NAME",'GA_POI','TEL',"TEL",
		--'TEL should not contain any special characters Except + and ,'',''1.16.8' FROM mmi_v180."GA_POI" AS t WHERE t."TEL"~'[^0-9\s+,]' AND (COALESCE("TEL",'')<>'')

		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'TEL should not contain any special characters Except + and';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.16.9
-- 687 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		( SELECT t7."ID",t7."NAME",'''||tbl_nme||''',''TEL'',t7."TEL"::text,''TEL should not be repeated or duplicate'',''1.16.9''
		FROM (Select t."ID",t."NAME",t."TEL",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		FROM (SELECT "ID","NAME","TEL",unnest(String_To_Array(replace("TEL",'','',''''), '' '')) as TEL, CONCAT("ID",'' '',unnest(String_To_Array(replace("TEL",'','',''''), '' ''))) 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE ("TEL"~''^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$'')) AS t) AS t7 WHERE ct>1 
		AND (COALESCE(t7.CONCAT,'''')<>'''') GROUP BY  t7."ID",t7."NAME",t7."TEL",t7.CONCAT)';

		
		--( SELECT t7."ID",t7."NAME",'tbl_nme','TEL',t7."TEL"::text,'TEL should not be repeated or duplicate','1.16.9'
		--FROM (Select t."ID",t."NAME",t."TEL",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		--FROM (SELECT "ID","NAME","TEL",unnest(String_To_Array(replace("TEL",',',''), ' ')) as TEL, CONCAT("ID",' ',unnest(String_To_Array(replace("TEL",',',''), ' '))) 
		--FROM mmi_v161."DL_POI" WHERE 
		--("TEL"~'^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$')) AS t) AS t7 WHERE ct>1 
		--AND (COALESCE(t7.CONCAT,'')<>'') GROUP BY  t7."ID",t7."NAME",t7."TEL",t7.CONCAT) 
				
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;	
	RAISE INFO 'TEL should not be repeated or duplicate';
	RAISE NOTICE 'time spent =%', clock_timestamp();
------------------------------------------------------------------------------------------------EM_TEL-----------------------------------------------------------------------------------------------------------------------------------------------
--1.17.5
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''EM_TEL'',"EM_TEL",''EM_TEL should not contain any special characters Except + and ,'',''1.17.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE t."EM_TEL"~''[^0-9\s+,]'' AND (COALESCE("EM_TEL",'''')<>'''')';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.17.7
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''EM_TEL'',"EM_TEL",''Double Spaces are not allowed'',''1.17.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE ("EM_TEL" LIKE ''%  %'')';
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.17.8
	-- BEGIN	
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT t7."ID",t7."NAME",'''||tbl_nme||''',''EM_TEL'',t7."EM_TEL"::text,''EM_TEL should not be repeated or duplicate'',''1.17.8''
		 -- FROM ( SELECT t."ID",t."NAME",t."EM_TEL",t.CONCAT,COUNT(*) OVER (PARTITION By t.CONCAT) As ct 
		 -- FROM ( SELECT "ID","NAME","EM_TEL",unnest(String_To_Array(replace("EM_TEL",'','',''''), '' '')) As EM_TEL, CONCAT("ID",'' '',unnest(String_To_Array(replace("EM_TEL",'','',''''), '' ''))) 
		 -- FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE 
		 -- (TRIM("EM_TEL") ~ ''[0-9][,][\s][0-9]'' OR TRIM("EM_TEL")~''[0-9][\s][0-9]'' OR TRIM("EM_TEL") ~ ''[0-9][,][\s][0-9][,][\s][0-9]'' OR TRIM("EM_TEL") ~ ''[0-9][,][\s][0-9]][\s][0-9]'' OR TRIM("EM_TEL") ~ ''[0-9][\s][0-9][\s][0-9]'' OR TRIM("EM_TEL") ~ ''[0-9][\s][0-9][,][\s][0-9]'' )) As t) As t7 WHERE ct>1 
		 -- AND (COALESCE(t7.CONCAT,'''')<>'''') GROUP By  t7."ID",t7."NAME",t7."EM_TEL",t7.CONCAT';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	
--1.17.5
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''EM_TEL'',"EM_TEL",
		''EM_TEL should not contain any special characters Except + and ,'',''1.17.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" AS t 
		WHERE t."EM_TEL"~''[^0-9\s+,]'' AND (COALESCE("EM_TEL",'''')<>'''')';

		--SELECT "ID","NAME",'DL','EM_TEL',"EM_TEL",
		--'EM_TEL should not contain any special characters Except + and ,','1.17.5' FROM mmi_v180."GA_POI" AS t 
		--WHERE t."EM_TEL"~'[^0-9\s+,]' AND (COALESCE("EM_TEL",'')<>'')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'EM_TEL should not contain any special characters Except + and ';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.17.7
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''EM_TEL'',"EM_TEL",
		''Double Spaces are not allowed'',''1.17.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE ("EM_TEL" LIKE ''%  %'')';

		--SELECT "ID","NAME",'tbl_nme','EM_TEL',"EM_TEL",
		--'Double Spaces are not allowed','1.17.7' FROM mmi_v180."GA_POI" WHERE ("EM_TEL" LIKE '%  %')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'Double Spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.17.8
--31 msec
	BEGIN	
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		( SELECT t7."ID",t7."NAME",'''||tbl_nme||''',''EM_TEL'',t7."EM_TEL"::text,''EM_TEL should not be repeated or duplicate'',''1.17.8''
		FROM (Select t."ID",t."NAME",t."EM_TEL",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		FROM (SELECT "ID","NAME","EM_TEL",unnest(String_To_Array(replace("EM_TEL",'','',''''), '' '')) as EM_TEL, CONCAT("ID",'' '',unnest(String_To_Array(replace("EM_TEL",'','',''''), '' ''))) 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (trim("EM_TEL") ~ ''[0-9][,][\s][0-9]'' OR trim("EM_TEL")~''[0-9][\s][0-9]''  OR trim("EM_TEL") ~ ''[0-9][,][\s][0-9][,][\s][0-9]'' 
		OR trim("EM_TEL") ~ ''[0-9][,][\s][0-9]][\s][0-9]'' OR trim("EM_TEL") ~ ''[0-9][\s][0-9][\s][0-9]'' OR trim("EM_TEL") ~ ''[0-9][\s][0-9][,][\s][0-9]'' )) AS t) AS t7 WHERE ct>1 
		AND (COALESCE(t7.CONCAT,'''')<>'''') GROUP BY  t7."ID",t7."NAME",t7."EM_TEL",t7.CONCAT)';
		
		/*
		 ( SELECT t7."ID",t7."NAME",'DL','EM_TEL',t7."EM_TEL"::text,'EM_TEL should not be repeated or duplicate','1.17.8'
		FROM (Select t."ID",t."NAME",t."EM_TEL",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
	        FROM (SELECT "ID","NAME","EM_TEL",unnest(String_To_Array(replace("EM_TEL",',',''), ' ')) as EM_TEL, CONCAT("ID",' ',unnest(String_To_Array(replace("EM_TEL",',',''), ' '))) 
		FROM mmi_v180."GA_POI" WHERE (trim("EM_TEL") ~ '[0-9][,][\s][0-9]' OR trim("EM_TEL")~'[0-9][\s][0-9]'  OR trim("EM_TEL") ~ '[0-9][,][\s][0-9][,][\s][0-9]' 
		OR trim("EM_TEL") ~ '[0-9][,][\s][0-9]][\s][0-9]' OR trim("EM_TEL") ~ '[0-9][\s][0-9][\s][0-9]' OR trim("EM_TEL") ~ '[0-9][\s][0-9][,][\s][0-9]' )
		) AS t) AS t7 WHERE ct>1 AND (COALESCE(t7.CONCAT,'')<>'') GROUP BY  t7."ID",t7."NAME",t7."EM_TEL",t7.CONCAT)	
		*/
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'EM_TEL should not be repeated or duplicate';
	RAISE NOTICE 'time spent =%', clock_timestamp();
------------------------------------------------------------------------------------------------MOB_TEL----------------------------------------------------------------------------------------------------------------------------------------------
--1.18.5
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''MOB_TEL'',"MOB_TEL",''MOB_TEL should not contain any special characters Except + and ,'',''1.18.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE 
		-- t."MOB_TEL"~''[^0-9\s+,]'' AND "MOB_TEL" !~ ''^[0-9+]+$'' AND "MOB_TEL" !~ ''^[0-9+]+[,\s]+[0-9+]+$'' AND "MOB_TEL" !~ ''^[0-9+]+[,\s]+[0-9+]+[,\s]+[0-9+]+$'' AND (COALESCE("MOB_TEL",'''')<>'''')';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.18.6
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''MOB_TEL'',"MOB_TEL",''MOB_TEL should not contain Tel & EM_TEL'',''1.18.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE 
		-- (TRIM("MOB_TEL") LIKE ''%''||TRIM("TEL")||''%'' OR TRIM("MOB_TEL") LIKE ''%''||TRIM("EM_TEL")||''%'')';

		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.18.7
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''MOB_TEL'',"MOB_TEL", ''Double Spaces are not allowed'',''1.18.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE ("MOB_TEL" LIKE ''%  %'')';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.18.8
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''MOB_TEL'',"MOB_TEL", ''POI_POINT MOB_TEL length <> 13, 28, 43'',''1.18.8'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE  LENGTH("MOB_TEL")<> 13 AND LENGTH("MOB_TEL")<> 28 AND LENGTH("MOB_TEL")<> 43';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.18.9
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		-- ( SELECT t7."ID",t7."NAME",'''||tbl_nme||''',''MOB_TEL'',t7."MOB_TEL"::text,''MOB_TEL should not be repeated or duplicate'',''1.18.9''
		 -- FROM ( SELECT t."ID",t."NAME",t."MOB_TEL",t.CONCAT,COUNT(*) OVER (PARTITION By t.CONCAT) As ct 
		 -- FROM ( SELECT "ID","NAME","MOB_TEL",unnest(String_To_Array(replace("MOB_TEL",'','',''''), '' '')) As MOB_TEL, CONCAT("ID",'' '',unnest(String_To_Array(replace("MOB_TEL",'','',''''), '' ''))) 
		 -- FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE 
		 -- (TRIM("MOB_TEL") ~ ''[0-9][,][\s][0-9]'' OR TRIM("MOB_TEL")~''[0-9][\s][0-9]'' OR TRIM("MOB_TEL") ~ ''[0-9][,][\s][0-9][,][\s][0-9]'' OR TRIM("MOB_TEL") ~ ''[0-9][,][\s][0-9]][\s][0-9]'' OR TRIM("MOB_TEL") ~ ''[0-9][\s][0-9][\s][0-9]'' OR TRIM("MOB_TEL") ~ ''[0-9][\s][0-9][,][\s][0-9]'')) As t) As t7 WHERE ct>1 
		 -- AND (COALESCE(t7.CONCAT,'''')<>'''') GROUP By  t7."ID",t7."NAME",t7."MOB_TEL",t7.CONCAT)';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	
--1.18.5
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''MOB_TEL'',"MOB_TEL",
		''MOB_TEL should not contain any special characters Except + and ,'',''1.18.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" AS t WHERE t."MOB_TEL"~''[^0-9\s+,]'' 
		 AND "MOB_TEL" !~ ''^[0-9+]+$'' AND "MOB_TEL" !~ ''^[0-9+]+[,\s]+[0-9+]+$'' AND "MOB_TEL" !~ ''^[0-9+]+[,\s]+[0-9+]+[,\s]+[0-9+]+$'' AND (COALESCE("MOB_TEL",'''')<>'''')';

		--SELECT "ID","NAME",'tbl_nm','MOB_TEL',"MOB_TEL",
		--'MOB_TEL should not contain any special characters Except + and ,','1.18.5' FROM mmi_v180."GA_POI" AS t WHERE t."MOB_TEL"~'[^0-9\s+,]' 
		--AND "MOB_TEL" !~ '^[0-9+]+$' AND "MOB_TEL" !~ '^[0-9+]+[,\s]+[0-9+]+$' AND "MOB_TEL" !~ '^[0-9+]+[,\s]+[0-9+]+[,\s]+[0-9+]+$' AND (COALESCE("MOB_TEL",'')<>'')

		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'MOB_TEL should not contain any special characters Except +';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.18.6
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		 SELECT "ID","NAME",'''||tbl_nme||''',''MOB_TEL'',"MOB_TEL",
		''MOB_TEL should not contain Tel & EM_TEL'',''1.18.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE ("MOB_TEL"="TEL" OR "MOB_TEL"="EM_TEL")';

		--SELECT "ID","NAME",'tbl_nme','MOB_TEL',"MOB_TEL",
		--'MOB_TEL should not contain Tel & EM_TEL','1.18.6' FROM mmi_v180."GA_POI" WHERE ("MOB_TEL"="TEL" OR "MOB_TEL"="EM_TEL")

		
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'MOB_TEL should not contain Tel & EM_TEL';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.18.7
-- 31 msec 
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''MOB_TEL'',"MOB_TEL",
		''Double Spaces are not allowed'',''1.18.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE ("MOB_TEL" LIKE ''%  %'')';

		--SELECT "ID","NAME",'tbl_nme','MOB_TEL',"MOB_TEL",
		--'Double Spaces are not allowed','1.18.7' FROM mmi_v180."GA_POI" WHERE ("MOB_TEL" LIKE '%  %')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'Double Spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.18.8
-- 32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''MOB_TEL'',"MOB_TEL",
		''POI_POINT MOB_TEL length <> 13, 28, 43'',''1.18.8'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE  LENGTH("MOB_TEL")<> 13 AND LENGTH("MOB_TEL")<> 28 
		AND LENGTH("MOB_TEL")<> 43';

		--SELECT "ID","NAME",'tbl_nme','MOB_TEL',"MOB_TEL",
		--'POI_POINT MOB_TEL length <> 13, 28, 43','1.18.8' FROM mmi_v180."GA_POI" WHERE  LENGTH("MOB_TEL")<> 13 AND LENGTH("MOB_TEL")<> 28 
		--AND LENGTH("MOB_TEL")<> 43
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'POI_POINT MOB_TEL length <> 13, 28, 43';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.18.9
-- 62 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		( SELECT t7."ID",t7."NAME",'''||tbl_nme||''',''MOB_TEL'',t7."MOB_TEL"::text,''MOB_TEL should not be repeated or duplicate'',''1.18.9''
		FROM (Select t."ID",t."NAME",t."MOB_TEL",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		FROM (SELECT "ID","NAME","MOB_TEL",unnest(String_To_Array(replace("MOB_TEL",'','',''''), '' '')) as MOB_TEL, CONCAT("ID",'' '',unnest(String_To_Array(replace("MOB_TEL",'','',''''), '' ''))) 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE ("MOB_TEL"~''^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$'' )) AS t) AS t7 WHERE ct>1 
		AND (COALESCE(t7.CONCAT,'''')<>'''') GROUP BY  t7."ID",t7."NAME",t7."MOB_TEL",t7.CONCAT)';

     /*
	  ( SELECT t7."ID",t7."NAME",'tbl_nme','MOB_TEL',t7."MOB_TEL"::text,'MOB_TEL should not be repeated or duplicate','1.18.9'
		FROM (Select t."ID",t."NAME",t."MOB_TEL",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		FROM (SELECT "ID","NAME","MOB_TEL",unnest(String_To_Array(replace("MOB_TEL",',',''), ' ')) as MOB_TEL, CONCAT("ID",' ',unnest(String_To_Array(replace("MOB_TEL",',',''), ' '))) 
		FROM mmi_v180."GA_POI" WHERE ("MOB_TEL"~'^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$')) AS t) AS t7 WHERE ct>1 
		AND (COALESCE(t7.CONCAT,'')<>'') GROUP BY  t7."ID",t7."NAME",t7."MOB_TEL",t7.CONCAT)
	 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
    RAISE INFO 'MOB_TEL should not be repeated or duplicate';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.18.10
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''MOB_TEL'',"MOB_TEL",
		''MOB_TEL should not contain 0 after +91 and should be in proper form'',''1.18.10'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" AS t WHERE  
	   (t."MOB_TEL"!~''^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$'' OR t."MOB_TEL"!~''[+]{1}[9]{1}[1]{1}[1-9]{1}[0-9]{9}'')';

		--SELECT "ID","NAME",'tbl_nme','MOB_TEL',"MOB_TEL",
		--'MOB_TEL should not contain 0 after +91 and should be in proper form','1.18.10' FROM mmi_v180."GA_POI" AS t WHERE (status NOT IN ('0','5') OR (COALESCE(status,'')='') ) 
		--AND (t."MOB_TEL"!~'^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$' OR t."MOB_TEL"!~'[+]{1}[9]{1}[1]{1}[1-9]{1}[0-9]{9}')
                 
 		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
    RAISE INFO 'MOB_TEL should not contain 0 after +91 and should be in proper form';
	RAISE NOTICE 'time spent =%', clock_timestamp();	
--------------------------------------------------------------------------------------------------PIN------------------------------------------------------------------------------------------------------------------------------------------------
--1.19.1
-- 219 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''PIN'',"PIN", ''PIN length must be equal to 6 and should be integer value'',''1.19.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE (LENGTH("PIN")<>6 OR "PIN"!~''[0-9]+$'') ';

		--SELECT "ID","NAME",'tbl_nme','PIN',"PIN", 'PIN length must be equal to 6 and should be integer value','1.19.1' FROM mmi_v180."GA_POI" 
		--WHERE  (LENGTH("PIN")<>6 OR "PIN"!~'[0-9]+$')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'PIN length must be equal to 6 and should be integer value';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.19.2
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''PIN'',"PIN", ''Double Spaces are not allowed'',''1.19.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ("PIN" LIKE ''%  %'')';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','PIN',"PIN", 'Double Spaces are not allowed','1.19.2' FROM mmi_v180."GA_POI" 
		 WHERE ("PIN" LIKE '%  %')
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Double Spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.19.3
-- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''PIN'',"PIN", ''PIN should not contain any special characters'',''1.19.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."PIN"~''[^0-9]''';
		 
		 --SELECT "ID","NAME",'GA_POI','PIN',"PIN", 'PIN should not contain any special characters','1.19.3' FROM mmi_v180."GA_POI" As t 
		 -- WHERE t."PIN"~'[^0-9]'
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'PIN should not contain any special characters';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--------------------------------------------------------------------------------------------------FAX------------------------------------------------------------------------------------------------------------------------------------------------
--1.20.1
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''FAX'',"FAX", ''FAX length should be 13 OR 28 OR 43'',''1.20.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND LENGTH("FAX") <> 13 AND LENGTH("FAX") <> 28 AND LENGTH("FAX") <> 43';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.20.7
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''FAX'',"FAX", ''FAX should not contain any special characters Except + and ,'',''1.20.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND t."FAX"~''[^0-9\s+,]''';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.20.8
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''FAX'',"FAX", ''Double Spaces are not allowed'',''1.20.8'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND "FAX" LIKE ''%  %''';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.20.9
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		 -- SELECT t7."ID",t7."NAME",'''||tbl_nme||''',''FAX'',t7."FAX"::text,''FAX should not be repeated or duplicate'',''1.18.9'' 
		 -- FROM ( SELECT t."ID",t."NAME",t."FAX",t.CONCAT,COUNT(*) OVER (PARTITION By t.CONCAT) As ct 
		 -- FROM ( SELECT "ID","NAME","FAX",unnest(String_To_Array(replace("FAX",'','',''''), '' '')) As FAX, CONCAT("ID",'' '',unnest(String_To_Array(replace("FAX",'','',''''), '' ''))) 
		 -- FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND 
		 -- (TRIM("FAX") ~ ''[0-9][,][\s][0-9]'' OR TRIM("FAX")~''[0-9][\s][0-9]'' OR TRIM("FAX") ~ ''[0-9][,][\s][0-9][,][\s][0-9]'' OR TRIM("FAX") ~ ''[0-9][,][\s][0-9]][\s][0-9]'' OR TRIM("FAX") ~ ''[0-9][\s][0-9][\s][0-9]'' OR TRIM("FAX") ~ ''[0-9][\s][0-9][,][\s][0-9]'')) As t) As t7 WHERE ct>1 
		 -- AND (COALESCE(t7.CONCAT,'''')<>'''') GROUP By  t7."ID",t7."NAME",t7."FAX",t7.CONCAT ';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	
--1.20.1
--141 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''FAX'',"FAX",
		''FAX length should be 13 or 28 or 43'',''1.20.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE LENGTH("FAX") <> 13 AND LENGTH("FAX") <> 28 AND LENGTH("FAX") <> 43';

		--SELECT "ID","NAME",'tbl_nme','FAX',"FAX",
		--'FAX length should be 13 or 28 or 43','1.20.1' FROM mmi_v180."GA_POI" WHERE LENGTH("FAX") <> 13 AND LENGTH("FAX") <> 28 AND LENGTH("FAX") <> 43
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'FAX length should be 13 or 28 or 43';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.20.7
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''FAX'',"FAX",
		''FAX should not contain any special characters Except + and ,'',''1.20.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" AS t WHERE t."FAX"~''[^0-9\s+,]''';

		--SELECT "ID","NAME",'tbl_nme','FAX',"FAX",
		--'FAX should not contain any special characters Except + and ,','1.20.7' FROM mmi_v180."GA_POI" AS t WHERE t."FAX"~'[^0-9\s+,]'
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'FAX should not contain any special characters Except +';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.20.8
--141 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''FAX'',"FAX",
		''Double Spaces are not allowed'',''1.20.8'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "FAX" LIKE ''%  %''';

		--SELECT "ID","NAME",'tbl_nme','FAX',"FAX",
		--'Double Spaces are not allowed','1.20.8' FROM mmi_v161."DL_POI" WHERE "FAX" LIKE '%  %'
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'Double Spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.20.9
-- 156 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		( SELECT t7."ID",t7."NAME",'''||tbl_nme||''',''FAX'',t7."FAX"::text,''FAX should not be repeated or duplicate'',''1.20.9''
		FROM (Select t."ID",t."NAME",t."FAX",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		FROM (SELECT "ID","NAME","FAX",unnest(String_To_Array(replace("FAX",'','',''''), '' '')) as FAX, CONCAT("ID",'' '',unnest(String_To_Array(replace("FAX",'','',''''), '' ''))) 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE ("FAX"~''^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$'') ) AS t) AS t7 WHERE ct>1 
		AND (COALESCE(t7.CONCAT,'''')<>'''') GROUP BY  t7."ID",t7."NAME",t7."FAX",t7.CONCAT)';

		--( SELECT t7."ID",t7."NAME",'tbl_nme','FAX',t7."FAX"::text,'FAX should not be repeated or duplicate','1.18.9'
		--FROM (Select t."ID",t."NAME",t."FAX",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		--FROM (SELECT "ID","NAME","FAX",unnest(String_To_Array(replace("FAX",',',''), ' ')) as FAX, CONCAT("ID",' ',unnest(String_To_Array(replace("FAX",',',''), ' '))) 
		--FROM mmi_v161."DL_POI" WHERE ("FAX"~'^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$') ) AS t) AS t7 WHERE ct>1 
		--AND (COALESCE(t7.CONCAT,'')<>'') GROUP BY  t7."ID",t7."NAME",t7."FAX",t7.CONCAT)

		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
    RAISE INFO 'Double Spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.20.10
---16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''FAX'',"FAX",
		''FAX should not contain 0 after +91 and should be in proper form'',''1.20.10'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" AS t WHERE (t."FAX"!~''^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$'' OR t."FAX"!~''[+]{1}[9]{1}[1]{1}[1-9]{1}[0-9]{9}'')';

		--SELECT "ID","NAME",'tbl_nme','FAX',"FAX",
		--'FAX should not contain 0 after +91 and should be in proper form','1.20.10' FROM mmi_v161."DL_POI" AS t WHERE  
		--(t."FAX"!~'^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$' OR t."FAX"!~'[+]{1}[9]{1}[1]{1}[1-9]{1}[0-9]{9}') 
 		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
    RAISE INFO 'FAX should not contain 0 after +91 and should be in proper form';
	RAISE NOTICE 'time spent =%', clock_timestamp();	
-------------------------------------------------------------------------------------------------EMAIL-----------------------------------------------------------------------------------------------------------------------------------------------
--1.21.1
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		 -- SELECT "ID","NAME",'''||tbl_nme||''',''EMAIL'',"EMAIL", ''EMAIL must contain @'',''1.21.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE "EMAIL" NOT LIKE ''%@%'' AND (COALESCE("EMAIL",'''')<>'''')';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.21.2
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		 -- SELECT "ID","NAME",'''||tbl_nme||''',''EMAIL'',"EMAIL", ''EMAIL should not contain any special characters Except @ .  _  - ,'' ,''1.21.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE t."EMAIL" ~ ''[^A-Za-z0-9\s.,@_-]'' AND (COALESCE("EMAIL",'''')<>'''')';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.21.3
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''EMAIL'',"EMAIL", ''EMAIL must contain .'',''1.21.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE "EMAIL" NOT LIKE ''%.%'' AND (COALESCE("EMAIL",'''')<>'''')';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.21.4
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''EMAIL'',"EMAIL", ''Only two EMAIL are allowed and EMAIL should not ends with special character'',''1.21.4'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE 
		 -- ("EMAIL" !~ ''^[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$'' AND "EMAIL" !~ ''^[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$'') AND (COALESCE("EMAIL",'''')<>'''')';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.21.6
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''EMAIL'',"EMAIL", ''EMAIL should not contain www'',''1.21.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE LOWER("EMAIL") LIKE ''%www%''';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.21.7
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''EMAIL'',"EMAIL", ''EMAIL does not contain @ OR .'',''1.21.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE (LOWER("EMAIL") NOT LIKE ''%''||''.''||''%'' OR LOWER("EMAIL") NOT LIKE ''%''||''@''||''%'')';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.21.8
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT t."ID",t."NAME",'''||tbl_nme||''',''EMAIL'',t."EMAIL", ''EMAIL should not be ends with special character'',''1.21.8'' FROM ( SELECT "ID","NAME",substring("EMAIL", char_length("EMAIL")-0) enstring, "EMAIL" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- ) As t WHERE t.enstring ~''[^A-Za-z]''';

		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.21.9
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''EMAIL'',"EMAIL", ''EMAIL should be in LOWER case'',''1.21.9'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE LOWER("EMAIL")<>"EMAIL"';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.21.10
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		-- ( SELECT t7."ID",t7."NAME",'''||tbl_nme||''',''EMAIL'',t7."EMAIL"::text,''EMAIL should not be repeated or duplicate'',''1.21.10''
		 -- FROM ( SELECT t."ID",t."NAME",t."EMAIL",t.CONCAT,COUNT(*) OVER (PARTITION By t.CONCAT) As ct 
		 -- FROM ( SELECT "ID","NAME","EMAIL",unnest(String_To_Array(replace("EMAIL",'','',''''), '' '')) As EMAIL, CONCAT("ID",'' '',unnest(String_To_Array(replace("EMAIL",'','',''''), '' ''))) 
		 -- FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE  
		 -- (TRIM("EMAIL") ~ ''[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$'' OR TRIM("EMAIL") ~ ''[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$'' OR 
		 -- TRIM("EMAIL") ~ ''[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$'')) As t ) As t7 
		 -- WHERE ct>1 AND (COALESCE(t7.CONCAT,'''')<>'''') GROUP By  t7."ID",t7."NAME",t7."EMAIL",t7.CONCAT)';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	
--1.21.1
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''EMAIL'',"EMAIL",
		''EMAIL should not contain any special characters Except (@._-,) AND only two EMAILs are allowed AND EMAIL must contain (. and @) AND EMAIL must not end with special character'' ,''1.21.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" AS t 
		 WHERE t."EMAIL" !~ ''^[\w._-]+@[\w._-]+\.[A-Za-z]{2,4}(, [\w._-]+@[\w._-]+\.[A-Za-z]{2,4})?$'' AND (COALESCE("EMAIL",'''')<>'''')';

		--best query for EMAIL
		--SELECT "ID","NAME",'tbl_nme','EMAIL',"EMAIL",
		--'EMAIL should not contain any special characters Except (@._-,) AND only two EMAILs are allowed AND EMAIL must contain (. and @) AND EMAIL must not end with special character' ,'1.21.2' FROM mmi_v180."GA_POI" AS t 
		--WHERE t."EMAIL" !~ '^[\w._-]+@[\w._-]+\.[A-Za-z]{2,4}(, [\w._-]+@[\w._-]+\.[A-Za-z]{2,4})?$' AND (COALESCE("EMAIL",'')<>'')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
    RAISE INFO 'EMAIL should not contain any special characters Except (@._-,) AND only two EMAILs are allowed AND EMAIL must contain (. and @) AND EMAIL must not end with special character';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.21.2
--32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''EMAIL'',"EMAIL",
		''EMAIL should not contain www'',''1.21.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE LOWER("EMAIL") LIKE ''%www%''';

		--SELECT "ID","NAME",'tbl_nme','EMAIL',"EMAIL",
		--'EMAIL should not contain www','1.21.2' FROM mmi_v180."GA_POI" WHERE LOWER("EMAIL") LIKE '%www%'

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
    RAISE INFO 'EMAIL should not contain www';
	RAISE NOTICE 'time spent =%', clock_timestamp(); 
	
--1.100.6
--32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''EMAIL'',"EMAIL",
		''EMAIL ending with co or con'',''1.100.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
		 where COALESCE("EMAIL",'''')<>'''' AND "EMAIL" LIKE ''%co'' OR "EMAIL" LIKE ''%con'' ';

		--select "ID", "EMAIL" FROM mmi_master."AN_POI" WHERE COALESCE("EMAIL",'')<>'' AND "EMAIL" LIKE '%co' OR "EMAIL" LIKE '%con'

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
    RAISE INFO 'EMAIL should not contain www';
	RAISE NOTICE 'time spent =%', clock_timestamp(); 
--1.21.3
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''EMAIL'',"EMAIL",
		''EMAIL should be in lower case'',''1.21.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE LOWER("EMAIL") NOT LIKE "EMAIL"';

		--SELECT "ID","NAME",'tbl_nme','EMAIL',"EMAIL",
		--'EMAIL should be in lower case','1.21.3' FROM mmi_v180."GA_POI" WHERE LOWER("EMAIL") NOT LIKE "EMAIL"
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'EMAIL should be in lower case';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--1.21.4
-- 47 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		( SELECT t7."ID",t7."NAME",'''||tbl_nme||''',''EMAIL'',t7."EMAIL"::text,''EMAIL should not be repeated or duplicate'',''1.21.4''
		FROM (Select t."ID",t."NAME",t."EMAIL",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		FROM (SELECT "ID","NAME","EMAIL",unnest(String_To_Array(replace("EMAIL",'','',''''), '' '')) as EMAIL, CONCAT("ID",'' '',unnest(String_To_Array(replace("EMAIL",'','',''''), '' ''))) 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (trim("EMAIL") ~ ''[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$'' 
		OR trim("EMAIL") ~ ''[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$'' OR 
		trim("EMAIL") ~ ''[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$'')) AS t ) AS t7 
		WHERE ct>1 AND (COALESCE(t7.CONCAT,'''')<>'''') GROUP BY  t7."ID",t7."NAME",t7."EMAIL",t7.CONCAT)';

		--( SELECT t7."ID",t7."NAME",'tbl_nme','EMAIL',t7."EMAIL"::text,'EMAIL should not be repeated or duplicate','1.21.4'
		--FROM (Select t."ID",t."NAME",t."EMAIL",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		--FROM (SELECT "ID","NAME","EMAIL",unnest(String_To_Array(replace("EMAIL",',',''), ' ')) as EMAIL, CONCAT("ID",' ',unnest(String_To_Array(replace("EMAIL",',',''), ' '))) 
		--FROM mmi_v180."GA_POI" WHERE (trim("EMAIL") ~ '[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$' 
		--OR trim("EMAIL") ~ '[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$' OR 
		--trim("EMAIL") ~ '[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$')) AS t ) AS t7 
		--WHERE ct>1 AND (COALESCE(t7.CONCAT,'')<>'') GROUP BY  t7."ID",t7."NAME",t7."EMAIL",t7.CONCAT)

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'EMAIL should not be repeated or duplicate';
	RAISE NOTICE 'time spent =%', clock_timestamp();
--------------------------------------------------------------------------------------------------WEB------------------------------------------------------------------------------------------------------------------------------------------------
--1.22.1
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''WEB'',"WEB", ''Double Spaces are not allowed'',''1.22.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE "WEB" LIKE ''%  %''';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE 'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.22.3
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''WEB'',"WEB", ''WEB must contain www.'',''1.22.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE LOWER("WEB") NOT LIKE ''%www.%'' AND (COALESCE("WEB",'''')<>'''')';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.22.4
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		 -- SELECT t."ID",t."NAME",'''||tbl_nme||''',''WEB'',t."WEB",''WEB should not Start AND End with Special character'',''1.22.4''
		 -- FROM ( SELECT "ID","NAME",substring("WEB", char_length("WEB")-0) enstring, "WEB" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE
		 -- (COALESCE("WEB",'''')<>'''') ) As t WHERE t.enstring ~''[^A-Za-z]'' AND (COALESCE(t."WEB",'''')<>'''')';

		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.22.6
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''WEB'',"WEB", ''WEB should be in LOWER case'',''1.22.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE LOWER("WEB") <> "WEB"';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
--1.22.7
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		-- ( SELECT t7."ID",t7."NAME",'''||tbl_nme||''',''WEB'',t7."WEB"::text,''WEB should not be repeated or duplicate'',''1.22.7''
		 -- FROM ( SELECT t."ID",t."NAME",t."WEB",t.CONCAT,COUNT(*) OVER (PARTITION By t.CONCAT) As ct 
		 -- FROM ( SELECT "ID","NAME","WEB",unnest(String_To_Array(replace("WEB",'','',''''), '' '')) As WEB, CONCAT("ID",'' '',unnest(String_To_Array(replace("WEB",'','',''''), '' ''))) 
		 -- FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE
		 -- (LOWER(TRIM("WEB")) ~ ''(w{3})[.]+[a-z0-9]+[.][a-z.]+$'' OR LOWER(TRIM("WEB"))~''(w{3})[.]+[a-z0-9]+[.][a-z.]+[,][\s](w{3})[.]+[a-z0-9]+[.][a-z.]+$'' OR LOWER(TRIM("WEB"))~''(w{3})[.]+[a-z0-9]+[.][a-z.]+[,][\s](w{3})[.]+[a-z0-9]+[.][a-z.]+[,][\s](w{3})[.]+[a-z0-9]+[.][a-z.]+$'')) As t) As t7 
		 -- WHERE ct>1 AND (COALESCE(t7.CONCAT,'''')<>'''') GROUP By  t7."ID",t7."NAME",t7."WEB",t7.CONCAT)';
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;

--2.47.227
--16 msec
---to be verify ashu
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''WEB'',"WEB", ''Special charecter must not available except  ’.’, ’And’, ’,’'',''2.47.227'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		where t."WEB" ~ ''[^0-9A-Za-z., +-\/]'' or ("WEB" LIKE ''-%'' OR "WEB" LIKE ''%-''
		OR "WEB" LIKE ''.%'' OR "WEB" LIKE ''%.'' OR "WEB" LIKE ''/%'' OR "WEB" LIKE ''%/'' OR "WEB" LIKE '',%'' OR "WEB" LIKE ''%,'') ';
		
        /*
		select "ID","NAME","WEB" from mmi_master."GA_POI" where "WEB" ~ '[^0-9A-Za-z., +-\/]' or ("WEB" LIKE '-%' OR "WEB" LIKE '%-'
		OR "WEB" LIKE '.%' OR "WEB" LIKE '%.' OR "WEB" LIKE '/%' OR "WEB" LIKE '%/' OR "WEB" LIKE ',%' OR "WEB" LIKE '%,');
		*/		
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''WEB'',"WEB", ''Special charecter must not available except except ’.’, ’And’, ’,’'',''2.47.227'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE t."WEB" IS NOT NULL AND (t."WEB"~''[^.\s\w,]'') ';
		 /*
		 select "ID","NAME","WEB" from mmi_master."GA_POI" where "WEB" ~ '[^0-9A-Za-z., +-\/]' or ("WEB" LIKE '-%' OR "WEB" LIKE '%-'
		OR "WEB" LIKE '.%' OR "WEB" LIKE '%.' OR "WEB" LIKE '/%' OR "WEB" LIKE '%/' OR "WEB" LIKE ',%' OR "WEB" LIKE '%,');
		 */
		     
		 /* CHANGE BY ASHUTOSH
		 SELECT "ID","NAME",'GA_POI','WEB',"WEB", 'Special charecter must not available except except ’.’,’-’,’And’, ’,’','2.47.227' FROM mmi_v180."GA_POI" As t 
		 WHERE t."WEB" IS NOT NULL AND ("WEB" <> TRIM(t."WEB",'[!"#$%&\'()*+,-./@:;<=>[\\]^_`{|}~]')) OR (t."WEB"~'[^-.\s\w,]') OR (t."WEB" LIKE '%- ,%' 
		 OR t."WEB" LIKE '%. ,%' OR t."WEB" LIKE '%, ' OR t."WEB" LIKE '%,') 
		 --("WEB" <> TRIM(t."WEB",''[!"#$%&''()*+,-./@:;<=>[\\]^_`{|}~]'')) OR
		*/

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Special charecter must not available except except';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

--2.47.227.1(FOR COMPLETE WEB SYNTAX)
--16 msec
---to be verify ashu
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''WEB'',"WEB", ''WEB MUST BE IN PROPER FORM'',''2.47.227.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		WHERE COALESCE(t."WEB",'''')<>'''' AND t."WEB"~''((ftp|http|https):\/\/)?(www.)?[a-zA-Z0-9_-]+(\.[a-zA-Z]+)+(\/?([a-zA-Z#0-9_-]+)?)*(, )?(((ftp|http|https):\/\/)?(www.)?[a-zA-Z0-9_-]+(\.[a-zA-Z]+)+(\/?([a-zA-Z#0-9_-]+)?)*)?(, )?(((ftp|http|https):\/\/)?(www.)?[a-zA-Z0-9_-]+(\.[a-zA-Z]+)+(\/?([a-zA-Z#0-9_-]+)?)*)?$'' = FALSE ';
		
		
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''WEB'',"WEB", ''Special charecter must not available except except ’.’, ’And’, ’,’'',''2.47.227'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE t."WEB" IS NOT NULL AND (t."WEB"~''[^.\s\w,]'') ';
		 /*
		 SELECT "ID","NAME",'GA_POI','WEB',"WEB", 'Special charecter must not available except except ’.’, ’And’, ’,’','2.47.227' FROM mmi_v180."GA_POI" As t 
		 WHERE t."WEB" IS NOT NULL AND (t."WEB"~'[^.\s\w,]')
		 */
		 
		 /* CHANGE BY ASHUTOSH
		 SELECT "ID","NAME",'GA_POI','WEB',"WEB", 'Special charecter must not available except except ’.’,’-’,’And’, ’,’','2.47.227' FROM mmi_v180."GA_POI" As t 
		 WHERE t."WEB" IS NOT NULL AND ("WEB" <> TRIM(t."WEB",'[!"#$%&\'()*+,-./@:;<=>[\\]^_`{|}~]')) OR (t."WEB"~'[^-.\s\w,]') OR (t."WEB" LIKE '%- ,%' 
		 OR t."WEB" LIKE '%. ,%' OR t."WEB" LIKE '%, ' OR t."WEB" LIKE '%,') 
		 --("WEB" <> TRIM(t."WEB",''[!"#$%&''()*+,-./@:;<=>[\\]^_`{|}~]'')) OR
		*/

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'WEB MUST BE IN PROPER FORM';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
--1.22.1
-- 31 msec 
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''WEB'',"WEB",
		''Double Spaces are not allowed'',''1.22.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "WEB" LIKE ''%  %''';

		--SELECT "ID","NAME",'tbl_nme','WEB',"WEB",
		--'Double Spaces are not allowed','1.22.1' FROM mmi_v180."GA_POI" WHERE "WEB" LIKE '%  %'		
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'Double Spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
--1.22.3
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		( SELECT t7."ID",t7."NAME",'''||tbl_nme||''',''WEB'',t7."WEB"::text,''WEB must contain www. in the starting of URL and should not contain whitespaces'',''1.22.3''
		FROM (Select t."ID",t."NAME",t."WEB",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		FROM (SELECT "ID","NAME","WEB",unnest(String_To_Array(replace("WEB",'','',''''), '' '')) as WEB, CONCAT("ID",'' '',unnest(String_To_Array(replace("WEB",'','',''''), '' ''))) 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" ) AS t WHERE t.CONCAT!~''^\d+ (www.){1}'') AS t7 
		WHERE (COALESCE(t7.CONCAT,'''')<>'''') GROUP BY  t7."ID",t7."NAME",t7."WEB",t7.CONCAT)';

		--new query
		--( SELECT t7."ID",t7."NAME",'tbl_nme','WEB',t7."WEB"::text,'WEB must contain www. in the starting of URL and should not contain whitespaces','1.22.3'
		--FROM (Select t."ID",t."NAME",t."WEB",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		--FROM (SELECT "ID","NAME","WEB",unnest(String_To_Array(replace("WEB",',',''), ' ')) as WEB, CONCAT("ID",' ',unnest(String_To_Array(replace("WEB",',',''), ' '))) 
		--FROM mmi_v180."GA_POI"  ) AS t WHERE t.CONCAT!~'^\d+ (www.){1}') AS t7 
		--WHERE (COALESCE(t7.CONCAT,'')<>'') GROUP BY  t7."ID",t7."NAME",t7."WEB",t7.CONCAT)
		
		--old query
		--SELECT "ID","NAME",'tbl_nme','WEB',"WEB",
		--'WEB must contain www.','1.22.3' FROM mmi_v161."DL_POI" WHERE LOWER("WEB") NOT LIKE '%www.%' AND (COALESCE("WEB",'')<>'')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'WEB must contain www. in the starting of URL and should not contain whitespaces';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
--1.22.4
--31 msec
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		( SELECT t7."ID",t7."NAME",'''||tbl_nme||''',''WEB'',t7."WEB"::text,''WEB should not start or ends with special character'',''1.22.4''
		FROM (Select t."ID",t."NAME",t."WEB",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		FROM (SELECT "ID","NAME","WEB",unnest(String_To_Array(replace("WEB",'','',''''), '' '')) as WEB, CONCAT("ID",'' '',unnest(String_To_Array(replace("WEB",'','',''''), '' ''))) 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE ("WEB"~''^\S+$|(, ){1,}| $|^ '' ) ) AS t WHERE t.CONCAT~''[^A-Za-z]$'' OR t.CONCAT~''^[\d]+ [^A-Za-z]'' )  AS t7 
		WHERE (COALESCE(t7.CONCAT,'''')<>'''') GROUP BY  t7."ID",t7."NAME",t7."WEB",t7.CONCAT)';

		--old query
		--SELECT t."ID",t."NAME",'tbl_nme','WEB',t."WEB",'WEB should not start or ends with special character','1.22.4'
		--FROM ( SELECT "ID","NAME",substring("WEB", char_length("WEB")-0) enstring, "WEB" from mmi_v161."DL_POI" 
		--where (COALESCE("WEB",'')<>'') ) AS t where t.enstring ~'[^A-Za-z]' AND (COALESCE(t."WEB",'')<>'')
		
		--new query
		--( SELECT t7."ID",t7."NAME",'tbl_nme','WEB',t7."WEB"::text,'WEB should not start or ends with special character','1.22.4'
		--FROM (Select t."ID",t."NAME",t."WEB",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		--FROM (SELECT "ID","NAME","WEB",unnest(String_To_Array(replace("WEB",',',''), ' ')) as WEB, CONCAT("ID",' ',unnest(String_To_Array(replace("WEB",',',''), ' '))) 
		--FROM mmi_v180."GA_POI" WHERE ("WEB"~'^\S+$|(, ){1,}| $|^ ' ) ) AS t WHERE t.CONCAT~'[^A-Za-z]$' OR t.CONCAT~'^[\d]+ [^A-Za-z]' )  AS t7 
		--WHERE (COALESCE(t7.CONCAT,'')<>'') GROUP BY  t7."ID",t7."NAME",t7."WEB",t7.CONCAT)
		
	
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'WEB should not start or ends with special character';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.22.6
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''WEB'',"WEB",
		''WEB should be in lower case'',''1.22.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE LOWER("WEB") NOT LIKE "WEB"';

		--SELECT "ID","NAME",'tbl_nme','WEB',"WEB",
		--'WEB should be in lower case','1.22.6' FROM mmi_v180."GA_POI" WHERE LOWER("WEB") NOT LIKE "WEB"
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'WEB should be in lower case';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.22.7
-- 63 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		( SELECT t7."ID",t7."NAME",'''||tbl_nme||''',''WEB'',t7."WEB"::text,''WEB should not be repeated or duplicate'',''1.22.7''
		FROM (Select t."ID",t."NAME",t."WEB",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		FROM (SELECT "ID","NAME","WEB",unnest(String_To_Array(replace("WEB",'','',''''), '' '')) as WEB, CONCAT("ID",'' '',unnest(String_To_Array(replace("WEB",'','',''''), '' ''))) 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (lower(trim("WEB")) ~ ''(w{3})[.]+[a-z0-9]+[.][a-z.]+$'' OR lower(trim("WEB"))~''(w{3})[.]+[a-z0-9]+[.][a-z.]+[,][\s](w{3})[.]+[a-z0-9]+[.][a-z.]+$'' 
		OR lower(trim("WEB"))~''(w{3})[.]+[a-z0-9]+[.][a-z.]+[,][\s](w{3})[.]+[a-z0-9]+[.][a-z.]+[,][\s](w{3})[.]+[a-z0-9]+[.][a-z.]+$'')) AS t) AS t7 
		WHERE ct>1 AND (COALESCE(t7.CONCAT,'''')<>'''') GROUP BY  t7."ID",t7."NAME",t7."WEB",t7.CONCAT)';

		--( SELECT t7."ID",t7."NAME",'tbl_nme','WEB',t7."WEB"::text,'WEB should not be repeated or duplicate','1.22.7'
		--FROM (Select t."ID",t."NAME",t."WEB",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		--FROM (SELECT "ID","NAME","WEB",unnest(String_To_Array(replace("WEB",',',''), ' ')) as WEB, CONCAT("ID",' ',unnest(String_To_Array(replace("WEB",',',''), ' '))) 
		--FROM mmi_v180."DL_POI" WHERE (lower(trim("WEB")) ~ '(w{3})[.]+[a-z0-9]+[.][a-z.]+$' OR lower(trim("WEB"))~'(w{3})[.]+[a-z0-9]+[.][a-z.]+[,][\s](w{3})[.]+[a-z0-9]+[.][a-z.]+$' 
		--OR lower(trim("WEB"))~'(w{3})[.]+[a-z0-9]+[.][a-z.]+[,][\s](w{3})[.]+[a-z0-9]+[.][a-z.]+[,][\s](w{3})[.]+[a-z0-9]+[.][a-z.]+$')) AS t) AS t7 
		--WHERE ct>1 AND (COALESCE(t7.CONCAT,'')<>'') GROUP BY  t7."ID",t7."NAME",t7."WEB",t7.CONCAT)
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||'(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;
	RAISE INFO 'WEB should not be repeated or duplicate';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-----------------------------------------------------------------------------------------------RICH_INFO---------------------------------------------------------------------------------------------------------------------------------------------
--1.23.2
-- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''RICH_INFO'', "RICH_INFO",''Must not have special character except ’&’ and ’,’'',''1.22.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."RICH_INFO" ~ ''[^A-Za-z0-9\s&,]'' ';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','RICH_INFO', "RICH_INFO",'Must not have special character except ’&’ and ’,’','1.22.2' FROM mmi_v180."GA_POI" As t 
		 WHERE t."RICH_INFO" ~ '[^A-Za-z0-9\s&,]'
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Must not have special character except ’&’ and ’,’';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.23.3
--16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''RICH_INFO'', "RICH_INFO",''Double Spaces are not allowed'',''1.23.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE "RICH_INFO" LIKE ''%  %''';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','RICH_INFO', "RICH_INFO",'Double Spaces are not allowed','1.23.3' FROM mmi_v180."GA_POI" 
		 WHERE "RICH_INFO" LIKE '%  %'
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Double Spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
------------------------------------------------------------------------------------------------IRR_POI----------------------------------------------------------------------------------------------------------------------------------------------
--1.24.2
-- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''IRR_POI'',"IRR_POI", ''IRR_POI should be only for those POIs which have no naming identification'',''1.24.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE (COALESCE("IRR_POI",'''')<>'''') AND (COALESCE("NAME",'''')='''')';
		 
		 --SELECT "ID","NAME",'GA_POI','IRR_POI',"IRR_POI", 'IRR_POI should be only for those POIs which have no naming identification','1.24.2' FROM mmi_v180."GA_POI" As t 
		 --WHERE (COALESCE("IRR_POI",'')<>'') AND (COALESCE("NAME",'')='')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'IRR_POI should be only for those POIs which have no naming identification';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.24.3
--- 31 sec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''IRR_POI'',"IRR_POI", ''If IRR_POI=IRR then IMP_POI should be blank'',''1.24.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE ( ("IRR_POI" LIKE ''IRR'') AND (COALESCE("IMP_POI",'''')<>'''') ) ';
		 
		 /*
		 SELECT "ID","NAME",'GA_POI','IRR_POI',"IRR_POI", 'If IRR_POI=IRR then IMP_POI should be blank','1.24.3' FROM mmi_v180."GA_POI" As t 
		 WHERE ( ("IRR_POI" LIKE 'IRR') AND (COALESCE("IMP_POI",'')<>'') )
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If IRR_POI=IRR then IMP_POI should be blank';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.24.5
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''IRR_POI'',"IRR_POI", ''All IRR_POI must have PRIORITY=97'',''1.24.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE "PRIORITY"<>97 AND (COALESCE("IRR_POI",'''')<>'''')';
		 
		 /*
		 SELECT "ID","NAME",'GA_POI','IRR_POI',"IRR_POI", 'All IRR_POI must have PRIORITY=97','1.24.5' FROM mmi_v180."GA_POI" 
		 WHERE "PRIORITY"<>97 AND (COALESCE("IRR_POI",'')<>'')
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'All IRR_POI must have PRIORITY=97';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.24.7
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''IRR_POI'',"IRR_POI", ''IRR_POI must be IRR and nothing else'',''1.24.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE UPPER("IRR_POI") <> ''IRR'' ';

		--SELECT "ID","NAME",'tbl_nme','IRR_POI',"IRR_POI", 'IRR_POI must be IRR and nothing else','1.24.7' FROM mmi_v161."DL_POI" 
		--WHERE UPPER("IRR_POI") <> 'IRR'

		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'IRR_POI must be IRR and nothing else';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
------------------------------------------------------------------------------------------------SRCNEW-----------------------------------------------------------------------------------------------------------------------------------------------
--1.25.1
--16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''SRCNEW'',"SRCNEW", ''SRCNEW should not be blank'',''1.25.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE (COALESCE("SRCNEW",'''')='''')';
		 
		 /*
		   SELECT "ID","NAME",'GA_POI','SRCNEW',"SRCNEW", 'SRCNEW should not be blank','1.25.1' FROM mmi_v180."GA_POI" 
		 WHERE (COALESCE("SRCNEW",'')='')
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'SRCNEW should not be blank';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.25.4
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''SRCNEW'',"SRCNEW", ''If SRCNEW is blank then DT_SRCNEW should be blank'',''1.25.4'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE (COALESCE("SRCNEW",'''')='''') AND (COALESCE("DT_SRCNEW",'''')<>'''')';
		 
		 /*
		 SELECT "ID","NAME",'GA_POI','SRCNEW',"SRCNEW", 'If SRCNEW is blank then DT_SRCNEW should be blank','1.25.4' FROM mmi_v180."GA_POI" 
		 WHERE (COALESCE("SRCNEW",'')='') AND (COALESCE("DT_SRCNEW",'')<>'')
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If SRCNEW is blank then DT_SRCNEW should be blank';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
----------------------------------------------------------------------------------------------DT_SRCNEW----------------------------------------------------------------------------------------------------------------------------------------------
--1.26.3
--2.47.90(oracle)
--47 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''DT_SRCNEW'',"DT_SRCNEW", ''DT_SRCNEW must be 6 digits numeric only'',''1.26.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE COALESCE(t."DT_SRCNEW",'''') <> '''' AND  t."DT_SRCNEW" ~''^\d{6}$'' = FALSE ';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','DT_SRCNEW',"DT_SRCNEW", 'DT_SRCNEW must be 6 digits numeric only','1.26.3' FROM mmi_v180."GA_POI" As t 
		  WHERE  COALESCE(t."DT_SRCNEW",'''') <> '''' AND t."DT_SRCNEW" ~'^\d{6}$' = FALSE 
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'DT_SRCNEW must be in numeric form only';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.26.4
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''DT_SRCNEW'',"DT_SRCNEW", ''DT_SRCNEW must be filled if SRCNEW is filled'',''1.26.4'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		WHERE COALESCE("SRCNEW",'''')<>'''' AND COALESCE("DT_SRCNEW",'''')=''''';
		 
		 --SELECT "ID","NAME",'GA_POI','DT_SRCNEW',"DT_SRCNEW", 'DT_SRCNEW must be filled if SRCNEW is filled','1.26.4' FROM mmi_v180."GA_POI" As t 
		 -- WHERE COALESCE("SRCNEW",'')<>'' AND COALESCE("DT_SRCNEW",'')=''
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'DT_SRCNEW must be filled if SRCNEW is filled';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

-- --1.26.5
-- --47 sec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''DT_SRCNEW'',"DT_SRCNEW", ''DT_SRCNEW must be 6 digits long only with no special character'',''1.26.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE "DT_SRCNEW"!~''^[0-9]{6}$'' AND COALESCE("DT_SRCNEW",'''')<>'''' ';

		-- --SELECT "ID","NAME",'tbl_nme','DT_SRCNEW',"DT_SRCNEW", 'DT_SRCNEW must be 6 digits long only with no special character','1.26.5' FROM mmi_v180."GA_POI" As t 
		-- --WHERE "DT_SRCNEW"!~'^[0-9]{6}$' AND COALESCE("DT_SRCNEW",'')<>''
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;	
	-- RAISE INFO 'DT_SRCNEW must be 6 digits long only with no special character';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
------------------------------------------------------------------------------------------------SRCMVD-----------------------------------------------------------------------------------------------------------------------------------------------
--1.27.2
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''SRCMVD'',"SRCMVD", ''If SRCMVD not filled then DT_SRCMVD should be blank'',''1.27.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE (COALESCE("SRCMVD",'''')='''') AND (COALESCE("DT_SRCMVD",'''')<>'''')';
		 /*
		  SELECT "ID","NAME",'GA_POI','SRCMVD',"SRCMVD", 'If SRCMVD not filled then DT_SRCMVD should be blank','1.27.2' FROM mmi_v180."GA_POI" 
		 WHERE (COALESCE("SRCMVD",'')='') AND (COALESCE("DT_SRCMVD",'')<>'')
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If SRCMVD not filled then DT_SRCMVD should be blank';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
----------------------------------------------------------------------------------------------DT_SRCMVD----------------------------------------------------------------------------------------------------------------------------------------------
--1.28.3
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''DT_SRCMVD'',"DT_SRCMVD", ''DT_SRCMVD must be 6 digit numeric only'',''1.28.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE COALESCE(t."DT_SRCMVD",'''') <> '''' AND "DT_SRCMVD" ~''^\d{6}$'' = FALSE ';
		 /*
		 SELECT "ID","NAME",'GA_POI','DT_SRCMVD',"DT_SRCMVD", 'DT_SRCMVD must be 6 digit numeric only','1.28.3' FROM mmi_v180."GA_POI" As t 
		 WHERE "DT_SRCMVD" ~'^\d{6}$' = FALSE 
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'DT_SRCMVD must be in numeric for m only';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.28.4
-- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''DT_SRCMVD'',"DT_SRCMVD", ''DT_SRCMVD must be filled if SRCMVD is filled'',''1.28.4'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE COALESCE("SRCMVD",'''')<>'''' AND COALESCE("DT_SRCMVD",'''')=''''';
		 
		 /*
		 SELECT "ID","NAME",'GA_POI','DT_SRCMVD',"DT_SRCMVD", 'DT_SRCMVD must be filled if SRCMVD is filled','1.28.4' FROM mmi_v180."GA_POI" As t 
		 WHERE COALESCE("SRCMVD",'')<>'' AND COALESCE("DT_SRCMVD",'')=''
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'DT_SRCMVD must be filled if SRCMVD is filled';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-- --1.28.5
-- -- 16 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''DT_SRCMVD'',"DT_SRCMVD", ''DT_SRCMVD must be 6 digits long only with no special character'',''1.28.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE "DT_SRCMVD"!~''^[0-9]{6}$'' AND COALESCE("DT_SRCMVD",'''')<>'''' ';

		-- --SELECT "ID","NAME",'tbl_nme','DT_SRCMVD',"DT_SRCMVD", 'DT_SRCMVD must be 6 digits long only with no special character','1.28.5' FROM mmi_v180."DL_POI" As t 
		-- --WHERE "DT_SRCMVD"!~'^[0-9]{6}$' AND COALESCE("DT_SRCMVD",'')<>''
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'DT_SRCMVD must be 6 digits long only with no special character';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
----------------------------------------------------------------------------------------------DT_SRCVRF----------------------------------------------------------------------------------------------------------------------------------------------
--1.30.3
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''DT_SRCVRF'',"DT_SRCVRF", ''DT_SRCVRF must be 6 digit  numeric form only'',''1.30.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE COALESCE(t."DT_SRCVRF",'''') <> '''' AND "DT_SRCVRF" ~''^\d{6}$'' = FALSE ';
		 
		 /*
		 SELECT "ID","NAME",'GA_POI','DT_SRCVRF',"DT_SRCVRF", 'DT_SRCVRF must be 6 digit  numeric form only','1.30.3' FROM mmi_v180."GA_POI" As t 
		 WHERE "DT_SRCVRF" ~''^\d{6}$'' = FALSE
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'DT_SRCVRF must be in numeric form only';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.30.4
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''DT_SRCVRF'',"DT_SRCVRF", ''DT_SRCVRF must be filled if SRCVRF is filled'',''1.30.4'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE COALESCE("SRCVRF",'''')<>'''' AND COALESCE("DT_SRCVRF",'''')=''''';
		 /*
		 SELECT "ID","NAME",'GA_POI','DT_SRCVRF',"DT_SRCVRF", 'DT_SRCVRF must be filled if SRCVRF is filled','1.30.4' FROM mmi_v180."GA_POI" As t 
		 WHERE COALESCE("SRCVRF",'')<>'' AND COALESCE("DT_SRCVRF",'')=''
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'DT_SRCVRF must be filled if SRCVRF is filled';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-- --1.30.5
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''DT_SRCVRF'',"DT_SRCVRF", ''DT_SRCVRF must be 6 digits long only with no special character'',''1.30.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE "DT_SRCVRF"!~''^[0-9]{6}$'' AND COALESCE("DT_SRCVRF",'''')<>'''' ';

		-- --SELECT "ID","NAME",'tbl_nme','DT_SRCVRF',"DT_SRCVRF", 'DT_SRCVRF must be 6 digits long only with no special character','1.30.5' FROM mmi_v180."GA_POI" As t 
		-- --WHERE "DT_SRCVRF"!~'^[0-9]{6}$' AND COALESCE("DT_SRCVRF",'')<>''
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;	
	-- RAISE INFO 'DT_SRCVRF must be 6 digits long only with no special character';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-----------------------------------------------------------------------------------------------SRCDAT------------------------------------------------------------------------------------------------------------------------------------------------
--1.31.2
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''SRCDAT'',"SRCDAT", ''SRCDAT must be filled if ADDRESS, PIN, FAX, WEB, EMAIL, TEL,EM_TEL OR MOB_TEL is filled'',''1.31.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE ((COALESCE("ADDRESS",'''')<>'''' OR COALESCE("PIN",'''')<>'''' OR COALESCE("FAX",'''')<>'''' OR COALESCE("WEB",'''')<>'''' OR COALESCE("EMAIL",'''')<>'''' OR 
		COALESCE("TEL",'''')<>'''' OR COALESCE("EM_TEL",'''')<>'''' OR COALESCE("MOB_TEL",'''')<>'''')) AND (COALESCE("SRCDAT",'''')='''')';
        
		--SELECT "ID","NAME",'GA_POI','SRCDAT',"SRCDAT", 'SRCDAT must be filled if ADDRESS, PIN, FAX, WEB, EMAIL, TEL,EM_TEL OR MOB_TEL is filled','1.31.2' FROM mmi_v180."GA_POI" As t 
		--WHERE ((COALESCE("ADDRESS",'')<>'' OR COALESCE("PIN",'')<>'' OR COALESCE("FAX",'')<>'' OR COALESCE("WEB",'')<>'' OR COALESCE("EMAIL",'')<>'' OR 
		--COALESCE("TEL",'')<>'' OR COALESCE("EM_TEL",'')<>'' OR COALESCE("MOB_TEL",'')<>'')) AND (COALESCE("SRCDAT",'')='')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'SRCDAT must be filled if ADDRESS, PIN, FAX, WEB, EMAIL, TEL,EM_TEL OR MOB_TEL is filled';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.31.3
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''SRCDAT'',"SRCDAT", ''SRCDAT must be blank if ADDRESS PIN FAX WEB EMAIL TEL,EM_TEL AND MOB_TEL is blank'',''1.31.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE
		(COALESCE("ADDRESS",'''')='''' ) AND COALESCE("PIN",'''')='''' AND COALESCE("FAX",'''')='''' AND COALESCE("WEB",'''')='''' AND COALESCE("EMAIL",'''')='''' AND 
		COALESCE("TEL",'''')='''' AND COALESCE("EM_TEL",'''')='''' AND (COALESCE("MOB_TEL",'''')='''') AND (COALESCE("SRCDAT",'''')<>'''')';
		/*
		  SELECT "ID","NAME",'GA_POI','SRCDAT',"SRCDAT", 'SRCDAT must be blank if ADDRESS PIN FAX WEB EMAIL TEL,EM_TEL AND MOB_TEL is blank','1.31.3' FROM mmi_v180."GA_POI" As t 
		 WHERE (COALESCE("ADDRESS",'')='' ) AND COALESCE("PIN",'')='' AND COALESCE("FAX",'')='' AND COALESCE("WEB",'')='' AND COALESCE("EMAIL",'')='' AND 
		COALESCE("TEL",'')='' AND COALESCE("EM_TEL",'')='' AND (COALESCE("MOB_TEL",'')='') AND (COALESCE("SRCDAT",'')<>'')
		*/
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'SRCDAT must be blank if ADDRESS PIN FAX WEB EMAIL TEL,EM_TEL AND MOB_TEL is blank';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
----------------------------------------------------------------------------------------------DT_SRCDAT----------------------------------------------------------------------------------------------------------------------------------------------
--2.47.104
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''DT_SRCDAT'',"DT_SRCDAT", ''Must be 6 digit numeric  only'',''2.47.104'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		WHERE COALESCE(t."DT_SRCDAT",'''') <> '''' AND "DT_SRCDAT" ~''^\d{6}$'' = FALSE  ';
		 /*
		  SELECT "ID","NAME",'GA_POI','DT_SRCDAT',"DT_SRCDAT", 'Must be 6 digit numeric  only','2.47.104' FROM mmi_v180."GA_POI" As t 
		 WHERE "DT_SRCDAT" ~''^\d{6}$'' = FALSE 
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Must be in numeric form only';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.32.4
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''DT_SRCDAT'',"DT_SRCDAT", ''DT_SRCDAT must be filled if SRCDAT is filled'',''1.32.4'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE (COALESCE("DT_SRCDAT",'''')='''') AND (COALESCE("SRCDAT",'''')<>'''')';
		 /*
		  SELECT "ID","NAME",'GA_POI','DT_SRCDAT',"DT_SRCDAT", 'DT_SRCDAT must be filled if SRCDAT is filled','1.32.4' FROM mmi_v180."GA_POI" As t 
		 WHERE (COALESCE("DT_SRCDAT",'')='') AND (COALESCE("SRCDAT",'')<>'')
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'DT_SRCDAT must be filled if SRCDAT is filled';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-- --1.32.5
-- --31 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''DT_SRCDAT'',"DT_SRCDAT", ''DT_SRCDAT must be 6 digits long only with no special character'',''1.32.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE "DT_SRCDAT"!~''^[0-9]{6}$'' AND COALESCE("DT_SRCDAT",'''')<>'''' ';

		-- --SELECT "ID","NAME",'tbl_nme','DT_SRCDAT',"DT_SRCDAT", 'DT_SRCDAT must be 6 digits long only with no special character','1.32.5' FROM mmi_v161."DL_POI" As t 
		-- --WHERE "DT_SRCDAT"!~'^[0-9]{6}$' AND COALESCE("DT_SRCDAT",'')<>''
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'DT_SRCDAT must be 6 digits long only with no special character';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
----------------------------------------------------------------------------------------------DT_SRCCLSD------------------------------------------------------------------------------------------------------------------------------------------------
--2.47.270
-- 15 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''DT_SRCCLSD'',"DT_SRCCLSD", ''Must be in  6 digit  numeric form only'',''2.47.270'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE COALESCE(t."DT_SRCCLSD",'''') <> '''' AND "DT_SRCCLSD" ~''^\d{6}$'' = FALSE  ';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','DT_SRCCLSD',"DT_SRCCLSD", 'Must be in  6 digit  numeric form only','2.47.270' FROM mmi_v180."GA_POI" As t 
		  WHERE "DT_SRCCLSD" ~''^\d{6}$'' = FALSE
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Must be in numeric form only';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-- --2.47.271
-- --31 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''DT_SRCCLSD'',"DT_SRCCLSD", ''DT_SRCCLSD must be 6 digits long only with no special character'',''2.47.271'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE "DT_SRCCLSD"!~''^[0-9]{6}$'' AND COALESCE("DT_SRCCLSD",'''')<>'''' ';

		-- --SELECT "ID","NAME",'tbl_nme','DT_SRCCLSD',"DT_SRCCLSD", 'DT_SRCCLSD must be 6 digits long only with no special character','2.47.271' FROM mmi_v180."GA`_POI" As t 
		-- --WHERE "DT_SRCCLSD"!~'^[0-9]{6}$' AND COALESCE("DT_SRCCLSD",'')<>''
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'DT_SRCCLSD must be 6 digits long only with no special character';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
----------------------------------------------------------------------------------------------PIP_ID------------------------------------------------------------------------------------------------------------------------------------------------
-- --1.35.2
-- -- 32 msec
	-- BEGIN
		-- --EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		 -- --SELECT d."ID",d."NAME",'''||tbl_nme||''',''PIP_ID'',d."PIP_ID"::text,''Child Poi’s pip id must match with parent id in same state poi master file'',''1.35.2''
		 -- --FROM ( SELECT a."PIP_ID",a."STT_ID" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" a EXCEPT SELECT b."ID",b."STT_ID" 
		 -- --FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" b) c,'||sch_name||'."'|| UPPER(tbl_nme) ||'" d 
		 -- --WHERE c."PIP_ID"=d."PIP_ID" AND c."PIP_ID"<>0 ';
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT d."ID",d."NAME",'''||tbl_nme||''',''PIP_ID'',d."PIP_ID"::text,''Child Poi’s pip id must match with parent id in same state poi master file'',''1.35.2'' 
		-- FROM (SELECT e."PIP_ID",e."STT_ID" FROM ( SELECT a."PIP_ID",a."STT_ID" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" a WHERE "PIP_ID" <> 0 
		-- EXCEPT SELECT b."ID",b."STT_ID" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" b) e WHERE e."PIP_ID" NOT IN 
		-- (SELECT col_id from uniqueid_log.master_unq_id WHERE stat_code LIKE '''||stat_code||''')) c,'||sch_name||'."'|| UPPER(tbl_nme) ||'" d 
		-- WHERE c."PIP_ID"=d."PIP_ID" AND c."PIP_ID"<>0 ';
		
		-- /*
		-- SELECT d."ID",d."NAME",'GA_POI','PIP_ID',d."PIP_ID"::text,'Child Poi’s pip id must match with parent id in same state poi master file','1.35.2' 
		-- FROM (SELECT e."PIP_ID",e."STT_ID" FROM ( SELECT a."PIP_ID",a."STT_ID" FROM mmi_v180."GA_POI" a WHERE "PIP_ID" <> 0 
		-- EXCEPT SELECT b."ID",b."STT_ID" FROM mmi_v180."GA_POI" b) e WHERE e."PIP_ID" NOT IN 
		-- (SELECT col_id from uniqueid_log.master_unq_id WHERE stat_code LIKE '||stat_code||')) c,mmi_v180."GA_POI" d 
		-- WHERE c."PIP_ID"=d."PIP_ID" AND c."PIP_ID"<>0
		-- */

		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'Child Poi’s pip id must match with parent id in same state poi master file';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.35.3
-- 31 msec
	BEGIN
	
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''PIP_ID'',"PIP_ID"::text, ''PIP_ID should not match with same POI ID'',''1.35.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t
		 WHERE "PIP_ID"="ID" AND "ID"<>0 ';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','PIP_ID',"PIP_ID"::text, 'PIP_ID should not match with same POI ID','1.35.3' FROM mmi_v180."GA_POI" As t
		 WHERE "PIP_ID"="ID" AND "ID"<>0
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'PIP_ID should not match with same POI ID';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.35.5
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''PIP_ID'',"PIP_ID"::text, ''PIP_ID must be filled if PIP_TYPE=1'',''1.35.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."PIP_TYP"=1 AND (t."PIP_ID" = 0 OR t."PIP_ID" IS NULL)';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','PIP_ID',"PIP_ID"::text, 'PIP_ID must be filled if PIP_TYPE=1','1.35.5' FROM mmi_v180."GA_POI" As t 
		 WHERE t."PIP_TYP"=1 AND (t."PIP_ID" = 0 OR t."PIP_ID" IS NULL)
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'PIP_ID must be filled if PIP_TYPE=1';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.35.6
--2.47.207
-- 687 msec
	BEGIN	
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		 SELECT tab."ID",tab."NAME",'''||tbl_nme||''',''PIP_ID'', tab."PIP_ID"::text,''Parent Poi’s and their responding child Poi’s Admin id, City id & Vicin Id must be same'',''2.47.207'' 
		 FROM ( SELECT b."ID", b."NAME", b."PIP_ID" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As a INNER JOIN '||sch_name||'."'|| UPPER(tbl_nme) ||'" As b ON 
		 b."PIP_TYP"  IN (1,2,3) AND ( a."ID"=b."PIP_ID" ) AND ( a."ADMIN_ID"<>b."ADMIN_ID" OR a."CITY_ID"<>b."CITY_ID" OR a."VICIN_ID"<>b."VICIN_ID") WHERE b."PIP_ID"<>0 ) As tab';

		--SELECT tab."ID",tab."NAME",'tbl_nme','PIP_ID', tab."PIP_ID"::text,'Parent Poi’s and their c OR responding child Poi’s Admin id, City id & Vicin Id must be same','2.47.207' 
	    --FROM ( SELECT b."ID", b."NAME", b."PIP_ID" FROM mmi_v180."DL_POI" As a INNER JOIN mmi_v180."DL_POI" As b ON 
        --( a."ID"=b."PIP_ID" ) AND ( a."ADMIN_ID"<>b."ADMIN_ID" OR a."CITY_ID"<>b."CITY_ID" OR a."VICIN_ID"<>b."VICIN_ID") WHERE b."PIP_ID"<>0 ) As tab
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Parent Poi’s and their responding child Poi’s Admin id, City id & Vicin Id must be same';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.35.7
--3.5 sec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		 SELECT t2."ID",t2."NAME",'''||tbl_nme||''',''PIP_ID'', t2."PIP_ID"::text,''Parent Poi’s and their c OR responding child Poi’s id AND pip id should not be same'',''1.35.7'' FROM ( SELECT t1."ID", t1."NAME", t1."PIP_ID"
		 FROM ( SELECT b."ID", b."NAME", b."PIP_ID",COUNT(*) OVER(PARTITION By b."ID") As ct1 
		 FROM ( SELECT child."ID", child."PIP_ID" FROM ( SELECT "ID","PIP_ID", COUNT(*) OVER(PARTITION By "PIP_ID") As ct 
		 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "PIP_ID"<>0) As child WHERE ct=1) As a INNER JOIN '||sch_name||'."'|| UPPER(tbl_nme) ||'" b ON a."PIP_ID"=b."ID" AND b."PIP_ID"<>0) As t1 WHERE ct1=1) As t2,
		( SELECT child."ID", child."PIP_ID" FROM ( SELECT "ID","PIP_ID", COUNT(*) OVER(PARTITION By "PIP_ID") As ct FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "PIP_ID"<>0) As child WHERE ct=1) As t3 
		 WHERE t3."ID"=t2."PIP_ID" AND t3."PIP_ID"=t2."ID" ';
        
        --SELECT t2."ID",t2."NAME",'GA_POI','PIP_ID', t2."PIP_ID"::text,'Parent Poi’s and their c OR responding child Poi’s id AND pip id should not be same','1.35.7' FROM ( SELECT t1."ID", t1."NAME", t1."PIP_ID" 
		--FROM ( SELECT b."ID", b."NAME", b."PIP_ID",COUNT(*) OVER(PARTITION By b."ID") As ct1 
		--FROM ( SELECT child."ID", child."PIP_ID" FROM ( SELECT "ID","PIP_ID", COUNT(*) OVER(PARTITION By "PIP_ID") As ct 
		--FROM mmi_v180."GA_POI" WHERE "PIP_ID"<>0) As child WHERE ct=1) As a INNER JOIN mmi_v180."GA_POI" b ON a."PIP_ID"=b."ID" AND b."PIP_ID"<>0) As t1 WHERE ct1=1) As t2,
		--(SELECT child."ID", child."PIP_ID" FROM ( SELECT "ID","PIP_ID", COUNT(*) OVER(PARTITION By "PIP_ID") As ct FROM mmi_v180."GA_POI" WHERE "PIP_ID"<>0) As child WHERE ct=1) As t3 
		--WHERE t3."ID"=t2."PIP_ID" AND t3."PIP_ID"=t2."ID"
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Parent Poi’s and their c OR responding child Poi’s id AND pip id should not be same';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
----2.47.322	
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT tab1."ID",tab1."NAME",'''||tbl_nme||''',''PIP_ID'',tab1."PIP_ID"::text, ''PIP_Id/Geometry If PIP_Id=1 then these records must not be greater then 500 meters parent record'',''2.47.322'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As tab1 Inner Join 
		(SELECT "SP_GEOMETRY" AS childgeom,"ID","PIP_ID" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "PIP_ID" IS NOT NULL  AND "PIP_ID" <> 0 ) AS tab2
		on tab1."ID" = tab2."PIP_ID" WHERE  ST_DISTANCE(tab1."SP_GEOMETRY"::geography,tab2.childgeom::geography) >500 AND tab1."PIP_ID"<>0 ';
		 
		 /*
		 Select tab1."ID",ST_DISTANCE(tab1."SP_GEOMETRY"::geography,tab2.childgeom::geography) From mmi_master."DL_POI" tab1 Inner Join 
		(SELECT "SP_GEOMETRY" AS childgeom,"ID","PIP_ID" FROM mmi_master."DL_POI" WHERE "PIP_ID" IS NOT NULL  AND "PIP_ID" <> 0 ) AS tab2
		on tab1."ID" = tab2."PIP_ID" WHERE  ST_DISTANCE(tab1."SP_GEOMETRY"::geography,tab2.childgeom::geography) >500
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'PIP_TYP should be 1 if PIP_ID exist';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
-----------------------------------------------------------------------------------------------PIP_TYP-----------------------------------------------------------------------------------------------------------------------------------------------
--1.36.1
--2.47.109
-- UPDATED BT GOLDY 12/04/2019
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''PIP_TYP'',"PIP_TYP"::text, ''PIP_TYP should be 1,2,3  if PIP_ID exist'',''1.36.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE (t."PIP_TYP" NOT IN (1,2,3) AND t."PIP_ID"<>0)';
		 
		 /*
		 SELECT "ID","NAME",'','PIP_TYP',"PIP_TYP"::text, 'PIP_TYP should be 1 if PIP_ID exist','1.36.1' FROM mmi_v180."GA_POI" As t 
		 WHERE ((t."PIP_TYP"=0 OR t."PIP_TYP" IS NULL) AND t."PIP_ID"<>0)
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'PIP_TYP should be 1 if PIP_ID exist';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.36.2
-- 32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''PIP_TYP'',"PIP_TYP"::text, ''PIP_TYP should be 0'',''1.36.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE ("PIP_TYP"<>0 AND "PIP_ID"=0)';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','PIP_TYP',"PIP_TYP"::text, 'PIP_TYP should be 0 AND 1','1.36.2' FROM mmi_v180."GA_POI" As t 
		 WHERE ("PIP_TYP"<>0 AND "PIP_TYP"<>1)
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'PIP_TYP should be 0 AND 1';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	

	
----------------------------------------------------------------------------------------------EDGE_ID-----------------------------------------------------------------------------------------------------------------------------------------------
--1.37.1
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''EDGE_ID'',"EDGE_ID"::text, ''EDGE_ID should not be 0'',''1.37.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ("EDGE_ID" = 0 OR "EDGE_ID" IS NULL)';
		 
		 /*
		 SELECT "ID","NAME",'GA_POI','EDGE_ID',"EDGE_ID"::text, 'EDGE_ID should not be 0','1.37.1' FROM mmi_v180."GA_POI" 
		 WHERE ("EDGE_ID" = 0 OR "EDGE_ID" IS NULL)
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'EDGE_ID should not be 0';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
---------------------------------------------------------------------------------------------EDGE_SIDE-----------------------------------------------------------------------------------------------------------------------------------------------
--1.38.1
-- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''EDGE_SIDE'',"EDGE_SIDE", ''EDGE_SIDE must be L OR R'',''1.38.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE COALESCE("EDGE_SIDE",'''')<>'''' AND  (COALESCE("EDGE_SIDE",'''')<>''L'') AND (COALESCE("EDGE_SIDE",'''')<>''R'')';
		 /*
		  SELECT "ID","NAME",'GA_POI','EDGE_SIDE',"EDGE_SIDE", 'EDGE_SIDE must be L OR R','1.38.1' FROM mmi_v180."GA_POI" As t 
		 WHERE (COALESCE("EDGE_SIDE",'')<>'L') AND (COALESCE("EDGE_SIDE",'')<>'R')
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'EDGE_SIDE must be L OR R';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	

-----------------------------------------------------------------------------------------------IMP_POI----------------------------------------------------------------------------------------------------------------------------------------------
--1.39.2
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''IMP_POI'',"IMP_POI", ''IMP_POI must contain codes like IMP_LOC or IMP_CITY or IMP_SO or IMP_NAT or IMP_DE or IMP'',''1.39.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE "IMP_POI" NOT IN (''IMP_LOC'',''IMP_CITY'',''IMP_SO'',''IMP_NAT'',''IMP_DE'',''IMP'')';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''IMP_POI'',"IMP_POI", ''IMP_POI must contain codes like IMP_LOC or IMP_CTY or IMP_STT or IMP_SO or IMP_NAT or IMP_DE or IMP'',''1.39.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
	    WHERE "IMP_POI" NOT IN (''IMP_LOC'',''IMP_CTY'',''IMP_STT'',''IMP_SO'',''IMP_NAT'',''IMP_DE'',''IMP'',''IMP_DST'', ''IMP_DST'')';
		
		/*
		 SELECT "ID","NAME",'GA_POI','IMP_POI',"IMP_POI", 'IMP_POI must contain codes like IMP_LOC or IMP_CTY or IMP_STT or IMP_SO or IMP_NAT or IMP_DE or IMP','1.39.2' FROM mmi_v180."GA_POI" As t 
		 WHERE "IMP_POI" NOT IN ('IMP_LOC','IMP_CTY','IMP_STT','IMP_SO','IMP_NAT','IMP_DE','IMP')
		*/
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'IMP_POI must contain codes like IMP_LOC or IMP_CTY or IMP_STT or IMP_SO or IMP_NAT or IMP_DE or IMP';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.39.3
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''IMP_POI'',"IMP_POI", ''Special charecter must not available except _'',''1.39.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."IMP_POI"~''[^A-Za-z0-9\s_,]''';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','IMP_POI',"IMP_POI", 'Special charecter must not available except _', '1.39.3' FROM mmi_v180."GA_POI" As t 
		 WHERE t."IMP_POI"~'[^A-Za-z0-9\s_,]'
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Special charecter must not available except _';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.39.4
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''IMP_POI'',"IMP_POI", ''IMP_POI AND IRR_POI cannot be filled for same POI'',''1.39.4'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE COALESCE("IMP_POI",'''')<>'''' AND COALESCE("IRR_POI",'''')<>''''';

		-- SELECT "ID","NAME",'tbl_nme','IMP_POI',"IMP_POI", 'IMP_POI AND IRR_POI cannot be filled for same POI','1.39.4' FROM mmi_v180."GA_POI" As t 
		-- WHERE COALESCE("IMP_POI",'')<>'' AND COALESCE("IRR_POI",'')<>''
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'IMP_POI AND IRR_POI cannot be filled for same POI';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.39.5
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''IMP_POI'',"IMP_POI", ''IMP_POI must be in UPPER Case'',''1.39.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE UPPER("IMP_POI") <> ("IMP_POI")';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','IMP_POI',"IMP_POI", 'IMP_POI must be in UPPER Case', '1.39.5' FROM mmi_v180."GA_POI" 
		 WHERE UPPER("IMP_POI") <> ("IMP_POI")
		 */
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'IMP_POI must be in UPPER Case';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-----------------------------------------------------------------------------------------------VICIN_ID----------------------------------------------------------------------------------------------------------------------------------------------
--1.41.4
-- 32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		 SELECT tab1.i As ID, tab1.poi As POI,'''||tbl_nme||''',''VICIN_ID'',"VICIN_ID"::text,''VICIN_ID also must be maintained in child AND parent POIs'',''1.41.4'' 
		 FROM ( SELECT a."ID" As i, a."NAME" As poi, b."PIP_ID", b."VICIN_ID" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As a INNER JOIN '||sch_name||'."'|| UPPER(tbl_nme) ||'" As b	ON a."ID"=b."PIP_ID" AND 
		 a."VICIN_ID"<>0 AND b."VICIN_ID"=0 AND a."ID"<>0 ) As tab1';
		 
		 --SELECT tab1.i As ID, tab1.poi As POI,'GA_POI','VICIN_ID',"VICIN_ID"::text,'VICIN_ID also must be maintained in child AND parent POIs','1.41.4' 
		 --FROM ( SELECT a."ID" As i, a."NAME" As poi, b."PIP_ID", b."VICIN_ID" FROM mmi_v180."GA_POI" As a INNER JOIN mmi_v180."GA_POI" As b	ON a."ID"=b."PIP_ID" AND 
		 --a."VICIN_ID"<>0 AND b."VICIN_ID"=0 AND a."ID"<>0 ) As tab1
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
 	END;
	RAISE INFO 'VICIN_ID also must be maintained in child AND parent POIs';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.41.5
--32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''VICIN_ID'',"VICIN_ID"::text, ''VICIN_ID never matched with CITY_ID'',''1.41.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE ("CITY_ID"="VICIN_ID" AND ("VICIN_ID"<>0 AND "VICIN_ID" IS NOT NULL AND "CITY_ID"<>0 AND "CITY_ID" IS NOT NULL)) ';

		 --SELECT "ID","NAME",'tbl_nme','VICIN_ID',"VICIN_ID"::text, 'VICIN_ID never matched with CITY_ID','1.41.5' FROM mmi_v180."GA_POI" As t 
		 --WHERE ("CITY_ID"="VICIN_ID" AND ("VICIN_ID"<>0 AND "VICIN_ID" IS NOT NULL AND "CITY_ID"<>0 AND "CITY_ID" IS NOT NULL))
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'VICIN_ID never matched with CITY_ID';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
------------------------------------------------------------------------------------------------SEC_STA----------------------------------------------------------------------------------------------------------------------------------------------
-- --1.44.1
-- -- 31 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''SEC_STA'',"SEC_STA", ''SEC_STA should contain only PC or R or KR or KC or C'',''1.44.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE "SEC_STA" NOT IN (''PC'',''R'',''KR'',''KC'',''C'') ';
         
		 -- --SELECT "ID","NAME",'GA_POI)','SEC_STA',"SEC_STA", 'SEC_STA should contain only PC or R or KR or KC or C','1.44.1' FROM mmi_v180."GA_POI" As t 
		-- -- WHERE "SEC_STA" NOT IN ('PC','R','KR','KC','C')
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'SEC_STA should contain only PC or R or KR or KC or C';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;

--2.47.120
-- UPDATED BY GOLDY 12/04/2019
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''SEC_STA'',"SEC_STA", ''Only C,KC and PC values are accepted'',''2.47.120'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE "SEC_STA" NOT IN (''PC'',''KC'',''C'') ';
         
		 -- SELECT "ID","NAME",'GA_POI)','SEC_STA',"SEC_STA", 'Only "C", "KC" and "PC" values are accepted','2.47.120' FROM upload."AS_CN002171_12042019_POI_EDT" As t 
		--WHERE t."SEC_STA" NOT IN ('PC','KC','C')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Only C, KC and PC values are accepted';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.44.2
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''SEC_STA'',"SEC_STA", ''SEC_STA must not be blank'',''1.44.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE COALESCE("SEC_STA",'''')=''''';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','SEC_STA',"SEC_STA", 'SEC_STA must not be blank','1.44.2' FROM mmi_v180."GA_POI" As t 
		 WHERE COALESCE("SEC_STA",'')=''
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'SEC_STA must not be blank';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.44.3
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''SEC_STA'',"SEC_STA",''SEC_STA must be in UPPER Case'',''1.44.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE UPPER("SEC_STA") <> ("SEC_STA")';
		 /*
		  SELECT "ID","NAME",'GA_POI','SEC_STA',"SEC_STA",'SEC_STA must be in UPPER Case','1.44.3' FROM mmi_v180."GA_POI" As t 
		 WHERE UPPER("SEC_STA") <> ("SEC_STA")
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'SEC_STA must be in UPPER Case';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.44.6
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''SEC_STA'',"SEC_STA", ''If SEC_STA is R OR KR THEN its PRIORITY should be 99'',''1.44.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE ("SEC_STA" = ''R'' OR "SEC_STA" =''KR'') AND "PRIORITY"<>99';
		 /*
		  SELECT "ID","NAME",'||tbl_nme||','SEC_STA',"SEC_STA", 'If SEC_STA is R OR KR THEN its PRIORITY should be 99','1.44.6' FROM mmi_v180."GA_POI" 
		 WHERE ("SEC_STA" = 'R' OR "SEC_STA" ='KR') AND "PRIORITY"<>99		 		 		 	 

		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If SEC_STA is R OR KR THEN its PRIORITY should be 99';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-- --1.44.10
-- --47 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		 -- SELECT tab1.i As ID,tab1.poi As POI,'''||tbl_nme||''',''SEC_STA'',"SEC_STA", ''Parent SEC_STA value does not match with its child SEC_STA column'',''1.44.10'' 
		 -- FROM ( SELECT a."ID" As i, a."NAME" As poi, b."PIP_ID", b."SEC_STA" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As a INNER JOIN '||sch_name||'."'|| UPPER(tbl_nme) ||'" As b ON a."ID"=b."PIP_ID" AND  
		 -- a."SEC_STA" <> b."SEC_STA" AND b."PIP_ID"<>0 AND (COALESCE(a."SEC_STA",'''')<>'''') ) tab1';
		 
		 -- /*
		  -- SELECT tab1.i As ID,tab1.poi As POI,'GA_POI','SEC_STA',"SEC_STA", 'Parent SEC_STA value does not match with its child SEC_STA column','1.44.10' 
		 -- FROM ( SELECT a."ID" As i, a."NAME" As poi, b."PIP_ID", b."SEC_STA" FROM mmi_v180."GA_POI" As a INNER JOIN mmi_v180."GA_POI" As b ON a."ID"=b."PIP_ID" AND  
		 -- a."SEC_STA" <> b."SEC_STA" AND b."PIP_ID"<>0 AND (COALESCE(a."SEC_STA",'')<>'') ) tab1
		 -- */

		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'Parent SEC_STA value does not match with its child SEC_STA column';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-------------------------------------------------------------------------------------------------Q_LVL-----------------------------------------------------------------------------------------------------------------------------------------------
--1.47.1
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''Q_LVL'',"Q_LVL", ''Q_LVL contains of value between 1 to 5 AND 9'',''1.47.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE 
		("Q_LVL"<>''1'' AND "Q_LVL"<>''2'' AND "Q_LVL"<>''3'' AND "Q_LVL"<>''4'' AND "Q_LVL"<>''5'' AND "Q_LVL"<>''9'') AND (COALESCE("Q_LVL",'''')<>'''')';

		/*
		 SELECT "ID","NAME",'GA_POI','Q_LVL',"Q_LVL", 'Q_LVL contains of value between 1 to 5 AND 9','1.47.1' FROM mmi_v180."GA_POI" As t 
		 WHERE ("Q_LVL"<>'1' AND "Q_LVL"<>'2' AND "Q_LVL"<>'3' AND "Q_LVL"<>'4' AND "Q_LVL"<>'5' AND "Q_LVL"<>'9') AND (COALESCE("Q_LVL",'')<>'')
		*/
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Q_LVL contains of value between 1 to 5 AND 9';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.47.2
--32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''Q_LVL'',"Q_LVL", ''Q_LVL should not contain any special characters'',''1.47.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE "Q_LVL" ~''[^A-Za-z0-9\s]''';
		 /*
		  SELECT "ID","NAME",'GA_POI','Q_LVL',"Q_LVL", 'Q_LVL should not contain any special characters','1.47.2' FROM mmi_v180."GA_POI" As t 
		 WHERE "Q_LVL" ~'[^A-Za-z0-9\s]'
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Q_LVL should not contain any special characters';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.47.5
-- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''Q_LVL'',"Q_LVL", ''Q_LVL=1 AND PRIORITY=97 AND PIP_ID=0 and FTR_CRY not like "%OTH"'',''1.47.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE "Q_LVL"=''1'' AND "PRIORITY"=97 AND "PIP_ID"=0 AND "FTR_CRY" NOT LIKE ''%OTH''';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','Q_LVL',"Q_LVL", 'Q_LVL=1 AND PRIORITY=97 Err OR ','1.47.5' FROM mmi_v180."GA_POI" As t 
		 WHERE "Q_LVL"='1' AND "PRIORITY"=97 AND "PIP_ID"=0 AND "FTR_CRY" NOT LIKE '%OTH'
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Q_LVL=1 AND PRIORITY=97 AND PIP_ID=0 and FTR_CRY not like OTH';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
---------------------------------------------------------------------------------------------BRAND_NME-----------------------------------------------------------------------------------------------------------------------------------------------
-- --2.47.230
-- -- 16 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''BRAND_NME'',"BRAND_NME", ''In BRAND_NME Special character must not be present except ’&’'',''2.47.230'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE t."BRAND_NME" IS NOT NULL AND (t."BRAND_NME"~''[^0-9A-Za-z&\s]'') AND  t."BRAND_NME" NOT IN (SELECT "BND_NME" FROM mmi_master."BRAND_LIST") ';
		 -- /*
		  -- SELECT "ID","NAME",'GA_POI','BRAND_NME',"BRAND_NME", 'In BRAND_NME Special character must not be present except ’&’','2.47.230' FROM mmi_v180."GA_POI" As t 
		 -- WHERE t."BRAND_NME" IS NOT NULL AND (t."BRAND_NME"~'[^0-9A-Za-z&\s]')
		 -- */

		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'In BRAND_NME Special character must not be present except ’&’';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.48.4
--32 msec
	BEGIN
		 sqlQuery = ' with res as (
		select tab1."ID",tab1."NAME",tab1."BRAND_NME",tab2."BND_NAME" from '||sch_name||'."'|| UPPER(tbl_nme) ||'" AS tab1 left join '||mst_sch||'."BRAND_LIST" tab2 on
		tab1."NAME" = tab2."BND_NAME" AND tab1."BRAND_NME" = tab2."BND_NAME" WHERE (coalesce(tab2."BND_NAME",'''')=''''  OR coalesce(tab2."BND_NAME",'''')='''') AND coalesce(tab1."BRAND_NME",'''')='''' )
		INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT t."ID",t."NAME",'''||tbl_nme||''',''BRAND_NME'',t."BRAND_NME", ''BRAND_NME should be part of NAME'',''1.48.4'' FROM res As t 
		WHERE 
		UPPER(t."NAME") NOT LIKE ''% '' || UPPER(t."BRAND_NME") || '' %'' AND UPPER(t."NAME") NOT LIKE '''' || UPPER(t."BRAND_NME") || '' %'' AND UPPER(t."NAME") NOT LIKE ''% '' || UPPER(t."BRAND_NME") || '''' AND 
		( UPPER(t."NAME") NOT LIKE'' % ATM'' AND UPPER(t."NAME") NOT LIKE ''ATM %'' AND UPPER(t."NAME") NOT LIKE ''% ATM %'') AND (COALESCE(t."BRAND_NME",'''')<>'''') AND UPPER(t."NAME") <> UPPER(t."BRAND_NME")';
		--raise info 'query %',sqlQuery;
		EXECUTE (sqlQuery);
		
		/*
		 with res as (
		select tab1."ID",tab1."NAME",tab2."NAME",tab1."BRAND_NME",tab2."BND_NAME" from mmi_master."DL_POI" AS tab1 left join mmi_master."BRAND_LIST" tab2 on
		tab1."NAME" = tab2."NAME" AND tab1."BRAND_NME" = tab2."BND_NAME" WHERE (tab2."NAME" IS NULL OR tab2."BND_NAME" IS NULL) AND tab1."BRAND_NME" is not null )
		SELECT "ID","NAME",'GA_POI','BRAND_NME',"BRAND_NME", 'BRAND_NME should be part of NAME','1.48.4' FROM res As t 
		WHERE 	UPPER(t."NAME") NOT LIKE '% ' || UPPER(t."BRAND_NME") || ' %' AND UPPER(t."NAME") NOT LIKE '' || UPPER(t."BRAND_NME") || ' %' AND UPPER(t."NAME") NOT LIKE '% ' || UPPER(t."BRAND_NME") || '' AND 
		( UPPER(t."NAME") NOT LIKE'% ATM' AND UPPER(t."NAME") NOT LIKE'ATM %' AND UPPER(t."NAME") NOT LIKE'% ATM %') AND (COALESCE("BRAND_NME",'')<>'') AND UPPER(t."NAME") <> UPPER(t."BRAND_NME")
		*/
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'BRAND_NME should be part of NAME';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.48.5
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''BRAND_NME'',"BRAND_NME", ''BRAND_NME should not be 0'',''1.48.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE (COALESCE("BRAND_NME",'''')=''0'')';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','BRAND_NME',"BRAND_NME", 'BRAND_NME should not be 0','1.48.5' FROM mmi_v180."GA_POI" As t 
		 WHERE (COALESCE("BRAND_NME",'')='0')
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'BRAND_NME should not be 0';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
---ADDED BY BIPIN NEW CHECK
	-- --1.1.1.10
	-- --16 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''BRAND_NME'',"BRAND_NME", ''Brand_Nme must not be match with Poplr_Nme'',''1.1.1.10'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		-- WHERE (LOWER("BRAND_NME") LIKE LOWER("POPLR_NME") AND (COALESCE("BRAND_NME",'''')<>'''')) ';
        -- /*
		 -- SELECT "ID","NAME",'GA_POI','BRAND_NME',"BRAND_NME", 'Brand_Nme must not be match with Poplr_Nme','1.1.1.10' FROM mmi_v180."GA_POI" 
		-- WHERE (LOWER("BRAND_NME") LIKE LOWER("POPLR_NME") AND (COALESCE("BRAND_NME",'')<>''))
		-- */
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'Brand_Nme must not be match with Poplr_Nme';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-- --1.1.1.10
-- --31 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''BRAND_NME'',"BRAND_NME", ''Brand_Nme must not be match with Alias_1'',''1.1.1.10'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		-- WHERE (LOWER("BRAND_NME") LIKE LOWER("ALIAS_1") AND (COALESCE("BRAND_NME",'''')<>'''')) ';
        -- /*
		 -- SELECT "ID","NAME",'GA_POI','BRAND_NME',"BRAND_NME", 'Brand_Nme must not be match with Alias_1','1.1.1.10' FROM mmi_v180."GA_POI" 
		-- WHERE (LOWER("BRAND_NME") LIKE LOWER("ALIAS_1") AND (COALESCE("BRAND_NME",'')<>''))
		-- */
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'Brand_Nme must not be match with Alias_1';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-- --1.1.1.10
-- --32 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''BRAND_NME'',"BRAND_NME", ''Brand_Nme must not be match with Alias_2'',''1.1.1.10'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		-- WHERE (LOWER("BRAND_NME") LIKE LOWER("ALIAS_2") AND (COALESCE("BRAND_NME",'''')<>'''')) ';
        -- /*
		 -- SELECT "ID","NAME",'GA_POI','BRAND_NME',"BRAND_NME", 'Brand_Nme must not be match with Alias_2','1.1.1.10' FROM mmi_v180."GA_POI" 
		-- WHERE (status NOT IN ('0','5') OR (COALESCE(status,'')='') ) AND (LOWER("BRAND_NME") LIKE LOWER("ALIAS_2") AND (COALESCE("BRAND_NME",'')<>''))
		-- */
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'Brand_Nme must not be match with Alias_2';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-- --1.1.1.10
-- --31 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''BRAND_NME'',"BRAND_NME", ''Brand_Nme must not be match with Alias_3'',''1.1.1.10'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		-- WHERE (LOWER("BRAND_NME") LIKE LOWER("ALIAS_3") AND (COALESCE("BRAND_NME",'''')<>'''')) ';
		-- /*
		-- SELECT "ID","NAME",'''||tbl_nme||''',''BRAND_NME'',"BRAND_NME", ''Brand_Nme must not be match with Alias_3'',''1.1.1.10'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		-- WHERE (LOWER("BRAND_NME") LIKE LOWER("ALIAS_3") AND (COALESCE("BRAND_NME",'''')<>''''))
		-- */

		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'Brand_Nme must not be match with Alias_3';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-- --1.1.1.10
-- --15 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''BRAND_NME'',"BRAND_NME", ''Brand_Nme must not be match with Address'',''1.1.1.10'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		-- WHERE (LOWER("BRAND_NME") LIKE LOWER("ADDRESS") AND (COALESCE("BRAND_NME",'''')<>'''')) ';
		
		-- /*
		 -- SELECT "ID","NAME",'GA_POI','BRAND_NME',"BRAND_NME", 'Brand_Nme must not be match with Address','1.1.1.10' FROM mmi_v180."GA_POI" 
		-- WHERE (LOWER("BRAND_NME") LIKE LOWER("ADDRESS") AND (COALESCE("BRAND_NME",'')<>''))
		-- */

		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'Brand_Nme must not be match with Address';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
---END ADDED BY BIPIN NEW CHECK	
---------------------------------------------------------------------------------------------PRIORITY----------------------------------------------------------------------------------------------------------------------------------------------
--1.49.1
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''PRIORITY'',"PRIORITY"::text, ''PRIORITY should not be 0'',''1.49.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE "PRIORITY" = 0';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','PRIORITY',"PRIORITY"::text, 'PRIORITY should not be 0','1.49.1' FROM mmi_v180."GA_POI" As t 
		 WHERE "PRIORITY" = 0
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'PRIORITY should not be 0';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.49.2
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''PRIORITY'',"PRIORITY"::text, ''PRIORITY contains this fixed integer range of PRIORITY 4 – 16, 97, 98, 99 OR 999'',''1.49,2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE ("PRIORITY" NOT BETWEEN 4 AND 16) AND "PRIORITY" <> 97 AND "PRIORITY" <> 98 AND "PRIORITY" <> 99 AND "PRIORITY" <> 999';
        /*
		SELECT "ID","NAME",'GA_POI','PRIORITY',"PRIORITY"::text, 'PRIORITY contains this fixed integer range of PRIORITY 4 – 16, 97, 98, 99 OR 999','1.49,2' FROM mmi_v180."GA_POI" As t 
		 WHERE ("PRIORITY" NOT BETWEEN 4 AND 16) AND "PRIORITY" <> 97 AND "PRIORITY" <> 98 AND "PRIORITY" <> 99 AND "PRIORITY" <> 999	
		*/
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'PRIORITY contains this fixed integer range of PRIORITY 4 – 16, 97, 98, 99 OR 999';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.49.8
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''PRIORITY'',"PRIORITY"::text, ''If PRIORITY=99 then SEC_STA should be R or KR'',''1.49.8'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE ("SEC_STA" LIKE ''%R%'' OR "SEC_STA" LIKE ''%KR%'') AND "PRIORITY"<>99';
		 
		 /*
		 SELECT "ID","NAME",'GA_POI','PRIORITY',"PRIORITY"::text, 'If PRIORITY=99 then SEC_STA should be R or KR','1.49.8' FROM mmi_v180."GA_POI" As t 
		 WHERE ("SEC_STA" LIKE '%R%' OR "SEC_STA" LIKE '%KR%') AND "PRIORITY"<>99
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If PRIORITY=99 then SEC_STA should be R or KR';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
----------------------------------------------------------------------------------------------LANDMARK-----------------------------------------------------------------------------------------------------------------------------------------------
--1.50.1
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''LANDMARK'',"LANDMARK", ''LANDMARK must be Y or N'',''1.50.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE  (COALESCE("LANDMARK",'''')<>''Y'') AND (COALESCE("LANDMARK",'''')<>''N'')';

		-- SELECT "ID","NAME",'tbl_nme','LANDMARK',"LANDMARK", 'LANDMARK must be Y or N','1.50.1' FROM mmi_v180."GA_POI" As t 
		-- WHERE (COALESCE("LANDMARK",'')<>'Y') AND (COALESCE("LANDMARK",'')<>'N')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'LANDMARK must be Y or N';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.50.1
--32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''LANDMARK'',"LANDMARK", ''LANDMARK must be in Upper Case'',''1.50.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE UPPER("LANDMARK") <> "LANDMARK"';
		 
		 /*
		 SELECT "ID","NAME",'GA_POI','LANDMARK',"LANDMARK", 'LANDMARK must be in Upper Case','1.50.1' FROM mmi_v180."GA_POI" As t 
		 WHERE UPPER("LANDMARK") <> "LANDMARK"
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'LANDMARK must be in Upper Case';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.50.2
--47 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''LANDMARK'',"LANDMARK",''Special charecter must not available'',''1.50.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE (t."LANDMARK"~''[^A-Za-z0-9]'' AND (COALESCE("LANDMARK",'''')<>''''))';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','LANDMARK',"LANDMARK",'Special charecter must not available','1.50.2' FROM mmi_v180."GA_POI" As t 
		 WHERE (t."LANDMARK"~'[^A-Za-z0-9]' AND (COALESCE("LANDMARK",'')<>''))
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Special charecter must not available';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
---------------------------------------------------------------------------------------------BRANCH_NME----------------------------------------------------------------------------------------------------------------------------------------------
--- -- -1.51.1
--- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''BRANCH_NME'',"BRANCH_NME", ''Special charecter must not available except ’&’'',''1.51.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE "BRANCH_NME" ~''[^A-Za-z0-9\s&]'''; 
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','BRANCH_NME',"BRANCH_NME", 'Special charecter must not available except ’&’','1.51.1' FROM mmi_v180."GA_POI" As t 
		 WHERE "BRANCH_NME" ~'[^A-Za-z0-9\s&]'
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Special charecter must not available except ’&’';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.51.4
---31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''BRANCH_NME'',"BRANCH_NME", ''Double Spaces are not allowed'',''1.51.4'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND "BRANCH_NME"= ''%  %''';
		--ADDED BY ABHI
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1", ''If (NAME" "Branch_Nme)=(Alias1)'',''1.51.4'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE CONCAT("NAME",'' '',"BRANCH_NME") = "ALIAS_1" ';
		
		/*
		 SELECT "ID","NAME",'GA_POI','ALIAS_1',"ALIAS_1", 'If (NAME" "Branch_Nme)=(Alias1)','1.51.4' FROM mmi_v180."GA_POI" 
		WHERE CONCAT("NAME",' ',"BRANCH_NME") = "ALIAS_1"
		*/

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Double Spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
----------------------------------------------------------------------------------------------STR_RATG-----------------------------------------------------------------------------------------------------------------------------------------------
--1.52.3
---31 msec
-- cahnge by ashutosh '^[1-5]{1}\.[0-9]{1,2}$|^[1-5]$|^[A-Z]$|^[1-5]{1}[*]{1}$|^[1-5][*]$|^[1-5]\.[1-9]{1,2}[*]$|^[A-Z][\+]{1,2}$'
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''STR_RATG'',"STR_RATG", ''STR_RATG Column can have only (0,1,2,3,4,5,A-Z,.,+,++,*) values'',''1.52.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND "STR_RATG"!~''^[1-5]{1}\.[1-9]{1,2}$|^[1-5]$|^[A-Z]$|^[1-5]{1}[*]{1}$|^[1-5][*]$|^[1-5]\.[1-9]{1,2}[*]$|^[A-Z][\+]{1,2}$'' ';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''STR_RATG'',"STR_RATG", ''STR_RATG Column can have only (1,2,3,4,5,A-Z,.,+,++,*) values'',''1.52.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE "STR_RATG"!~''^[1-5]{1}\.[0-9]{1,2}$|^[1-5]$|^[A-Z]$|^[1-5]{1}[*]{1}$|^[1-5][*]$|^[1-5]\.[1-9]{1,2}[*]$|^[A-Z][\+]{1,2}$'' ';
		 /*
		 SELECT "ID","NAME",'GA_POI','STR_RATG',"STR_RATG", 'STR_RATG Column can have only (1,2,3,4,5,A-Z,.,+,++,*) values','1.52.3' FROM mmi_v180."GA_POI" As t 
		 WHERE "STR_RATG"!~'^[1-5]{1}\.[1-9]{1,2}$|^[1-5]$|^[A-Z]$|^[1-5]{1}[*]{1}$|^[1-5][*]$|^[1-5]\.[1-9]{1,2}[*]$|^[A-Z][\+]{1,2}$'
		 '^[1-5]{1}\.[1-9]{1,2}$|^[1-5]$|^[A-Z]$|^[1-5]{1}[*]{1}$|^[1-5][*]$|^[1-5]\.[1-9]{1,2}[*]$|^[A-Z][\+]{1,2}$'
		 */
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'STR_RATG Column can have only (1,2,3,4,5,A-Z,.,+,++,*) values';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--- -- --------------------------------------------------------------------------------------RANKING------------------------------------------------------------------------------------------------------------------------------------------------
--1.53.2
--31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''RANKING'',"RANKING"::text, ''Ranking  must be in range of 1 to 1000'',''1.53.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE ("RANKING" NOT BETWEEN 1 AND 1000) AND "RANKING"<>0';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''RANKING'',"RANKING"::text, ''Ranking must be in range of 1 to 4000'',''1.53.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE ("RANKING" NOT BETWEEN 1 AND 4000) AND "RANKING"<>0';
		 
		 /*
		  SELECT "ID","NAME",'GA_POI','RANKING',"RANKING"::text, 'Ranking must be in range of 1 to 4000','1.53.2' FROM mmi_v180."GA_POI" As t 
		 WHERE ("RANKING" NOT BETWEEN 1 AND 4000) AND "RANKING"<>0
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Ranking must be in range of 1 to 4000';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.53.3
	-- BEGIN	
		
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		 -- SELECT t3."ID", t3."NAME",'''||tbl_nme||''',''RANKING'',t3."RANKING"::text, ''CITY_ID,FTR_CRY,SUB_CRY,RANKING should not be same'',''1.53.3'' 
		 -- FROM ( SELECT * FROM ( SELECT "CITY_ID","FTR_CRY","SUB_CRY","RANKING",Count(*) FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE "RANKING"<>0 group By "CITY_ID","FTR_CRY","SUB_CRY","RANKING") t1 
		 -- WHERE t1.count>1) As t2, '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t3 
		 -- WHERE 
		-- t3."CITY_ID"=t2."CITY_ID" AND t3."FTR_CRY"= t2."FTR_CRY" AND t3."RANKING"= t2."RANKING" AND COALESCE(t2."SUB_CRY",'''')=COALESCE(t3."SUB_CRY",'''')';

		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
-----------------------------------------------------------------------------------------------TOVRF-------------------------------------------------------------------------------------------------------------------------------------------------
--1.55.1
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		 SELECT "ID","NAME",'''||tbl_nme||''',''TOVRF'',"TOVRF",''TOVRF must contain only Y or N'',''1.55.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE "TOVRF" ~''[^YNyn,\s]''';
		 
		--  SELECT "ID","NAME",'tbl_nme','TOVRF',"TOVRF",'TOVRF must contain only Y or N','1.55.1' FROM mmi_v180."GA_POI" As t 
		-- WHERE "TOVRF" ~'[^YNyn,\s]'

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
 	END;
	RAISE INFO 'TOVRF must contain only Y or N';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-----------------------------------------------------------------------------------------RSN_TOVRF----------------------------------------------------------------------------------------------------------------------------------------------
--1.56.1
-- 391 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''RSN_TOVRF'',"RSN_TOVRF", ''If Y is updated in TOVRF THEN RSN_TOVRF must be filled'',''1.56.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE ("TOVRF" NOT LIKE ''%Y'' OR "TOVRF" NOT LIKE ''%N'')  AND COALESCE("RSN_TOVRF",'''')='''' ';
		 
		 ---SELECT "ID","NAME",'GA_POI','RSN_TOVRF',"RSN_TOVRF", 'If Y is updated in TOVRF THEN RSN_TOVRF must be filled','1.56.1' FROM mmi_v180."GA_POI" As t 
		 ---WHERE "TOVRF"<>'Y' AND COALESCE("RSN_TOVRF",'')=''

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If Y is updated in TOVRF THEN RSN_TOVRF must be filled';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--- ---------------------------------------------------------------------------------------SPELLCHK------------------------------------------------------------------------------------------------------------------------------------------------
--1.59.1
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''SPELLCHK'',"SPELLCHK", ''Only C or S or L or D or blank values are accepted in SPELLCHK '',''1.59.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE "SPELLCHK"<>''C'' AND "SPELLCHK"<>''S'' AND "SPELLCHK"<>''L'' AND "SPELLCHK"<>''D'' AND COALESCE("SPELLCHK",'''')<>''''';
		
		--SELECT "ID","NAME",'GA_POI','SPELLCHK',"SPELLCHK", 'Only C or S or L or D or blank values are accepted in SPELLCHK','1.59.1' FROM mmi_v180."GA_POI" As t 
		--WHERE "SPELLCHK"<>'C' AND "SPELLCHK"<>'S' AND "SPELLCHK"<>'L' AND "SPELLCHK"<>'D' AND COALESCE("SPELLCHK",'')<>'';
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Only C or S or L or D or blank values are accepted in SPELLCHK';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
---------------------------------------------------------------------------------------------K_PRIORITY----------------------------------------------------------------------------------------------------------------------------------------------
--1.60.1
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''K_PRIORITY'',"K_PRIORITY", ''Only K, M ,F and blank values are accepted in K_PRIORITY'',''1.60.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE "K_PRIORITY" NOT IN (''K'',''M'',''F'') AND COALESCE("K_PRIORITY",'''')<>''''';
		 
		 --SELECT "ID","NAME",'GA_POI','K_PRIORITY',"K_PRIORITY", 'Only K, M and blank values are accepted in K_PRIORITY','1.60.1' FROM mmi_v180."GA_POI" As t 
		 --WHERE "K_PRIORITY" <>'K' AND "K_PRIORITY"<>'M' AND COALESCE("K_PRIORITY",'')<>''

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Only K, M and blank values are accepted in K_PRIORITY';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
---------------------------------------------------------------------------------------------ADMIN_ID------------------------------------------------------------------------------------------------------------------------------------------------
--1.7.3
--47 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		 SELECT tab.i As ID, tab.poi As POI ,'''||tbl_nme||''',''child ADMIN_ID__parent ADMIN_ID'' ,tab.j,''Parent Poi’s and their corresponding child Poi’s admin id must be same'',''1.7.3'' 
		 FROM ( SELECT a."ID" As i ,b."ID" As id , b."PIP_ID",  a."ADMIN_ID" As j, b."ADMIN_ID" j1,a."NAME" As poi 
		 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As a INNER JOIN '||sch_name||'."'|| UPPER(tbl_nme) ||'" As b ON a."ID"=b."PIP_ID" 
         AND a."ADMIN_ID" <> b."ADMIN_ID" AND b."PIP_ID"<>0 AND b."ID"<>0 AND a."ADMIN_ID"<>0 AND a."PIP_TYP"<>2 ) As tab ';
	     
		 -- SELECT tab.i As ID, tab.poi As POI ,'GA_POI','child ADMIN_ID__parent ADMIN_ID' ,tab.j,'Parent Poi’s and their corresponding child Poi’s admin id must be same','1.7.3' 
		-- FROM ( SELECT a."PIP_TYP", a."ID" As i ,b."ID" As id , b."PIP_ID",  a."ADMIN_ID" As j, b."ADMIN_ID" j1,a."NAME" As poi FROM mmi_master."DL_POI" As a INNER JOIN mmi_master."DL_POI" As b ON a."ID"=b."PIP_ID"	  
		-- AND a."ADMIN_ID" <> b."ADMIN_ID" AND b."PIP_ID"<>0 AND b."ID"<>0 AND a."ADMIN_ID"<>0 AND a."PIP_TYP"<>2 ) As tab
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Parent Poi’s and their corresponding child Poi’s admin id must be same';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
---------------------------------------------------------------------------------------------LABEL_NME------------------------------------------------------------------------------------------------------------------------------------------------
-- --2.47.258
-- -- 31 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''LABEL_NME'',"LABEL_NME", ''LABEL_NME must not have special character except ’&’ and -'',''2.47.258'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE t."LABEL_NME" IS NOT NULL AND (t."LABEL_NME"~''[^&\s\w-]'') ';
		 
		 -- --SELECT "ID","NAME",'GA_POI','LABEL_NME',"LABEL_NME", 'LABEL_NME must not have special character except ’&’ and -','2.47.258' FROM mmi_v180."GA_POI" As t 
		 -- --WHERE t."LABEL_NME" IS NOT NULL AND (t."LABEL_NME"~'[^&\s\w-]')
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
-- --2.47.259
-- --31 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''LABEL_NME'',"LABEL_NME", ''Double Spaces are not allowed'',''2.47.259'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE "LABEL_NME" LIKE ''%  %'' ';
		 
		 -- --SELECT "ID","NAME",'GA_POI','LABEL_NME',"LABEL_NME", 'Double Spaces are not allowed','2.47.259' FROM mmi_v180."GA_POI" 
		 -- --WHERE "LABEL_NME" LIKE '%  %'
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
-- --2.47.260
-- -- 15 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''LABEL_NME'',"LABEL_NME", ''Start spaces and end spaces are not allowed'',''2.47.260'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE "LABEL_NME" LIKE ''% '' OR "LABEL_NME" LIKE '' %'' ';
		 
		 -- --SELECT "ID","NAME",'GA_POI','LABEL_NME',"LABEL_NME", 'Start spaces and end spaces are not allowed','2.47.260' FROM mmi_v180."GA_POI" 
		 -- --WHERE "LABEL_NME" LIKE '% ' OR "LABEL_NME" LIKE ' %'

		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
-- --2.47.279
-- --31 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''LABEL_NME'',"LABEL_NME", ''Special character must not present at start and End of name'',''2.47.279'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 -- WHERE"LABEL_NME" like ''&%'' OR "LABEL_NME" like ''%&'' OR "LABEL_NME" like ''%-'' OR "LABEL_NME" like ''-%'' ';
		 
		 -- --SELECT "ID","NAME",'GA_POI','LABEL_NME',"LABEL_NME", 'Special character must not present at start and End of name','2.47.279' FROM mmi_v180."GA_POI" 
		 -- --WHERE"LABEL_NME" like '&%' OR "LABEL_NME" like '%&' OR "LABEL_NME" like '%-' OR "LABEL_NME" like '-%'

		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
----------------------------------------------------------------------------------------------STT_ID-------------------------------------------------------------------------------------------------------------------------------------------------
--1.9.2
-- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''STT_ID'',"STT_ID"::text, ''STT_ID should not be 0'',''1.9.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE "STT_ID"= 0';
         
		 --SELECT "ID","NAME",'GA_POI','STT_ID',"STT_ID"::text, 'STT_ID should not be 0','1.9.2' FROM mmi_v180."GA_POI" As t 
		 ---WHERE (status NOT IN ('0','5') OR (COALESCE(status,'')='') ) AND "STT_ID"= 0
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'STT_ID should not be 0';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--1.15.10
--47 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT t."ID",t."NAME",'''||tbl_nme||''',''ADDRESS'',t."ADDRESS", ''ADDRESS should not start/end with special character'',''1.15.10'' 
		-- FROM ( SELECT "ID","NAME", substring("ADDRESS", char_length("ADDRESS")-0) enstring,substring("ADDRESS", 1,1) ststring,"ADDRESS" 
		 -- FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'") As t 
		 -- WHERE t.enstring ~''[^A-Za-z0-9]'' OR t.ststring ~''[^A-Za-z0-9]'' ';
         
		 -- ---SELECT t."ID",t."NAME",'GA_POI','ADDRESS',t."ADDRESS", 'ADDRESS should not start/end with special character','1.15.10' 
		 -- --FROM ( SELECT status,"ID","NAME", substring("ADDRESS", char_length("ADDRESS")-0) enstring,substring("ADDRESS", 1,1) ststring,"ADDRESS" 
		 -- --FROM mmi_v180."GA_POI") As t 
		 -- --WHERE (t.status NOT IN ('0','5') OR (COALESCE(t.status,'')='') ) AND t.enstring ~'[^A-Za-z0-9]' OR t.ststring ~'[^A-Za-z0-9]';
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'ADDRESS should not start/end with special character';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.15.2
--16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS", ''ADDRESS must not have special character except / - , and ’&’'',''1.15.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."ADDRESS" IS NOT NULL AND t."ADDRESS"~''[^-0-9A-Za-z/ ,&\(\) +]'' OR t."ADDRESS"~''^.*?\((?!.*\))[^\]]*$''';
		 
		 --SELECT "ID","NAME",'GA_POI','ADDRESS',"ADDRESS", 'ADDRESS must not have special character except / - , and ’&’','1.15.2' FROM mmi_v180."GA_POI" As t 
		 --WHERE t."ADDRESS" IS NOT NULL AND t."ADDRESS"~'[^-0-9A-Za-z/ ,&\(\) +]' OR t."ADDRESS"~'^.*?\((?!.*\))[^\]]*$'

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ADDRESS must not have special character except / - , and ’&’';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.15.2.1
--16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS", ''ADDRESS must not have special character except / - , and ’&’'',''1.15.2.1'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE COALESCE("ADDRESS",'''')<> '''' AND ("ADDRESS" LIKE ''%(%'' OR  "ADDRESS" LIKE ''%)%'') AND  "ADDRESS"~''^[\((?:[^)(?R)?)*+\)]'' ';
		 
		 --SELECT "ID","ADDRESS" FROM mmi_master."DL_POI" 
		 --WHERE ("ADDRESS" LIKE '%(%' OR  "ADDRESS" LIKE '%)%') AND  "ADDRESS"~'^[\((?:[^)(?R)?)*+\)]'

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ADDRESS must not have special character except / - , and ’&’';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.15.8
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS", ''ADDRESS must not have start and end space'',''1.15.8'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."ADDRESS" IS NOT NULL AND t."ADDRESS" LIKE '' %'' OR t."ADDRESS" like ''% '' ';
		 
		 --SELECT "ID","NAME",'GA_POI','ADDRESS',"ADDRESS", 'ADDRESS must not have start and end space','1.15.8' FROM mmi_v180."GA_POI" As t 
		 --WHERE t."ADDRESS" IS NOT NULL AND t."ADDRESS" LIKE ' %' OR t."ADDRESS" like '% '

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ADDRESS must not have start and end space';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.11.3.1
-- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1", ''ALIAS_1 must not have special character except ’&’ and single quotes'',''1.11.3.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE (t."ALIAS_1"~''[^A-Za-z0-9\s&]'' AND (COALESCE("ALIAS_1",'''')<>'''')  AND  "BRAND_NME" IS NULL) ';
		  
		 /*
		 SELECT "ID","NAME",'GA_POI','ALIAS_1',"ALIAS_1",
		'Must not have special character except ’&’ and single quotes','1.11.3' FROM mmi_master."GA_POI" As t 
		 WHERE (t."ALIAS_1"~'[^A-Za-z0-9\s&'']' AND (COALESCE("ALIAS_1",'')<>'') AND  "BRAND_NME" IS NULL)
		 */

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ALIAS_1 must not have special character except ’&’ and single quotes';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.12.3
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2", ''ALIAS_2 must not have special character except ’&’ and single quotes'',''1.12.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."ALIAS_2" IS NOT NULL AND (t."ALIAS_2"~''[^0-9A-Za-z&\s'''']'') ';
		
		--SELECT "ID","NAME",'GA_POI','ALIAS_2',"ALIAS_2", 'ALIAS_2 must not have special character except ’&’ and single quotes','1.12.3' FROM mmi_v180."GA_POI" As t 
		--WHERE t."ALIAS_2" IS NOT NULL AND (t."ALIAS_2"~'[^0-9A-Za-z&\s'']')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ALIAS_2 must not have special character except ’&’ and single quotes';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.13.3
--32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3", ''ALIAS_3 must not have special character except ’&’ and single quotes'',''1.13.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE t."ALIAS_3" IS NOT NULL AND (t."ALIAS_3"~''[^0-9A-Za-z&\s'''']'') ';
		 
		 --SELECT "ID","NAME",'GA_POI','ALIAS_3',"ALIAS_3", 'ALIAS_3 must not have special character except ’&’ and single quotes','1.13.3' FROM mmi_v180."GA_POI" As t 
		 --WHERE t."ALIAS_3" IS NOT NULL AND (t."ALIAS_3"~'[^0-9A-Za-z&\s'']')

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ALIAS_3 must not have special character except ’&’ and single quotes';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.32
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", ''Start spaces and end spaces are not allowed'',''1.2.32'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE "NAME" LIKE ''% '' OR "NAME" LIKE '' %'' ';
		
		--SELECT "ID","NAME",'GA_POI','NAME',"NAME", 'Start spaces and end spaces are not allowed','1.2.32' FROM mmi_v180."GA_POI" 
		--WHERE "NAME" LIKE '% ' OR "NAME" LIKE ' %'
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Start spaces and end spaces are not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.10.4
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME", ''Must not have special character except ’&’ and single quotes'',''1.10.4'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE "POPLR_NME" IS NOT NULL AND ("POPLR_NME"~''[^0-9A-Za-z&\s'''']'') ';
		
		--SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME", 'Must not have special character except ’&’ and single quotes','1.10.4' FROM mmi_v180."GA_POI" 
		--WHERE "POPLR_NME" IS NOT NULL AND ("POPLR_NME"~'[^0-9A-Za-z&\s'']');
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Must not have special character except ’&’ and single quotes';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
/*
-------------------------------------------------------------------------------------------status-------------------------------------------------------------------------------------------------------------------------------------------------	
--1.61.1
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''status'',status, ''status must be a digit between 0 to 6 only'',''1.61.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND status IS NOT NULL AND (status~''[^0-6]{1}'') ';

		--SELECT "ID","NAME",'tbl_nme','status',status, 'status must be a digit between 0 to 6 only','1.61.1' FROM mmi_v161."DL_POI" 
		--WHERE (status NOT IN ('0','5') OR (COALESCE(status,'')='') ) AND status IS NOT NULL AND (status~'[^0-6]{1}')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	*/
------------------------------------------------------------------------------------------username-------------------------------------------------------------------------------------------------------------------------------------------------
--1.62.1
--31 msec
if(user_type <> 'DE' ) then 
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''user_name'',user_name, ''username must be in proper form : starting with CE or CN followed by numbers with no special characters'',''1.62.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE user_name IS NOT NULL AND (user_name!~''^(CE|CN){1}[0-9]+$'') ';

-- 		SELECT "ID","NAME",'tbl_nme','user_name',user_name, 'username must be in proper form : starting with CE or CN followed by numbers with no special characters','1.62.1' FROM mmi."DL_POI" 
-- 		WHERE user_name IS NOT NULL AND (user_name!~'^(CE|CN){1}[0-9]+$')
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'username must be in proper form : starting with CE or CN followed by numbers with no special characters';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	end if;
-----------------------------------------------------------------------------------------DE_IMGPATH-------------------------------------------------------------------------------------------------------------------------------------------------
--1.64.1
--203 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''DE_IMGPATH'',"DE_IMGPATH", ''DE_IMGPATH must start with either \\10.1.1.38 OR \\10.1.1.31 OR \\10.1.1.35 and end with jpeg or jpg'',''1.64.1'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE "DE_IMGPATH" IS NOT NULL AND (("DE_IMGPATH"!~''^(\\\\10.1.1.38){1}'' AND "DE_IMGPATH"!~''^(\\\\10.1.1.31){1}'' AND "DE_IMGPATH"!~''^(\\\\10.1.1.35){1}'') OR LOWER("DE_IMGPATH")!~''(jpg|jpeg)$'' ) ';

		--SELECT "ID","NAME",'tbl_nme','DE_IMGPATH',"DE_IMGPATH", 'DE_IMGPATH must start with either \\10.1.1.38 OR \\10.1.1.31 OR \\10.1.1.35 and end with jpeg or jpg','1.64.1' FROM mmi_v180."GA_POI" 
		--WHERE "DE_IMGPATH" IS NOT NULL AND (("DE_IMGPATH"!~'^(\\\\10.1.1.38){1}' AND "DE_IMGPATH"!~'^(\\\\10.1.1.31){1}' AND "DE_IMGPATH"!~'^(\\\\10.1.1.35){1}') OR LOWER("DE_IMGPATH")!~'(jpg|jpeg)$') 
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'DE_IMGPATH must start with either \\10.1.1.38 OR \\10.1.1.31 OR \\10.1.1.35 and end with jpeg or jpg';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--------------------------------------------------------------------------------------------EXCP-----------------------------------------------------------------------------------------------------------------------------------------------
--1.61.1 --ADDED BY ABHI
--updated by goldy 13/06/2019
-- 15 msec
	BEGIN
		EXECUTE 'With sel1 as (select "ID","NAME", unnest(string_to_array("EXCP",'','')) as excp from '||sch_name||'."'|| UPPER(tbl_nme) ||'" )
		INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''EXCP'',excp, ''Value must be from excp_list'',''1.61.1''
		FROM sel1
		where Trim(excp) not in (select code from spatial_layer_functions.excp_code ) ';

		--With sel1 as (select "ID","NAME", unnest(string_to_array("EXCP",',')) as excp from mmi_master."DL_POI" )
		-- SELECT "ID","NAME",excp FROM sel1 where Trim(excp) not in (select code from spatial_layer_functions.excp_code )
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'It contains value like  RLY , WAY , MDY , 1KY ';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--PNY
--1.1.1.16
--1.100.1
--47 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''EXCP'',"EXCP"::text, 
		-- ''If any special character exists in POI name then add “PNY” in Exception column'',''NO ERROR CODE'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
		-- WHERE "NAME"~''[^A-Za-z0-9\s]'' AND "EXCP" NOT LIKE ''%PNY%'' AND (status NOT IN (''0'',''5'') OR COALESCE(status,'''')='''') ';
		--ADDED BIPIN
		sqlQuery = ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME"::text,''If any special character exists in POI name then add “PNY” in Exception column'',''1.100.1''
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t1,(Select "NAME" As NAME From '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "NAME"~''[^A-Za-z0-9\s&]'' AND "EXCP" NOT LIKE ''%PNY%'' AND COALESCE("NAME",'''')<>''''
		Except Select "BND_NAME" From '||mst_sch||'."BRAND_LIST") As t2 Where t1."NAME"=t2.NAME';
		
		--SELECT "ID","NAME",'GA_POI','NAME',"NAME"::text,'If any special character exists in POI name then add “PNY” in Exception column','1.1.1.16'
		--FROM mmi_v180."GA_POI" As t1,(Select "NAME" As NAME From mmi_v180."GA_POI" WHERE "NAME"~'[^A-Za-z0-9\s&]' AND "EXCP" NOT LIKE '%PNY%' AND COALESCE("NAME",'')<>''
		--Except Select "NAME" From mmi_v180."BRAND_LIST") As t2 Where t1."NAME"=t2.NAME
		--RAISE INFO 'sqlQuery -> %',sqlQuery;	
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If any special character exists in POI name then add “PNY” in Exception column ';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--ALY
--1.1.1.12
--1.100.2
-- 15 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''EXCP'',"EXCP"::text, 
		-- ''If any special character exists in Aliases or Popular name then add “ALY” in Exception column'',''NO ERROR CODE'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
		-- WHERE "POPLR_NME"~''[^A-Za-z0-9\s]'' AND "EXCP" NOT LIKE ''%ALY%'' ';
--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text, ''If any special character exists in Poplr_Nme then add “ALY” in Exception column'',''1.100.2'' 
		From (Select "ID","NAME","POPLR_NME","BRAND_NME" From '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		Where "POPLR_NME"~''[^A-Za-z0-9\s]'' AND "EXCP" NOT LIKE ''%ALY%'' AND COALESCE("POPLR_NME",'''')<>'''') As A 
		Where A."BRAND_NME" Not In (Select "BND_NAME" From '||mst_sch||'."BRAND_LIST") ';
		
		--SELECT "ID","NAME",'GA_POI','POPLR_NME',"POPLR_NME"::text, 'If any special character exists in Poplr_Nme then add “ALY” in Exception column','1.100.2' 
		--From (Select "ID","NAME","POPLR_NME","BRAND_NME" From mmi_v180."GA_POI" 
		--Where "POPLR_NME"~'[^A-Za-z0-9\s]' AND "EXCP" NOT LIKE '%ALY%' AND COALESCE("POPLR_NME",'')<>'') As A 
		--Where A."BRAND_NME" Not In (Select "BND_NAME" From mmi_v180."BRAND_LIST")
	
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If any special character exists in Poplr_Nme then add “ALY” in Exception column';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--ALY
--1.1.1.13
--1.100.2
-- 31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''EXCP'',"EXCP"::text, 
		-- ''If any special character exists in Aliases or Popular name then add “ALY” in Exception column'',''NO ERROR CODE'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
		-- WHERE "ALIAS_1"~''[^A-Za-z0-9\s]'' AND "EXCP" NOT LIKE ''%ALY%'' ';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1"::text, ''If any special character exists in Alias_1 then add “ALY” in Exception column'',''1.100.2'' 
		From (Select "ID","NAME","ALIAS_1","BRAND_NME" From '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		Where "ALIAS_1"~''[^A-Za-z0-9\s]'' AND "EXCP" NOT LIKE ''%ALY%'' AND COALESCE("ALIAS_1",'''')<>'''') As A 
		Where A."BRAND_NME" Not In (Select "BND_NAME" From '||mst_sch||'."BRAND_LIST") ';
		
		--SELECT "ID","NAME",'GA_POI','ALIAS_1',"ALIAS_1"::text, 'If any special character exists in Alias_1 then add “ALY” in Exception column','1.100.2' 
		--From (Select "ID","NAME","ALIAS_1","BRAND_NME" From mmi_v180."GA_POI" 
		--Where "ALIAS_1"~'[^A-Za-z0-9\s]' AND "EXCP" NOT LIKE '%ALY%' AND COALESCE("ALIAS_1",'')<>'') As A 
		--Where A."BRAND_NME" Not In (Select "BND_NAME" From mmi_v180."BRAND_LIST")
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If any special character exists in Alias_1 then add “ALY” in Exception column';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--ALY
--1.1.1.14
--1.100.2
-- 32 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''EXCP'',"EXCP"::text, 
		-- ''If any special character exists in Aliases or Popular name then add “ALY” in Exception column'',''NO ERROR CODE'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
		-- WHERE "ALIAS_2"~''[^A-Za-z0-9\s]'' AND "EXCP" NOT LIKE ''%ALY%'' AND (status NOT IN (''0'',''5'') OR COALESCE(status,'''')='''') ';
		-- ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2"::text, ''If any special character exists in Alias_2 then add “ALY” in Exception column'',''1.100.2'' 
		From (Select "ID","NAME","ALIAS_2","BRAND_NME" From '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		Where "ALIAS_2"~''[^A-Za-z0-9\s]'' AND "EXCP" NOT LIKE ''%ALY%'' AND COALESCE("ALIAS_2",'''')<>'''') As A 
		Where A."BRAND_NME" Not In (Select "BND_NAME" From '||mst_sch||'."BRAND_LIST") ';
		
		--SELECT "ID","NAME",'GA_POI','ALIAS_2',"ALIAS_2"::text, 'If any special character exists in Alias_2 then add “ALY” in Exception column','1.100.2' 
		--From (Select "ID","NAME","ALIAS_2","BRAND_NME" From mmi_v180."GA_POI" 
		--Where "ALIAS_2"~'[^A-Za-z0-9\s]' AND "EXCP" NOT LIKE '%ALY%' AND COALESCE("ALIAS_2",'')<>'') As A 
		--Where A."BRAND_NME" Not In (Select "BND_NAME" From mmi_v180."BRAND_LIST")
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If any special character exists in Alias_2 then add “ALY” in Exception column';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--ALY
--1.100.2
--31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) SELECT "ID","NAME",'''||tbl_nme||''',''EXCP'',"EXCP"::text, 
		-- ''If any special character exists in Aliases or Popular name then add “ALY” in Exception column'',''NO ERROR CODE'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
		-- WHERE "ALIAS_3"~''[^A-Za-z0-9\s]'' AND "EXCP" NOT LIKE ''%ALY%'' ';
		-- ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text, ''If any special character exists in Alias_3 then add “ALY” in Exception column'',''1.100.2'' 
		From (Select "ID","NAME","ALIAS_3","BRAND_NME" From '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		Where "ALIAS_3"~''[^A-Za-z0-9\s]'' AND "EXCP" NOT LIKE ''%ALY%'' AND COALESCE("ALIAS_3",'''')<>'''') As A 
		Where A."BRAND_NME" Not In (Select "BND_NAME" From '||mst_sch||'."BRAND_LIST") ';
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If any special character exists in Alias_3 then add “ALY” in Exception column';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--ADY
--1.1.1.17
--1.100.3
-- 46 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''EXCP'',"EXCP"::text, 
		''If any special character exists in Address like (‘’, @, (), #, \ ) then, add “ADY” in Exception column'',''1.100.3'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
		WHERE "ADDRESS" LIKE ''%@%'' OR "ADDRESS" LIKE ''%#%'' OR "ADDRESS" LIKE ''%\%'' OR "ADDRESS"~''["]'' AND "EXCP" NOT LIKE ''%ADY%'' ';
		
        --SELECT "ID","NAME",'GA_POI','EXCP',"EXCP"::text, 
		--'If any special character exists in Address like (‘’, @, (), #, \ ) then, add “ADY” in Exception column','1.100.3'' FROM  mmi_v180."GA_POI"
		--WHERE "ADDRESS" LIKE '%@%' OR "ADDRESS" LIKE '%#%' OR "ADDRESS" LIKE '%(%' OR "ADDRESS" LIKE '%)%' OR "ADDRESS" LIKE '%\%' OR "ADDRESS"~'["]' AND "EXCP" NOT LIKE '%ADY%';

		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If any special character exists in Address like (‘’, @, (), #, \ ) then, add “ADY” in Exception column';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--EMY
--1.1.1.11
--1.100.4
-- 31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- ( SELECT t7."ID",t7."NAME",'''||tbl_nme||''',''EXCP'',t7."EXCP"::text,''If any email does not comes with (“.com”, “.co. in”, “.in”) but exists on authentic websites then adds “EMY” in Exception column'',''NO ERROR CODE''
		-- FROM (Select t."ID",t."NAME",t."EMAIL",t."EXCP",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		-- FROM (SELECT "ID","NAME","EXCP","EMAIL",unnest(String_To_Array(replace("EMAIL",'','',''''), '' '')) as EMAIL, CONCAT("ID",'' '',unnest(String_To_Array(replace("EMAIL",'','',''''), '' ''))) 
		-- FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE  (trim("EMAIL") ~ ''[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$'' 
		-- OR trim("EMAIL") ~ ''[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$'' OR 
		-- trim("EMAIL") ~ ''[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$'')) AS t WHERE 
		-- LOWER(t.CONCAT) NOT LIKE ''%.com'' AND LOWER(t.CONCAT) NOT LIKE ''%.co'' AND LOWER(t.CONCAT) NOT LIKE ''%.in''  AND COALESCE(LOWER(t.concat),'''') <>'''')  AS t7 
		-- WHERE (COALESCE(t7.concat,'''')<>'''') AND "EXCP" NOT LIKE ''%EMY%'' GROUP BY  t7."ID",t7."NAME",t7."EMAIL",t7.concat,t7."EXCP") ';
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		( SELECT t7."ID",t7."NAME",'''||tbl_nme||''',''EXCP'',t7."EXCP"::text,''If any email does not comes with (“.com”, “.co. in”, “.in”, “.org”, “.gov”, “.aero”, “.net”, “.biz”) but exists on authentic websites then add “EMY” in Exception column'',''1.100.4''
		FROM (Select t."ID",t."NAME",t."EMAIL",t."EXCP",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		FROM (SELECT "ID","NAME","EXCP","EMAIL",unnest(String_To_Array(replace("EMAIL",'','',''''), '' '')) as EMAIL, CONCAT("ID",'' '',unnest(String_To_Array(replace("EMAIL",'','',''''), '' ''))) 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (trim("EMAIL") ~ ''[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$'' OR 
		trim("EMAIL") ~ ''[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$'' OR 
		trim("EMAIL") ~ ''[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$'' OR 
		trim("EMAIL") ~ ''[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$'')) AS t WHERE 
		LOWER(t.CONCAT) NOT LIKE ''%.com'' AND LOWER(t.CONCAT) NOT LIKE ''%.co'' AND LOWER(t.CONCAT) NOT LIKE ''%.in'' AND LOWER(t.CONCAT) NOT LIKE ''%.org'' AND LOWER(t.CONCAT) NOT LIKE ''%.gov'' AND 
		LOWER(t.CONCAT) NOT LIKE ''%.aero'' AND LOWER(t.CONCAT) NOT LIKE ''%.net'' AND LOWER(t.CONCAT) NOT LIKE ''%.biz'' AND COALESCE(LOWER(t.concat),'''') <>'''')  AS t7 
		WHERE (COALESCE(t7.concat,'''')<>'''') AND "EXCP" NOT LIKE ''%EMY%'' GROUP BY  t7."ID",t7."NAME",t7."EMAIL",t7.concat,t7."EXCP") ';
		
		/*
		SELECT t7."ID",t7."NAME",'GA_POI','EXCP',t7."EXCP"::text,'If any email does not comes with (“.com”, “.co. in”, “.in”, “.org”, “.gov”, “.aero”, “.net”, “.biz”) but exists on authentic websites then add “EMY” in Exception column','1.100.4'
		FROM (Select t."ID",t."NAME",t."EMAIL",t."EXCP",t.CONCAT, COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		FROM (SELECT "ID","NAME","EXCP","EMAIL",unnest(String_To_Array(replace("EMAIL",',',''), ' ')) as EMAIL, CONCAT("ID",' ',unnest(String_To_Array(replace("EMAIL",',',''), ' '))) 
		FROM mmi_v180."GA_POI" WHERE (trim("EMAIL") ~ '[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$' OR 
		trim("EMAIL") ~ '[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$' OR 
		trim("EMAIL") ~ '[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$' OR 
		trim("EMAIL") ~ '[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+[,][\s]+[A-Za-z0-9.,_%-]+@[A-Za-z0-9,._%-]+[.][A-Za-z]+$')) AS t WHERE 
		LOWER(t.CONCAT) NOT LIKE '%.com' AND LOWER(t.CONCAT) NOT LIKE '%.co' AND LOWER(t.CONCAT) NOT LIKE '%.in' AND LOWER(t.CONCAT) NOT LIKE '%.org' AND LOWER(t.CONCAT) NOT LIKE '%.gov' AND 
		LOWER(t.CONCAT) NOT LIKE '%.aero' AND LOWER(t.CONCAT) NOT LIKE '%.net' AND LOWER(t.CONCAT) NOT LIKE '%.biz' AND COALESCE(LOWER(t.concat),'') <>'')  AS t7 
		WHERE (COALESCE(t7.concat,'')<>'') AND "EXCP" NOT LIKE '%EMY%' GROUP BY  t7."ID",t7."NAME",t7."EMAIL",t7.concat,t7."EXCP"
		*/
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If any email does not comes with (“.com”, “.co. in”, “.in”, “.org”, “.gov”, “.aero”, “.net”, “.biz”) but exists on authentic websites then add “EMY” in Exception column';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--WBY
-- No error code
--1.100.5
--47 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		( SELECT t7."ID",t7."NAME",'''||tbl_nme||''',''EXCP'',t7."EXCP"::text,''If any special character exists in website like (“www.thetrendydiva.biz”, “www.aai.aero”) then add “WBY” in Exception column'',''1.100.5''
		FROM (Select t."ID",t."NAME",t."WEB",t."EXCP",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		FROM (SELECT "ID","NAME","WEB","EXCP",unnest(String_To_Array(replace("WEB",'','',''''), '' '')) as WEB, CONCAT("ID",'' '',unnest(String_To_Array(replace("WEB",'','',''''), '' ''))) 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (lower(trim("WEB")) ~ ''(w{3})[.]+[a-z0-9]+[.][a-z.]+$'' OR lower(trim("WEB"))~''(w{3})[.]+[a-z0-9]+[.][a-z.]+[,][\s](w{3})[.]+[a-z0-9]+[.][a-z.]+$'' 
		OR lower(trim("WEB"))~''(w{3})[.]+[a-z0-9]+[.][a-z.]+[,][\s](w{3})[.]+[a-z0-9]+[.][a-z.]+[,][\s](w{3})[.]+[a-z0-9]+[.][a-z.]+$'')) AS t 
		WHERE LOWER(t.CONCAT) NOT LIKE ''%.com'' AND LOWER(t.CONCAT) NOT LIKE ''%.in'' AND LOWER(t.CONCAT) NOT LIKE ''%.info'' AND LOWER(t.CONCAT) NOT LIKE ''%.gov'' AND LOWER(t.CONCAT) NOT LIKE ''%.net'' AND 
		LOWER(t.CONCAT) NOT LIKE ''%.org'' AND LOWER(t.CONCAT) NOT LIKE ''%.edu'' AND LOWER(t.CONCAT) NOT LIKE ''%.nic'' AND COALESCE(LOWER(t.concat),'''') <>'''' ) AS t7 
		WHERE (COALESCE(t7.CONCAT,'''')<>'''') AND t7.CONCAT~''[^A-Za-z0-9\s]'' AND t7."EXCP" NOT LIKE ''%WBY%'' GROUP BY t7."ID",t7."NAME",t7."WEB",t7."EXCP",t7.CONCAT) ';
        
		/*SELECT t7."ID",t7."NAME",'GA_POI','EXCP',t7."EXCP"::text,'If any special character exists in website like (“www.thetrendydiva.biz”, “www.aai.aero”) then add “WBY” in Exception column','1.100.5'
		FROM (Select t."ID",t."NAME",t."WEB",t."EXCP",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		FROM (SELECT "ID","NAME","WEB","EXCP",unnest(String_To_Array(replace("WEB",',',''), ' ')) as WEB, CONCAT("ID",' ',unnest(String_To_Array(replace("WEB",',',''), ' '))) 
		FROM mmi_v180."GA_POI" WHERE (lower(trim("WEB")) ~ '(w{3})[.]+[a-z0-9]+[.][a-z.]+$' OR lower(trim("WEB"))~'(w{3})[.]+[a-z0-9]+[.][a-z.]+[,][\s](w{3})[.]+[a-z0-9]+[.][a-z.]+$' 
		OR lower(trim("WEB"))~'(w{3})[.]+[a-z0-9]+[.][a-z.]+[,][\s](w{3})[.]+[a-z0-9]+[.][a-z.]+[,][\s](w{3})[.]+[a-z0-9]+[.][a-z.]+$')) AS t 
		WHERE LOWER(t.CONCAT) NOT LIKE '%.com' AND LOWER(t.CONCAT) NOT LIKE '%.in' AND LOWER(t.CONCAT) NOT LIKE '%.info' AND LOWER(t.CONCAT) NOT LIKE '%.gov' AND LOWER(t.CONCAT) NOT LIKE '%.net' AND 
		LOWER(t.CONCAT) NOT LIKE '%.org' AND LOWER(t.CONCAT) NOT LIKE '%.edu' AND LOWER(t.CONCAT) NOT LIKE '%.nic' AND COALESCE(LOWER(t.concat),'') <>'' ) AS t7 
		WHERE (COALESCE(t7.CONCAT,'')<>'') AND t7.CONCAT~'[^A-Za-z0-9\s]' AND t7."EXCP" NOT LIKE '%WBY%' GROUP BY t7."ID",t7."NAME",t7."WEB",t7."EXCP",t7.CONCAT
	     */
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If any special character exists in website like (“www.thetrendydiva.biz”, “www.aai.aero”) then add “WBY” in Exception column';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-- --SCY
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''EXCP'',"EXCP"::text,''Maintain the exception only for the non premium heritage hotels where Ftr_cry <> ”HOTPRE” but Sub_Cry=”PREHRG”'',''NO ERROR CODE''
		-- FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "FTR_CRY"<>''HOTPRE'' AND "SUB_CRY"=''PREHRG'' AND "EXCP" NOT LIKE ''%SCY%'' ';
	
	-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'Maintain the exception only for the non premium heritage hotels where Ftr_cry <> ”HOTPRE” but Sub_Cry=”PREHRG”';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
-- --ADMIN_ID
-- --7.6 sec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code)	
		-- SELECT  "ID","NAME",'''||tbl_nme||''',''EXCP'',"EXCP"::text,''If Parent and child poi’s have different Admin Id, then maintain ”PCY” in EXCP'',''NO ERROR CODE'' 
		-- FROM (SELECT "ID","PIP_ID","ADMIN_ID","NAME","EXCP" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "PIP_ID"<>0 AND "ADMIN_ID"<>0 AND COALESCE("EXCP",'''') NOT LIKE ''%PCA%''
		 -- GROUP BY "PIP_ID","ADMIN_ID","ID","NAME","EXCP") As a 
		-- WHERE a."PIP_ID" IN (SELECT "ID" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As b WHERE a."ADMIN_ID"<>b."ADMIN_ID" AND b."ADMIN_ID"<>0 AND COALESCE(b."EXCP",'''') NOT LIKE ''%PCA%'' ) ';
        
        -- --SELECT  "ID","NAME",'GA_POI','EXCP',"EXCP"::text,'If Parent and child poi’s have different Admin Id, then maintain ”PCY” in EXCP','NO ERROR CODE' 
		-- --FROM (SELECT "ID","PIP_ID","ADMIN_ID","NAME","EXCP" FROM mmi_v180."GA_POI" WHERE "PIP_ID"<>0 AND "ADMIN_ID"<>0 AND COALESCE("EXCP",'') NOT LIKE '%PCA%'
		-- -- GROUP BY "PIP_ID","ADMIN_ID","ID","NAME","EXCP") As a 
		-- --WHERE a."PIP_ID" IN (SELECT "ID" FROM mmi_v180."GA_POI" As b WHERE a."ADMIN_ID"<>b."ADMIN_ID" AND b."ADMIN_ID"<>0 AND COALESCE(b."EXCP",'') NOT LIKE '%PCA%' ) 		
		
		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'If Parent and child poi’s have different Admin Id, then maintain ”PCY” in EXCP';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--GTY
--1.100.60
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''EXCP'',"EXCP"::text,''Gate must have PIP_ID, if not then maintain exception ”GTY”'',''1.100.60''
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "FTR_CRY"=''COMGAT'' AND ("PIP_ID"=0) AND "EXCP" NOT LIKE ''%GTY%'' ';
		
		--SELECT "ID","NAME",'GA_POI','EXCP',"EXCP"::text,'Gate must have PIP_ID, if not then maintain exception ”GTY”','1.100.60'
		--FROM mmi_v180."GA_POI" WHERE "FTR_CRY"='COMGAT' AND "EXCP" NOT LIKE '%GTY%'
	
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Gate must have PIP_ID, if not then maintain exception ”GTY”';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
------------------------------------------------------------------------Address---------------------------------------------------------------------------------------------------------------------------------------
--1.15.13 --ADDED BY ABHI
--63 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS", ''ADDRESS should not be one word, check addresses having length less than or equal to 5 and correct irrelevent words from address'',''1.15.13'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE TRIM("ADDRESS") NOT LIKE ''% %'' AND LENGTH("ADDRESS") <= 5 ';

		--SELECT "ID","NAME",'tbl_nme','ADDRESS',"ADDRESS", 'ADDRESS should not be one word, check addresses having length less than or equal to 5 and correct irrelevent words from address','1.15.13' FROM mmi_v180."GA_POI" 
		--WHERE TRIM("ADDRESS") NOT LIKE '% %' AND LENGTH("ADDRESS") <= 5
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ADDRESS should not be one word, check addresses having length less than or equal to 5 and correct irrelevent words from address”';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.15.15 --ADDED BY ABHI
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS", ''Address must not contain Pincode'',''1.15.15'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE "ADDRESS"~''[\d]{6}'' ';

		--SELECT "ID","NAME",'tbl_nme','ADDRESS',"ADDRESS", 'Address must not contain Pincode','1.15.15' FROM mmi_v180."GA_POI" 
		--WHERE "ADDRESS"~'[\d]{6}'
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Address must not contain Pincode';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
--2.47.67
-- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS",''Must not have Roman Numbers'',''2.47.67'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		WHERE "ADDRESS"~''^(?:IX|IV|V|V?I{1,3}|X|XI{1,3})[\s].+$'' OR "ADDRESS" ~ ''^.+[\s](?:IX|IV|V|V?I{1,3}|X|XI{1,3})[\s].+$'' OR "ADDRESS" ~ ''^.+[\s](?:IX|IV|V|V?I{1,3}|X|XI{1,3})$'' OR "ADDRESS" ~ ''^[\!\&\*\-\_\(\)\\](?:IX|IV|V|V?I{1,3}|X|XI{1,3})[\s]$'' OR "ADDRESS" ~ ''^.+[\!\&\*\-\_\(\)\\](?:IX|IV|V|V?I{1,3}|X|XI{1,3})[\s].+$'' OR "ADDRESS" ~ ''^.+[\s](?:IX|IV|V|V?I{1,3}|X|XI{1,3})[\!\&\*\-\_\(\)\\].+$''OR "ADDRESS" ~ ''^.+[\!\&\*\-\_\(\)\\](?:IX|IV|V|V?I{1,3}|X|XI{1,3})$'' AND COALESCE("ADDRESS",'''')<>'''' ';

-- 		SELECT "ID","NAME",'tbl_nme','','ADDRESS',"ADDRESS",'Must not have Roman Numbers','2.47.67' FROM mmi180."GA_POI" As t 
-- 		WHERE "ADDRESS"~''^(?:IX|IV|V|V?I{1,3}|X|XI{1,3})[\s].+$'' OR "NAME" ~ ''^.+[\s](?:IX|IV|V|V?I{1,3}|X|XI{1,3})[\s].+$''OR "NAME" ~ ''^.+[\s](?:IX|IV|V|V?I{1,3}|X|XI{1,3})$'' OR "NAME" ~ ''^[\!\&\*\-\_\(\)\\](?:IX|IV|V|V?I{1,3}|X|XI{1,3})[\s]$'' OR "NAME" ~ ''^.+[\!\&\*\-\_\(\)\\](?:IX|IV|V|V?I{1,3}|X|XI{1,3})[\s].+$'' OR "POI_NME" ~ ''^.+[\s](?:IX|IV|V|V?I{1,3}|X|XI{1,3})[\!\&\*\-\_\(\)\\].+$''OR "NAME" ~ ''^.+[\!\&\*\-\_\(\)\\](?:IX|IV|V|V?I{1,3}|X|XI{1,3})$'' AND COALESCE("ADDRESS",'')<>''

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Must not have Roman Numbers';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-- --2.47.178
-- --16 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS",''Addresss and Phone number should not be blank in Airport Data'',''2.47.178'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE "SUB_CRY" = ''TRNARC'' AND ( COALESCE("ADDRESS",'''') = '''' OR COALESCE("TEL",'''')  '''' ) ';

-- -- 		SELECT "ID","NAME",'tbl_nme','','ADDRESS',"ADDRESS",'Addresss and Phone number should not be blank in Airport Data','2.47.178' FROM mmi180."GA_POI" As t 
-- -- 		WHERE "SUB_CRY" = 'TRNARC' AND ( COALESCE("ADDRESS",'') = '' OR COALESCE("TEL",'') = '' )

		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'Addresss and Phone number should not be blank in Airport Data';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.295
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''REFLR_ID'',"REFLR_ID"::text,''If REFLR_TYP available then REFLR_ID must be present'',''2.47.295'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE ( COALESCE("REFLR_TYP",'''') <> '''' AND "REFLR_ID"=0 ) ';

-- 		SELECT "ID","NAME",'tbl_nme','REFLR_ID',"REFLR_ID",'If REFLR_TYP available then REFLR_ID must be present','2.47.295' FROM mmi180."GA_POI" As t 
-- 		WHERE ( COALESCE("REFLR_TYP",'') <> '' AND "REFLR_ID"=0 )

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If REFLR_TYP available then REFLR_ID must be present';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.294
--32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''REFLR_TYP'',"REFLR_TYP"::text,''If available then must be G or W or O or J'',''2.47.294'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE "REFLR_TYP" Not In (''G'',''W'',''O'',''J'') AND COALESCE("REFLR_TYP",'''') <> '''' ';

-- 		SELECT "ID","NAME",'tbl_nme','REFLR_TYP',"REFLR_TYP",'If available then must be G or W or O or J','2.47.294' FROM mmi180."GA_POI" As t 
-- 		WHERE "REFLR_TYP" Not In ('G','W','O','J') AND COALESCE("REFLR_TYP",'''') <> ''''

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If available then must be G or W or O or J';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.282
--172 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''RVW_VER'',"RVW_VER"::text,''Records having values must start with Y or N'',''2.47.282'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE SUBSTRING("RVW_VER" from 1 For 1) Not In (''Y'',''N'') ';

-- 		SELECT "ID","NAME",'tbl_nme','RVW_VER',"RVW_VER",'Records having values must start with Y or N','2.47.282' FROM mmi180."GA_POI" As t 
-- 		WHERE SUBSTRING("RVW_VER" from 1 For 1) Not In ('Y','N')

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Records having values must start with Y or N';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.47  
--2.47.239
--31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME"::text,''Charecter length is greater then 95. Reveiw these records'',''1.2.47'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE LENGTH("NAME")>95 ';

-- 		SELECT "ID","NAME",'tbl_nme','NAME',"NAME",'Charecter length is greater then 95. Reveiw these records','2.47.239' FROM mmi180."GA_POI" As t 
-- 		WHERE LENGTH("NAME")>95

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Charecter length is greater then 95. Reveiw these records';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.48
--2.47.193
--31 msec
--ADDED BY ABHI
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", ''Check NAME not having Spaces and their length is more than 25 characters'',''1.2.48'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE "NAME" NOT LIKE ''% %'' AND LENGTH("NAME") > 25 ';

		--SELECT "ID","NAME",'tbl_nme','NAME',"NAME", 'Check NAME not having Spaces and their length is more than 25 characters','1.2.48' FROM mmi_v180."GA_POI" 
		--WHERE "NAME" NOT LIKE '% %' AND LENGTH("NAME") > 25
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	RAISE INFO 'Check NAME not having Spaces and their length is more than 25 characters';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.48
--1.2.49
-- 78 msec 
--ADDED BY ABHI
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", ''Any word in poi name should not exceed more than 15 character in continuity'',''1.2.49'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE "NAME"~''[^ ]{16,}'' ';

		--SELECT "ID","NAME",'tbl_nme','NAME',"NAME", 'Any word in poi name should not exceed more than 15 character in continuity','1.2.49' FROM mmi_v180."GA_POI" 
		--WHERE "NAME"~'[^ ]{16,}'
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Any word in poi name should not exceed more than 15 character in continuity';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-- --2.47.245
-- --47 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''ADDRESS'',"ADDRESS"::text,''Character length is greater then 95. Reveiw these records'',''2.47.245'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE LENGTH("ADDRESS")>95 ';

-- -- 		SELECT "ID","NAME",'tbl_nme','ADDRESS',"ADDRESS",'Character length is greater then 95. Reveiw these records','2.47.245' FROM mmi_v180."GA_POI" As t 
-- -- 		WHERE LENGTH("ADDRESS")>95

		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'Charecter length is greater then 95. Reveiw these records';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.240 ----1.10.10
--32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''Charecter length is greater then 95. Reveiw these records'',''1.10.10'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE LENGTH("POPLR_NME")>95 ';

-- 		SELECT "ID","NAME",'tbl_nme','POPLR_NME',"POPLR_NME",'Charecter length is greater then 95. Reveiw these records','2.47.240' FROM mmi_v180."GA_POI" As t 
-- 		WHERE LENGTH("POPLR_NME")>95

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Charecter length is greater then 95. Reveiw these records';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.11.8 --2.47.241
--16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1"::text,''Charecter length is greater then 95. Reveiw these records'',''1.11.8'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE LENGTH("ALIAS_1")>95 ';

-- 		SELECT "ID","NAME",'tbl_nme','ALIAS_1',"ALIAS_1",'Charecter length is greater then 95. Reveiw these records','2.47.241' FROM mmi_V180."GA_POI" As t 
-- 		WHERE LENGTH("ALIAS_1")>95

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Charecter length is greater then 95. Reveiw these records';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.12.8 --2.47.242
--- 31 msec	
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2"::text,''Charecter length is greater then 95. Reveiw these records'',''1.12.8'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE LENGTH("ALIAS_2")>95 ';

-- 		SELECT "ID","NAME",'tbl_nme','ALIAS_2',"ALIAS_2",'Charecter length is greater then 95. Reveiw these records','2.47.242' FROM mmi_v180."GA_POI" As t 
-- 		WHERE LENGTH("ALIAS_2")>95

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Charecter length is greater then 95. Reveiw these records';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.13.8 --2.47.243
--- 16 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text,''Charecter length is greater then 95. Reveiw these records'',''1.13.8'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE LENGTH("ALIAS_3")>95 ';

-- 		SELECT "ID","NAME",'tbl_nme','ALIAS_3',"ALIAS_3",'Charecter length is greater then 95. Reveiw these records','2.47.243' FROM mmi_v180."GA_POI" As t 
-- 		WHERE LENGTH("ALIAS_3")>95

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Charecter length is greater then 95. Reveiw these records';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.37 --2.47.314
--31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''BRANCH_NME'',"BRANCH_NME"::text,''BRANCH_NME should not be like (NAME+ALIAS_1)'',''2.47.314'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE "BRANCH_NME" LIKE CONCAT("NAME",'' '',"ALIAS_1") ';
		--ADDED BY ABHI
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''BRANCH_NME'',"BRANCH_NME", ''(NAME " " Alias1)=(Branch_Nme)'',''1.2.37'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE CONCAT("NAME",'' '',"ALIAS_1") = "BRANCH_NME" ';

-- 		SELECT "ID","NAME",'tbl_nme','BRANCH_NME',"BRANCH_NME",'BRANCH_NME should not be like (NAME+ALIAS_1)','2.47.314' FROM mmi_V180."GA_POI" As t 
-- 		WHERE "BRANCH_NME" LIKE CONCAT("NAME",' ',"ALIAS_1")

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO '1.2.37--2.47.314';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.38 --2.47.315
--- 32 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''BRANCH_NME'',"BRANCH_NME"::text,''BRANCH_NME should not be like (NAME+ALIAS_2)'',''2.47.315'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND "BRANCH_NME" LIKE CONCAT("NAME",'' '',"ALIAS_2") ';
		--ADDED BY ABI
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''BRANCH_NME'',"BRANCH_NME", ''(NAME " " Alias2)=(Branch_Nme)'',''1.2.38'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE CONCAT("NAME",'' '',"ALIAS_2") = "BRANCH_NME" ';

-- 		SELECT "ID","NAME",'tbl_nme','BRANCH_NME',"BRANCH_NME",'BRANCH_NME should not be like (NAME+ALIAS_2)','2.47.315' FROM mmi_v180."GA_POI" As t 
-- 		WHERE "BRANCH_NME" LIKE CONCAT("NAME",' ',"ALIAS_2")

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO '1.2.38 --2.47.315';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.2.39 --2.47.316
-- 47 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''BRANCH_NME'',"BRANCH_NME"::text,''BRANCH_NME should not be like (NAME+ALIAS_3)'',''2.47.316'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND "BRANCH_NME" LIKE CONCAT("NAME",'' '',"ALIAS_3") ';
		---ADDED BY ABI
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''BRANCH_NME'',"BRANCH_NME", ''(NAME " " Alias3)=(Branch_Nme)'',''1.2.39'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE CONCAT("NAME",'' '',"ALIAS_3") = "BRANCH_NME" ';

-- 		SELECT "ID","NAME",'tbl_nme','BRANCH_NME',"BRANCH_NME",'BRANCH_NME should not be like (NAME+ALIAS_3)','2.47.316' FROM mmi_v180."GA_POI" As t 
-- 		WHERE "BRANCH_NME" LIKE CONCAT("NAME",' ',"ALIAS_3")

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO '1.2.39 --2.47.316';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.317
-- 32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1"::text,''ALIAS_1 should not be like (NAME+BRANCH_NME)'',''2.47.317'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 WHERE "ALIAS_1" LIKE CONCAT("NAME",'' '',"BRANCH_NME") ';

-- 		SELECT "ID","NAME",'tbl_nme','ALIAS_1',"ALIAS_1",'ALIAS_1 should not be like (NAME+BRANCH_NME)','2.47.317' FROM mmi_v180."GA_POI" As t 
-- 		WHERE "BRANCH_NME" LIKE CONCAT("NAME",' ',"BRANCH_NME")

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'ALIAS_1 should not be like (NAME+BRANCH_NME)';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.51.5 --2.47.318
--- 281 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2"::text,''ALIAS_2 should not be like (NAME+BRANCH_NME)'',''2.47.318'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND "ALIAS_2" LIKE CONCAT("NAME",'' '',"BRANCH_NME") ';
		--ADDED BY ABI
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2", ''If (NAME" "Branch_Nme)=(ALIAS_2)'',''1.51.5'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE CONCAT("NAME",'' '',"BRANCH_NME") = "ALIAS_2" ';

-- 		SELECT "ID","NAME",'tbl_nme','ALIAS_2',"ALIAS_2",'ALIAS_2 should not be like (NAME+BRANCH_NME)','2.47.318' FROM mmi."DL_POI" As t 
-- 		WHERE "ALIAS_2" LIKE CONCAT("NAME",' ',"BRANCH_NME")

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If (NAME" "Branch_Nme)=(ALIAS_2)';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.51.6 --2.47.319
--- 31 msec			
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text,''ALIAS_3 should not be like (NAME+BRANCH_NME)'',''2.47.319'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND "ALIAS_3" LIKE CONCAT("NAME",'' '',"BRANCH_NME") ';

		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3", ''If (NAME" "Branch_Nme)=(ALIAS_3)'',''1.51.6'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE  CONCAT("NAME",'' '',"BRANCH_NME") = "ALIAS_3" ';

-- 		SELECT "ID","NAME",'tbl_nme','ALIAS_3',"ALIAS_3",'ALIAS_3 should not be like (NAME+BRANCH_NME)','2.47.319' FROM mmi_v180."GA_POI" As t 
-- 		WHERE  "ALIAS_3" LIKE CONCAT("NAME",' ',"BRANCH_NME")

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If (NAME" "Branch_Nme)=(ALIAS_3)';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.51.7 --2.47.320
--31 msec
	BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''POPLR_NME should not be like (NAME+BRANCH_NME)'',''2.47.320'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND "POPLR_NME" LIKE CONCAT("NAME",'' '',"BRANCH_NME") ';
		--ADDED BY ABI
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME", ''If (NAME" "Branch_Nme)=(POPLR_NME)'',''1.51.7'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE  CONCAT("NAME",'' '',"BRANCH_NME") = "POPLR_NME" ';

-- 		SELECT "ID","NAME",'tbl_nme','POPLR_NME',"POPLR_NME",'POPLR_NME should not be like (NAME+BRANCH_NME)','2.47.320' FROM mmi_v180."GA_POI" As t 
-- 		WHERE "POPLR_NME" LIKE CONCAT("NAME",' ',"BRANCH_NME")

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If (NAME" "Branch_Nme)=(POPLR_NME)';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-- --2.47.38
-- -- 31 msec
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''Poi which have any special char in main name should be replace with alphabates in Poplr_Nme.For example ’&’ with ’And’, ’@’ with ’At’ '',''2.47.38'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		 -- WHERE "NAME"~''[&@]'' AND "POPLR_NME"~''[&@]'' ';

-- -- 		SELECT "ID","NAME",'tbl_nme','POPLR_NME',"POPLR_NME",'All Poi name which have any special character in main name should be identifed with special character in poplr_nme. For example ’&’ with ’And’, ’@’ with ’At’ ','2.47.38' FROM mmi."DL_POI" As t 
-- -- 		WHERE "NAME"~'[&@]' AND "POPLR_NME"~'[&@]' 

		-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'All Poi name which have any special character in main name should be identifed with special character in poplr_nme. For example ’&’ with ’And’, ’@’ with ’At’';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
-- --2.47.155
-- --47 msec
-- -- ADDED ASHU ORDER BY "_ID"
	-- BEGIN
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''DE_ID'',"DE_ID"::text, ''DE_ID should be integer and unique'',''2.47.155'' FROM 
		-- ( SELECT "ID","NAME","DE_ID", COUNT(*) OVER (PARTITION By "DE_ID") As ct FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "DE_ID"<>0 ORDER BY "DE_ID") sub WHERE ct>1';

-- -- 		SELECT "ID","NAME",'tbl_nme','DE_ID',"DE_ID"::text, 'DE_ID should be integer and unique','2.47.155' FROM 
-- -- 		( SELECT "ID","NAME","DE_ID", COUNT(*) OVER (PARTITION By "DE_ID") As ct FROM mmi_V180."GA_POI" WHERE "DE_ID"<>0) sub WHERE ct>1
		
	-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE INFO 'DE_ID should be integer and unique';
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.1
--32 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''PROJECTION'',sr_id, ''Projection should be Lat/Lon WGS 84'',''2.47.1'' FROM 
		(SELECT "ID","NAME",ST_SRID("SP_GEOMETRY") As sr_id FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" LIMIT 1) As t WHERE sr_id<>4326 ';

-- 		SELECT "ID","NAME",'tbl_nme','PROJECTION',sr_id,'Projection should be Lat/Lon WGS 84','2.47.1' FROM 
-- 		(SELECT "ID","NAME",ST_SRID("SP_GEOMETRY") As sr_id FROM mmi_v180."GA_POI" LIMIT 1) As t WHERE sr_id<>4326
	
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Projection should be Lat/Lon WGS 84';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.179
--- 32 msec
	BEGIN
	--ADDED BY BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''FTR_CRY'',"FTR_CRY",''Wrong naming convention with ftr_cry=“SHPREP”'',''2.47.179'' 
		From(Select * From (Select "ID","NAME","BRAND_NME","FTR_CRY" From '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "FTR_CRY" = ''SHPREP'' AND (LOWER("NAME") NOT LIKE ''% service'' AND LOWER("NAME") NOT LIKE ''% service centre %'' AND  
		LOWER("NAME") NOT LIKE ''% service centre'' AND LOWER("NAME") NOT LIKE ''% workshop'' AND LOWER("NAME") NOT LIKE ''% service station'' AND LOWER("NAME") NOT LIKE ''% spare %'')) As A Where A."NAME" Not In (Select "NAME" From '||mst_sch||'."BRAND_LIST")) As B Where B."BRAND_NME" Not In (Select "BND_NAME" From '||mst_sch||'."BRAND_LIST")';
		/*
		SELECT "ID","NAME",'DL_POI','FTR_CRY',"FTR_CRY",'Wrong naming convention with ftr_cry=“SHPREP”','2.47.179' 
		From(Select * From (Select "ID","NAME","BRAND_NME","FTR_CRY" From mmi_v180."GA_POI" WHERE "FTR_CRY" = 'SHPREP' AND (LOWER("NAME") NOT LIKE '% service' AND LOWER("NAME") NOT LIKE '% service centre %' AND  
		LOWER("NAME") NOT LIKE '% service centre' AND LOWER("NAME") NOT LIKE '% workshop' AND LOWER("NAME") NOT LIKE '% service station' AND LOWER("NAME") NOT LIKE '% spare %')) As A Where A."NAME" Not In (Select "NAME" From mmi_v180."BRAND_LIST")) As B Where B."BRAND_NME" Not In (Select "BND_NAME" From mmi_v180."BRAND_LIST");
		
		*/
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT "ID","NAME",'''||tbl_nme||''',''FTR_CRY'',"FTR_CRY",''Wrong naming convention with ftr_cry'',''2.47.179'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		-- WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND t."FTR_CRY" = ''SHPREP'' AND (LOWER(t."NAME") NOT LIKE ''% service'' AND LOWER(t."NAME") NOT LIKE ''% service centre %'' AND 
		-- LOWER(t."NAME") NOT LIKE ''% service centre'' AND LOWER(t."NAME") NOT LIKE ''% workshop'' AND LOWER(t."NAME") NOT LIKE ''% service station'' AND LOWER(t."NAME") NOT LIKE ''% spare %'') ';

-- 		SELECT "ID","NAME",'tbl_nme','FTR_CRY',"FTR_CRY",'Wrong naming convention with ftr_cry','2.47.179' FROM mmi."DL_POI" As t 
-- 		WHERE ( t."FTR_CRY" = 'SHPREP' AND 
-- 		(LOWER(t."NAME") NOT LIKE '% service' AND LOWER(t."NAME") NOT LIKE '% service centre %' AND LOWER(t."NAME") NOT LIKE '% service centre' AND LOWER(t."NAME") NOT LIKE '% workshop' AND LOWER(t."NAME") NOT LIKE '% service station' AND LOWER(t."NAME") NOT LIKE '% spare %')

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Wrong naming convention with ftr_cry=“SHPREP”';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.285
--15 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''FTR_CRY'',"FTR_CRY",''If Ftr_Cry in NATNTC, RESLCS, MNYFIN, AIRTRN, WTRTRN,SRFTRN, ONGTRN, PLCHIS, AMURCN, DINFOD, RLGPLP then Sub_Cry must not be blank'',''2.47.285'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		WHERE t."FTR_CRY" In (''NATNTC'', ''RESLCS'', ''MNYFIN'', ''AIRTRN'', ''WTRTRN'',''SRFTRN'', ''ONGTRN'', ''PLCHIS'', ''AMURCN'', ''DINFOD'', ''RLGPLP'') AND COALESCE(t."SUB_CRY",'''')='''' ';

-- 		SELECT "ID","NAME",'tbl_nme','FTR_CRY',"FTR_CRY",'If Ftr_Cry in NATNTC, RESLCS, MNYFIN, AIRTRN, WTRTRN,SRFTRN, ONGTRN, PLCHIS, AMURCN, DINFOD, RLGPLP then Sub_Cry must not be blank','2.47.285' FROM mmi_v180."GA_POI" As t 
-- 		WHERE t."FTR_CRY" In ('NATNTC', 'RESLCS', 'MNYFIN', 'AIRTRN', 'WTRTRN','SRFTRN', 'ONGTRN', 'PLCHIS', 'AMURCN', 'DINFOD', 'RLGPLP') AND COALESCE(t."SUB_CRY",'')=''
	
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'If Ftr_Cry in NATNTC, RESLCS, MNYFIN, AIRTRN, WTRTRN,SRFTRN, ONGTRN, PLCHIS, AMURCN, DINFOD, RLGPLP then Sub_Cry must not be blank';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.2
---109 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''SP_GEOMETRY'',"SP_GEOMETRY",''Poi must be geocoded/object'',''2.47.2'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t 
		WHERE "SP_GEOMETRY" IS NULL ';

-- 		SELECT "ID","NAME",'tbl_nme','SP_GEOMETRY',"SP_GEOMETRY",'Poi must be geocoded/object','2.47.2' FROM mmi_v180."GA_POI"
-- 		WHERE "SP_GEOMETRY" IS NULL
	
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Poi must be geocoded/object';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.264
--31 msec
	BEGIN
		--ADDED BIPIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT t3."ID", t3."NAME",'''||tbl_nme||''',''RANKING'',t3."RANKING"::text, ''Duplicacy of ranking within a city except (HOTALL,HOTPRE,HOTNOP,HOTRES) cotegories'',''2.47.264'' 
		 FROM ( SELECT * FROM ( SELECT "CITY_ID","FTR_CRY","SUB_CRY","RANKING",Count(*) FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE "RANKING"<>0 AND "CITY_ID"<>0 AND "FTR_CRY" Not In (''HOTALL'',''HOTPRE'',''HOTNOP'',''HOTRES'') group By "CITY_ID","FTR_CRY","SUB_CRY","RANKING") t1 
		 WHERE t1.count>1) As t2, '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t3 
		 WHERE t3."CITY_ID"=t2."CITY_ID" AND t3."FTR_CRY"= t2."FTR_CRY" AND t3."RANKING"= t2."RANKING" AND COALESCE(t2."SUB_CRY",'''')=COALESCE(t3."SUB_CRY",'''') ';
		
		/*
		 SELECT t3."ID", t3."NAME",'DL_POI','RANKING',t3."RANKING"::text, 'Duplicacy of ranking within a city except (HOTALL,HOTPRE,HOTNOP,HOTRES) cotegories','2.47.264' 
		 FROM ( SELECT * FROM ( SELECT "CITY_ID","FTR_CRY","SUB_CRY","RANKING",Count(*) FROM mmi_v180."GA_POI" 
		 WHERE "RANKING"<>0 AND "CITY_ID"<>0 AND "FTR_CRY" Not In ('HOTALL','HOTPRE','HOTNOP','HOTRES') group By "CITY_ID","FTR_CRY","SUB_CRY","RANKING") t1 
		 WHERE t1.count>1) As t2, mmi_v180."GA_POI" As t3 
		 WHERE t3."CITY_ID"=t2."CITY_ID" AND t3."FTR_CRY"= t2."FTR_CRY" AND t3."RANKING"= t2."RANKING" AND COALESCE(t2."SUB_CRY",'')=COALESCE(t3."SUB_CRY",'')
		*/
		-- EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		-- SELECT t3."ID",t3."NAME",'''||tbl_nme||''',''RANKING'',t3."RANKING"::text, ''Duplicacy of ranking within a city except given categories(HOTALL,HOTPRE,HOTNOP,HOTRES)'',''2.47.264''
		-- FROM ( SELECT * FROM ( SELECT "CITY_ID","RANKING",Count(*) FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "RANKING"<>0 group By "CITY_ID","RANKING") t1 
		 -- WHERE t1.count>1) As t2, '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t3 WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND 
		-- t3."CITY_ID"=t2."CITY_ID" AND t3."RANKING"= t2."RANKING" Order by t3."CITY_ID",t3."RANKING" ';

-- 		 SELECT t3."ID",t3."NAME",'tbl_nme','RANKING',t3."RANKING"::text, 'Duplicacy of ranking within a city except given categories(HOTALL,HOTPRE,HOTNOP,HOTRES)','2.47.264' 
-- 		 FROM ( SELECT * FROM ( SELECT "CITY_ID","RANKING",Count(*) FROM mmi."DL_POI" WHERE "RANKING"<>0 group By "CITY_ID","RANKING") t1 
-- 		 WHERE t1.count>1) As t2, mmi."DL_POI" As t3 WHERE (status NOT IN ('0','5') OR (COALESCE(status,'')='') ) AND 
-- 		t3."CITY_ID"=t2."CITY_ID" AND t3."RANKING"= t2."RANKING" Order by t3."CITY_ID",t3."RANKING"

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Duplicacy of ranking within a city except (HOTALL,HOTPRE,HOTNOP,HOTRES) cotegories';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--2.47.264
--31 msec
	BEGIN	
		
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT t3."ID", t3."NAME",'''||tbl_nme||''',''RANKING'',t3."RANKING"::text, ''Duplicacy of ranking within a city for (HOTALL,HOTPRE,HOTNOP,HOTRES) categories'',''2.47.264'' 
		 FROM ( SELECT * FROM ( SELECT "CITY_ID","FTR_CRY","SUB_CRY","RANKING",Count(*) FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE "RANKING"<>0 AND "CITY_ID"<>0 AND "FTR_CRY" In (''HOTALL'',''HOTPRE'',''HOTNOP'',''HOTRES'') group By "CITY_ID","FTR_CRY","SUB_CRY","RANKING") t1 
		 WHERE t1.count>1) As t2, '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t3 
		 WHERE t3."CITY_ID"=t2."CITY_ID" AND t3."FTR_CRY"= t2."FTR_CRY" AND t3."RANKING"= t2."RANKING" AND COALESCE(t2."SUB_CRY",'''')=COALESCE(t3."SUB_CRY",'''') ';
	    /*
		  SELECT t3."ID", t3."NAME",'''||tbl_nme||''',''RANKING'',t3."RANKING"::text, ''Duplicacy of ranking within a city for (HOTALL,HOTPRE,HOTNOP,HOTRES) categories'',''2.47.264'' 
		 FROM ( SELECT * FROM ( SELECT "CITY_ID","FTR_CRY","SUB_CRY","RANKING",Count(*) FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		 WHERE "RANKING"<>0 AND "CITY_ID"<>0 AND "FTR_CRY" In (''HOTALL'',''HOTPRE'',''HOTNOP'',''HOTRES'') group By "CITY_ID","FTR_CRY","SUB_CRY","RANKING") t1 
		 WHERE t1.count>1) As t2, '||sch_name||'."'|| UPPER(tbl_nme) ||'" As t3 
		 WHERE (status NOT IN (''0'',''5'') OR (COALESCE(status,'''')='''') ) AND 
		t3."CITY_ID"=t2."CITY_ID" AND t3."FTR_CRY"= t2."FTR_CRY" AND t3."RANKING"= t2."RANKING" AND COALESCE(t2."SUB_CRY",'''')=COALESCE(t3."SUB_CRY",'''') ';

		
		*/	
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Duplicacy of ranking within a city for (HOTALL,HOTPRE,HOTNOP,HOTRES) categories';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	-- ADDED BY GOLDY 02/04/2019
	--SRCUPDT_ID CHECKS START
	--2.47.364
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''SRCUPDT_ID'',"SRCUPDT_ID"::text, ''Must not be 0 '',''2.47.364''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE COALESCE("SRCUPDT_ID",'''') = ''0''  ';

		-- SELECT "ID","NAME",'tbl_nme','ID',"ID"::text, 'Must not be 0 "Zero"','2.47.364'
		-- FROM  poi_testing."CH_POI"
		-- WHERE COALESCE("SRCUPDT_ID",'') = '0'
		
		RAISE INFO '<-----------2.47.364';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	-- ADDED BY GOLDY 02/04/2019
	-- GEO_LVL CHECKS START
	-- 2.47.365
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''GEO_LVL'',"GEO_LVL"::text, ''Only  E ,R ,A ,AP and NULL values are accepted '',''2.47.365''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE  "GEO_LVL"  NOT IN (''E'',''R'',''A'',''AP'') AND COALESCE("GEO_LVL",'''') <> '''' ';

		-- SELECT "ID","NAME","GEO_LVL",'tbl_nme','ID',"ID"::text, 'Only  E ,  R ,  A ,  AP  and NULL values are accepted','2.47.365'
		-- FROM  poi_testing."CH_POI"
		-- WHERE  "GEO_LVL"  NOT IN ('E','R','A','AP') AND COALESCE("GEO_LVL",'') <> ''

		
		RAISE INFO '<-----------2.47.365';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	--2.47.366
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''GEO_LVL'',"GEO_LVL"::text, ''MUST BE IN UPPER CASE '',''2.47.366''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE  "GEO_LVL" <> UPPER("GEO_LVL") ';

		-- SELECT "ID","NAME","GEO_LVL",'tbl_nme','ID',"ID"::text, 'MUST BE IN UPPER CASE','2.47.366'
		-- FROM  poi_testing."CH_POI"
		-- WHERE  "GEO_LVL" <> UPPER("GEO_LVL")

		
		RAISE INFO '<-----------2.47.366';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	--2.47.368
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''LYR_TYP'',"LYR_TYP"::text, ''Only P or B values are accepted'',''2.47.368''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE COALESCE("LYR_TYP",'''')<>'''' AND "LYR_TYP" NOT IN (''P'',''B'') ';

		-- SELECT "ID","NAME","LYR_TYP",'tbl_nme','ID',"ID"::text, 'Only P or B values are accepted','2.47.368'
		-- FROM  poi_testing."CH_POI"
		-- WHERE "LYR_TYP" NOT IN ('P','B')

		
		RAISE INFO '<-----------2.47.368';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	--2.47.357
	-- ADDED BY GOLDY 04/04/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''PUB_PVT'',"PUB_PVT"::text, ''Must have 0, 1, 2 values'',''2.47.357''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				WHERE "PUB_PVT" NOT IN (0,1,2) ';

		-- SELECT "ID","NAME","PUB_PVT",'tbl_nme','ID',"ID"::text, 'Must have 0, 1, 2 values','2.47.357'
		-- FROM  mmi_master."BR_POI"
		-- WHERE "PUB_PVT" NOT IN (0,1,2)

		
		RAISE INFO '<-----------2.47.357';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	
	--2.47.358
	-- ADDED BY GOLDY 04/04/2019
	-- BEGIN
		-- EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 -- SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME"::text, ''One character Name must not be allowed'',''2.47.358''
				 -- FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 -- WHERE COALESCE("BRAND_NME",'''')<>'''' AND  LENGTH("NAME") = 1 ';

		-- SELECT "ID","NAME",'tbl_nme','ID',"ID"::text, 'One character Name must not be allowed','2.47.358'
		-- FROM  mmi_master."BR_POI"
		-- WHERE LENGTH("NAME") = 1

		
		-- RAISE INFO '<-----------2.47.358';
		
	-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	-- END;
	-- RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	
	--2.47.359
	-- ADDED BY GOLDY 04/04/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text, ''One character Name must not be allowed'',''2.47.359''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE  LENGTH("POPLR_NME") = 1 ';

		-- SELECT "ID","NAME",'tbl_nme','ID',"ID"::text, 'One character Name must not be allowed','2.47.359'
		-- FROM  mmi_master."BR_POI"
		-- WHERE LENGTH("POPLR_NME") = 1

		
		RAISE INFO '<-----------2.47.359';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	
	--2.47.360
	-- ADDED BY GOLDY 04/04/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1"::text, ''One character Name must not be allowed'',''2.47.360''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE LENGTH("ALIAS_1") = 1 ';

		-- SELECT "ID","NAME",'tbl_nme','ID',"ID"::text, 'One character Name must not be allowed','2.47.360'
		-- FROM  mmi_master."BR_POI"
		-- WHERE LENGTH("ALIAS_1") = 1

		
		RAISE INFO '<-----------2.47.360';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	
	--2.47.361
	-- ADDED BY GOLDY 04/04/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2"::text, ''One character Name must not be allowed'',''2.47.361''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE LENGTH("ALIAS_2") = 1 ';

		-- SELECT "ID","NAME",'tbl_nme','ID',"ID"::text, 'One character Name must not be allowed','2.47.361'
		-- FROM  mmi_master."BR_POI"
		-- WHERE LENGTH("ALIAS_2") = 1

		
		RAISE INFO '<-----------2.47.361';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	-- 2.47.362
	-- ADDED BY GOLDY 04/04/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text, ''One character Name must not be allowed'',''2.47.362''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE LENGTH("ALIAS_3") = 1 ';

		-- SELECT "ID","NAME",'tbl_nme','ID',"ID"::text, 'One character Name must not be allowed','2.47.362'
		-- FROM  mmi_master."BR_POI"
		-- WHERE LENGTH("ALIAS_3") = 1

		
		RAISE INFO '<-----------2.47.362';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	
	-- 2.47.373
	-- ADDED BY GOLDY 04/04/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text, ''If Alias_2 is blank and Alias_3 has values then provide errors'',''2.47.373''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE  COALESCE("ALIAS_2",'''') = '''' AND COALESCE("ALIAS_3",'''') <>'''' ';

		-- SELECT "ID","NAME","ALIAS_2","ALIAS_3",'tbl_nme','ID',"ID"::text, 'If Alias_2 is blank and Alias_3 has values then provide errors','2.47.373'
		-- FROM  mmi_master."BR_POI"
		-- WHERE  COALESCE("ALIAS_2",'') = '' AND COALESCE("ALIAS_3",'') <>''

		
		RAISE INFO '<-----------2.47.373';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	-- 2.47.372
	-- ADDED BY GOLDY 04/04/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''BRANCH_NME'',"BRANCH_NME"::text, ''Branch word must not be exist with the name in Branch Name Column for COMUNV COMCLG COMSCH COMEOT and COMLIB Ftr_Cry'',''2.47.372''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE "BRANCH_NME" LIKE ''%BRANCH%'' AND "FTR_CRY" IN (''COMUNV'', ''COMCLG'', ''COMSCH'', ''COMEOT'', ''COMLIB'')	 ';

		-- SELECT "ID","NAME","BRANCH_NME","FTR_CRY",'tbl_nme','ID',"ID"::text, 'One character Name must not be allowed','2.47.362'
		-- FROM  mmi_master."BR_POI"
		-- WHERE "BRANCH_NME" LIKE '%BRANCH%' AND "FTR_CRY" IN ('COMUNV', 'COMCLG', 'COMSCH', 'COMEOT', 'COMLIB')

		
		RAISE INFO '<-----------2.47.372';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	-- 2.47.348.1
	-- ADDED BY GOLDY 04/06/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''BRANCH_NME'',"BRANCH_NME"::text, '' Branch word must be there with the name in branch name in case of education category '',''2.47.348.1''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE "BRANCH_NME" LIKE ''% BRANCH'' AND "BRANCH_NME" LIKE ''% BRANCH %'' AND "BRANCH_NME" LIKE ''BRANCH %'' AND  "FTR_CRY"  IN (''COMUNV'', ''COMCLG'', ''COMSCH'', ''COMEOT'', ''COMLIB'') ';

		-- SELECT "ID","NAME","FTR_CRY",'BRANCH_NME',"BRANCH_NME"::text, '"Branch" word must be suffix with the name in Branch Name Column ','2.47.348.1'
		-- FROM mmi_master."DL_POI"
		-- WHERE "BRANCH_NME" LIKE '% BRANCH' AND "BRANCH_NME" LIKE '% BRANCH %' AND "BRANCH_NME" LIKE 'BRANCH %' AND  "FTR_CRY"  IN ('COMUNV', 'COMCLG', 'COMSCH', 'COMEOT', 'COMLIB')

		
		RAISE INFO '<-----------2.47.378.1';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	-- 2.47.348.2
	-- ADDED BY GOLDY 04/06/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''BRANCH_NME'',"BRANCH_NME"::text, '' Branch word must be suffix  with the name in branch name (except education category) '',''2.47.348.2''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE "BRANCH_NME" LIKE ''% BRANCH''  AND  "FTR_CRY" NOT  IN (''COMUNV'', ''COMCLG'', ''COMSCH'', ''COMEOT'', ''COMLIB'') ';

		-- SELECT "ID","NAME","FTR_CRY",'BRANCH_NME',"BRANCH_NME"::text, '"Branch" word must be suffix with the name in Branch Name Column ','2.47.348'
		-- FROM mmi_master."DL_POI"
		-- WHERE "BRANCH_NME" LIKE '% BRANCH'  AND  "FTR_CRY" NOT  IN ('COMUNV', 'COMCLG', 'COMSCH', 'COMEOT', 'COMLIB')

		
		RAISE INFO '<-----------2.47.378.2';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	-- 2.47.356
	-- ADDED BY GOLDY 18/06/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''SRCCLSD'',"SRCCLSD"::text, ''If SrcClsd have some value then its Id must not be available in PIP_ID for remaining all records'',''2.47.356''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE "SRCCLSD" IS NOT NULL AND  "SEC_STA" IN (''R'',''KR'')  ';

		-- select "ID","SRCCLSD","SEC_STA" FROM mmi_master."DL_POI" WHERE "SRCCLSD" IS NOT NULL AND  "SEC_STA" IN ('R','KR')  
		
		RAISE INFO '<-----------2.47.356';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	
	--version 21.0
	-- 2.47.377.1
	-- ADDED BY GOLDY 13/06/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''SRCUPDT_ID'',"SRCUPDT_ID", ''If SRCUPDT_ID available then SRCNME must not be blank'',''2.47.377.1''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE coalesce("SRCUPDT_ID",'''')<>''''  AND COALESCE("SRCNME",'''')='''' ';

		-- select "ID","SRCUPDT_ID","SRCNME" FROM mmi_master."DL_POI"
		-- WHERE "SRCUPDT_ID" IS NOT NULL and "SRCUPDT_ID" <> 0  AND COALESCE("SRCNME",'')=''
		
		RAISE INFO '<-----------2.47.377.1';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	
	-- 2.47.377.2
	-- ADDED BY GOLDY 13/06/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''SRCNME'',"SRCNME", ''If SRCNME available then SRCUPDT_ID must not be blank'',''2.47.377.2''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE COALESCE("SRCNME",'''')<>'''' and  coalesce("SRCUPDT_ID",'''')='''' ';

		-- select "ID","SRCUPDT_ID","SRCNME" FROM mmi_master."DL_POI"
		-- WHERE "SRCUPDT_ID" IS NOT NULL and "SRCUPDT_ID" <> 0  AND COALESCE("SRCNME",'')=''
		
		RAISE INFO '<-----------2.47.377.2';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	
	-- 2.47.376	
	-- ADDED BY GOLDY 13/06/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''SRCNME'',"SRCNME", ''Single charecter and numeric values are not accepted'',''2.47.376''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 where COALESCE("SRCNME",'''')<>'''' AND (LENGTH("SRCNME")=1 OR "SRCNME" ~ ''[0-9]'') ';

		-- select "ID", "SRCNME" FROM mmi_master."DL_POI" WHERE COALESCE("SRCNME",'')<>'' AND (LENGTH("SRCNME")=1 OR "SRCNME" ~'[0-9]')
		
		RAISE INFO '<-----------2.47.376';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	
	-- 2.47.375
	-- ADDED BY GOLDY 13/06/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''CODE_TYP'',"CODE_TYP", ''Single charecter and numeric values are not accepted'',''2.47.375''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 where COALESCE("CODE_TYP",'''')<>'''' AND (LENGTH("CODE_TYP")=1 OR "CODE_TYP" ~ ''[0-9]'') ';

		-- select "ID", "CODE_TYP" FROM mmi_master."DL_POI" WHERE COALESCE("CODE_TYP",'')<>'' AND (LENGTH("CODE_TYP")=1 OR "CODE_TYP" ~'[0-9]')
		
		RAISE INFO '<-----------2.47.375';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	
	-- 2.47.374.1
	-- ADDED BY GOLDY 13/06/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''CODE_TYP'',"CODE_TYP", ''If CODE_TYP available then CODE_NME must not be blank'',''2.47.374.1''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE coalesce("CODE_TYP",'''')<>'''' AND COALESCE("CODE_NME",'''')='''' ';

		-- select "ID","SRCUPDT_ID","SRCNME" FROM mmi_master."DL_POI"
		-- WHERE "SRCUPDT_ID" IS NOT NULL and "SRCUPDT_ID" <> 0  AND COALESCE("SRCNME",'')=''
		
		RAISE INFO '<-----------2.47.374.1';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	-- 2.47.374.2
	-- ADDED BY GOLDY 13/06/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''CODE_NME'',"CODE_NME", ''If CODE_NME available then CODE_TYP must not be blank'',''2.47.374.2''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE COALESCE("CODE_NME",'''')<>'''' and  coalesce("CODE_TYP",'''')='''' ';

		-- select "ID","SRCUPDT_ID","SRCNME" FROM mmi_master."DL_POI"
		-- WHERE "SRCUPDT_ID" IS NOT NULL and "SRCUPDT_ID" <> 0  AND COALESCE("SRCNME",'')=''
		
		RAISE INFO '<-----------2.47.374.2';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
-- 2.47.358
-- ADDED BY GOLDY 13/06/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''NAME'',"NAME", ''One character Name must not be allowed, ignore records where brand_Nme is not null'',''2.47.358''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE COALESCE("BRAND_NME",'''')='''' AND LENGTH("NAME")=1 AND UPPER("NAME") LIKE ANY(ARRAY(SELECT UPPER("BND_NAME") FROM '||sch_name||'."BRAND_LIST"))= FALSE';

		-- select "ID","NAME","BRAND_NME" FROM mmi_master."DL_POI" WHERE COALESCE("BRAND_NME",'')='' AND LENGTH("NAME")=1 AND UPPER("NAME") LIKE ANY(ARRAY(SELECT UPPER("BND_NAME") FROM mmi_master."BRAND_LIST"))= FALSE
		
		RAISE INFO '<-----------2.47.358';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
---2.47.323
--- ADDED GOLDY 13/06/2019
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME",''Occurance of Same character thrice and more than thrice is not allowed'',''2.47.323'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE regexp_replace("POPLR_NME",''[0-9/, ]'','''')~''(.)\1{2}'' AND "POPLR_NME"~''(.)\1{2}'' ';
		
		--SELECT "ID","NAME" FROM mmi_v180."DL_POI" WHERE regexp_replace("NAME",'[0-9/, ]','')~'(.)\1{2}' AND "NAME"~'(.)\1{2}'
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'NAME Occurance of Same character thrice and more than thrice is not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	
---2.47.328
--- ADDED GOLDY 13/06/2019
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''BRANCH_NME'',"BRANCH_NME",''Occurance of Same character thrice and more than thrice is not allowed'',''2.47.328'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE regexp_replace("BRANCH_NME",''[0-9/, ]'','''')~''(.)\1{2}'' AND "BRANCH_NME"~''(.)\1{2}'' ';
		
		--SELECT "ID","NAME" FROM mmi_v180."DL_POI" WHERE regexp_replace("NAME",'[0-9/, ]','')~'(.)\1{2}' AND "NAME"~'(.)\1{2}'
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'NAME Occurance of Same character thrice and more than thrice is not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	
	
---2.47.90
--- ADDED GOLDY 14/06/2019
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''DT_SRCNEW'',"DT_SRCNEW",''Occurance of Same character thrice and more than thrice is not allowed'',''2.47.90'' 
		FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		where LENGTH("DT_SRCNEW")<>6 OR "DT_SRCNEW" ~''^[[:alpha:]]'' ';
		
		-- select "ID","DT_SRCNEW" FRom mmi_master."DL_POI" where LENGTH("DT_SRCNEW")<>6 OR "DT_SRCNEW" ~'^[[:alpha:]]'
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'NAME Occurance of Same character thrice and more than thrice is not allowed';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	
	
-- 2.47.350
-- ADDED BY GOLDY 18/06/2019
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID","NAME",'''||tbl_nme||''',''PIP_ID'',"PIP_ID", '' Where Pip_Id<>0 and count > 1 then Vicin_Id must be same for all records according to PIP_Id'',''2.47.350''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
				 WHERE "PIP_ID" IN (SELECT "PIP_ID" FROM (SELECT "PIP_ID","VICIN_ID" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
				 WHERE "PIP_ID" IN (SELECT "PIP_ID" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE "PIP_ID"<>0 GROUP BY "PIP_ID" HAVING COUNT(*)>1)ORDER BY "PIP_ID") AS t GROUP BY "PIP_ID" HAVING COUNT (DISTINCT "VICIN_ID")>1) ';

		-- SELECT "ID","PIP_ID","NAME" FROM mmi_master."DL_POI" WHERE "PIP_ID" IN (SELECT "PIP_ID" FROM (SELECT "PIP_ID","VICIN_ID" FROM mmi_master."DL_POI" 
		-- WHERE "PIP_ID" IN (SELECT "PIP_ID" FROM mmi_master."DL_POI" WHERE "PIP_ID"<>0 GROUP BY "PIP_ID" HAVING COUNT(*)>1)ORDER BY "PIP_ID") AS t GROUP BY "PIP_ID" HAVING COUNT (DISTINCT "VICIN_ID")>1)

		
		RAISE INFO '<-----------2.47.350';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
--1.1.1.02
-- UPDATED BY GOLDY 12/04/2019
-- 31 msec
	BEGIN
		EXECUTE ' INSERT INTO '||error_table||' ( poi_id,name,table_name,field_name,field_value,error_type,error_code) 
		SELECT "ID","NAME",'''||tbl_nme||''',''PIP_ID'',"PIP_ID", ''PIP_TYP=3 AND PIP_ID PRESNT IN MASTER TABLE'',''1.1.1.02'' FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" 
		WHERE "PIP_TYP"=3 AND  "PIP_ID" IN (SELECT "ID" FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" )  ';
         
		--SELECT "PIP_ID","ID","PIP_TYP" FROM mmi_master."DL_POI" WHERE "PIP_TYP"=3 AND  "PIP_ID" IN (SELECT "ID" FROM mmi_master."DL_POI")
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'Only C, KC and PC values are accepted';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
---------exception pca	
--1.100.18
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT t1."ID",t1."NAME",'''||tbl_nme||''',''PIP_ID'',t1."PIP_ID"::text, ''If Parent and child poi’s have different Admin Id, then maintain ”PCA” in EXCP'',''1.100.18''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" AS t1 left join 
				 (Select "ID","ADMIN_ID","PIP_ID","EXCP" From '||sch_name||'."'|| UPPER(tbl_nme) ||'" where "PIP_ID"<>0) as t2 
				 on t1."ID"=t2."PIP_ID" where t1."ADMIN_ID"<>t2."ADMIN_ID" and COALESCE(t2."EXCP",'''') not like ''%PCA%'' AND t2."ADMIN_ID"<>0  ';

		-- Select * From mmi_master."DL_POI" as t1 left join
		--(Select "ID","ADMIN_ID","PIP_ID","EXCP" From mmi_master."DL_POI" where "PIP_ID"<>0) as t2 
		--on t1."ID"=t2."PIP_ID" where t1."ADMIN_ID"<>t2."ADMIN_ID" and COALESCE(t2."EXCP",'') not like '%PCA%' AND t2."ADMIN_ID"<>0 

		
		RAISE INFO '<-----------1.100.18';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

------------------------------------------------------------------------PIP_TYP/PIP_ID-----------------------------------------------------------------------------------------------------------------------	

-- 2.47.106
-- ADDED BY ABHINAV
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT tab1."ID",tab1."NAME",'''||tbl_nme||''',''PIP_ID'',tab1."PIP_ID"::text, ''If PIP_Typ=1 or 2 then PIP_ID must be available in ID of POI/POI_TPD layer'',''2.47.106''
				 FROM '||sch_name||'."'||UPPER(tbl_nme)||'" tab1 left join '||sch_name||'."'||UPPER(master_tbl_poi_tpd)||'" tab2 on tab1."ID" <> tab2."ID"
				WHERE tab1."PIP_TYP" = 1 AND tab1."PIP_TYP" = 2  ';

		-- SELECT tab1."ID",tab1."NAME"
		--FROM mmi_master."DL_POI" tab1 left join mmi_master."DL_POI_TPD" tab2 on tab1."ID" <> tab2."ID"
		--WHERE tab1."PIP_TYP" = 1 AND tab1."PIP_TYP" = 2

		
		RAISE INFO '<-----------2.47.106';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	-- 2.47.106
	-- ADDED BY ABHINAV
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT tab1."ID",tab1."NAME",'''||tbl_nme||''',''PIP_ID'',tab1."PIP_ID"::text, ''If PIP_Typ=3 then PIP_ID must be available in ID of ADDR_Point layer'',''2.47.106''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" tab1 left join '||UPPER(tbl_nme_point)||' tab2 on tab1."ID" <> tab2."ID"
				WHERE tab1."PIP_TYP" = 3 ';

		-- SELECT tab1."ID",tab1."NAME"
		--FROM mmi_master."DL_POI" tab1 left join mmi_master."DL_P1_ADDR_POINT" tab2 on tab1."ID" <> tab2."ID"
		--WHERE tab1."PIP_TYP" = 3

		
		RAISE INFO '<-----------2.47.106';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
	-- 2.47.106
	-- ADDED BY ABHINAV
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT tab1."ID",tab1."NAME",'''||tbl_nme||''',''PIP_ID'',tab1."PIP_ID"::text, ''If PIP_Typ=3 then PIP_ID must be available in ID of ADDR_Point layer'',''2.47.106''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" tab1 left join '||sch_name||'."'||UPPER(master_tbl_admin_p)||'" tab2 on tab1."ID" <> tab2."ID"
				WHERE tab1."PIP_TYP" = 4 ';

		-- SELECT tab1."ID",tab1."NAME"
		--FROM mmi_master."DL_POI" tab1 left join mmi_master."DL_ADDR_ADMIN_P" tab2 on tab1."ID" <> tab2."ID"
		--WHERE tab1."PIP_TYP" = 4

		
		RAISE INFO '<-----------2.47.106';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

--2.47.379	
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID", "NAME",'''||tbl_nme||''',''PIP_ID'', "PIP_ID"::text, ''If Pip_Typ has value then its Pip_Id must not be zero and vise versa'',''2.47.379''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE (COALESCE("PIP_TYP"::TEXT,'''')=''0'' AND "PIP_ID" <> 0) 
				 OR (COALESCE("PIP_ID"::TEXT,'''')=''0'' AND "PIP_TYP" <> 0) ';

		-- SELECT "ID", "PIP_ID", "PIP_TYP" FROM mmi_master."DL_POI" WHERE (COALESCE("PIP_TYP"::TEXT,'')='0' AND "PIP_ID" <> 0) OR (COALESCE("PIP_ID"::TEXT,'')='0' AND "PIP_TYP" <> 0)
		
		RAISE INFO '<-----------2.47.379';
		
	EXCEPTION 
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

-----------------------------------------------------------------------LYR_TYP------------------------------------------------------------------------------------------------------------------
--2.47.400	
	BEGIN
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID", "NAME",'''||tbl_nme||''',''LYR_TYP'', "LYR_TYP", ''LYR_TYP must be null'',''2.47.400''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" WHERE  COALESCE("LYR_TYP",'''') = '''' AND "LYR_TYP" IS NULL ';

		-- SELECT "ID", "NAME", "LYR_TYP" FROM mmi_master."DL_POI" WHERE  COALESCE("LYR_TYP",'') = '' AND "LYR_TYP" IS NULL
		
		RAISE INFO '<-----------2.47.400';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
-------EXCP(BNY)	
	BEGIN	
		sqlQuery = 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT tab1."ID",tab1."NAME",'''||tbl_nme||''',''NAME'',tab1."NAME"::text, ''EXCEPTION TO MAINTAIN BNY WHERE BRAND_NMW IS NULL WHILE NAME  FTR_CRY SUB_CRY  IS THERE'',''1.100.7''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" AS tab1 , '||mst_sch||'."BRAND_LIST" as tab2
				 WHERE tab1."NAME"=tab2."BND_NAME" AND tab1."FTR_CRY" = tab2."FTR_CRY" and tab1."SUB_CRY" = tab2."SUB_CRY" AND 
				 coalesce(tab1."BRAND_NME",'''') = '''' AND COALESCE(tab1."EXCP",'''') <>''BNY''  ';
		
		-- SELECT tab1."ID",tab1."NAME",tab2."NAME" ,tab1."FTR_CRY",tab1."SUB_CRY",tab2."FTR_CRY",tab2."SUB_CRY",tab1."BRAND_NME",tab1."EXCP"
		-- FROM mmi_master."DL_POI" tab1,mmi_master."BRAND_LIST" tab2
		-- WHERE tab1."NAME"=tab2."NAME" AND tab1."FTR_CRY" = tab2."FTR_CRY" and tab1."SUB_CRY" = tab2."SUB_CRY" AND 
		-- coalesce(tab1."BRAND_NME") = '' AND COALESCE(tab1."EXCP",'') <>'BNY'
		--RAISE INFO 'sqlQuery->%',sqlQuery;	
		EXECUTE sqlQuery;
		RAISE INFO '<-----------2.60.38';
		
	-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||'_attobj (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

-------EXCP(SSY)	
	BEGIN	
		EXECUTE 'INSERT INTO '||error_table||' ( poi_id,NAME,table_name,field_name,field_value,error_type,error_code)
				 SELECT tab1."ID",tab1."NAME",'''||tbl_nme||''',''EXCP'',tab1."EXCP"::text, ''EXCEPTION TO MAINTAIN SSY WHERE SECURITY KEYWORD IS THERE IN NAME'',''1.100.8''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'" AS tab1 , spatial_layer_functions."Sec_Keyword" as tab2
				 where (tab1."NAME" LIKE ''%''||tab2."Keyword"||'' %'' OR tab1."NAME" LIKE ''% ''||tab2."Keyword"||'' %'' or tab1."NAME" LIKE tab2."Keyword" or tab1."NAME" LIKE ''% ''||tab2."Keyword" ) and tab1."EXCP" <> ''%SSY%''  ';

				 
		-- select tab1."ID",tab1."NAME",tab2."Keyword",tab1."EXCP" FROM mmi_master."DL_POI" tab1,spatial_layer_functions."Sec_Keyword" tab2
		-- where (tab1."NAME" LIKE '%'||tab2."Keyword"||' %' OR tab1."NAME" LIKE tab2."Keyword" or tab1."NAME" LIKE '% '||tab2."Keyword" ) and tab1."EXCP" <> '%SSY%'

			
		
		RAISE INFO '<-----------2.60.38';
		
	-- EXCEPTION
		-- WHEN OTHERS THEN
		-- GET STACKED DIAGNOSTICS 
			-- f1=MESSAGE_TEXT,
			-- f2=PG_EXCEPTION_CONTEXT; 
				
		-- EXECUTE'insert into '||attrib_error||'_attobj (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme_poi||''')';
		-- RAISE info 'error caught 2.1:%',f1;
		-- RAISE info 'error caught 2.2:%',f2;
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;


	
--IGNORE ERRORS FROM EXCEPTION TABLE 
if(upper(user_type)= 'USER' or user_type = 'PACKING' or user_type = 'ADMIN') then 
	BEGIN
		EXECUTE 'select count(table_name) from information_schema.tables where table_schema=''mmi_lock'' and table_name=''explog''' into count;

		IF count=1  THEN
			EXECUTE 'DELETE FROM '||error_table||' a WHERE EXISTS (select * FROM mmi_lock.explog b WHERE a.poi_id=b.un_id and coalesce(TRIM(a.field_name),'''')=coalesce(TRIM(b.field_name),'''') and coalesce(TRIM(a.field_value),'''')=coalesce(TRIM(b.field_value),'''') and coalesce(TRIM(a.error_type),'''')=coalesce(TRIM(b.error_type),'''') and coalesce(TRIM(a.error_code),'''')=coalesce(TRIM(b.error_code),'''') and TRIM(b.user_id)='''||UPPER(user_id)||''') AND (error_code not like ''1.1.2'' AND error_code not like ''1.1.3'' AND error_code not like ''1.1.4'' AND error_code not like ''1.1.5'' AND error_code not like ''1.1.6'' AND error_code not like ''1.1.7'')';
		END IF;

		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||attrib_error||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
end if;
END;	

$BODY$;

ALTER FUNCTION upload.qc_poi_attribute(character varying, character varying, character varying, character varying)
    OWNER TO postgres;
