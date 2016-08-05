<cfComponent
	Description	= ""
	Hint		= ""
	output		= "no"
	extends		= "BoundaryImport"
	accessors	= "yes"
>

	<cfProperty name="FilePath" type="string" />
	<cfScript>
		variables.filePath = '/Users/Acker/Downloads/State KML.csv';
	</cfScript>

	<cfFunction
		name		= "insert"
		returnType	= "any"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfQuery timeout="120">
			#preserveSingleQuotes(getInsertSyntax)#
		</cfQuery>
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
						INSERT	Geo.StateBoundaries
								(lat,lon,StateId,SegmentId)
				<cfLoop from="1" to="#arrayLen(local.structOfArrays.id)#" index="local.stateIndex">
					<cfset local.stateId = local.structOfArrays.id[local.stateIndex] />
					<cfset local.geometryArray = local.structOfArrays.geometry[local.stateIndex] />
					<cfif local.stateIndex GT 1 >
						UNION ALL
					</cfif>
						SELECT	i.Lat,i.Lon,s.StateId,i.SegmentId
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
						ON		s.Abbr = '#local.stateId#'
				</cfLoop>
			</cfOutput>
		</cfSaveContent>
		<cfset local.output = CFMethods().Strings().removeLeftTabs(local.output,6) />
		<cfReturn local.output />
	</cfFunction>

</cfComponent>