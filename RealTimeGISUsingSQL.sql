	--- This example is utilizing fire department AVL's where the GPS pings are stored in the database as x and y values which are int data types.
  
	--- Purge Existing Old Data
	Delete from [Database].[Schema].[FeatureClass]
	where unit not in (select unit from [Database].[Schema].[GPS_Table] where unit_type = 'f' and unit_kind in ('Supervisor','Engine','Truck','HazMat','Squad') and active_flag<>0)

	--inserts new units
	insert into [Database].[Schema].[FeatureClass] (ObjectID,Shape,GDB_GEOMATTR_DATA,Unit,active_flag,Lat,Long,unit_kind,CallID)
	--- Auto Calculate ObjectID based on the number of records currently in the feature class
	select case when (select count(*) from [Database].[Schema].[FeatureClass]) = 0
	then row_number() over(order by unit)
	else (select  max(objectid) from [Database].[Schema].[FeatureClass])+row_number() over(order by unit) end as ObjectID,
	--- Calculates the shape blob based on in the x, y, and SRID
	--- syntax is geometry::Point(X,Y,SRID)
	geometry::Point(cast (x as decimal(15,1))/1000000,cast(y as decimal(15,1))/1000000,4326) as shape,
	null as GDB_GEOMATTR_DATA,
	unit,
	active_flag,
	cast(y as decimal(15,1))/1000000 as Lat, 
	cast(x as decimal(15,1))/1000000 as Long, 
	unit_kind,
	callid
	from [Database].[Schema].[GPS_Table]
	where unit not in (select unit from [Database].[Schema].[FeatureClass]) AND unit_kind in ('Supervisor','Engine','Truck','HazMat','Squad') and agency = 'VFD'
	and x <> 0

	--updates existing units
	update a
	set a.lat = cast(b.y as decimal(15,1))/1000000,
	a.long = cast(b.x as decimal(15,1))/1000000,
	a.active_flag = b.active_flag,
	a.unit_kind = b.unit_kind,
	a.shape = geometry::Point(cast (b.x as decimal(15,1))/1000000,cast(b.y as decimal(15,1))/1000000,4326),
	a.callid = b.callid
	from [Database].[Schema].[FeatureClass] a
	join [Database].[Schema].[GPS_Table] b
	on a.unit = b.unit
	where a.lat <> cast (b.y as decimal(15,1))/1000000
	or a.long <> cast (b.x as decimal(15,1))/1000000
	or a.active_flag <> b.active_flag
	or a.unit_kind <> b.unit_kind
	or a.callid <> b.callid
