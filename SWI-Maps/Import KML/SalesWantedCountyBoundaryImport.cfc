<cfComponent
	Description	= ""
	Hint		= ""
	output		= "no"
	extends		= "BoundaryImport"
>
	<cfProperty name="FilePath" type="string" />
	<cfScript>
		variables.filePath = '/Users/Acker/Downloads/United States Counties.csv';
	</cfScript>

	<cfFunction
		name		= "insert"
		returnType	= "any"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfScript>
			local.CsvFile = getCsvFile();
			local.pageCount = local.CsvFile.getTotalPageCount();
		</cfScript>
		<cfSetting requestTimeOut="1260" />
		<cfLoop from="1" to="#local.pageCount#" index="local.page">
			<cfQuery datasource="McDermottDev" timeout="1260">
				#getInsertSyntax()#
			</cfQuery>
			<cfif local.page NEQ local.pageCount >
				<cfset local.CsvFile.gotoNextPage() />
			</cfif>
		</cfLoop>
		<cfScript>
			local.CsvFile.close();
			return this;
		</cfScript>
	</cfFunction>

	<cfFunction
		name		= "getInsertSyntax"
		returnType	= "string"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfScript>
			local.structOfArrays = getStructOfArrays();
		</cfScript>
		<cfSaveContent Variable="local.output">
			<cfOutput>
						INSERT	Geo.CountyBoundaries
								(lat,lon,CountyId,SegmentId)
				<cfLoop from="1" to="#arrayLen(local.structOfArrays['state abbr'])#" index="local.stateIndex">
					<cfScript>
						local.stateAbbr = local.structOfArrays['state abbr'][local.stateIndex];
						local.geometryArray = local.structOfArrays.geometry[local.stateIndex];
						local.countyName = local.structOfArrays['County Name'][local.stateIndex];
					</cfScript>
					<cfif local.stateIndex GT 1 >
						UNION ALL
					</cfif>
						SELECT	i.Lat,i.Lon,co.CountyId,i.SegmentId
						FROM	(
							<cfset local.segmentArray = local.geometryArray />
							<cfLoop from="1" to="#arrayLen(local.segmentArray)#" index="local.segIndex">
								<cfset local.segment = local.segmentArray[local.segIndex] />
								<cfset local.latArray = local.segment.lat />
								<cfset local.lonArray = local.segment.lon />
								<cfLoop from="1" to="#arrayLen(local.latArray)#" index="local.llIndex">
									<cfif local.segIndex GT 1 OR local.llIndex GT 1 >
										UNION ALL
									</cfif>
										SELECT	Lat='#local.latArray[local.llIndex]#'
												,Lon='#local.lonArray[local.llIndex]#'
												,SegmentId=#local.segIndex#
								</cfLoop>
							</cfLoop>
								) i
						JOIN	geo.States s
						ON		s.Abbr = '#local.stateAbbr#'
						JOIN	geo.Counties co
						ON		co.name = '#reReplaceNoCase(local.countyName, chr(39), chr(39)&chr(39), 'all')#'
						AND		co.StateId = s.StateId
				</cfLoop>
			</cfOutput>
		</cfSaveContent>
		<cfset local.output = CFMethods().Strings().removeLeftTabs(local.output,6) />
		<cfReturn local.output />
	</cfFunction>

</cfComponent>