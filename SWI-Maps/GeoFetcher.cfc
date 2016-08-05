<cfComponent
	Description	= ""
	Hint		= ""
	output		= "no"
	extends		= "Tagol.Javascript.RequestSwitch"
	accessors	= "yes"
>

	<cfProperty name="DomainId" type="numeric" />
	<cfScript>
		variables.colors={sold='##f90acb', available='green', partial='orange'};
	</cfScript>

	<cfFunction
		name		= "setDomainId"
		returnType	= "any"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfArgument name="DomainId" required="yes" type="numeric" hint="" />
		<cfScript>
			variables.DomainId = arguments.DomainId;
			return this;
		</cfScript>
	</cfFunction>

	<!--- state --->
		<cfFunction
			name		= "getStateSumarryQueryById"
			returnType	= "query"
			access		= "public"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfArgument name="stateId" required="yes" type="numeric" hint="" />
			<cfQuery name="local.getStateSumarryQueryById" timeout="120">
				DECLARE	@stateId int,@verticalId int

				SELECT	@stateId = <cfQueryParam value="#arguments.stateId#" cfsqltype="cf_sql_INTEGER" />
						,@verticalId = <cfQueryParam value="#getDomainId()#" cfsqltype="cf_sql_INTEGER" />

				SELECT	--ss.Population,
						ss.PopulationEstimate,ss.CountyCount,ss.ZipCount
						,CountyPurchaseCount=
						(
							SELECT	COUNT(*)
							FROM	dbo.CountyToDomainAvailability
							WHERE	IsAvailable=0
							AND		StateId = ss.StateId
							AND		VerticalId = @verticalId
						)
						,ZipPurchaseCount=
						(
							SELECT	COUNT(*)
							FROM	geo.Zips z WITH (NOLOCK)
							JOIN	dbo.ZipToDomainAvailability zda
							ON		zda.ZipNumber = z.ZipNumber
							WHERE	IsAvailable=0
							AND		z.StateId = ss.StateId
							AND		VerticalId = @verticalId
						)
				FROM	geo.StateStats ss
				WHERE	ss.StateId = @stateId
			</cfQuery>
			<cfReturn local.getStateSumarryQueryById />
		</cfFunction>

		<cfFunction
			name		= "getStateBoundaryJson"
			returnType	= "string"
			access		= "public"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfScript>
				return serializeJson(getStateBoundaryArray());
			</cfScript>
		</cfFunction>

		<cfFunction
			name		= "getStateBoundaryArray"
			returnType	= "array"
			access		= "public"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfScript>
				local.returnArray = arrayNew(1);

				local.sQuery = getStateBoundaryQuery();
			</cfScript>
			<cfOutput query="local.sQuery" group="StateId">
				<cfset local.segmentArray = arrayNew(1) />
				<cfOutput group="segmentId">
					<cfset local.boundArray = arrayNew(1) />
					<cfOutput>
						<cfset arrayAppend(local.boundArray, [local.sQuery.lat[currentRow], local.sQuery.lon[currentRow]]) />
					</cfOutput>
					<cfset arrayAppend(local.segmentArray, local.boundArray) />
				</cfOutput>
				<cfScript>
					local.stateStruct=
					{
						 stateId		= local.sQuery.stateId[currentRow]
						,name			= local.sQuery.name[currentRow]
						,abbr			= local.sQuery.abbr[currentRow]
						,segmentArray	= local.segmentArray
						,CenterLon		= local.sQuery.centerLon[currentRow]
						,CenterLat		= local.sQuery.centerLat[currentRow]
					};

					arrayAppend(local.returnArray, local.stateStruct);
				</cfScript>
			</cfOutput>
			<cfScript>
				return local.returnArray;
			</cfScript>
		</cfFunction>

		<cfFunction
			name		= "getStateBoundaryQuery"
			returnType	= "query"
			access		= "public"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfQuery name="local.getStateBoundaryQuery" timeout="120" cachedWithin="#createTimeSpan(0, 6, 0, 0)#">
				SELECT		sb.StateId,sb.SegmentId,sb.Lat,sb.Lon
							,s.Abbr,s.Name,CenterLat=s.Lat,CenterLon=s.Long
				FROM		geo.StateBoundaries sb
				JOIN		geo.States s
				ON			s.StateId = sb.StateId
				WHERE		s.FipsInteger < 60
				ORDER BY	sb.StateId,sb.SegmentId,sb.StateBoundaryId
			</cfQuery>
			<cfReturn local.getStateBoundaryQuery />
		</cfFunction>

		<cfFunction
			name		= "getStateStatusJsonQuery"
			returnType	= "string"
			access		= "remote"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfScript>
				return serializeJson(getStateStatusQuery());
			</cfScript>
		</cfFunction>

		<cfFunction
			name		= "getStateStatusQuery"
			returnType	= "query"
			access		= "public"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfQuery name="local.getStateStatusQuery" timeout="120">
				SELECT	sda.StateId
						,PopEst=ss.PopulationEstimate
						,FillColor=
						CASE
							WHEN sda.IsAvailable = 0--SOLD
							THEN '#variables.colors.sold#'
							WHEN sda.IsAvailable != ss.ZipCount--PARTIAL SOLD
							THEN '#variables.colors.partial#'
							ELSE '#variables.colors.available#'--ALL AVAILABLE
						END
				FROM	dbo.StateToDomainAvailability sda
				JOIN	geo.States s WITH (NOLOCK)
				ON		s.StateId = sda.StateId
				AND		s.FipsInteger < 60
				JOIN	geo.StateStats ss WITH (NOLOCK)
				ON		s.StateId = ss.StateId
				WHERE	sda.VerticalId IN (<cfQueryParam value="#getDomainId()#" cfsqltype="cf_sql_INTEGER" list="yes" />)
			</cfQuery>
			<cfReturn local.getStateStatusQuery />
		</cfFunction>
	<!--- end: state --->

	<!--- state to county --->
		<cfFunction
			name		= "getCountyStatusJsonQueryByStateId"
			returnType	= "string"
			access		= "remote"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfArgument name="stateId"	required="yes"	type="numeric"	hint="" />
			<cfArgument name="countyId"	required="no"	type="string"	hint="" />
			<cfScript>
				if(structKeyExists(arguments, "countyId") AND !isNumeric(arguments.countyId))
					structDelete(arguments, "countyId");

				return serializeJson(getCountyStatusQueryByStateId(argumentCollection=arguments));
			</cfScript>
		</cfFunction>

		<cfFunction
			name		= "getCountyStatusQueryByStateId"
			returnType	= "query"
			access		= "public"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfArgument name="stateId"	required="yes"	type="numeric"	hint="" />
			<cfArgument name="countyId"	required="no"	type="numeric"	hint="" />
			<cfQuery name="local.getCountyStatusQueryByStateId" timeout="120">
					SELECT	cda.CountyId
							,FillColor=
							CASE
								WHEN cda.IsAvailable = 0--SOLD
								THEN '#variables.colors.sold#'
								WHEN cda.IsAvailable != cs.ZipCount--PARTIAL SOLD
								THEN '#variables.colors.partial#'
								ELSE '#variables.colors.available#'--ALL AVAILABLE
							END
							,ZipsSold=CASE WHEN cda.IsAvailable=0 THEN cs.ZipCount ELSE cs.ZipCount - cda.IsAvailable END
							,Competitors=
							(
								SELECT	COUNT(*)
								FROM	McDermottDev.tbl_business
								WHERE	DomainId = <cfQueryParam value="#getDomainId()#" cfsqltype="cf_sql_INTEGER" />
								AND		AddressZipNumber
								IN		(
											SELECT	ZipNumber
											FROM	geo.ZipRelations
											WHERE	CountyId = co.CountyId
										)
							)
					FROM	dbo.CountyToDomainAvailability cda
					JOIN	geo.Counties co WITH (NOLOCK)
					ON		cda.CountyId = co.CountyId
				<cfif arguments.stateId GT 0 OR !structKeyExists(arguments, 'countyId') >
					AND		co.StateId = <cfQueryParam value="#arguments.stateId#" cfsqltype="cf_sql_INTEGER" />
				</cfif>
				<cfif structKeyExists(arguments, 'countyId') >
					AND		co.CountyId = <cfQueryParam value="#arguments.countyId#" cfsqltype="cf_sql_INTEGER" />
				</cfif>
					JOIN	geo.CountyStats cs WITH (NOLOCK)
					ON		cs.CountyId = co.CountyId
					WHERE	cda.VerticalId = <cfQueryParam value="#getDomainId()#" cfsqltype="cf_sql_INTEGER" />
					<cf_QueryLogLine />
			</cfQuery>
			<cfReturn local.getCountyStatusQueryByStateId />
		</cfFunction>

		<cfFunction
			name		= "getCountyJsonByStateId"
			returnFormat= "plain"
			returnType	= "string"
			access		= "remote"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfArgument name="stateId"	required="yes"	type="numeric"	hint="" />
			<cfArgument name="countyId"	required="no"	type="string"	hint="" />
			<cfScript>
				if(structKeyExists(arguments, "countyId") AND !isNumeric(arguments.countyId))
					structDelete(arguments, "countyId");

				return serializeJson( getCountyQueryByStateId(argumentCollection=arguments) );
			</cfScript>
		</cfFunction>

		<cfFunction
			name		= "getCountyQueryByStateId"
			returnType	= "query"
			access		= "public"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfArgument name="stateId"	required="yes"	type="numeric"	hint="" />
			<cfArgument name="countyId"	required="no"	type="numeric"	hint="" />
			<cfQuery name="local.getCountyQueryByStateId" timeout="120" cachedWithin="#createTimeSpan(0, 1, 0, 0)#">
					SELECT		co.Name,co.CountyId
								,CenterLat=co.Lat,CenterLon=co.Long,co.StateId
								,PopEst=cs.PopulationEstimate
								,Zips=cs.ZipCount
								,zcp.Cost
					FROM		geo.Counties co
					LEFT JOIN	geo.CountyStats cs
					ON			cs.CountyId = co.CountyId
					Left Join dbo.tbl_ZipCode_Pricing zcp 
					on co.name = zcp.county
					WHERE		0=0
				<cfif arguments.stateId GT 0 OR !structKeyExists(arguments, "countyId") >
					AND			co.StateId = <cfQueryParam value="#arguments.stateId#" cfsqltype="cf_sql_INTEGER" />
				</cfif>
				<cfif arguments.stateId eq 0 AND structKeyExists(arguments, "countyId") >
					AND			co.CountyId = <cfQueryParam value="#arguments.countyId#" cfsqltype="cf_sql_INTEGER" />
				</cfif>
					<cf_QueryLogLine />
			</cfQuery>
			<cfReturn local.getCountyQueryByStateId />
		</cfFunction>
	<!--- end: state to county --->

	<!--- County --->
		<cfFunction
			name		= "getCountyQueryById"
			returnType	= "query"
			access		= "public"
			output		= "no"
			hint		= ""
			description	= "not used"
		>
			<cfArgument name="countyId" required="yes" type="numeric" hint="" />
			<cfQuery name="local.getCountyQueryById" timeout="120">
				SELECT		co.Name,co.CountyId
							,CenterLat=co.Lat,CenterLon=co.Long,co.StateId
							,PopEst=cs.PopulationEstimate
							,Zips=cs.ZipCount
				FROM		geo.Counties co
				LEFT JOIN	geo.CountyStats cs
				ON			cs.CountyId = co.CountyId
				WHERE		0 = 0
				AND			co.CountyId in (<cfQueryParam value="#arguments.countyId#" cfsqltype="cf_sql_INTEGER" list="yes" />)
			</cfQuery>
			<cfReturn local.getCountyQueryById />
		</cfFunction>

		<cfFunction
			name		= "getCountySumarryQueryById"
			returnType	= "query"
			access		= "public"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfArgument name="countyId" required="yes" type="numeric" hint="" />
			<cfQuery name="local.getCountySumarryQueryById" timeout="120">
				DECLARE	@countyId int,@verticalId int

				SELECT	@countyId = <cfQueryParam value="#arguments.countyId#" cfsqltype="cf_sql_INTEGER" />
						,@verticalId = <cfQueryParam value="#getDomainId()#" cfsqltype="cf_sql_INTEGER" />

				SELECT	--cs.Population,
						cs.PopulationEstimate,cs.CityCount,cs.ZipCount
						,ZipPurchaseCount=
						(
							SELECT	COUNT(*)
							FROM	geo.Zips z WITH (NOLOCK)
							JOIN	dbo.ZipToDomainAvailability zda
							ON		zda.ZipNumber = z.ZipNumber
							
							WHERE	IsAvailable=0
							AND		z.CountyId = cs.CountyId
							AND		VerticalId = @verticalId
						),
						CountyCost=
						(
						SELECT		ZCP.cost
					FROM		geo.Counties co
					LEFT JOIN	geo.CountyStats cs
					ON			cs.CountyId = co.CountyId
					Left Join dbo.tbl_ZipCode_Pricing zcp on co.name = zcp.county
					WHERE		0=0
					AND			co.CountyId = @countyId
						),
						Cities=
						(
						SELECT		ZCP.Cities
					FROM		geo.Counties co
					LEFT JOIN	geo.CountyStats cs
					ON			cs.CountyId = co.CountyId
					Left Join dbo.tbl_ZipCode_Pricing zcp on co.name = zcp.county
					WHERE		0=0
					AND			co.CountyId = @countyId
						)
						/*
						,CityPurchaseCount=
						(
							SELECT	COUNT(*)
							FROM	dbo.CityToDomainAvailability
							WHERE	IsAvailable=0
							AND		CountyId = cs.CountyId
							AND		VerticalId = @verticalId
						)
						*/
				FROM	geo.CountyStats cs
				
				WHERE	cs.CountyId = @countyId
			</cfQuery>
			<cfReturn local.getCountySumarryQueryById />
		</cfFunction>

		<cfFunction
			name		= "getCountyBoundaryArrayById"
			returnType	= "array"
			access		= "public"
			output		= "no"
			hint		= "accepts list of countyids"
			description	= ""
		>
			<cfArgument name="countyId" required="yes" type="string" hint="" />
			<cfScript>
				local.returnArray = arrayNew(1);

				local.cQuery = getCountyBoundaryQueryById(arguments.countyId);
				return geoBoundaryQueryToArray(local.cQuery, 'countyId');
			</cfScript>
		</cfFunction>

		<cfFunction
			name		= "getCountyBoundaryQueryById"
			returnType	= "query"
			access		= "public"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfArgument name="countyId" required="yes" type="string" hint="" />
			<cfQuery name="local.getCountyBoundaryQueryByStateId" timeout="120">
				SELECT		cob.SegmentId,cob.Lat,cob.Lon,cob.CountyId
				FROM		geo.CountyBoundaries cob
				WHERE		cob.CountyId IN (<cfQueryParam value="#arguments.countyId#" cfsqltype="cf_sql_INTEGER" list="yes" />)
				ORDER BY	cob.CountyId, cob.SegmentId, cob.CountyBoundaryId
			</cfQuery>
			<cfReturn local.getCountyBoundaryQueryByStateId />
		</cfFunction>

		<cfFunction
			name		= "getCountyBoundaryJsonById"
			returnFormat= "plain"
			returnType	= "string"
			access		= "remote"
			output		= "no"
			hint		= "accepts lists"
			description	= ""
		>
			<cfArgument name="countyId" required="yes" type="string" hint="" />
			<cfScript>
				return serializeJson( getCountyBoundaryArrayById(arguments.countyId) );
			</cfScript>
		</cfFunction>
	<!--- end: County --->

	<!--- zip --->
		<cfFunction
			name		= "getZipBoundaryJsonById"
			returnFormat= "plain"
			returnType	= "string"
			access		= "remote"
			output		= "no"
			hint		= "accepts lists"
			description	= ""
		>
			<cfArgument name="zipNumber" required="yes" type="string" hint="" />
			<cfScript>
				return serializeJson( getZipBoundaryArrayById(arguments.zipNumber) );
			</cfScript>
		</cfFunction>

		<cfFunction
			name		= "getZipBoundaryArrayById"
			returnType	= "array"
			access		= "public"
			output		= "no"
			hint		= "accepts list of countyids"
			description	= ""
		>
			<cfArgument name="zipNumber" required="yes" type="string" hint="" />
			<cfScript>
				local.zQuery = getZipBoundaryQueryById(arguments.zipNumber);
				return geoBoundaryQueryToArray(local.zQuery, 'ZipNumber');
			</cfScript>
		</cfFunction>

		<cfFunction
			name		= "getZipBoundaryQueryById"
			returnType	= "query"
			access		= "public"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfArgument name="ZipNumber" required="yes" type="string" hint="" />
			<cfQuery name="local.getZipBoundaryQueryById" timeout="120">
				SELECT		SegmentId=1,Lat,Lon=Lng,ZipNumber
				FROM		tbl_zip_boundaries
				WHERE		ZipNumber IN (<cfQueryParam value="#arguments.zipNumber#" cfsqltype="cf_sql_INTEGER" list="yes" />)
				AND			Start = 0
				ORDER BY	ZipNumber, BoundaryId desc
			</cfQuery>
			<cfReturn local.getZipBoundaryQueryById />
		</cfFunction>

		<cfFunction
			name		= "getZipSumarryQueryById"
			returnType	= "query"
			access		= "public"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfArgument name="zipNumber" required="yes" type="numeric" hint="" />
			<cfQuery name="local.getCountySumarryQueryById" timeout="120">
				DECLARE	@zipNumber int,@verticalId int

				SELECT		@zipNumber = <cfQueryParam value="#arguments.zipNumber#" cfsqltype="cf_sql_INTEGER" />
							,@verticalId = <cfQueryParam value="#getDomainId()#" cfsqltype="cf_sql_INTEGER" />

				/*SELECT		--zs.Population,
							zs.PopulationEstimate
							,zda.IsAvailable
				FROM		geo.ZipStats zs WITH (NOLOCK)
				LEFT JOIN	dbo.ZipToDomainAvailability zda
				ON			zda.ZipNumber = zs.ZipNumber
				WHERE		zs.ZipNumber = @zipNumber
				AND			zda.VerticalId = @verticalId*/
				
				SELECT		--zs.Population,
							zs.PopulationEstimate
							,zda.IsAvailable, zcp.cost
				FROM		geo.ZipStats zs WITH (NOLOCK)
				LEFT JOIN	dbo.ZipToDomainAvailability zda
				ON			zda.ZipNumber = zs.ZipNumber
				Left JOIN   geo.Zips zip
				ON          zip.zipnumber = zs.ZipNumber
				Left Join   geo.Counties zct
				ON			zip.countyid = zct.countyID
				Left Join   dbo.tbl_ZipCode_Pricing zcp
				On          zct.Name = zcp.county
				WHERE		zs.ZipNumber = @zipNumber
				AND			zda.VerticalId = @verticalID
				
			</cfQuery>
			<cfReturn local.getCountySumarryQueryById />
		</cfFunction>
	<!--- end: zip --->

	<cfFunction
		name		= "geoBoundaryQueryToArray"
		returnType	= "array"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfArgument name="query"		required="yes" type="query" hint="" />
		<cfArgument name="pkColumnName"	required="yes" type="string" hint="" />
		<cfScript>
			local.returnArray = arrayNew(1);
			arguments.pkColumnName = uCase(arguments.pkColumnName);
		</cfScript>
		<cfOutput query="arguments.query" group="#arguments.pkColumnName#">
			<cfset local.segmentArray = arrayNew(1) />
			<cfOutput group="segmentId">
				<cfset local.boundArray = arrayNew(1) />
				<cfOutput>
					<cfset arrayAppend(local.boundArray, [arguments.query.lat[currentRow], arguments.query.lon[currentRow]]) />
				</cfOutput>
				<cfset arrayAppend(local.segmentArray, local.boundArray) />
			</cfOutput>
			<cfScript>
				local.zipStruct = {segmentArray=local.segmentArray};
				local.zipStruct[arguments.pkColumnName] = arguments.query[arguments.pkColumnName][currentRow];
				arrayAppend(local.returnArray, local.zipStruct);
			</cfScript>
		</cfOutput>
		<cfScript>
			return local.returnArray;
		</cfScript>
	</cfFunction>

	<!--- county to zip --->
		<cfFunction
			name		= "getZipStatusJsonQueryByCountyId"
			returnType	= "string"
			access		= "remote"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfArgument name="countyId" required="yes" type="numeric" hint="" />
			<cfScript>
				return serializeJson(getZipStatusQueryByCountyId(arguments.countyId));
			</cfScript>
		</cfFunction>

		<cfFunction
			name		= "getZipStatusQueryByCountyId"
			returnType	= "query"
			access		= "public"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfArgument name="countyId" required="yes" type="numeric" hint="" />
			<cfQuery name="local.getZipStatusQueryByCountyId" timeout="120">
				SELECT	zda.ZipNumber
						,FillColor=
						CASE
							WHEN zda.IsAvailable = 0--SOLD
							THEN '#variables.colors.sold#'
							ELSE '#variables.colors.available#'
						END
						,Competitors=
						(
							SELECT	COUNT(*)
							FROM	McDermottDev.tbl_business
							WHERE	DomainId = <cfQueryParam value="#getDomainId()#" cfsqltype="cf_sql_INTEGER" />
							AND		AddressZipNumber = z.ZipNumber
						)
				FROM	dbo.ZipToDomainAvailability zda
				JOIN	geo.Zips z WITH (NOLOCK)
				ON		zda.ZipNumber = z.ZipNumber
				AND		z.CountyId = <cfQueryParam value="#arguments.countyId#" cfsqltype="cf_sql_INTEGER" />
				JOIN	geo.ZipStats zs WITH (NOLOCK)
				ON		zs.ZipNumber = z.ZipNumber
				WHERE	zda.VerticalId = <cfQueryParam value="#getDomainId()#" cfsqltype="cf_sql_INTEGER" />
			</cfQuery>
			<cfReturn local.getZipStatusQueryByCountyId />
		</cfFunction>

		<cfFunction
			name		= "getZipJsonByCountyId"
			returnFormat= "plain"
			returnType	= "string"
			access		= "remote"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfArgument name="countyId" required="yes" type="numeric" hint="" />
			<cfScript>
				return serializeJson( getZipQueryByCountyId(arguments.countyId) );
			</cfScript>
		</cfFunction>

		<cfFunction
			name		= "getZipQueryByCountyId"
			returnType	= "query"
			access		= "public"
			output		= "no"
			hint		= ""
			description	= ""
		>
			<cfArgument name="countyId" required="yes" type="numeric" hint="" />
			<cfQuery name="local.getZipQueryByCountyId" timeout="120" cachedWithin="#createTimeSpan(0, 0, 10, 0)#">
				SELECT		Name=z.ZipNumber,z.ZipNumber
							,CenterLat=z.Lat,CenterLon=z.Long
							,PopEst=zs.PopulationEstimate
							,z.StateId,z.CountyId
				FROM		geo.Zips z
				LEFT JOIN	geo.ZipStats zs
				ON			zs.ZipNumber = z.ZipNumber
				WHERE		z.CountyId = <cfQueryParam value="#arguments.countyId#" cfsqltype="cf_sql_INTEGER" />
			</cfQuery>
			<cfReturn local.getZipQueryByCountyId />
		</cfFunction>
	<!--- end: county to zip --->

	<cfFunction
		name		= "getCompetitorJsonByCountyId"
		returnType	= "string"
		returnFormat= "plain"
		access		= "remote"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfArgument name="countyId" required="yes" type="numeric" hint="" />
		<cfScript>
			return serializeJson(getCompetitorQueryByCountyId(argumentCollection=arguments));
		</cfScript>
	</cfFunction>

	<cfFunction
		name		= "getCompetitorArrayByCountyId"
		returnType	= "array"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfArgument name="countyId" required="yes" type="numeric" hint="" />
		<cfArgument name="maxRows" required="no" type="numeric" hint="" />
		<cfScript>
			local.filters.domainId = getDomainId();
			local.filters.addressZipNumbers = getZipNumberArrayByCountyId(argumentCollection=arguments);

			local.options = {};
			if(structKeyExists(arguments, "maxRows"))
				local.options.maxresults = arguments.maxRows;

			local.hql=
			'
				FROM	Business b
				WHERE	b.Active=1
				AND		b.DomainId=:DomainId
				AND		b.AddressZipNumber IN (:AddressZipNumbers)
			';

			local.hql = CFMethods().cleanseHqlString(local.hql);

			return ormExecuteQuery(local.hql, local.filters, false, local.options);
		</cfScript>
	</cfFunction>

	<cfFunction
		name		= "getZipNumberArrayByCountyId"
		returnType	= "array"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfArgument name="countyId" required="yes" type="numeric" hint="" />
		<cfScript>
		</cfScript>
		<cfQuery name="local.getZipNumberArrayByCountyId" timeout="120">
			SELECT	ZipNumber
			FROM	geo.Zips WITH (NOLOCK)
			WHERE	CountyId = <cfQueryParam value="#arguments.countyId#" list="no" />
		</cfQuery>
		<cfReturn listToArray(valueList(local.getZipNumberArrayByCountyId.ZipNumber)) />
	</cfFunction>

	<cfFunction
		name		= "getCompetitorQueryByCountyId"
		returnType	= "query"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfArgument name="countyId"			required="yes" type="numeric" hint="" />
		<cfArgument name="isLatLonRequired"	required="no" type="boolean" default="true" hint="" />
		<cfArgument name="maxRows"			required="no" type="numeric" hint="" />
		<cfQuery name="local.getCompetitorQueryByCountyId" timeout="120">
				SELECT	<cfif structKeyExists(arguments, "maxRows") >
							TOP (<cfQueryParam value="#arguments.maxRows#" cfsqltype="cf_sql_INTEGER" />)
						</cfif>
						Lat,Lon
						,BusinessId=uid,BusinessName=bizName
						,addressStreet,addressStreet2,addressCity,addressState
						,AddressZipNumber
				FROM	mcdermottdev.tbl_business WITH (NOLOCK)
				WHERE	AddressZipNumber
				IN		(
							SELECT	ZipNumber
							FROM	geo.Zips WITH (NOLOCK)
							WHERE	CountyId = 	<cfQueryParam value="#arguments.countyId#" list="no" />
						)
				AND		DomainId = <cfQueryParam value="#getDomainId()#" cfsqltype="cf_sql_integer" />
			<cfif arguments.isLatLonRequired >
				AND		LEN(Lat) > 0
				AND		LEN(Lon) > 0
			</cfif>
			<cf_QueryLogLine />
		</cfQuery>
		<cfReturn local.getCompetitorQueryByCountyId />
	</cfFunction>

</cfComponent>
<!---
	<cfFunction
		name		= "getCountyBoundaryQueryByStateId"
		returnType	= "query"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfArgument name="stateId" required="yes" type="numeric" hint="" />
		<cfQuery name="local.getCountyBoundaryQueryByStateId" timeout="120" cachedWithin="#createTimeSpan(0, 0, 15, 0)#">
			SELECT		cob.SegmentId,cob.Lat,cob.Lon,cob.CountyId
			FROM		geo.CountyBoundaries cob
			WHERE		cob.CountyId
			IN			(
							SELECT	CountyId
							FROM	Geo.Counties WITH (NOLOCK)
							WHERE	StateId = <cfQueryParam value="#arguments.stateId#" cfsqltype="cf_sql_INTEGER" />
						)
			ORDER BY	cob.SegmentId,cob.CountyBoundaryId
		</cfQuery>
		<cfReturn local.getCountyBoundaryQueryByStateId />
	</cfFunction>
--->