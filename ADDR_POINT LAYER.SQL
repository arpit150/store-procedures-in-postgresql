-- FUNCTION: qaupload.qc_addr_point_attribute(character varying, character varying, character varying, text)

-- DROP FUNCTION qaupload.qc_addr_point_attribute(character varying, character varying, character varying, text);

CREATE OR REPLACE FUNCTION qaupload.qc_addr_point_attribute(
	sch_name character varying,
	tbl_nme character varying,
	user_id character varying,
	error_tab_name text DEFAULT 'attrib'::text)
    RETURNS integer
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$

DECLARE 
f1 text; f2 text;
t1 text; t2 text;
count integer;
DECLARE RETURNVAL integer;
DECLARE MAINTABLECOUNT integer;
DECLARE SqlQuery text;
DECLARE t timestamptz := clock_timestamp();
DECLARE mst_sch text;
declare tbl_name_poi_cat text;

DECLARE TableForQa text;

DECLARE qaerrortablelogtabname text;
DECLARE qauploadlogtabname text;
DECLARE qauploadlogschema text;

DECLARE qaerrorschema text;
DECLARE qaerrortabname text;
DECLARE functionerrortabname text;

declare master_unq_id character varying;
declare idlog character varying;
declare userlock character varying;

DECLARE errortablecount integer;

BEGIN   
	
	mst_sch = 'mmi_master';
	
	qaerrorschema = 'qa';
	IF(error_tab_name='attrib') THEN
		qaerrortabname = qaerrorschema||'.'||user_id||'_'||error_tab_name;
		qaerrortabname = lower(qaerrortabname);
	ELSE
		qaerrortabname = qaerrorschema||'.'||error_tab_name;
		qaerrortabname = lower(qaerrortabname);
	END IF;
	functionerrortabname = qaerrorschema||'.attriberror';

	qauploadlogschema = 'uploadlog';
	qaerrortablelogtabname = qauploadlogschema||'.qaerrortable';
	qauploadlogtabname = qauploadlogschema||'.qauploadlog';

	TableForQa = sch_name||'."'||UPPER(tbl_nme)||'"';
	master_unq_id = 'uniqueid_log.master_unq_id';
	idlog = 'uniqueid_log.idlog';
	userlock = 'addr_features_lock.userlock';
	
	--DROP ERROR TABLE IF ALREADY EXIST
	EXECUTE FORMAT('DROP TABLE IF EXISTS %1$s',qaerrortabname);

	--CREATE ERROR TABLE 
	EXECUTE FORMAT('CREATE TABLE if not exists %1$s (id serial, addr_id integer,table_name text, field_name text,field_value text, error_type text,error_code text )',qaerrortabname);

	--CREATE FUNCTION EXCEPTION ERROR TABLE
	EXECUTE FORMAT('CREATE TABLE if not exists %1$s (id serial,user_id text,layer_nme text, message text,context text,db_edit_datetime timestamp without time zone DEFAULT now())',functionerrortabname);

