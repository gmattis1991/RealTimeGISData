	--inserts new units
	insert into [Database].[Schema].[FeatureClass] (ObjectID,Shape,GDB_GEOMATTR_DATA,Unit,Latitude,Longitude)
	--- Auto Calculate ObjectID based on the number of records currently in the feature class
	select case when (select count(*) from [Database].[Schema].[FeatureClass]) = 0
	then row_number() over(order by unit)
	else (select  max(objectid) from [Database].[Schema].[FeatureClass])+row_number() over(order by unit) end as ObjectID,
	--- Calculates the shape blob based on in the x, y, and WKID
	--- syntax is geometry::Point(X,Y,WKID)
	geometry::Point(cast X,Y,4326) as shape,
	null as GDB_GEOMATTR_DATA,
	unit,
	Y as Latitude, 
	X as Longitude, 
	from [Database].[Schema].[GPS_Table]
	where unit not in (select unit from [Database].[Schema].[FeatureClass])

	--updates existing units
	update GIS
	set GIS.Latitude = GPS.Y,
	GIS.Longitude = GPS.X,
	GIS.shape = geometry::Point(GPS.X,GPS.Y,4326),
	from [Database].[Schema].[FeatureClass] GIS
	join [Database].[Schema].[GPS_Table] GPS
	on GIS.unit = GPS.unit
	where GIS.Latitude <> GPS.Y
	or GIS.Longitude <> GPS.X
	
	--- Purge Existing Old Data
	Delete from [Database].[Schema].[FeatureClass]
	where unit not in (select unit from [Database].[Schema].[GPS_Table])