---------------------------------------------------------------------------------Checking for Poi Cat---------------------------------------------------------------------------------------
	BEGIN
		EXECUTE'SELECT count(table_name) FROM information_schema.tables WHERE UPPER(table_name) LIKE ''POI_CAT'' AND TABLE_SCHEMA ='''||mst_sch||''' ' into count;
		IF count = 1 THEN
			tbl_name_poi_cat=''||mst_sch||'."POI_CAT"';
		ELSE
			tbl_name_poi_cat = '';
			IF tbl_name_poi_cat = '' THEN
				RAISE WARNING '<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>POI_CAT DOES NOT EXISTS<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>|<>';
				EXECUTE'insert into qa.attriberror_attobj(message) values(''POI_CAT Table Does not Exists in '||mst_sch||' Schema'')';
			END IF;
		END IF;
	    RAISE INFO 'Checking for POI Category';
	END;	
	
	
	--PROCESS START FOR ATTRIBUTE VALIDATION
		-------------------------------------------------------------------------ID--------------------------------------------------------------------------------------------------------------------------	

--2.62.9
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ID'',"ID"::text,''check Uniqueness with in State'',''2.62.9''
		FROM '||TableForQa||'
		GROUP BY "ID" HAVING COUNT("ID") >1 ';

		
        -- SELECT "ID","ID"::text, 'Must not be zero 0','2.62.9' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- GROUP BY "ID" HAVING COUNT("ID") >1

		RAISE INFO '<-----------2.62.9';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.11
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ID'',"ID"::text,''Ids must be within the range (23100001 to 43100000) or (199000001 to 203000000) or (350000001 to 380000000)'',''2.62.11''
		FROM '||TableForQa||'
		WHERE ("ID" NOT BETWEEN 23100001 and 43100000) AND ("ID" NOT BETWEEN 199000001 and 203000000) AND ("ID" NOT BETWEEN 350000001 and 380000000) AND ("ID" NOT BETWEEN 43100001 and 63100000)';

        --SELECT "ID","ID"::text, 'Ids must be within the range (23100001 to 43100000) or (199000001 to 203000000) or (350000001 to 380000000)','2.62.11' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ("ID" NOT BETWEEN 23100001 and 43100000) AND ("ID" NOT BETWEEN 199000001 and 203000000) AND ("ID" NOT BETWEEN 350000001 and 380000000)
		
		RAISE INFO '<-----------2.62.11';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
--1.1.4
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
			SELECT "ID",'''||tbl_nme||''',''ID'',"ID"::text,''MASTER addr point RECORD should be Locked'',''1.1.4'' FROM (SELECT * FROM (SELECT A."ID",A."NAME" FROM '||TableForQa||' AS A,'||master_unq_id||' AS B 
			WHERE A."ID"=B.col_id AND B.state_code LIKE LEFT('''||UPPER(tbl_nme)||''',2)) AS C LEFT JOIN '||idlog||' D ON C."ID"=D.munid WHERE D.munid IS NULL) AS E LEFT JOIN '||userlock||' F ON E."ID"=F.table_id WHERE F.table_id IS NULL';

		
		--SELECT "ID","NAME",'tbl_nme','ID',"ID"::text, 
		--'POI_ID should be extracted FROM MMI Portal only and should not be 0','1.1.3' FROM mmi_v161."DL_POI" WHERE "ID"  NOT BETWEEN 43100001 AND 63100000 
		--AND "ID"  NOT BETWEEN 195338001 AND 199000000 AND ( status NOT IN ('0','5') OR (COALESCE(status,'')='') )
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'MASTER addr point RECORD should be Locked';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.1.4
		BEGIN
			EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
			SELECT "ID",'''||tbl_nme||''',''ID'',"ID"::text, 
			''MASTER addr point RECORD should be Locked'',''1.1.4'' FROM (SELECT A."ID",A."NAME" FROM '||TableForQa||' AS A,'||master_unq_id||' AS B 
			WHERE A."ID"=B.col_id AND B.state_code LIKE LEFT('''||UPPER(tbl_nme)||''',2)) AS C WHERE C."ID"
			NOT IN (SELECT TABLE_ID FROM '||userlock||' WHERE user_id='''||UPPER(user_id)||''')';

			--SELECT "ID","NAME",'GA_POI','ID',"ID"::text, 
			--'MASTER POI RECORD should be Locked','1.1.4' FROM (SELECT A."ID",A."NAME" FROM mmi_v180."GA_POI" AS A,uniqueid_log.master_unq_id AS B 
			--WHERE A."ID"=B.col_id AND B.state_code LIKE LEFT('GA_POI',2)) AS C WHERE C."ID"
			--NOT IN (SELECT TABLE_ID FROM mmi_lock.userlock WHERE user_id='CN002733')
			 
			EXCEPTION
			WHEN OTHERS THEN
			GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
					
			EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
			RAISE info 'error caught 2.1:%',f1;
			RAISE info 'error caught 2.2:%',f2;
		END;
		RAISE INFO 'MASTER addr point RECORD should be Locked';
		RAISE NOTICE 'time spent =%', clock_timestamp() - t;
--1.1.6
-- 123 msec
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT C."ID",'''||tbl_nme||''',''ID'',C."ID"::text,''RECORD NOT FOUND INTO NEWLY ADDED OR MASTER TABLE'',''1.1.6'' 
		FROM (SELECT A."ID",A."NAME" FROM (Select "ID","NAME" FROM '||TableForQa||' 
		WHERE "ID"  BETWEEN 43100001 AND 63100000 OR "ID"  BETWEEN 195338001 AND 199000000) 
		AS A LEFT JOIN '||master_unq_id||' AS B ON A."ID"=B.col_id WHERE B.col_id IS NULL)
		AS C LEFT JOIN '||idlog||' AS D ON C."ID"=D.munid WHERE D.munid IS NULL';
		
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
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'RECORD NOT FOUND INTO NEWLY ADDED OR MASTER TABLE';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
	
--1.1.7
--63 msec
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT A."ID",'''||tbl_nme||''',''ID'',A."ID"::text,''DUPLICATE NEW ADD ID FOUND INTO STATE ''||LEFT(B.editable_table_name,2),''1.1.7''
		FROM '||TableForQa||' A,'||idlog||' B 
		WHERE A."ID"=B.munid AND B.stt_id<>A."STT_ID"';
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	RAISE INFO 'DUPLICATE NEW ADD ID FOUND INTO STATE';
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;
		
	
--2.62.12
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ID'',"ID"::text,''Must not be zero 0'',''2.62.12''
		FROM '||TableForQa||'
		WHERE "ID" IS NULL  ';

        -- SELECT "ID","ID"::text, 'Must not be zero 0','2.62.12' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ID" IS NULL AND "ID" = 0
		
		RAISE INFO '<-----------2.62.12';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
-----------------------------------------------------------------------PREFIX----------------------------------------------------------------------------	
--2.62.90
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''PREFIX'',"PREFIX"::text,''Must not have any special character (Only / and - and , accepted in this column)	'',''2.62.90''
		FROM '||TableForQa||'
		 WHERE ("PREFIX"~''[^0-9A-Za-z\-\,\/]'') ';

        -- SELECT "ID","PREFIX"::text, 'Must not have any special character (Only / and - and , accepted in this column)	','2.62.90' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ("PREFIX"~'[^0-9A-Za-z\-\,\/]');
		
		RAISE INFO '<-----------2.62.90';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.91
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''PREFIX'',"PREFIX"::text,''Must not have double space'',''2.62.91''
		FROM '||TableForQa||'
		WHERE ("PREFIX" LIKE ''%  %'') ';

        -- SELECT "ID","PREFIX"::text, 'Must not have double space','2.62.91' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ("PREFIX" LIKE '%  %');
		
		RAISE INFO '<-----------2.62.91';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.92
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''PREFIX'',"PREFIX"::text,''Must not start with space'',''2.62.92''
		FROM '||TableForQa||'
		WHERE ("PREFIX" LIKE '' %'') ';

        -- SELECT "ID","PREFIX"::text, 'Must not start with space','2.62.92' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ("PREFIX" LIKE ' %');
		
		RAISE INFO '<-----------2.62.92';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.93
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNME_ORG'',"BLDNME_ORG"::text,''Only character and Integer values are accepted'',''2.62.93''
		FROM '||TableForQa||'
		WHERE "PREFIX" ~ ''[A-Za-z0-9]'' = false ';

		
        -- SELECT "ID","PREFIX"::text, 'Only character and Integer values are accepted','2.62.93' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "PREFIX" ~ '[A-Za-z0-9]' = false

		RAISE INFO '<-----------2.62.93';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.137
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''PREFIX'',"PREFIX"::text,''If Saperator is available then Prefix must be available'',''2.62.137''
		FROM '||TableForQa||'
		WHERE COALESCE("SEPARATOR",'''') <>''''  AND  COALESCE("PREFIX",'''') =''''  ';

        -- SELECT "ID","SEPARATOR","PREFIX"::text, 'If Saperator is available then Prefix must be available','2.62.137' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("SEPARATOR",'') <>''  AND  COALESCE("PREFIX",'') ='' 
		
		RAISE INFO '<-----------2.62.137';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.158
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''PREFIX'',"PREFIX"::text,''If last character of prefix is avaialable and it has numeric type values then their should be / as saperator'',''2.62.158''
		FROM '||TableForQa||'
		WHERE RIGHT("PREFIX",1) ~''[0-9]'' AND COALESCE("SEPARATOR",'''') <> ''/'' ';

        -- SELECT "ID","SEPARATOR","PREFIX"::text, 'If last character of prefix is avaialable and it has numeric type values then their should be / as saperator','2.62.158' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE RIGHT("PREFIX",1) ~'[0-9]' AND "SEPARATOR" <> '/'
		
		RAISE INFO '<-----------2.62.158';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.142
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''PREFIX'',"PREFIX"::text,''If value available in this column then Bld_Num must not be null or blank'',''2.62.142''
		FROM '||TableForQa||'
		WHERE COALESCE("PREFIX",'''') <> '''' AND COALESCE("BLDNUM",'''') = '''' ';

        -- SELECT "ID","BLDNUM","PREFIX"::text, 'If value available in this column then Bld_Num must not be null or blank','2.62.142' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("PREFIX",'') <> '' AND COALESCE("BLDNUM",'') = ''
				
		RAISE INFO '<-----------2.62.142';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.159
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''PREFIX'',"PREFIX"::text,''If separator available as - then Prefix should be within values( BOOTH  EWS  HIG  MIG  JRMIG  SRMIG  LIG  SHOP  PLOT  SCF  SCO  OLD  NEW )'',''2.62.159''
		FROM '||TableForQa||'
		WHERE COALESCE("SEPARATOR",'''') = ''-'' AND "PREFIX" NOT IN  (''BOOTH'', ''EWS'', ''HIG'', ''MIG'', ''JRMIG'', ''SRMIG'', ''LIG'', ''SHOP'', ''PLOT'', ''SCF'', ''SCO'', ''OLD'', ''NEW'') ';

        -- SELECT "ID","SEPARATOR","PREFIX"::text, 'If separator available as - then Prefix should be within values( BOOTH  EWS  HIG  MIG  JRMIG  SRMIG  LIG  SHOP  PLOT  SCF  SCO  OLD  NEW )','2.62.159' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("SEPARATOR",'') = '-' AND "PREFIX" NOT IN  ('BOOTH', 'EWS', 'HIG', 'MIG', 'JRMIG', 'SRMIG', 'LIG', 'SHOP', 'PLOT', 'SCF', 'SCO', 'OLD', 'NEW')

				
		RAISE INFO '<-----------2.62.159';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
-------------------------------------------------------------------------------BLDNUM----------------------------------------------------------------------------------------------------------------------------------------------------------------	
--2.62.25
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNUM'',"BLDNUM"::text,'' / AND  - AND(  and  ) AND comma   these character are accepted with number (other special character would not be accepted)'',''2.62.25''
		FROM '||TableForQa||'
		WHERE COALESCE("BLDNUM",'''') <> '''' AND "BLDNUM" !~ ''^[A-Za-z0-9\/\,\-\(\)]'' ';

        -- SELECT "ID","BLDNUM"::text, ' / AND  - AND(  and  ) AND comma   these character are accepted with number (other special character would not be accepted)','2.62.25' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("BLDNUM",'''') <> '''' AND "BLDNUM" !~ '^[A-Za-z0-9\/\,\-\(\)]'

				
		RAISE INFO '<-----------2.62.25';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.26
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNUM'',"BLDNUM"::text,''accepted special character should not be consicutively present in Bldg_Num'',''2.62.26''
		FROM '||TableForQa||'
		WHERE "BLDNUM" ~ ''[/]{2,}|[-]{2,}|[,]{2,}|[(]{2,}|[)]{2,}'' ';

        -- SELECT "ID","BLDNUM","PREFIX"::text, 'accepted special character should not be consicutively present in Bldg_Num','2.62.26' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "BLDNUM" ~ '[/]{2,}|[-]{2,}|[,]{2,}|[(]{2,}|[)]{2,}'

				
		RAISE INFO '<-----------2.62.26';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.27
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNUM'',"BLDNUM"::text,''Must not start with special character or zero and must not be end with special character or special character with zero '',''2.62.27''
		FROM '||TableForQa||'
		WHERE LEFT("BLDNUM",1) ~ ''^[0\/\,\-\(\)]'' OR RIGHT("BLDNUM",1) ~ ''^[\/\,\-\(\)]'' ';

        -- SELECT "ID","BLDNUM","PREFIX"::text, 'POI_ID should be extracted FROM MMI Portal only and should not be 0','2.62.27' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE LEFT("BLDNUM",1) ~ '^[0\/\,\-\(\)]' OR RIGHT("BLDNUM",1) ~ '^[\/\,\-\(\)]'

				
		RAISE INFO '<-----------2.62.27';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.28
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNUM'',"BLDNUM"::text,''should be in upper case'',''2.62.28''
		FROM '||TableForQa||'
		WHERE "BLDNUM" <> UPPER("BLDNUM") ';

        -- SELECT "ID","BLDNUM","PREFIX"::text, 'should be in upper case','2.62.28' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "BLDNUM" <> UPPER("BLDNUM")
				
		RAISE INFO '<-----------2.62.28';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
	
--2.62.30
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNUM'',"BLDNUM"::text,''Check if building number are more than 6 digit'',''2.62.30''
		FROM '||TableForQa||'
		WHERE "BLDNUM" ~ ''^[0-9]{7}'' ';

        -- SELECT "ID","BLDNUM","PREFIX"::text, 'Check if building number are more than 6 digit','2.62.30' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "BLDNUM" ~ '^[0-9]{7}'
				
		RAISE INFO '<-----------2.62.30';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.32
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNUM'',"BLDNUM"::text,''Must not have space'',''2.62.32''
		FROM '||TableForQa||'
		WHERE ("BLDNUM" LIKE ''% %'') ';

        --SELECT "ID","PREFIX"::text, 'Must not have space','2.62.32' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		--WHERE ("BLDNUM" LIKE '% %');
		
		RAISE INFO '<-----------2.62.32';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.33
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNUM'',"BLDNUM"::text,''Must not start with space'',''2.62.33''
		FROM '||TableForQa||'
		WHERE ("BLDNUM" LIKE '' %'') ';

        --SELECT "ID","PREFIX"::text, 'Must not start with space','2.62.33' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		--WHERE ("BLDNUM" LIKE ' %');
		
		RAISE INFO '<-----------2.62.33';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

---------------------------------------------------------NAME,BLDNUM--------------------------------------------------------------------	
--2.62.35
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNUM'',"BLDNUM"::text,''Name, Bld_Num must not be zero'',''2.62.35''
		FROM '||TableForQa||'
		WHERE COALESCE("BLDNUM",'''') = ''0'' and COALESCE("NAME",'''') = ''0'' ';

        -- SELECT "ID","BLDNUM","PREFIX"::text, 'Name, Bld_Num must not be zero','2.62.35' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("BLDNUM",'') = '0' and COALESCE("NAME",'') = '0'
				
		RAISE INFO '<-----------2.62.35';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.36
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNUM'',"BLDNUM"::text,''Name , Bld_Num must not be same'',''2.62.36''
		FROM '||TableForQa||'
		WHERE COALESCE("BLDNUM",'''')<>'''' AND  COALESCE("NAME",'''') <>'''' AND COALESCE("BLDNUM",'''') =  COALESCE("NAME",'''') ';

        -- SELECT "ID","BLDNUM","PREFIX"::text, 'Name , Bld_Num must not be same','2.62.36' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("BLDNUM",'')<>'' AND  COALESCE("NAME",'') <>'' AND   COALESCE("BLDNUM",'') =  COALESCE("NAME",'')
				
		RAISE INFO '<-----------2.62.36';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

-------------------------------------------------------------NAME--------------------------------------------------------------------------------------------------

--2.62.17
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''NAME'',"NAME"::text,''Must not have any special character Except & and single quote or apostrophe'',''2.62.17''
		FROM '||TableForQa||'
		WHERE COALESCE("NAME",'''')<>'''' AND  "NAME" ~ ''[^\s\w&'''']'' ';

        -- SELECT "ID","NAME"::text, 'Must not have any special character axcept & and single quote or apostrophe','2.62.17' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "NAME" ~ '[^\s\w&'' +]'

				
		RAISE INFO '<-----------2.62.17';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.18
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''NAME'',"NAME"::text,''Must not have double space'',''2.62.18''
		FROM '||TableForQa||'
		WHERE ("NAME" LIKE ''%  %'') ';

        -- SELECT "ID","NAME"::text, 'Must not have double space','2.62.18' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ("NAME" LIKE '%  %');
		
		RAISE INFO '<-----------2.62.18';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

--2.62.19
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''NAME'',"NAME"::text,''Must not start with space'',''2.62.19''
		FROM '||TableForQa||'
		WHERE ("NAME" LIKE '' %'') ';

        --SELECT "ID","NAME"::text, 'Must not start with space','2.62.19' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		--WHERE ("NAME" LIKE ' %');
		
		RAISE INFO '<-----------2.62.19';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.138
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''NAME'',"NAME"::text,''Special charecter must not present at start and End of name'',''2.62.138''
		FROM '||TableForQa||'
		WHERE LEFT("NAME",1) !~ ''^[0-9A-Za-z]'' or right("NAME",1) !~ ''^[0-9A-Za-z]'' ';

        -- SELECT "ID","NAME"::text, 'Special charecter must not present at start and End of name','2.62.138' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE LEFT("NAME",1) !~ '^[0-9A-Za-z]' or right("NAME",1) !~ '^[0-9A-Za-z]'

				
		RAISE INFO '<-----------2.62.138';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.147
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''NAME'',"NAME"::text,''All characters must not be in Upper case.'',''2.62.147''
		FROM '||TableForQa||'
		WHERE COALESCE("NAME",'''') <> '''' AND "NAME" = UPPER("NAME") ';

        -- SELECT "ID","NAME"::text, 'All characters must not be in Upper case.','2.62.147' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("NAME",'') <> '' AND "NAME" = UPPER("NAME")

				
		RAISE INFO '<-----------2.62.147';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
	
--2.62.148
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''NAME'',"NAME"::text,''All characters must not be in LOWER case.'',''2.62.148''
		FROM '||TableForQa||'
		WHERE COALESCE("NAME",'''') <> '''' AND "NAME" = LOWER("NAME") ';

        -- SELECT "ID","NAME"::text, 'All characters must not be in LOWER case.','2.62.148' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("NAME",'') <> '' AND "NAME" = LOWER("NAME")

		
		RAISE INFO '<-----------2.62.148';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.149
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''NAME'',"NAME"::text,''Must not be start with lower case'',''2.62.149''
		FROM '||TableForQa||'
		WHERE COALESCE("NAME",'''') <> '''' AND LEFT("NAME",1) ~ ''[a-z]'' ';

        -- SELECT "ID","NAME"::text, 'All characters must not be in LOWER case.','2.62.149' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE  COALESCE("NAME",'') <> '' AND LEFT("NAME",1) ~ '[a-z]'

		
		RAISE INFO '<-----------2.62.149';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.150
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''NAME'',"NAME"::text,''Occurance of Same character thrice and more than thrice'',''2.62.150''
		FROM '||TableForQa||'
		WHERE regexp_replace("NAME",''[0-9/, ]'','''')~''(.)\1{2}'' AND "NAME"~''(.)\1{2}'' ';

        -- SELECT "ID","NAME"::text, 'Occurance of Same character thrice and more than thrice','2.62.150' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE regexp_replace("NAME",'[0-9/, ]','')~'(.)\1{2}' AND "NAME"~'(.)\1{2}'
	

				
		RAISE INFO '<-----------2.62.150';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.136
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''NAME'',"NAME"::text,''Extract the records where charecter length is greater then 95. reveiw the name for these records.'',''2.62.136''
		FROM '||TableForQa||'
		WHERE LENGTH("NAME")>95  ';

		
        -- SELECT "ID","PREFIX"::text, 'Extract the records where charecter length is greater then 95. reveiw the name for these records.','2.62.136' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE LENGTH("NAME")>95

		RAISE INFO '<-----------2.62.136';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.173
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''NAME'',"NAME"::text,''Extract the records where charecter length is greater then 245 including Name Poplr_Nme Alias_1 Alias_2 Alias_3. reveiw the name for these records.'',''2.62.173''
		FROM '||TableForQa||'
		WHERE LENGTH(COALESCE("NAME",'''')||COALESCE("POPLR_NME",'''')||COALESCE("ALIAS_1",'''')||COALESCE("ALIAS_2",'''') ||COALESCE("ALIAS_3",''''))>245 ';

		
        -- SELECT "ID","NAME"::text, 'Extract the records where charecter length is greater then 245 including Name, Poplr_Nme, Alias_1, Alias_2, Alias_3. reveiw the name for these records.','2.62.173' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE LENGTH(COALESCE("NAME",'')||COALESCE("NAME",'')||COALESCE("POPLR_NME",'')||COALESCE("ALIAS_1",'')||COALESCE("ALIAS_2",'') ||COALESCE("ALIAS_3",''))>245

		-- SELECT "ID",LENGTH(COALESCE("NAME",'')||COALESCE("POPLR_NME",'')||COALESCE("ALIAS_1",'')||COALESCE("ALIAS_2",'') ||COALESCE("ALIAS_3",'')) FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE LENGTH(COALESCE("NAME",'')||COALESCE("NAME",'')||COALESCE("POPLR_NME",'')||COALESCE("ALIAS_1",'')||COALESCE("ALIAS_2",'') ||COALESCE("ALIAS_3",''))>245

		RAISE INFO '<-----------2.62.173';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
		
	
	
---------------------------------------------------------------------FTR_CRY----------------------------------------------------------------	
--2.62.161
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''FTR_CRY'',"FTR_CRY"::text,''Category code must be in capital letters'',''2.62.161''
		FROM '||TableForQa||'
		WHERE "FTR_CRY" <> UPPER("FTR_CRY") ';

        -- SELECT "ID","FTR_CRY"::text, 'Category code must be in capital letters','2.62.161' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "FTR_CRY" <> UPPER("FTR_CRY")

				
		RAISE INFO '<-----------2.62.161';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.162
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''FTR_CRY'',"FTR_CRY"::text,''Must be of six characters'',''2.62.162''
		FROM '||TableForQa||'
		WHERE Length("FTR_CRY") <> 6 ';

        -- SELECT "ID","FTR_CRY"::text,'Must be of six characters','2.62.162' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE Length("FTR_CRY") <> 6

				
		RAISE INFO '<-----------2.62.162';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.163
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''FTR_CRY'',"FTR_CRY"::text,''Category must not be blank'',''2.62.162''
		FROM '||TableForQa||'
		WHERE COALESCE("FTR_CRY",'''') = '''' ';

        -- SELECT "ID","FTR_CRY"::text,'Category must not be blank','2.62.163' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("FTR_CRY",'') = '' 

				
		RAISE INFO '<-----------2.62.163';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
---------------------------------------------------------SUB_CRY--------------------------------------------------------------------------	
--2.62.166
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''SUB_CRY'',"SUB_CRY"::text,''Must not be Null or Blank and must be in capital letters'',''2.62.166''
		FROM '||TableForQa||'
		WHERE COALESCE("SUB_CRY",'''') = '''' AND "SUB_CRY" <> UPPER("SUB_CRY") ';

        -- SELECT "ID","SUB_CRY"::text, 'Must not be Null or Blank and must be in capital letters','2.62.166' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("SUB_CRY",'') = '' AND "SUB_CRY" <> UPPER("SUB_CRY")

				
		RAISE INFO '<-----------2.62.166';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.167
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''SUB_CRY'',"SUB_CRY"::text,''Must be of six characters'',''2.62.167''
		FROM '||TableForQa||'
		WHERE Length("SUB_CRY") <> 6 ';

        -- SELECT "ID","SUB_CRY"::text,'Must be of six characters','2.62.167' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE Length("SUB_CRY") <> 6

				
		RAISE INFO '<-----------2.62.167';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
-------------------------------------------------------------POPLR_NME-----------------------------------------------------------------------------------------------
--2.62.168.1
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''Must not match with Name'',''2.62.168.1''
		FROM '||TableForQa||'
		WHERE ((COALESCE("POPLR_NME",'''')<>'''') AND (LOWER(TRIM("POPLR_NME")) LIKE LOWER(TRIM("NAME")) )) ';

        -- SELECT "ID","POPLR_NME"::text, 'Must not match with Name','2.62.168.1' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ((COALESCE("POPLR_NME",'')<>'') AND (LOWER(TRIM("POPLR_NME")) LIKE LOWER(TRIM("NAME")) ))

	
		RAISE INFO '<-----------2.62.168.1';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.168.2
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''Must not match with alias_1'',''2.62.168.2''
		FROM '||TableForQa||'
		WHERE ((COALESCE("POPLR_NME",'''')<>'''') AND (LOWER(TRIM("POPLR_NME")) LIKE LOWER(TRIM("ALIAS_1")) )) ';

        -- SELECT "ID","POPLR_NME"::text, 'Must not match with ALIAS_1','2.62.168.1' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ((COALESCE("POPLR_NME",'')<>'') AND (LOWER(TRIM("POPLR_NME")) LIKE LOWER(TRIM("ALIAS_1")) ))

	
		RAISE INFO '<-----------2.62.168.2';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.168.3
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''Must not match with alias_2'',''2.62.168.3''
		FROM '||TableForQa||'
		WHERE ((COALESCE("POPLR_NME",'''')<>'''') AND (LOWER(TRIM("POPLR_NME")) LIKE LOWER(TRIM("ALIAS_2")) )) ';

        -- SELECT "ID","POPLR_NME"::text, 'Must not match with ALIAS_2','2.62.168.3' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ((COALESCE("POPLR_NME",'')<>'') AND (LOWER(TRIM("POPLR_NME")) LIKE LOWER(TRIM("ALIAS_2")) ))

	
		RAISE INFO '<-----------2.62.168.3';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.168.4
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''Must not match with alias_2'',''2.62.168.4''
		FROM '||TableForQa||'
		WHERE ((COALESCE("POPLR_NME",'''')<>'''') AND (LOWER(TRIM("POPLR_NME")) LIKE LOWER(TRIM("ALIAS_3")) )) ';

        -- SELECT "ID","POPLR_NME"::text, 'Must not match with ALIAS_2','2.62.168.4' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ((COALESCE("POPLR_NME",'')<>'') AND (LOWER(TRIM("POPLR_NME")) LIKE LOWER(TRIM("ALIAS_3")) ))

	
		RAISE INFO '<-----------2.62.168.4';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.169
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''Must not have special character except &'',''2.62.169''
		FROM '||TableForQa||'
		WHERE ("POPLR_NME" ~ ''[^A-Za-z0-9&\\s]'')';

		--Changed By Bhupesh On 23092019
		-- SELECT "ID","POPLR_NME"::text, 'Must not have special character except &','2.62.169' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ("POPLR_NME" ~ '[^A-Za-z0-9&\\s]')=FALSE

        -- SELECT "ID","POPLR_NME"::text, 'Must not have special character except &','2.62.169' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "POPLR_NME" ~ '[^A-Za-z0-9&]'

	
		RAISE INFO '<-----------2.62.169';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.170
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''Double Spaces are not allowed'',''2.62.170''
		FROM '||TableForQa||'
		WHERE "POPLR_NME" LIKE ''%  %'' ';

        -- SELECT "ID","POPLR_NME"::text, 'Double Spaces are not allowed &','2.62.170' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "POPLR_NME" LIKE '%  %'

	
		RAISE INFO '<-----------2.62.170';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.171
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''Start spaces and end spaces are not allowed'',''2.62.171''
		FROM '||TableForQa||'
		WHERE "POPLR_NME" LIKE '' %'' OR "POPLR_NME" LIKE ''% '' ';

        -- SELECT "ID","POPLR_NME"::text, 'Start spaces and end spaces are not allowed','2.62.171' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "POPLR_NME" LIKE ' %' OR "POPLR_NME" LIKE '% ' 

	
		RAISE INFO '<-----------2.62.171';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.174
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''Must not have repeatative special character like &'',''2.62.174''
		FROM '||TableForQa||'
		WHERE "POPLR_NME" ~ ''[&]{2,}''';

        -- SELECT "ID","POPLR_NME"::text, 'Must not have repeatative special character like &','2.62.174' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE"POPLR_NME" ~ '[&]{2,}'

	
		RAISE INFO '<-----------2.62.174';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.175
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''Special charecter must not present at start and End of name'',''2.62.175''
		FROM '||TableForQa||'
		WHERE LEFT("POPLR_NME",1) !~ ''^[0-9A-Za-z]'' or right("POPLR_NME",1) !~ ''^[0-9A-Za-z]'' ';

        -- SELECT "ID","POPLR_NME"::text, 'Special charecter must not present at start and End of name','2.62.175' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE LEFT("POPLR_NME",1) !~ '^[0-9A-Za-z]' or right("POPLR_NME",1) !~ '^[0-9A-Za-z]'

				
		RAISE INFO '<-----------2.62.175';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.176
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''All characters must be in Proper case'',''2.62.176''
		FROM '||TableForQa||'
		WHERE "POPLR_NME" <> INITCAP("POPLR_NME") ';

        -- SELECT "ID","POPLR_NME"::text, 'All characters must be in Proper case','2.62.176' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "POPLR_NME" <> INITCAP("POPLR_NME")
	
		RAISE INFO '<-----------2.62.176';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.177
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''All character must not be in lower case.'',''2.62.177''
		FROM '||TableForQa||'
		WHERE "POPLR_NME" = LOWER("POPLR_NME") ';

        -- SELECT "ID","POPLR_NME"::text, 'All character must not be in lower case.','2.62.177' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "POPLR_NME" = LOWER("POPLR_NME")
	
		RAISE INFO '<-----------2.62.177';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.178
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''Must not be start with lower case'',''2.62.178''
		FROM '||TableForQa||'
		WHERE COALESCE("POPLR_NME",'''') <> '''' AND LEFT("POPLR_NME",1) ~ ''[a-z]'' ';

        -- SELECT "ID","NAME"::text, 'All characters must not be in LOWER case.','2.62.178' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE  COALESCE("POPLR_NME",'') <> '' AND LEFT("POPLR_NME",1) ~ '[a-z]'

		
		RAISE INFO '<-----------2.62.178';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.179
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''Occurance of Same character thrice and more than thrice'',''2.62.179''
		FROM '||TableForQa||'
		WHERE regexp_replace("POPLR_NME",''[0-9/, ]'','''')~''(.)\1{2}'' AND "POPLR_NME"~''(.)\1{2}'' ';

        -- SELECT "ID","POPLR_NME"::text, 'Occurance of Same character thrice and more than thrice','2.62.179' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE regexp_replace("POPLR_NME",'[0-9/, ]','')~'(.)\1{2}' AND "POPLR_NME"~'(.)\1{2}'

				
		RAISE INFO '<-----------2.62.179';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
--2.62.180
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''One character Name must not be allowed'',''2.62.180''
		FROM '||TableForQa||'
		WHERE length("POPLR_NME") = 1 ';

        -- SELECT "ID","POPLR_NME"::text, 'One character Name must not be allowed','2.62.180' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE length("POPLR_NME") = 1
	
		RAISE INFO '<-----------2.62.180';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.172
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''POPLR_NME'',"POPLR_NME"::text,''Extract the records where charecter length is greater than 95'',''2.62.172''
		FROM '||TableForQa||'
		WHERE LENGTH("POPLR_NME")>95  ';

		
        -- SELECT "ID","POPLR_NME"::text, 'Extract the records where charecter length is greater than 95','2.62.172' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE LENGTH("POPLR_NME")>95

		RAISE INFO '<-----------2.62.172';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--------------------------------------------------------------ALIAS_1---------------------------------------------------------------------------------	

--2.62.181.1
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1"::text,''Must not match with Name'',''2.62.181.1''
		FROM '||TableForQa||'
		WHERE ((COALESCE("ALIAS_1",'''')<>'''') AND (LOWER(TRIM("ALIAS_1")) LIKE LOWER(TRIM("NAME")) )) ';

        -- SELECT "ID","ALIAS_1"::text, 'Must not match with Name','2.62.181.1' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ((COALESCE("ALIAS_1",'')<>'') AND (LOWER(TRIM("ALIAS_1")) LIKE LOWER(TRIM("NAME")) ))

	
		RAISE INFO '<-----------2.62.181.1';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.181.2
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1"::text,''Must not match with POPLR_NME'',''2.62.181.2''
		FROM '||TableForQa||'
		WHERE ((COALESCE("ALIAS_1",'''')<>'''') AND (LOWER(TRIM("ALIAS_1")) LIKE LOWER(TRIM("POPLR_NME")) )) ';

        -- SELECT "ID","POPLR_NME"::text, 'Must not match with ALIAS_1','2.62.181.1' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ((COALESCE("POPLR_NME",'')<>'') AND (LOWER(TRIM("POPLR_NME")) LIKE LOWER(TRIM("ALIAS_1")) ))

	
		RAISE INFO '<-----------2.62.181.2';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.181.3
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1"::text,''Must not match with alias_2'',''2.62.181.3''
		FROM '||TableForQa||'
		WHERE ((COALESCE("ALIAS_1",'''')<>'''') AND (LOWER(TRIM("ALIAS_1")) LIKE LOWER(TRIM("ALIAS_2")) )) ';

        -- SELECT "ID","ALIAS_1"::text, 'Must not match with ALIAS_2','2.62.181.3' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ((COALESCE("ALIAS_1",'')<>'') AND (LOWER(TRIM("ALIAS_1")) LIKE LOWER(TRIM("ALIAS_2")) ))

	
		RAISE INFO '<-----------2.62.181.3';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.181.4
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1"::text,''Must not match with alias_3'',''2.62.181.4''
		FROM '||TableForQa||'
		WHERE ((COALESCE("ALIAS_1",'''')<>'''') AND (LOWER(TRIM("ALIAS_1")) LIKE LOWER(TRIM("ALIAS_3")) )) ';

        -- SELECT "ID","ALIAS_1"::text, 'Must not match with ALIAS_2','2.62.181.4' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ((COALESCE("ALIAS_1",'')<>'') AND (LOWER(TRIM("ALIAS_1")) LIKE LOWER(TRIM("ALIAS_3")) ))

	
		RAISE INFO '<-----------2.62.181.4';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.182
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1"::text,''Must not have special character except &'',''2.62.182''
		FROM '||TableForQa||'
		WHERE ("ALIAS_1" ~ ''[^A-Za-z0-9&\\s]'')';

		--Changed By Bhupesh On 23092019
		-- SELECT "ID","ALIAS_1"::text, 'Must not have special character except &','2.62.182' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ("ALIAS_1" ~ '[^A-Za-z0-9&\s]')

        -- SELECT "ID","ALIAS_1"::text, 'Must not have special character except &','2.62.182' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ALIAS_1" ~ '[^A-Za-z0-9&]'

	
		RAISE INFO '<-----------2.62.182';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.183
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1"::text,''Double Spaces are not allowed'',''2.62.183''
		FROM '||TableForQa||'
		WHERE "ALIAS_1" LIKE ''%  %'' ';

        -- SELECT "ID","ALIAS_1"::text, 'Double Spaces are not allowed &','2.62.183' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ALIAS_1" LIKE '%  %'

	
		RAISE INFO '<-----------2.62.183';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
--2.62.185
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1"::text,''Must not have repeatative special character like &'',''2.62.185''
		FROM '||TableForQa||'
		WHERE "ALIAS_1" ~ ''[&]{2,}''';

        -- SELECT "ID","ALIAS_1"::text, 'Must not have repeatative special character like &','2.62.185' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE"ALIAS_1" ~ '[&]{2,}'

	
		RAISE INFO '<-----------2.62.185';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.186
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1"::text,''Special charecter must not present at start and End of name'',''2.62.186''
		FROM '||TableForQa||'
		WHERE LEFT("ALIAS_1",1) !~ ''^[0-9A-Za-z]'' or right("ALIAS_1",1) !~ ''^[0-9A-Za-z]'' ';

        -- SELECT "ID","ALIAS_1"::text, 'Special charecter must not present at start and End of name','2.62.186' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE LEFT("ALIAS_1",1) !~ '^[0-9A-Za-z]' or right("ALIAS_1",1) !~ '^[0-9A-Za-z]'

				
		RAISE INFO '<-----------2.62.186';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

--2.62.187
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1"::text,''All character must not be in UPPER case.'',''2.62.187''
		FROM '||TableForQa||'
		WHERE "ALIAS_1" = UPPER("ALIAS_1") ';

        -- SELECT "ID","ALIAS_1"::text, 'All character must not be in lower case.','2.62.187' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ALIAS_1" = UPPER("ALIAS_1")
	
		RAISE INFO '<-----------2.62.187';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.188
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1"::text,''All character must not be in lower case.'',''2.62.188''
		FROM '||TableForQa||'
		WHERE "ALIAS_1" = LOWER("ALIAS_1")';

        -- SELECT "ID","ALIAS_1"::text, 'All character must not be in lower case.','2.62.188' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ALIAS_1" = LOWER("ALIAS_1")
	
		RAISE INFO '<-----------2.62.188';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.189
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1"::text,''Must not be start with lower case'',''2.62.189''
		FROM '||TableForQa||'
		WHERE COALESCE("ALIAS_1",'''') <> '''' AND LEFT("ALIAS_1",1) ~ ''[a-z]'' ';

        -- SELECT "ID","NAME"::text, 'All characters must not be in LOWER case.','2.62.189' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE  COALESCE("ALIAS_1",'') <> '' AND LEFT("ALIAS_1",1) ~ '[a-z]'

		
		RAISE INFO '<-----------2.62.189';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.190
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1"::text,''Occurance of Same character thrice and more than thrice'',''2.62.190''
		FROM '||TableForQa||'
		WHERE regexp_replace("ALIAS_1",''[0-9/, ]'','''')~''(.)\1{2}'' AND "ALIAS_1"~''(.)\1{2}'' ';

        -- SELECT "ID","ALIAS_1"::text, 'Occurance of Same character thrice and more than thrice','2.62.190' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE regexp_replace("ALIAS_1",'[0-9/, ]','')~'(.)\1{2}' AND "ALIAS_1"~'(.)\1{2}'

				
		RAISE INFO '<-----------2.62.190';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
--2.62.191
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_1'',"ALIAS_1"::text,''One character Name must not be allowed'',''2.62.191''
		FROM '||TableForQa||'
		WHERE length("ALIAS_1") = 1 ';

        -- SELECT "ID","ALIAS_1"::text, 'One character Name must not be allowed','2.62.191' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE length("ALIAS_1") = 1
	
		RAISE INFO '<-----------2.62.191';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

----------------------------------------------------------ALIAS_2---------------------------------------------------------------------------	
	
--2.62.192.1
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2"::text,''Must not match with Name'',''2.62.192.1''
		FROM '||TableForQa||'
		WHERE ((COALESCE("ALIAS_2",'''')<>'''') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("NAME")) )) ';

        -- SELECT "ID","ALIAS_2"::text, 'Must not match with Name','2.62.192.1' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ((COALESCE("ALIAS_2",'')<>'') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("NAME")) ))

	
		RAISE INFO '<-----------2.62.192.1';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.192.2
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2"::text,''Must not match with POPLR_NME'',''2.62.192.2''
		FROM '||TableForQa||'
		WHERE ((COALESCE("ALIAS_2",'''')<>'''') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("POPLR_NME")) )) ';

        -- SELECT "ID","ALIAS_2"::text, 'Must not match with ALIAS_1','2.62.192.1' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ((COALESCE("ALIAS_2",'')<>'') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("POPLR_NME")) ))

	
		RAISE INFO '<-----------2.62.192.2';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.192.3
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2"::text,''Must not match with alias_1'',''2.62.192.3''
		FROM '||TableForQa||'
		WHERE ((COALESCE("ALIAS_2",'''')<>'''') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("ALIAS_1")) )) ';

        -- SELECT "ID","ALIAS_2"::text, 'Must not match with ALIAS_2','2.62.192.3' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ((COALESCE("ALIAS_2",'')<>'') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("ALIAS_1")) ))

	
		RAISE INFO '<-----------2.62.192.3';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.192.4
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2"::text,''Must not match with alias_3'',''2.62.192.4''
		FROM '||TableForQa||'
		WHERE ((COALESCE("ALIAS_2",'''')<>'''') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("ALIAS_3")) )) ';

        -- SELECT "ID","ALIAS_2"::text, 'Must not match with ALIAS_2','2.62.192.4' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ((COALESCE("ALIAS_2",'')<>'') AND (LOWER(TRIM("ALIAS_2")) LIKE LOWER(TRIM("ALIAS_3")) ))

	
		RAISE INFO '<-----------2.62.192.4';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.193
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2"::text,''Must not have special character except &'',''2.62.193''
		FROM '||TableForQa||'
		WHERE ("ALIAS_2" ~ ''[^A-Za-z0-9&\\s]'')';

		--Changed By Bhupesh On 23092019
		-- SELECT "ID","ALIAS_2"::text, 'Must not have special character except &','2.62.193' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ("ALIAS_2" ~ '[^A-Za-z0-9&\s]')

        -- SELECT "ID","ALIAS_2"::text, 'Must not have special character except &','2.62.193' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ALIAS_2" ~ '[^A-Za-z0-9&]'

	
		RAISE INFO '<-----------2.62.193';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.194
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2"::text,''Double Spaces are not allowed'',''2.62.194''
		FROM '||TableForQa||'
		WHERE "ALIAS_2" LIKE ''%  %'' ';

        -- SELECT "ID","ALIAS_2"::text, 'Double Spaces are not allowed &','2.62.194' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ALIAS_2" LIKE '%  %'

	
		RAISE INFO '<-----------2.62.194';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
--2.62.196
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2"::text,''Must not have repeatative special character like &'',''2.62.196''
		FROM '||TableForQa||'
		WHERE "ALIAS_2" ~ ''[&]{2,}''';

        -- SELECT "ID","ALIAS_2"::text, 'Must not have repeatative special character like &','2.62.196' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE"ALIAS_2" ~ '[&]{2,}'

	
		RAISE INFO '<-----------2.62.196';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.197
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2"::text,''Special charecter must not present at start and End of name'',''2.62.197''
		FROM '||TableForQa||'
		WHERE LEFT("ALIAS_2",1) !~ ''^[0-9A-Za-z]'' or right("ALIAS_2",1) !~ ''^[0-9A-Za-z]'' ';

        -- SELECT "ID","ALIAS_2"::text, 'Special charecter must not present at start and End of name','2.62.197' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE LEFT("ALIAS_2",1) !~ '^[0-9A-Za-z]' or right("ALIAS_2",1) !~ '^[0-9A-Za-z]'

				
		RAISE INFO '<-----------2.62.197';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

--2.62.198
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2"::text,''All character must not be in UPPER case.'',''2.62.198''
		FROM '||TableForQa||'
		WHERE "ALIAS_2" = UPPER("ALIAS_2") ';

        -- SELECT "ID","ALIAS_2"::text, 'All character must not be in lower case.','2.62.198' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ALIAS_2" = UPPER("ALIAS_2")
	
		RAISE INFO '<-----------2.62.198';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.199
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2"::text,''All character must not be in lower case.'',''2.62.199''
		FROM '||TableForQa||'
		WHERE "ALIAS_2" = LOWER("ALIAS_2") ';

        -- SELECT "ID","ALIAS_2"::text, 'All character must not be in lower case.','2.62.199' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ALIAS_2" = LOWER("ALIAS_2")
	
		RAISE INFO '<-----------2.62.199';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.200
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2"::text,''Must not be start with lower case'',''2.62.200''
		FROM '||TableForQa||'
		WHERE COALESCE("ALIAS_2",'''') <> '''' AND LEFT("ALIAS_2",1) ~ ''[a-z]'' ';

        -- SELECT "ID","NAME"::text, 'All characters must not be in LOWER case.','2.62.200' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE  COALESCE("ALIAS_2",'') <> '' AND LEFT("ALIAS_2",1) ~ '[a-z]'

		
		RAISE INFO '<-----------2.62.200';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.201
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2"::text,''Occurance of Same character thrice and more than thrice'',''2.62.201''
		FROM '||TableForQa||'
		WHERE regexp_replace("ALIAS_2",''[0-9/, ]'','''')~''(.)\1{2}'' AND "ALIAS_2"~''(.)\1{2}'' ';

        -- SELECT "ID","ALIAS_2"::text, 'Occurance of Same character thrice and more than thrice','2.62.201' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE regexp_replace("ALIAS_2",'[0-9/, ]','')~'(.)\1{2}' AND "ALIAS_2"~'(.)\1{2}'

				
		RAISE INFO '<-----------2.62.201';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
--2.62.202
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_2'',"ALIAS_2"::text,''One character Name must not be allowed'',''2.62.202''
		FROM '||TableForQa||'
		WHERE length("ALIAS_2") = 1 ';

        -- SELECT "ID","ALIAS_2"::text, 'One character Name must not be allowed','2.62.202' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE length("ALIAS_2") = 1
	
		RAISE INFO '<-----------2.62.202';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

-------------------------------------------------------------ALIAS_3---------------------------------------------------------------------------	
	
--2.62.203.1
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text,''Must not match with Name'',''2.62.203.1''
		FROM '||TableForQa||'
		WHERE ((COALESCE("ALIAS_3",'''')<>'''') AND (LOWER(TRIM("ALIAS_3")) LIKE LOWER(TRIM("NAME")) )) ';

        -- SELECT "ID","ALIAS_3"::text, 'Must not match with Name','2.62.203.1' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ((COALESCE("ALIAS_3",'')<>'') AND (LOWER(TRIM(ALIAS_3)) LIKE LOWER(TRIM("NAME")) ))

	
		RAISE INFO '<-----------2.62.203.1';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.203.2
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text,''Must not match with POPLR_NME'',''2.62.203.2''
		FROM '||TableForQa||'
		WHERE ((COALESCE("ALIAS_3",'''')<>'''') AND (LOWER(TRIM("ALIAS_3")) LIKE LOWER(TRIM("POPLR_NME")) )) ';

        -- SELECT "ID","ALIAS_3"::text, 'Must not match with ALIAS_1','2.62.203.1' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ((COALESCE("ALIAS_3",'')<>'') AND (LOWER(TRIM("ALIAS_3")) LIKE LOWER(TRIM("POPLR_NME")) ))

	
		RAISE INFO '<-----------2.62.203.2';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.203.3
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text,''Must not match with alias_1'',''2.62.203.3''
		FROM '||TableForQa||'
		WHERE ((COALESCE("ALIAS_3",'''')<>'''') AND (LOWER(TRIM("ALIAS_3")) LIKE LOWER(TRIM("ALIAS_1")) )) ';

        -- SELECT "ID","ALIAS_3"::text, 'Must not match with ALIAS_3','2.62.203.3' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ((COALESCE("ALIAS_3",'')<>'') AND (LOWER(TRIM("ALIAS_3")) LIKE LOWER(TRIM("ALIAS_1")) ))

	
		RAISE INFO '<-----------2.62.203.3';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.203.4
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text,''Must not match with alias_2'',''2.62.203.4''
		FROM '||TableForQa||'
		WHERE ((COALESCE("ALIAS_3",'''')<>'''') AND (LOWER(TRIM("ALIAS_3")) LIKE LOWER(TRIM("ALIAS_2")) )) ';

        -- SELECT "ID","ALIAS_3"::text, 'Must not match with ALIAS_3','2.62.203.4' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ((COALESCE("ALIAS_3",'')<>'') AND (LOWER(TRIM("ALIAS_3")) LIKE LOWER(TRIM("ALIAS_2")) ))

	
		RAISE INFO '<-----------2.62.203.4';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.204
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text,''Must not have special character except &'',''2.62.204''
		FROM '||TableForQa||'
		WHERE "ALIAS_3" ~ ''[^A-Za-z0-9&]'' ';

        -- SELECT "ID","ALIAS_3"::text, 'Must not have special character except &','2.62.204' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ALIAS_3" ~ '[^A-Za-z0-9&]'

	
		RAISE INFO '<-----------2.62.204';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.205
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text,''Double Spaces are not allowed'',''2.62.205''
		FROM '||TableForQa||'
		WHERE "ALIAS_3" LIKE ''%  %'' ';

        -- SELECT "ID","ALIAS_3"::text, 'Double Spaces are not allowed &','2.62.205' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ALIAS_3" LIKE '%  %'

	
		RAISE INFO '<-----------2.62.205';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
--2.62.207
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text,''Must not have repeatative special character like &'',''2.62.207''
		FROM '||TableForQa||'
		WHERE "ALIAS_3" ~ ''[&]{2,}'' ';

        -- SELECT "ID","ALIAS_3"::text, 'Must not have repeatative special character like &','2.62.207' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE"ALIAS_3" ~ '[&]{2,}'

	
		RAISE INFO '<-----------2.62.207';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.208
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text,''Special charecter must not present at start and End of name'',''2.62.208''
		FROM '||TableForQa||'
		WHERE LEFT("ALIAS_3",1) !~ ''^[0-9A-Za-z]'' or right("ALIAS_3",1) !~ ''^[0-9A-Za-z]'' ';

        -- SELECT "ID","ALIAS_3"::text, 'Special charecter must not present at start and End of name','2.62.208' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE LEFT("ALIAS_3",1) !~ '^[0-9A-Za-z]' or right("ALIAS_3",1) !~ '^[0-9A-Za-z]'

				
		RAISE INFO '<-----------2.62.208';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

--2.62.209
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text,''All character must not be in UPPER case.'',''2.62.209''
		FROM '||TableForQa||'
		WHERE "ALIAS_3" = UPPER("ALIAS_3") ';

        -- SELECT "ID","ALIAS_3"::text, 'All character must not be in lower case.','2.62.209' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ALIAS_3" = UPPER("ALIAS_3")
	
		RAISE INFO '<-----------2.62.209';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.210
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text,''All character must not be in lower case.'',''2.62.210''
		FROM '||TableForQa||'
		WHERE "ALIAS_3" = LOWER("ALIAS_3") ';

        -- SELECT "ID","ALIAS_3"::text, 'All character must not be in lower case.','2.62.210' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ALIAS_3" = LOWER("ALIAS_3")
	
		RAISE INFO '<-----------2.62.210';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.211
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text,''Must not be start with lower case'',''2.62.211''
		FROM '||TableForQa||'
		WHERE COALESCE("ALIAS_3",'''') <> '''' AND LEFT("ALIAS_3",1) ~ ''[a-z]'' ';

        -- SELECT "ID","NAME"::text, 'All characters must not be in LOWER case.','2.62.211' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE  COALESCE("ALIAS_3",'') <> '' AND LEFT("ALIAS_3",1) ~ '[a-z]'

		
		RAISE INFO '<-----------2.62.211';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.212
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text,''Occurance of Same character thrice and more than thrice'',''2.62.212''
		FROM '||TableForQa||'
		WHERE regexp_replace("ALIAS_3",''[0-9/, ]'','''')~''(.)\1{2}'' AND "ALIAS_3"~''(.)\1{2}'' ';

        -- SELECT "ID","ALIAS_3"::text, 'Occurance of Same character thrice and more than thrice','2.62.212' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE regexp_replace("ALIAS_3",'[0-9/, ]','')~'(.)\1{2}' AND "ALIAS_3"~'(.)\1{2}'

				
		RAISE INFO '<-----------2.62.212';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
--2.62.213
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ALIAS_3'',"ALIAS_3"::text,''One character Name must not be allowed'',''2.62.213''
		FROM '||TableForQa||'
		WHERE length("ALIAS_3") = 1 ';

        -- SELECT "ID","ALIAS_3"::text, 'One character Name must not be allowed','2.62.213' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE length("ALIAS_3") = 1
	
		RAISE INFO '<-----------2.62.213';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
-----------------------------------------------------------EDGE_SIDE-----------------------------------------------------------------------------
	
--2.62.50
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''EDGE_SIDE'',"EDGE_SIDE"::text,''Only L and R values are accepted'',''2.62.50''
		FROM '||TableForQa||'
		WHERE coalesce("EDGE_SIDE",'''')<>'''' AND (COALESCE("EDGE_SIDE",'''')<>''L'') AND (COALESCE("EDGE_SIDE",'''')<>''R'') ';

        -- SELECT "ID","EDGE_SIDE"::text, 'Only L and R values are accepted','2.62.50' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE (COALESCE("EDGE_SIDE",'''')<>''L'') AND (COALESCE("EDGE_SIDE",'''')<>''R'')
	
		RAISE INFO '<-----------2.62.50';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
--2.62.51
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''EDGE_SIDE'',"EDGE_SIDE"::text,''Must not be blank'',''2.62.51''
		FROM '||TableForQa||'
		WHERE COALESCE("EDGE_SIDE",'''') = '''' ';

        -- SELECT "ID","EDGE_SIDE"::text, 'Must not be blank','2.62.51' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("EDGE_SIDE",'') = ''
	
		RAISE INFO '<-----------2.62.51';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
--2.62.52
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''EDGE_SIDE'',"EDGE_SIDE"::text,''Must be in capital letter'',''2.62.52''
		FROM '||TableForQa||'
		WHERE "EDGE_SIDE" <> UPPER("EDGE_SIDE") ';

        -- SELECT "ID","EDGE_SIDE"::text, 'Must be in capital letter','2.62.52' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "EDGE_SIDE" <> UPPER("EDGE_SIDE") 
	
		RAISE INFO '<-----------2.62.52';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;		

-----------------------------------------------------------------STT_ID----------------------------------------------------------------------------------	

--2.62.52
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''STT_ID'',"STT_ID"::text,''Must not be zero 0 or blank'',''2.62.52''
		FROM '||TableForQa||'
		WHERE "STT_ID" = 0 AND "STT_ID" IS NULL ';

        -- SELECT "ID","STT_ID"::text, 'Must be in capital letter','2.62.52' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "STT_ID" = 0 AND "STT_ID" IS NULL
	
		RAISE INFO '<-----------2.62.52';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
---------------------------------------------------------------------ADDRESS------------------------------------------------------------------------------------------	
--2.62.214
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ADDRESS'',"ADDRESS"::text,''Must not have special character except / - comma and &'',''2.62.214''
		FROM '||TableForQa||'
		WHERE ("ADDRESS" ~ ''[^A-Za-z0-9\/\-\&\,\s]'')';

		--Changed By Bhupesh On 23092019
        -- SELECT "ID","ADDRESS"::text, 'Must not have special character except / - comma and &','2.62.214' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ("ADDRESS" ~ '[^A-Za-z0-9\/\-\&\,\s])'

		-- SELECT "ID","ADDRESS"::text, 'Must not have special character except / - comma and &','2.62.214' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ("ADDRESS" ~ '[^A-Za-z0-9\/\-\&\,])'
	
		RAISE INFO '<-----------2.62.214';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.215
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ADDRESS'',"ADDRESS"::text,''Must not have Roman Numbers'',''2.62.215''
		FROM '||TableForQa||'
		WHERE "ADDRESS"~''[MDCLXVI]+$'' AND COALESCE("ADDRESS",'''')<>'''' ';

        -- SELECT "ID","ADDRESS"::text, 'Must not have Roman Numbers','2.62.215' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ADDRESS" ~ '[^A-Za-z0-9\/\-\&\,]'
	
		RAISE INFO '<-----------2.62.215';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

--2.62.216
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ADDRESS'',"ADDRESS"::text,''Extract the records where charecter length is greater then 95. reveiw the name for these records.'',''2.62.216''
		FROM '||TableForQa||'
		WHERE LENGTH("ADDRESS")>95 ';

        -- SELECT "ID","ADDRESS"::text, 'Extract the records where charecter length is greater then 95. reveiw the name for these records.','2.62.216' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE LENGTH("ADDRESS")>95
	
		RAISE INFO '<-----------2.62.216';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
--2.62.217
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ADDRESS'',"ADDRESS"::text,''Must not have repeatative special character'',''2.62.217''
		FROM '||TableForQa||'
		WHERE "ADDRESS" ~ ''[/]{2,}|[-]{2,}|[,]{2,}|[&]{2,}'' ';

        -- SELECT "ID","ADDRESS"::text, 'Must not have repeatative special character','2.62.217' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ADDRESS" ~ '[/]{2,}|[-]{2,}|[,]{2,}|[&]{2,}'
	
		RAISE INFO '<-----------2.62.217';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.218
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ADDRESS'',"ADDRESS"::text,''Special charecter must not present at start and End of name'',''2.62.218''
		FROM '||TableForQa||'
		WHERE LEFT("ADDRESS",1) !~ ''^[0-9A-Za-z]'' or right("ADDRESS",1) !~ ''^[0-9A-Za-z]'' ';

        -- SELECT "ID","ADDRESS"::text, 'Special charecter must not present at start and End of name','2.62.218' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE LEFT("ADDRESS",1) !~ '^[0-9A-Za-z]' or right("ADDRESS",1) !~ '^[0-9A-Za-z]'

				
		RAISE INFO '<-----------2.62.218';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
--2.62.219
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ADDRESS'',"ADDRESS"::text,''Left space right space and double space must not be avilable in this column.'',''2.62.219''
		FROM '||TableForQa||'
		WHERE "ADDRESS" LIKE '' %'' OR "ADDRESS" LIKE ''% '' OR "ADDRESS" LIKE ''%  %'' ';

        -- SELECT "ID","ADDRESS"::text, 'Left space, right space and double space must not be avilable in this column.','2.62.219' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ADDRESS" LIKE ' %' OR "ADDRESS" LIKE '% ' OR "ADDRESS" LIKE '%  %'
	
		RAISE INFO '<-----------2.62.219';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

--2.62.220
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ADDRESS'',"ADDRESS"::text,''All character must not be in UPPER case.'',''2.62.220''
		FROM '||TableForQa||'
		WHERE "ADDRESS" = UPPER("ADDRESS") ';

        -- SELECT "ID","ALIAS_3"::text, 'All character must not be in lower case.','2.62.220' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ADDRESS" = UPPER("ADDRESS")
	
		RAISE INFO '<-----------2.62.220';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.221
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ADDRESS'',"ADDRESS"::text,''All character must not be in lower case.'',''2.62.221''
		FROM '||TableForQa||'
		WHERE "ADDRESS" = LOWER("ADDRESS") ';

        -- SELECT "ID","ADDRESS"::text, 'All character must not be in lower case.','2.62.221' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ADDRESS" = LOWER("ADDRESS")
	
		RAISE INFO '<-----------2.62.221';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.222
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ADDRESS'',"ADDRESS"::text,''Occurance of Same character thrice and more than thrice'',''2.62.222''
		FROM '||TableForQa||'
		WHERE regexp_replace("ADDRESS",''[0-9/, ]'','''')~''(.)\1{2}'' AND "ADDRESS"~''(.)\1{2}'' ';

        -- SELECT "ID","ADDRESS"::text, 'Occurance of Same character thrice and more than thrice','2.62.222' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE regexp_replace("ADDRESS",'[0-9/, ]','')~'(.)\1{2}' AND "ADDRESS"~'(.)\1{2}'

				
		RAISE INFO '<-----------2.62.222';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.223
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ADDRESS'',"ADDRESS"::text,''ADDRESS SHOULD NOT CONTAIN NAME'',''2.62.223''
		FROM '||TableForQa||'
		WHERE (LOWER(TRIM("ADDRESS")) LIKE ''% ''||LOWER(TRIM("NAME"))||'' %'' OR LOWER(TRIM("ADDRESS")) LIKE ''''||LOWER(TRIM("NAME"))||'' %'' OR LOWER(TRIM("ADDRESS")) LIKE ''% ''||LOWER(TRIM("NAME"))||'''') AND (COALESCE("ADDRESS",'''')<>'''') ';

        -- SELECT "ID","ADDRESS"::text, 'Must not have special character except &','2.62.223' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE (LOWER(TRIM("ADDRESS")) LIKE '% '||LOWER(TRIM("NAME"))||' %' OR LOWER(TRIM("ADDRESS")) LIKE ''||LOWER(TRIM("NAME"))||' %' OR LOWER(TRIM("ADDRESS")) LIKE '% '||LOWER(TRIM("NAME"))||'') AND (COALESCE("ADDRESS",'')<>'')
	
		RAISE INFO '<-----------2.62.223';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.224
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ADDRESS'',"ADDRESS"::text,''ADDRESS SHOULD NOT CONTAIN ALIAS_1'',''2.62.224''
		FROM '||TableForQa||'
		WHERE (LOWER(TRIM("ADDRESS")) LIKE ''% ''||LOWER(TRIM("ALIAS_1"))||'' %'' OR LOWER(TRIM("ADDRESS")) LIKE ''''||LOWER(TRIM("ALIAS_1"))||'' %'' OR LOWER(TRIM("ADDRESS")) LIKE ''% ''||LOWER(TRIM("ALIAS_1"))||'''') AND (COALESCE("ADDRESS",'''')<>'''') ';

        -- SELECT "ID","ADDRESS"::text, 'Must not have special character except &','2.62.224' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE (LOWER(TRIM("ADDRESS")) LIKE '% '||LOWER(TRIM("NAME"))||' %' OR LOWER(TRIM("ADDRESS")) LIKE ''||LOWER(TRIM(ALIAS_1))||' %' OR LOWER(TRIM("ADDRESS")) LIKE '% '||LOWER(TRIM("ALIAS_1"))||'') AND (COALESCE("ADDRESS",'')<>'')
	
		RAISE INFO '<-----------2.62.224';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.225
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ADDRESS'',"ADDRESS"::text,''ADDRESS SHOULD NOT CONTAIN ALIAS_2'',''2.62.225''
		FROM '||TableForQa||'
		WHERE (LOWER(TRIM("ADDRESS")) LIKE ''% ''||LOWER(TRIM("ALIAS_2"))||'' %'' OR LOWER(TRIM("ADDRESS")) LIKE ''''||LOWER(TRIM("ALIAS_2"))||'' %'' OR LOWER(TRIM("ADDRESS")) LIKE ''% ''||LOWER(TRIM("ALIAS_2"))||'''') AND (COALESCE("ADDRESS",'''')<>'''') ';

        -- SELECT "ID","ADDRESS"::text, 'Must not have special character except &','2.62.225' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE (LOWER(TRIM("ADDRESS")) LIKE '% '||LOWER(TRIM("ALIAS_2"))||' %' OR LOWER(TRIM("ADDRESS")) LIKE ''||LOWER(TRIM("ALIAS_2"))||' %' OR LOWER(TRIM("ADDRESS")) LIKE '% '||LOWER(TRIM("ALIAS_2"))||'') AND (COALESCE("ADDRESS",'')<>'')
	
		RAISE INFO '<-----------2.62.225';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.226
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ADDRESS'',"ADDRESS"::text,''ADDRESS SHOULD NOT CONTAIN ALIAS_3'',''2.62.226''
		FROM '||TableForQa||'
		WHERE (LOWER(TRIM("ADDRESS")) LIKE ''% ''||LOWER(TRIM("ALIAS_3"))||'' %'' OR LOWER(TRIM("ADDRESS")) LIKE ''''||LOWER(TRIM("ALIAS_3"))||'' %'' OR LOWER(TRIM("ADDRESS")) LIKE ''% ''||LOWER(TRIM("ALIAS_3"))||'''') AND (COALESCE("ADDRESS",'''')<>'''') ';

        -- SELECT "ID","ADDRESS"::text, 'Must not have special character except &','2.62.226' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE (LOWER(TRIM("ADDRESS")) LIKE '% '||LOWER(TRIM("ALIAS_3"))||' %' OR LOWER(TRIM("ADDRESS")) LIKE ''||LOWER(TRIM("ALIAS_2"))||' %' OR LOWER(TRIM("ADDRESS")) LIKE '% '||LOWER(TRIM("ALIAS_2"))||'') AND (COALESCE("ADDRESS",'')<>'')
	
		RAISE INFO '<-----------2.62.226';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

--2.62.227
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ADDRESS'',"ADDRESS"::text,''5 or More than 5 Numeric values in continuity must not be present'',''2.62.223''
		FROM '||TableForQa||'
		WHERE "ADDRESS" ~''[0-9]{5}''	 ';

        -- SELECT "ID","ADDRESS"::text, '5 or More than 5 Numeric values in continuity must not be present','2.62.227' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "ADDRESS" ~'[0-9]{5}'	

		RAISE INFO '<-----------2.62.227';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.228
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''ADDRESS'',"ADDRESS"::text,''Address must not have length of 5 or less than 5 character'',''2.62.228''
		FROM '||TableForQa||'
		WHERE LENGTH("ADDRESS")<6	 ';

        -- SELECT "ID","ADDRESS"::text, 'Address must not have length of 5 or less than 5 character','2.62.228' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE LENGTH("ADDRESS")<6

		RAISE INFO '<-----------2.62.228';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

---------------------------------------------------------------------------TEL-------------------------------------------------------------------------

--2.62.229
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''TEL'',"TEL"::text,''Must be 13 OR 28 OR 43 digit that too in numeric form only'',''2.62.229''
		FROM '||TableForQa||'
		WHERE "TEL" ~ ''^[0-9\+\,]'' AND LENGTH("TEL") <> 13 AND LENGTH("TEL") <> 28 AND LENGTH("TEL") <> 43 ';

        -- SELECT "ID","TEL"::text, 'Must not have special character except &','2.62.229' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "TEL" ~ '^[0-9\+\,]' AND LENGTH("TEL") <> 13 AND LENGTH("TEL") <> 28 AND LENGTH("TEL") <> 43

		RAISE INFO '<-----------2.62.229';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.230
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''TEL'',"TEL"::text,''Should be in proper form'',''2.62.229''
		FROM '||TableForQa||'
		WHERE ("TEL"!~''^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$''  
		 OR "TEL"!~''[+]{1}[9]{1}[1]{1}[1-9]{1}[0-9]{9}'') ';

        -- SELECT "ID","TEL"::text, 'Should be in proper form','2.62.230' 
		-- FROM mmi_master."DL_P1_ADDR_POINT" as t
		-- WHERE (t."TEL"!~'^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$' OR t."TEL"!~'[+]{1}[9]{1}[1]{1}[1-9]{1}[0-9]{9}')

		RAISE INFO '<-----------2.62.230';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.232
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''TEL'',"TEL"::text,''Should not contains consecutive space'',''2.62.232''
		FROM '||TableForQa||'
		WHERE "TEL" LIKE ''%  %'' ';

        -- SELECT "ID","POPLR_NME"::text, 'Should not contains consecutive space','2.62.232' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "POPLR_NME" LIKE '%  %'

	
		RAISE INFO '<-----------2.62.232';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

-------------------------------------------------------------EM_TEL--------------------------------------------------------------------------	

--2.62.239
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''EM_TEL'',"EM_TEL"::text,''Should not contains consecutive space'',''2.62.239''
		FROM '||TableForQa||'
		WHERE "EM_TEL" LIKE ''%  %'' ';

        -- SELECT "ID","EM_TEL"::text, 'Should not contains consecutive space','2.62.239' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "EM_TEL" LIKE '%  %'

	
		RAISE INFO '<-----------2.62.239';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.240
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''EM_TEL'',"EM_TEL"::text,''Special charecter must not available except comma'',''2.62.240''
		FROM '||TableForQa||'
		WHERE "EM_TEL" ~ ''[^A-Za-z0-9\,]'' ';

        -- SELECT "ID","EM_TEL"::text, 'Special charecter must not available except comma','2.62.240' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "EM_TEL" ~ '[^A-Za-z0-9\,]'

	
		RAISE INFO '<-----------2.62.240';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
---------------------------------------------------------------MOB_TEL----------------------------------------------------------------------------------
--2.62.234
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''MOB_TEL'',"MOB_TEL"::text,''Should not contains consecutive space'',''2.62.234''
		FROM '||TableForQa||'
		WHERE "MOB_TEL" LIKE ''%  %'' ';

        -- SELECT "ID","MOB_TEL"::text, 'Should not contains consecutive space','2.62.234' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "MOB_TEL" LIKE '%  %'

	
		RAISE INFO '<-----------2.62.234';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.235
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''MOB_TEL'',"MOB_TEL"::text,''Must be 13 OR 28 OR 43 digit that too in numeric form only'',''2.62.235''
		FROM '||TableForQa||'
		WHERE "MOB_TEL" ~ ''^[0-9\+\,]'' AND LENGTH("MOB_TEL") <> 13 AND LENGTH("MOB_TEL") <> 28 AND LENGTH("MOB_TEL") <> 43 ';

        -- SELECT "ID","MOB_TEL"::text, 'Must not have special character except &','2.62.235' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "MOB_TEL" ~ '^[0-9\+\,]' AND LENGTH("MOB_TEL") <> 13 AND LENGTH("MOB_TEL") <> 28 AND LENGTH("MOB_TEL") <> 43

		RAISE INFO '<-----------2.62.229';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.236
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''MOB_TEL'',"MOB_TEL"::text,''Should be in proper form'',''2.62.236''
		FROM '||TableForQa||'
		WHERE ("MOB_TEL"!~''^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$''  
		 OR "MOB_TEL"!~''[+]{1}[9]{1}[1]{1}[1-9]{1}[0-9]{9}'') ';

        -- SELECT "ID","MOB_TEL"::text, 'Should be in proper form','2.62.236' 
		-- FROM mmi_master."DL_P1_ADDR_POINT" as t
		-- WHERE (t."MOB_TEL"!~'^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$' OR t."MOB_TEL"!~'[+]{1}[9]{1}[1]{1}[1-9]{1}[0-9]{9}')

		RAISE INFO '<-----------2.62.236';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

----------------------------------------------------------------FAX------------------------------------------------------------------------------
--2.62.241
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''FAX'',"FAX"::text,''Must be 13 OR 28 OR 43 digit that too in numeric form only'',''2.62.241''
		FROM '||TableForQa||'
		WHERE "FAX" ~ ''^[0-9\+\,]'' AND LENGTH("FAX") <> 13 AND LENGTH("FAX") <> 28 AND LENGTH("FAX") <> 43 ';

        -- SELECT "ID","FAX"::text, 'Must not have special character except &','2.62.241' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "FAX" ~ '^[0-9\+\,]' AND LENGTH(FAX) <> 13 AND LENGTH("FAX") <> 28 AND LENGTH("FAX") <> 43

		RAISE INFO '<-----------2.62.241';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.242
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''FAX'',"FAX"::text,''Should be in proper form'',''2.62.242''
		FROM '||TableForQa||'
		WHERE ("FAX"!~''^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$''  
		 OR "FAX"!~''[+]{1}[9]{1}[1]{1}[1-9]{1}[0-9]{9}'') ';

        -- SELECT "ID","FAX"::text, 'Should be in proper form','2.62.242' 
		-- FROM mmi_master."DL_P1_ADDR_POINT" as t
		-- WHERE (t."FAX"!~'^((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?([,])?([\s])?)?((\+91)?[1-9]\d{9}?)?$' OR t."FAX"!~'[+]{1}[9]{1}[1]{1}[1-9]{1}[0-9]{9}')

		RAISE INFO '<-----------2.62.242';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.243
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''FAX'',"FAX"::text,''Should not contains consecutive space'',''2.62.243''
		FROM '||TableForQa||'
		WHERE "FAX" LIKE ''%  %'' ';

        -- SELECT "ID","FAX"::text, 'Should not contains consecutive space','2.62.243' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "FAX" LIKE '%  %'

	
		RAISE INFO '<-----------2.62.243';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--------------------------------------------------------------------EMAIL------------------------------------------------------------------------
--2.62.246
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''EMAIL'',"EMAIL",''EMAIL should not contain any special characters Except (@._-,) AND only two EMAILs are allowed AND EMAIL must contain (. and @) AND EMAIL must not end with special character'' ,''2.62.246'' 
		FROM '||TableForQa||'AS t 
		WHERE t."EMAIL" !~ ''^[\w._-]+@[\w._-]+\.[A-Za-z]{2,4}(, [\w._-]+@[\w._-]+\.[A-Za-z]{2,4})?$'' AND (COALESCE("EMAIL",'''')<>'''')';

		
		--SELECT "ID",'tbl_nme','EMAIL',"EMAIL",
		--'EMAIL should not contain any special characters Except (@._-,) AND only two EMAILs are allowed AND EMAIL must contain (. and @) AND EMAIL must not end with special character' ,'2.47.246'
		--FROM mmi_v180."GA_POI" AS t 
		--WHERE t."EMAIL" !~ '^[\w._-]+@[\w._-]+\.[A-Za-z]{2,4}(, [\w._-]+@[\w._-]+\.[A-Za-z]{2,4})?$' AND (COALESCE("EMAIL",'')<>'')
		
		RAISE INFO '<-----------2.62.246';
		
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into qa.attriberror(message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;

--2.62.247
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''EMAIL'',"EMAIL"::text,''Special charecter must not available except . @ _ COMMA and -'',''2.62.247''
		FROM '||TableForQa||'
		WHERE ("EMAIL" ~ ''[a-zA-Z0-9_.-@,]+$'' = FALSE) ';

        -- SELECT "ID","EMAIL"::text, 'Special charecter must not available except . @ _ COMMA and -','2.62.247' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ("EMAIL" ~ '[a-zA-Z0-9_.-@,]+$' = FALSE)

		RAISE INFO '<-----------2.62.247';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
----------------------------------------------------------------------WEB-----------------------------------------------------------------------	
--2.62.248
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		( SELECT t7."ID",'''||tbl_nme||''',''WEB'',t7."WEB"::text,''Must have www.$$$$ Format'',''2.62.248''
		FROM (Select t."ID",t."WEB",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		FROM (SELECT "ID","WEB",unnest(String_To_Array(replace("WEB",'','',''''), '' '')) as WEB, CONCAT("ID",'' '',unnest(String_To_Array(replace("WEB",'','',''''), '' ''))) 
		FROM '||TableForQa||') AS t WHERE t.CONCAT!~''^\d+ (www.){1}'') AS t7 
		WHERE (COALESCE(t7.CONCAT,'''')<>'''') GROUP BY  t7."ID",t7."WEB",t7.CONCAT)';

		-- SELECT t7."ID",'tbl_nme','WEB',t7."WEB"::text,'Must have www.$$$$ Format','2.62.248'
		-- FROM (Select t."ID",t."WEB",t.CONCAT,COUNT(*) OVER (PARTITION BY t.CONCAT) AS ct 
		-- FROM (SELECT "ID","WEB",unnest(String_To_Array(replace("WEB",',',''), ' ')) as WEB, CONCAT("ID",' ',unnest(String_To_Array(replace("WEB",',',''), ' '))) 
		-- FROM mmi_master."DL_P1_ADDR_POINT" ) AS t WHERE t.CONCAT!~'^\d+ (www.){1}') AS t7 
		-- WHERE (COALESCE(t7.CONCAT,'')<>'') GROUP BY  t7."ID",t7."WEB",t7.CONCAT
		
		
		RAISE INFO '<-----------2.62.247';
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caugth 2.1:%',f1;
		RAISE info 'error caugth 2.2:%',f2;
	END;

--2.62.249
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''WEB'',"WEB"::text,''Should not contains consecutive space'',''2.62.249''
		FROM '||TableForQa||'
		WHERE "WEB" LIKE ''%  %'' ';

        -- SELECT "ID","WEB"::text, 'Should not contains consecutive space','2.62.249' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "WEB" LIKE '%  %'

	
		RAISE INFO '<-----------2.62.249';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.250
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''WEB'',"WEB"::text,''Special charecter must not available except except . And COMMA'',''2.62.250''
		FROM '||TableForQa||'
		where "WEB" ~''^[a-zA-Z0-9\.\,]+$'' = FALSE ';

        -- SELECT "ID","WEB"::text, 'Special charecter must not available except except . And COMMA','2.62.250' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- where "WEB" ~'^[a-zA-Z0-9\.\,]+$' = FALSE

	
		RAISE INFO '<-----------2.62.250';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

-------------------------------------------------------------PIP_TYP----------------------------------------------------------------------	
--2.62.251
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''PIP_TYP'',"PIP_TYP"::text,''Must have 1,2,3,4 or 5 where PIP_Id is present'',''2.62.251''
		FROM '||TableForQa||'
		where "PIP_TYP" NOT IN (1,2,3,4,5) AND "PIP_ID" <> 0 ';

		-- SELECT "ID","PIP_TYP"::text, 'Must have 3 or 4 or 5 where PIP_Id is present','2.62.251' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- where "PIP_TYP" NOT IN (1,2,3,4,5) AND "PIP_ID" <> 0

        -- SELECT "ID","PIP_TYP"::text, 'Must have 3 or 4 or 5 where PIP_Id is present','2.62.251' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- where "PIP_TYP" NOT IN (3,4,5) AND "PIP_ID" <> 0

		RAISE INFO '<-----------2.62.251';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.252
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''PIP_TYP'',"PIP_TYP"::text,''Only 0,1,2,3,4 and 5 values are accepted'',''2.62.252''
		FROM '||TableForQa||'
		where "PIP_TYP" NOT IN (0,1,2,3,4,5)  ';

		--Changed By Bhupesh On 23092019
		-- SELECT "ID","PIP_TYP"::text, 'Only 0 or 3 or 4 and 5 values are accepted','2.62.252' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- where "PIP_TYP" NOT IN (0,1,2,3,4,5) 

        -- SELECT "ID","PIP_TYP"::text, 'Only 0 or 3 or 4 and 5 values are accepted','2.62.252' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- where "PIP_TYP" NOT IN (0,3,4,5) 

		RAISE INFO '<-----------2.62.252';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--------------------------------------------------------------------DT_SRCNEW------------------------------------------------------------------------------------
--2.62.70
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''DT_SRCNEW'',"DT_SRCNEW"::text,''There should not be any character values'',''2.62.70''
		FROM '||TableForQa||'
		where "DT_SRCNEW" ~''[0-9]'' = FALSE  ';

        -- SELECT "ID","DT_SRCNEW"::text, 'there should not be any character values','2.62.70' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- where "DT_SRCNEW" ~'[0-9]' = FALSE

		RAISE INFO '<-----------2.62.70';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
----------------------------------------------------------------SRCMVD------------------------------------------------------------------------------------------	
	
--2.62.154
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''SRCMVD'',"SRCMVD"::text,''If values available then SRCUPDT_ID column must be filled and vice versa.'',''2.62.154''
		FROM '||TableForQa||'
		where (COALESCE("SRCMVD",'''')<> '''' AND COALESCE("SRCUPDT_ID",'''')= '''') OR (COALESCE("SRCUPDT_ID",'''')<> '''' AND COALESCE("SRCMVD",'''')= '''')  ';

        -- SELECT "ID","SRCMVD","SRCUPDT_ID"::text, 'If values available then SRCUPDT_ID column must be filled and vice versa','2.62.154' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- where (COALESCE("SRCMVD",'')<> '' AND COALESCE("SRCUPDT_ID",'')= '') OR (COALESCE("SRCUPDT_ID",'')<> '' AND COALESCE("SRCMVD",'')= '')

		RAISE INFO '<-----------2.62.154';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

-------------------------------------------------------------------DT_SRCMVD-------------------------------------------------------------------------------------------------------------------
--2.62.255
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''DT_SRCMVD'',"DT_SRCMVD"::text,''Must be in numeric form and 6 digit only'',''2.62.255''
		FROM '||TableForQa||'
		WHERE COALESCE("DT_SRCMVD",'''') <> '''' AND "DT_SRCMVD" ~''^\d{6}$'' = FALSE ';

        -- SELECT "ID","DT_SRCMVD","SRCUPDT_ID"::text, 'Must be in numeric form and 6 digit only','2.62.255' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("DT_SRCMVD",'''') <> '''' AND "DT_SRCMVD" ~''^\d{6}$'' = FALSE

		RAISE INFO '<-----------2.62.255';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

-----------------------------------------------------------------DT_SRCVRF-------------------------------------------------------------------------------------------------------------------
--2.62.256
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''DT_SRCVRF'',"DT_SRCVRF"::text,''Must be in numeric form and 6 digit only'',''2.62.256''
		FROM '||TableForQa||'
		WHERE COALESCE("DT_SRCVRF",'''') <> '''' AND "DT_SRCVRF" ~''^\d{6}$'' = FALSE ';

        -- SELECT "ID","DT_SRCVRF","SRCUPDT_ID"::text, 'Must be in numeric form and 6 digit only','2.62.256' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("DT_SRCVRF",'''') <> '''' AND "DT_SRCVRF" ~''^\d{6}$'' = FALSE

		RAISE INFO '<-----------2.62.256';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

------------------------------------------------------------SRCDAT-------------------------------------------------------------------

--2.62.265
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''SRCDAT'',"SRCDAT"::text,''Dt_srcDat & Src Dat either one of them only contain a value then error'',''2.62.265''
		FROM '||TableForQa||'
		where (COALESCE("SRCDAT",'''')<> '''' AND COALESCE("DT_SRCDAT",'''')= '''') OR (COALESCE("DT_SRCDAT",'''')<> '''' AND COALESCE("SRCDAT",'''')= '''')  ';

        -- SELECT "ID","SRCDAT","SRCUPDT_ID"::text, 'Dt_srcDat & Src Dat either one of them only contain a value then error','2.62.265' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- where (COALESCE("SRCDAT",'')<> '' AND COALESCE("DT_SRCDAT",'')= '') OR (COALESCE("DT_SRCDAT",'')<> '' AND COALESCE("SRCMVD",'')= '')

		RAISE INFO '<-----------2.62.265';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

-------------------------------------------------------------------------DT_SRCDAT---------------------------------------------------------

--2.62.256
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''DT_SRCDAT'',"DT_SRCDAT"::text,''Must be in numeric form and 6 digit only'',''2.62.256''
		FROM '||TableForQa||'
		WHERE COALESCE("DT_SRCDAT",'''') <> '''' AND "DT_SRCDAT" ~''^\d{6}$'' = FALSE ';

        -- SELECT "ID","DT_SRCDAT","SRCUPDT_ID"::text, 'Must be in numeric form and 6 digit only','2.62.256' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("DT_SRCDAT",'''') <> '''' AND "DT_SRCDAT" ~''^\d{6}$'' = FALSE

		RAISE INFO '<-----------2.62.256';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

------------------------------------------------------------DT_SRCCLSD-------------------------------------------------------------------------------------	
--2.62.256
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''DT_SRCCLSD'',"DT_SRCCLSD"::text,''Must be in numeric form and 6 digit only'',''2.62.256''
		FROM '||TableForQa||'
		WHERE COALESCE("DT_SRCCLSD",'''') <> '''' AND "DT_SRCCLSD" ~''^\d{6}$'' = FALSE ';

        -- SELECT "ID","DT_SRCCLSD","SRCUPDT_ID"::text, 'Must be in numeric form and 6 digit only','2.62.256' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("DT_SRCCLSD",'''') <> '''' AND "DT_SRCCLSD" ~''^\d{6}$'' = FALSE

		RAISE INFO '<-----------2.62.256';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
----------------------------------------------------------PUB_PVT---------------------------------------------------------------------------------
--2.62.259
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''PUB_PVT'',"PUB_PVT"::text,''Must have 0 OR 1 OR 2 values'',''2.62.259''
		FROM '||TableForQa||'
		WHERE "PUB_PVT" NOT IN (0,1,2) ';

        -- SELECT "ID","PUB_PVT"::text, 'Must have 0 OR 1 OR 2 values','2.62.259' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "PUB_PVT" NOT IN (0,1,2)

		RAISE INFO '<-----------2.62.259';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

------------------------------------------------------------VICIN_ID--------------------------------------------------------------------------------------
--2.62.260
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''VICIN_ID'',"VICIN_ID"::text,''VICIN_ID must not be matched with CITY_ID in same record'',''2.62.260''
		FROM '||TableForQa||'
		WHERE ("CITY_ID"="VICIN_ID" AND ("VICIN_ID"<>0 AND "VICIN_ID" IS NOT NULL AND "CITY_ID"<>0 AND "CITY_ID" IS NOT NULL)) ';

        -- SELECT "ID","VICIN_ID"::text, 'VICIN_ID must not be matched with CITY_ID in same record','2.62.260' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ("CITY_ID"="VICIN_ID" AND ("VICIN_ID"<>0 AND "VICIN_ID" IS NOT NULL AND "CITY_ID"<>0 AND "CITY_ID" IS NOT NULL))

		RAISE INFO '<-----------2.62.260';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

---------------=--------------------------------------------------SEC_STA---------------------------------------------------------------------------------

--2.62.98
--20/05/2019
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''SEC_STA'',"SEC_STA"::text,''Only C OR KC OR PC and Blank values are accepted'',''2.62.98''
		FROM '||TableForQa||'
		WHERE "SEC_STA" NOT IN (''PC'',''KC'',''C'','''')  ';

        -- SELECT "ID","SEC_STA"::text, 'Only C OR KC OR PC and Blank values are accepted','2.62.98' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "SEC_STA" NOT IN ('PC','KC','C','')

		RAISE INFO '<-----------2.62.98';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.99
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''SEC_STA'',"SEC_STA"::text,''Must not be blank where bld_nme or bld_num is present'',''2.62.99''
		FROM '||TableForQa||'
		WHERE (COALESCE("BLDNME_ORG",'''')<> '''' AND COALESCE("SEC_STA",'''')= '''') OR (COALESCE("BLDNUM_ORG",'''')<> '''' AND COALESCE("SEC_STA",'''')= '''') ';

        -- SELECT "ID","SEC_STA","BLDNME_ORG","BLDNUM_ORG"::text, 'Must not be blank where bld_nme or bld_num is present','2.62.99' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE (COALESCE("BLDNME_ORG",'')<> '' AND COALESCE("SEC_STA",'')= '') OR (COALESCE("BLDNUM_ORG",'')<> '' AND COALESCE("SEC_STA",'')= '')

		RAISE INFO '<-----------2.62.99';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE 'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.100
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''SEC_STA'',"SEC_STA"::text,''It must be in upper case'',''2.62.100''
		FROM '||TableForQa||'
		WHERE "SEC_STA" <> UPPER("SEC_STA") ';

        -- SELECT "ID","SEC_STA","BLDNME_ORG","BLDNUM_ORG"::text, 'It must be in upper case','2.62.100' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "SEC_STA" <> UPPER("SEC_STA")

		RAISE INFO '<-----------2.62.99';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

----------------------------------------------------------------IMP_POI----------------------------------------------------------------------------

--2.62.261
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''IMP_POI'',"IMP_POI"::text,''Special character must not available except _'',''2.62.261''
		FROM '||TableForQa||'
		WHERE "IMP_POI"~''[^A-Za-z0-9\s_,]'' ';

        -- SELECT "ID","IMP_POI"::text, 'Must not be blank where bld_nme or bld_num is present','2.62.261' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "IMP_POI"~'[^A-Za-z0-9\s_,]'

		RAISE INFO '<-----------2.62.261';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.271
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''IMP_POI'',"IMP_POI"::text,''IMP_Poi must always contain codes like "IMP_LOC OR IMP_CTY OR IMP_SO OR IMP_NAT OR IMP_DE OR IMP OR IMP_STT OR IMP_DST'',''2.62.271''
		FROM '||TableForQa||'
		WHERE "IMP_POI" NOT IN (''IMP_LOC'',''IMP_CTY'',''IMP_STT'',''IMP_SO'',''IMP_NAT'',''IMP_DE'',''IMP'',''IMP_STT'',''IMP_DST'') ';

		
        -- SELECT "ID","IMP_POI"::text, 'IMP_LOC OR IMP_CTY OR IMP_SO OR IMP_NAT OR IMP_DE OR IMP OR IMP_STT OR IMP_DST','2.62.271' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "IMP_POI" NOT IN ('IMP_LOC','IMP_CTY','IMP_STT','IMP_SO','IMP_NAT','IMP_DE','IMP','IMP_STT','IMP_DST')

		RAISE INFO '<-----------2.62.271';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
------------------------------------------------------------Q_LVL----------------------------------------------------------------------------------------------------------------------

--2.62.268
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''IMP_POI'',"IMP_POI"::text,''Specifies the quality level of the poi and consists of value only between 1 to 5 and 9 and 10.'',''2.62.268''
		FROM '||TableForQa||'
		WHERE ("Q_LVL"<>''1'' AND "Q_LVL"<>''2'' AND "Q_LVL"<>''3'' AND "Q_LVL"<>''4'' AND "Q_LVL"<>''5'' AND "Q_LVL"<>''9'' AND "Q_LVL"<>''10'') AND (COALESCE("Q_LVL",'''')<>'''') ';

		
        -- SELECT "ID","IMP_POI"::text, 'Specifies the quality level of the poi and consists of value only between 1 to 5 and 9 and 10.','2.62.268' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ("Q_LVL"<>'1' AND "Q_LVL"<>'2' AND "Q_LVL"<>'3' AND "Q_LVL"<>'4' AND "Q_LVL"<>'5' AND "Q_LVL"<>'9' AND "Q_LVL"<>'10') AND (COALESCE("Q_LVL",'')<>'')

		RAISE INFO '<-----------2.62.268';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

------------------------------------------------------------------PRIORITY---------------------------------------------------

--2.62.114
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''PRIORITY'',"PRIORITY"::text,''Must not be zero 0 If Dlv_Bldg_Nme or Dlv_Bldg_Num is blank then priority can have value 0'',''2.62.114''
		FROM '||TableForQa||'
		WHERE "PRIORITY"=0 and  (COALESCE("BLDNME_ORG",'''')<>''''  AND "PRIORITY" = 0) OR (COALESCE("BLDNUM_ORG",'''')<>'''' AND "PRIORITY" = 0) ';

		
        -- SELECT "ID","BLDNME_ORG","BLDNUM_ORG","PRIORITY"::text, 'Must not be zero 0 (If Dlv_Bldg_Nme or Dlv_Bldg_Num is blank then priority can have value 0.)','2.62.114' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "PRIORITY"=0 and  (COALESCE("BLDNME_ORG",'')<>''   and "PRIORITY" = 0) and (COALESCE("BLDNUM_ORG",'')<>'' and "PRIORITY" = 0)

		RAISE INFO '<-----------2.62.114';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
--2.62.115
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''PRIORITY'',"PRIORITY"::text,''Must be according to specified values (14 or 15 or 97)'',''2.62.115''
		FROM '||TableForQa||'
		WHERE "PRIORITY" NOT IN (4,5,6,7,8,9,10,11,12,13,14,15,16 ,97) ';

		--Changed By Bhupesh On 23092019
		-- SELECT "ID","BLDNME_ORG","BLDNUM_ORG","PRIORITY"::text, 'Must be according to specified values (14, 15, 97)','2.62.115' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "PRIORITY" NOT IN (4,5,6,7,8,9,10,11,12,13,14,15,16 ,97)

		
        -- SELECT "ID","BLDNME_ORG","BLDNUM_ORG","PRIORITY"::text, 'Must be according to specified values (14, 15, 97)','2.62.115' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "PRIORITY" NOT IN (14,15,97)

		RAISE INFO '<-----------2.62.115';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;		
	
--2.62.128
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''PRIORITY'',"PRIORITY"::text,''If BLDNUM NOT NULL THEN PRIORITY SHOULD IN (14 OR 97)'',''2.62.128''
		FROM '||TableForQa||'
		WHERE COALESCE("BLDNUM",'''') <> '''' AND  "PRIORITY" NOT IN (14,97) ';

		
        -- SELECT "ID","BLDNME_ORG","BLDNUM","PRIORITY"::text, 'If BLDNUM NOT NULL THEN PRIORITY SHOULD IN (14 OR97)','2.62.128' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("BLDNUM",'''') <> '''' AND  "PRIORITY" NOT IN (14,97)

		RAISE INFO '<-----------2.62.128';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
	
--2.62.129
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''PRIORITY'',"PRIORITY"::text,''If Name NOT NULL AND BLDNUM NULL THEN PRIORITY SHOULD IN (15 OR97)'',''2.62.129''
		FROM '||TableForQa||'
		WHERE COALESCE("NAME",'''')<>'''' AND   COALESCE("BLDNUM",'''') = '''' AND "PRIORITY" NOT IN (15,97) ';

		
        -- SELECT "ID","BLDNME_ORG","BLDNUM","PRIORITY"::text, 'If Name NOT NULL AND BLDNUM NULL THEN PRIORITY SHOULD IN (15 OR 97)','2.62.129' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("NAME",'')<>'' AND   COALESCE("BLDNUM",'') = '' AND "PRIORITY" NOT IN (15,97)

		RAISE INFO '<-----------2.62.129';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
------------------------------------------------------------K_PRIORITY-----------------------------------------------------------------------

--2.62.269
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''K_PRIORITY'',"K_PRIORITY"::text,''Only K OR M and Blank values are acepted'',''2.62.269''
		FROM '||TableForQa||'
		WHERE "K_PRIORITY" NOT IN (''K'',''M'') AND COALESCE("K_PRIORITY",'''')<>''''';

		
        -- SELECT "ID","K_PRIORITY"::text, 'Only K OR M and Blank values are acepted','2.62.269' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "K_PRIORITY" <>'K' AND "K_PRIORITY"<>'M' AND COALESCE("K_PRIORITY",'')<>''

		RAISE INFO '<-----------2.62.269';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
-----------------------------------------------------------LANDMARK-------------------------------------------------------------------------------	

--2.47.133
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''LANDMARK'',"LANDMARK"::text,''Only Y OR N values are acepted'',''2.47.133''
		FROM '||TableForQa||'
		WHERE "LANDMARK" NOT IN (''Y'',''N'') AND COALESCE("LANDMARK",'''')<>''''';

		
        -- SELECT "ID","K_PRIORITY"::text, 'Only Y OR N values are acepted','2.47.133' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "LANDMARK" <>'Y' AND "LANDMARK"<>'N' AND COALESCE("LANDMARK",'')<>''

		RAISE INFO '<-----------2.62.269';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

------------------------------------------------------------------RANKING--------------------------------------------------------------------------------------

--2.62.262
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''RANKING'',"RANKING"::text,''Must be in range (1 to 4000) or 0 for default'',''2.62.262''
		FROM '||TableForQa||'
		WHERE ("RANKING" NOT BETWEEN 1 AND 4000) AND "RANKING"<>0  ';

		
        -- SELECT "ID","RANKING"::text, 'Must be in range (1 to 4000) or 0 for default','2.62.262' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE ("RANKING" NOT BETWEEN 1 AND 4000) AND "RANKING"<>0 

		RAISE INFO '<-----------2.62.262';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

-------------------------------------------------------------TOVRF-------------------------------------------------------------------------------
--2.62.275
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''TOVRF'',"TOVRF"::text,''Accept Only Y OR N and Its Combination'',''2.62.275''
		FROM '||TableForQa||'
		WHERE COALESCE("TOVRF",'''')<>'''' AND "TOVRF"~''[^NY,]''';

		--Changed By Bhupesh On 23092019
		-- SELECT "ID","K_PRIORITY"::text, 'Only Y OR N  AND BLANK values are acepted','2.62.275' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("TOVRF",'')<>'' AND "TOVRF"~'[^NY,]'

        -- SELECT "ID","K_PRIORITY"::text, 'Only Y OR N  AND BLANK values are acepted','2.62.275' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "TOVRF" NOT IN ('Y','N') 

		RAISE INFO '<-----------2.62.269';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

-----------------------------------------------------------RSN_TOVRF-----------------------------------------------------------------------

--2.62.276
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''RSN_TOVRF'',"RSN_TOVRF"::text,''Must be filled in case N is updated in ToVrf column'',''2.62.276''
		FROM '||TableForQa||'
		WHERE "TOVRF" = ''N'' AND COALESCE("RSN_TOVRF",'''')=''''  ';

		
        -- SELECT "ID","TOVRF","RSN_TOVRF"::text, 'Must have 3 or 4 or 5 where PIP_Id is present','2.62.276' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "TOVRF" = 'N' AND COALESCE("RSN_TOVRF",'')=''

		RAISE INFO '<-----------2.62.276';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--------------------------------------------------------------------------DE_IMGPATH-------------------------------------------------------------------------

--2.62.276
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''DE_IMGPATH'',"DE_IMGPATH"::text,''If De_Imgpathavailable then Src_Id must be available	'',''2.62.276''
		FROM '||TableForQa||'
		WHERE COALESCE("DE_IMGPATH",'''') <>'''' AND COALESCE("SRC_ID",'''')= '''' ';

		
        -- SELECT "ID","SRC_ID","DE_IMGPATH"::text, 'If De_Imgpathavailable then Src_Id must be available','2.62.251' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("DE_IMGPATH",'') <>'' AND COALESCE("SRC_ID",'')= ''

		RAISE INFO '<-----------2.62.276';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

-------------------------------------------------------------------SPELLCHK----------------------------------------------------------------------------------------------

--2.62.263
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''SPELLCHK'',"SPELLCHK"::text,''Only C OR L and Blank values are accepted'',''2.62.263''
		FROM '||TableForQa||'
		WHERE "SPELLCHK"<>''C'' AND "SPELLCHK"<>''L'' AND COALESCE("SPELLCHK",'''')<>'''' ';

		
        -- SELECT "ID","SRC_ID","SPELLCHK"::text, 'Only C OR L and Blank values are accepted','2.62.263' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "SPELLCHK"<>'C' AND "SPELLCHK"<>'L' AND COALESCE("SPELLCHK",'')<>''

		RAISE INFO '<-----------2.62.263';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

----------------------------------------------------------------DLV----------------------------------------------------------------------------

--2.62.95
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''DLV'',"DLV"::text,''Only Y, N and D values are accepted'',''2.62.263''
		FROM '||TableForQa||'
		WHERE "DLV" NOT IN (''Y'',''N'',''D'') AND COALESCE("DLV",'''') <>'''' ';

		
        -- SELECT "ID","DLV","NAME","BLDNUM_ORG"::text, 'Only Y, N and D values are accepted','2.62.95' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "DLV" NOT IN ('Y','N','D') AND COALESCE("DLV",'') <>''

		RAISE INFO '<-----------2.62.95';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
	
--2.62.97
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''DLV'',"DLV"::text,''Must be in upper case'',''2.62.97''
		FROM '||TableForQa||'
		WHERE "DLV" <> UPPER("DLV") ';

		
        -- SELECT "ID","DLV","NAME","BLDNUM_ORG"::text, 'Must be in upper case','2.62.97' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "DLV" <> UPPER("DLV") 

		RAISE INFO '<-----------2.62.97';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

---------------------------------------------------------------GEO_LVL--------------------------------------------------------------------------------------

--2.62.155
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''GEO_LVL'',"GEO_LVL"::text,''Must not be null or blank'',''2.62.155''
		FROM '||TableForQa||'
		WHERE  COALESCE("GEO_LVL",'''') =''''  ';

		
        -- SELECT "ID","GEO_LVL"::text, 'Must not be null or blank','2.62.155' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE  COALESCE("GEO_LVL",'') =''

		RAISE INFO '<-----------2.62.155';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.156
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''GEO_LVL'',"GEO_LVL"::text,''Only E R and A values are accepted.'',''2.62.156''
		FROM '||TableForQa||'
		WHERE COALESCE("GEO_LVL",'''')<>'''' AND "GEO_LVL" NOT IN (''E'',''R'',''A'')  ';

		
        -- SELECT "ID","GEO_LVL"::text, 'Only "E", "R" and "A" values are accepted.','2.62.156' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE  "GEO_LVL" NOT IN ('E','R','A')

		RAISE INFO '<-----------2.62.156';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
-----------------------------------------------------------EDGID_ADR------------------------------------------------------------------------------------

--2.62.104
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''EDGID_ADR'',"EDGID_ADR"::text,''Must not match with Edge_Id'',''2.62.156''
		FROM '||TableForQa||'
		WHERE  "EDGE_ID" = "EDGID_ADR" ';

		
        -- SELECT "ID","GEO_LVL"::text, 'Must not match with Edge_Id','2.62.104' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE  "EDGE_ID" = "EDGID_ADR"

		RAISE INFO '<-----------2.62.104';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--------------------------------------------------------------------EDGSID_ADR-----------------------------------------------------------------------------------------------
--2.62.108
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''EDGSID_ADR'',"EDGSID_ADR"::text,''Only L OR R and blank values are accepted'',''2.62.108''
		FROM '||TableForQa||'
		WHERE "EDGSID_ADR" <>''L'' AND "EDGSID_ADR" <>''R'' AND  COALESCE("EDGSID_ADR",'''')<> ''''  ';

		
        --SELECT "ID","EDGSID_ADR"::text, 'Only L OR R and blank values are accepted','2.62.108' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "EDGSID_ADR" <>'L' AND "EDGSID_ADR" <>'R' AND  COALESCE("EDGSID_ADR",'')<> ''

		RAISE INFO '<-----------2.62.108';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	

--2.62.109
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''EDGSID_ADR'',"EDGSID_ADR"::text,''Must be in capital letter'',''2.62.109''
		FROM '||TableForQa||'
		WHERE "EDGSID_ADR" <> UPPER("EDGSID_ADR")  ';

		
        --SELECT "ID","EDGSID_ADR"::text, 'Must be in capital letter','2.62.109' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "EDGSID_ADR" <> UPPER("EDGSID_ADR")

		RAISE INFO '<-----------2.62.109';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;		
	
-----------------------------------------------------------------------------RDNME_ADDR----------------------------------------------------------------------------------------
--2.62.112
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''RDNME_ADDR'',"RDNME_ADDR"::text,''If Road Name present in this column then Edge_Id_Addr must be present'',''2.62.112''
		FROM '||TableForQa||'
		WHERE COALESCE("RDNME_ADDR" ,'''') <> '''' AND "EDGID_ADR" IS NULL  ';

		
        -- SELECT "ID","RDNME_ADDR"::text, 'Must have 3 or 4 or 5 where PIP_Id is present','2.62.112' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("RDNME_ADDR" ,'') <> '' AND "EDGID_ADR" IS NULL

		RAISE INFO '<-----------2.62.112';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
-------------------------------------------------------------PREFIX_TYP------------------------------------------------------------------------------------------------
--2.62.272
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''RDNME_ADDR'',"RDNME_ADDR"::text,''If available then must be ADM OR RDN OR OTH OR NUM'',''2.62.272''
		FROM '||TableForQa||'
		WHERE COALESCE("PREFIX_TYP" ,'''') <> '''' AND "PREFIX_TYP" NOT IN (''ADM'', ''RDN'', ''OTH'', ''NUM'') ';

		
        -- SELECT "ID","PREFIX_TYP"::text, 'If available then must be ADM OR RDN OR OTH OR NUM','2.62.272' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("PREFIX_TYP" ,'') <> '' AND "PREFIX_TYP" NOT IN ('ADM', 'RDN', 'OTH', 'NUM')

		RAISE INFO '<-----------2.62.272';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
	
--2.62.273
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''PREFIX_TYP'',"PREFIX_TYP"::text,''If Available then Must be in UPPER case'',''2.62.273''
		FROM '||TableForQa||'
		WHERE COALESCE("PREFIX_TYP" ,'''') <> '''' AND "PREFIX_TYP" <> UPPER("PREFIX_TYP") ';

		
        -- SELECT "ID","PREFIX_TYP"::text, 'If Available then Must be in UPPER case','2.62.273' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("PREFIX_TYP" ,'') <> '' AND "PREFIX_TYP" <> UPPER("PREFIX_TYP") 

		RAISE INFO '<-----------2.62.273';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

--2.62.274
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''PREFIX_TYP'',"PREFIX_TYP"::text,''If Prefix_Typ avaialable then Prefix must be present'',''2.62.274''
		FROM '||TableForQa||'
		WHERE COALESCE("PREFIX_TYP" ,'''') <> '''' AND COALESCE("PREFIX",'''')= '''' ';

		
        -- SELECT "ID","PREFIX_TYP"::text, 'If Prefix_Typ avaialable then Prefix must be present','2.62.274' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("PREFIX_TYP" ,'') <> '' AND COALESCE("PREFIX",'')= ''

		RAISE INFO '<-----------2.62.274';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

------------------------------------------------------------------LYR_TYP---------------------------------------------------------------------------------------
--2.62.266
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''LYR_TYP'',"LYR_TYP"::text,''Must not be NULL or Blank'',''2.62.266''
		FROM '||TableForQa||'
		WHERE COALESCE("LYR_TYP" ,'''') = ''''  ';

		
        -- SELECT "ID","LYR_TYP"::text, 'Must not be NULL or Blank	','2.62.266' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE COALESCE("LYR_TYP" ,'') = '' 

		RAISE INFO '<-----------2.62.266';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

--2.62.267
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''LYR_TYP'',"LYR_TYP"::text,''Only P or B values are accepted and must be in UPPER case'',''2.62.267''
		FROM '||TableForQa||'
		WHERE "LYR_TYP" <> ''P'' AND "LYR_TYP" <> ''B'' AND "LYR_TYP" <> UPPER("LYR_TYP") ';

		
        -- SELECT "ID","LYR_TYP"::text, 'Only "P" or "B" values are accepted and must be in UPPER case	','2.62.267' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "LYR_TYP" <> ''P'' AND "LYR_TYP" <> ''B'' AND "LYR_TYP" <> UPPER("LYR_TYP")

		RAISE INFO '<-----------2.62.267';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

	
-------------------------------------------------------------------OWNER_NME-----------------------------------------------------------------------
--2.62.57
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''OWNER_NME'',"OWNER_NME"::text,''Must not have double space'',''2.62.57''
		FROM '||TableForQa||'
		WHERE "OWNER_NME" LIKE ''%  %'' ';

		
        -- SELECT "ID","OWNER_NME"::text, 'Must not have double space','2.62.57' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "OWNER_NME" LIKE '%  %'

		RAISE INFO '<-----------2.62.57';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.58
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''OWNER_NME'',"OWNER_NME"::text,''Must not start with space'',''2.62.58''
		FROM '||TableForQa||'
		WHERE "OWNER_NME" LIKE '' %'' ';

		
        -- SELECT "ID","OWNER_NME"::text, 'Must not start with space','2.62.58' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "OWNER_NME" LIKE '' %''

		RAISE INFO '<-----------2.62.58';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
----------------------------------------------------------------------BLDNUM----------------------------------------------------------------------------
--2.62.29.1
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT max("ID"),'''||tbl_nme||''',''BLDNUM'',max("BLDNUM")::text, ''Must be unique with reference to lowest admin'',''2.62.29.1''
				 FROM '||TableForQa||' 
				 WHERE "DLV"=''Y'' AND COALESCE("BLDNUM",'''')<>'''' AND COALESCE("NAME",'''')<>''''
				 GROUP BY  COALESCE("NAME",'''')||'',''||COALESCE("PREFIX",'''')||'',''||COALESCE("SEPARATOR",'''')||'',''||COALESCE("BLDNUM",'''')||'',''||COALESCE("ROAD_NME",'''')||'',''||COALESCE("RDNME_ADDR",'''')||'',''||"ADMIN_ID" 
				 HAVING COUNT (COALESCE("NAME",'''')||'',''||COALESCE("PREFIX",'''')||'',''||COALESCE("SEPARATOR",'''')||'',''||COALESCE("BLDNUM",'''')||'',''||COALESCE("ROAD_NME",'''')||'',''||COALESCE("RDNME_ADDR",'''')||'',''||"ADMIN_ID") > 1	'; 

		 -- select MAX("ID") FROM mmi_master."DL_P1_ADDR_POINT" WHERE "DLV"='Y' AND "BLDNUM" IS NOT NULL AND "NAME" IS NOT NULL 
		 -- GROUP BY  COALESCE("NAME",'')||','||COALESCE("PREFIX",'')||','||COALESCE("SEPARATOR",'')||','||COALESCE("BLDNUM",'')||','||COALESCE("ROAD_NME",'')||','||COALESCE("RDNME_ADDR",'')||','||"ADMIN_ID"  
		 -- HAVING COUNT (COALESCE("NAME",'')||','||COALESCE("PREFIX",'')||','||COALESCE("SEPARATOR",'')||','||COALESCE("BLDNUM",'')||','||COALESCE("ROAD_NME",'')||','||COALESCE("RDNME_ADDR",'')||','||"ADMIN_ID") > 1

		RAISE INFO '<----------2.62.29.1';
		
	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into qa.attriberror (message, context) values('''||f1||''','''||f2||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

-------------------------------------------------------------------BLDNME_ORG-----------------------------------------------------------------------
--2.62.74
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNME_ORG'',"BLDNME_ORG"::text,''Must not have double space'',''2.62.74''
		FROM '||TableForQa||'
		WHERE "BLDNME_ORG" LIKE ''%  %'' ';

		
        -- SELECT "ID","BLDNME_ORG"::text, 'Must not have double space','2.62.74' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "BLDNME_ORG" LIKE '%  %'

		RAISE INFO '<-----------2.62.74';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.75
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNME_ORG'',"BLDNME_ORG"::text,''Must not start with space'',''2.62.75''
		FROM '||TableForQa||'
		WHERE "BLDNME_ORG" LIKE '' %'' ';

		
        -- SELECT "ID","BLDNME_ORG"::text, 'Must not start with space','2.62.75' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "BLDNME_ORG" LIKE '' %''

		RAISE INFO '<-----------2.62.75';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	

--2.62.74
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNME_ORG'',"BLDNME_ORG"::text,''Must not have double space'',''2.62.74''
		FROM '||TableForQa||'
		WHERE "BLDNME_ORG" LIKE ''%  %'' ';

		
        -- SELECT "ID","BLDNME_ORG"::text, 'Must not have double space','2.62.74' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "BLDNME_ORG" LIKE '%  %'

		RAISE INFO '<-----------2.62.74';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.75
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNME_ORG'',"BLDNME_ORG"::text,''Must not start with space'',''2.62.75''
		FROM '||TableForQa||'
		WHERE "BLDNME_ORG" LIKE '' %'' ';

		
        -- SELECT "ID","BLDNME_ORG"::text, 'Must not start with space','2.62.75' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "BLDNME_ORG" LIKE '' %''

		RAISE INFO '<-----------2.62.75';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;

-------------------------------------------------------------------BLDNME_ORG-----------------------------------------------------------------------
--2.62.74
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNME_ORG'',"BLDNME_ORG"::text,''Must not have double space'',''2.62.74''
		FROM '||TableForQa||'
		WHERE "BLDNME_ORG" LIKE ''%  %'' ';

		
        -- SELECT "ID","BLDNME_ORG"::text, 'Must not have double space','2.62.74' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "BLDNME_ORG" LIKE '%  %'

		RAISE INFO '<-----------2.62.74';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.75
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNME_ORG'',"BLDNME_ORG"::text,''Must not start with space'',''2.62.75''
		FROM '||TableForQa||'
		WHERE "BLDNME_ORG" LIKE '' %'' ';

		
        -- SELECT "ID","BLDNME_ORG"::text, 'Must not start with space','2.62.75' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "BLDNME_ORG" LIKE '' %''

		RAISE INFO '<-----------2.62.75';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
----------------------------------------------------------------------BLDNUM_ORG---------------------------------------------------------------------------------
--2.62.76
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNUM_ORG'',"BLDNUM_ORG"::text,''Must not have double space'',''2.62.76''
		FROM '||TableForQa||'
		WHERE "BLDNUM_ORG" LIKE ''%  %'' ';

		
        -- SELECT "ID","BLDNUM_ORG"::text, 'Must not have double space','2.62.76' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "BLDNUM_ORG" LIKE '%  %'

		RAISE INFO '<-----------2.62.76';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--2.62.77
	BEGIN
		EXECUTE ' INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''BLDNUM_ORG'',"BLDNUM_ORG"::text,''Must not start with space'',''2.62.77''
		FROM '||TableForQa||'
		WHERE "BLDNUM_ORG" LIKE '' %'' ';

		
        -- SELECT "ID","BLDNUM_ORG"::text, 'Must not start with space','2.62.77' 
		-- FROM mmi_master."DL_P1_ADDR_POINT"
		-- WHERE "BLDNUM_ORG" LIKE '' %''

		RAISE INFO '<-----------2.62.77';
		 
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
						  
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;
	
--ADDR_POINT,FTR_CRY,POI_CAT
--1.1.3
--1.3.1
--31 msec
	IF tbl_name_poi_cat<>'' THEN
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT t4."ID",'''||tbl_nme||''',''FTR_CRY'',t4."FTR_CRY"::text,''Addr_POINT Ftr_Cry does not match with Mtsr_Code in Poi Cat'',''1.1.3'' FROM (( SELECT "FTR_CRY"
		FROM '||sch_name||'."'||tbl_nme||'" ) EXCEPT (SELECT "MSTR_CODE" FROM '||tbl_name_poi_cat||' WHERE (COALESCE("MSTR_CODE",'''')<> '''')) ) As t1, '||sch_name||'."'||tbl_nme||'" t4 WHERE 
	    t1."FTR_CRY" = t4."FTR_CRY"';
	    
		--SELECT t4."ID",'GA_POI','FTR_CRY',t4."FTR_CRY"::text,'Poi’s Ftr_Cry does not match with Mtsr_Code in Poi Cat','1.1.3' FROM (( SELECT "FTR_CRY"
		--FROM mmi_v180."GA_POI" ) EXCEPT (SELECT "MSTR_CODE" FROM mmi_v180."POI_CAT" WHERE (COALESCE("MSTR_CODE",'')<> '')) ) As t1, mmi_v180."GA_POI" t4 WHERE 
	    --t1."FTR_CRY" = t4."FTR_CRY"
		
		RAISE INFO '<----------1.1.3';
		
		EXCEPTION 
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS 
				f1=MESSAGE_TEXT,
				f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 19.1:%',f1;
		RAISE info 'error caught 19.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;

--ADDR,POI_CAT->SUB_CRY2
--1.1.2
--1.5.4
--16 msec
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		(SELECT t."ID",'''||tbl_nme||''',''SUB_CRY'',t."SUB_CRY"::text,''Addr Sub_Cry must be part of Mtr_Subcod group in Poi Cat'',''1.1.2''
		FROM '||sch_name||'."'||tbl_nme||'" As t WHERE  t."SUB_CRY" NOT IN ( 
		SELECT "MTR_SUBCOD" FROM '||tbl_name_poi_cat||' WHERE (COALESCE("MTR_SUBCOD",'''')<> '''')) AND t."SUB_CRY" IN ( 
		SELECT "MTR_SUBCOD" FROM '||tbl_name_poi_cat||' WHERE (COALESCE("MTR_SUBCOD",'''')<> '''')))';
	    
		--SELECT t."ID",'''||tbl_nme||''',''SUB_CRY'',t."SUB_CRY"::text,''Poi’s Sub_Cry must be part of Mtr_Subcod group in Poi Cat'',''1.5.4''
		--FROM '||sch_name||'."'||tbl_nme||'" As t WHERE  t."SUB_CRY" NOT IN ( 
		--SELECT "MTR_SUBCOD" FROM '|| mst_sch ||'."'||tbl_name_poi_cat||'" WHERE (COALESCE("MTR_SUBCOD",'''')<> '''')) AND t."SUB_CRY" IN ( 
		--SELECT "MTR_SUBCOD" FROM '|| mst_sch ||'."'||tbl_name_poi_cat||'" WHERE (COALESCE("MTR_SUBCOD",'''')<> ''''))
		
		RAISE INFO '<----------1.1.2';
		
		EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
		f1=MESSAGE_TEXT,
		f2=PG_EXCEPTION_CONTEXT; 
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 19.1:%',f1;
		RAISE info 'error caught 19.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	
--ADDR,POI_CAT->FTR_CRY,SUB_CRY COMBINATION
--1.1.91
--16 msec
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT "ID",'''||tbl_nme||''',''FTR_CRY_SUB_CRY'',ftrcrycom::text,''FTR_CRY and SUB_CRY Combination Not Match With POI_CAT'',''1.1.91''
		FROM (SELECT "ID",(COALESCE("FTR_CRY",'''') ||''_''|| COALESCE("SUB_CRY",'''')) as ftrcrycom 
		FROM '||sch_name||'."'||tbl_nme||'" WHERE (COALESCE("FTR_CRY",'''') ||''_''|| COALESCE("SUB_CRY",''''))
		NOT IN (SELECT (COALESCE("MSTR_CODE",'''') ||''_''|| COALESCE("MTR_SUBCOD",'''')) FROM '||tbl_name_poi_cat||' )) as t1 ';
		
		
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
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 18.1:%',f1;
		RAISE info 'error caught 18.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
--ADDR,POI_CAT->SUB_CRY1
--1.1.1
--1.5.1
--16 msec
	BEGIN
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
		SELECT t1."ID",'''||tbl_nme||''',''SUB_CRY'',t1."SUB_CRY"::text,''Addr Sub_Cry does not match with Mtr_Subcod in Poi Cat'',''1.1.1''
		FROM ( (SELECT "SUB_CRY" FROM '||sch_name||'."'||tbl_nme||'" WHERE (COALESCE("SUB_CRY",'''')<> '''') ) EXCEPT
		(SELECT "MTR_SUBCOD" FROM '||tbl_name_poi_cat||' WHERE (COALESCE("MTR_SUBCOD",'''')<> '''') ) ) As t, '||sch_name||'."'||tbl_nme||'" As t1 WHERE 
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
		
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 18.1:%',f1;
		RAISE info 'error caught 18.2:%',f2;
	END;
	RAISE NOTICE 'time spent =%', clock_timestamp() - t;	
	END IF;
	
--2.62.21
	BEGIN	
		EXECUTE 'INSERT INTO '||qaerrortabname||' (addr_id,table_name,field_name,field_value,error_type,error_code)
				 SELECT "ID",'''||tbl_nme||''',''NAME'',"NAME"::text, ''Name should be in Proper case'',''2.62.21''
				 FROM '||sch_name||'."'|| UPPER(tbl_nme) ||'"
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
				
		EXECUTE'insert into '||functionerrortabname||' (message,context,user_id,layer_nme) values('''||f1||''','''||f2||''','''||user_id||''','''||tbl_nme||''')';
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
	END;	
--IGNORE ERRORS FROM EXCEPTION TABLE 	
	BEGIN
		EXECUTE 'select count(table_name) from information_schema.tables where table_schema=''mmi_lock'' and table_name=''explog''' into count;

		IF count=1 THEN
			-- EXECUTE 'DELETE FROM qa.'||user_id||'_attobj a WHERE EXISTS (select * FROM mmi_lock.explog b WHERE a.unquid=b.un_id and coalesce(a.field_name,'''')=coalesce(b.field_name,'''') and coalesce(a.field_value,'''')=coalesce(b.field_value,'''') and coalesce(a.error_type,'''')=coalesce(b.error_type,'''') and coalesce(a.error_code,'''')=coalesce(b.error_code,'''') and coalesce(b.user_id,'''')='''||UPPER(user_id)||''')';
			EXECUTE 'DELETE FROM '||qaerrortabname||' a WHERE EXISTS (select * FROM addr_features_lock.explog b WHERE a.addr_id=b.un_id and coalesce(TRIM(a.field_name),'''')=coalesce(TRIM(b.field_name),'''') and (coalesce(TRIM(a.field_value),'''')=coalesce(TRIM(b.field_value),'''') OR coalesce(TRIM(b.field_value),'''')=''NULLVAL'') and coalesce(TRIM(a.error_type),'''')=coalesce(TRIM(b.error_type),'''') and coalesce(TRIM(a.error_code),'''')=coalesce(TRIM(b.error_code),'''') and TRIM(b.user_id)='''||UPPER(user_id)||''')';
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
	begin
	EXECUTE FORMAT('SELECT count(*) FROM %1$s',qaerrortabname) INTO errortablecount;
	RAISE INFO 'TOTAL ERROR COUNT:%',errortablecount;
	IF (errortablecount IS NOT NULL) THEN
		EXECUTE FORMAT('UPDATE %1$s SET err_attrib_count=%2$s,err_attrib_error_tabname=''%3$s'' WHERE id in (select max(id) from %1$s where edt_table_name=''%4$s'')',qauploadlogtabname,errortablecount,qaerrortabname,tbl_nme);
		EXECUTE FORMAT('UPDATE %1$s SET error_count=%2$s WHERE error_tab_name=''%3$s''',qaerrortablelogtabname,errortablecount,error_tab_name);
		RETURNVAL = errortablecount;
	END IF;	

	RETURN RETURNVAL;

	EXCEPTION
		WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS 
			f1=MESSAGE_TEXT,
			f2=PG_EXCEPTION_CONTEXT; 
		RAISE info 'error caught 2.1:%',f1;
		RAISE info 'error caught 2.2:%',f2;
		RETURNVAL = -1;
	end;
	RETURN RETURNVAL;
	
END;	

$BODY$;

ALTER FUNCTION qaupload.qc_addr_point_attribute(character varying, character varying, character varying, text)
    OWNER TO postgres;
