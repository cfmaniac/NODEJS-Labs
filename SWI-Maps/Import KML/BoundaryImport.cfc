<cfComponent
	Description	= ""
	Hint		= ""
	output		= "no"
	extends		= "CFExpose.ComponentExtension"
	accessors	= "yes"
>

	<cfProperty name="FilePath" type="string" />
	<cfProperty name="CsvFile" type="CFExpose.CsvKit.CsvFile" />

	<cfFunction
		name		= "setCsvFile"
		returnType	= "any"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfArgument name="CsvFile" required="yes" type="CFExpose.CsvKit.CsvFile" hint="" />
		<cfScript>
			variables.CsvFile = arguments.CsvFile;
			return this;
		</cfScript>
	</cfFunction>

	<cfFunction
		name		= "getCsvFile"
		returnType	= "any"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfScript>
			if( NOT structKeyExists(variables, "CsvFile") )
			{
				variables.CsvFile = new CFExpose.CsvKit.CsvFile(var=getFilePath());
				variables.CsvFile.getBatch().setBatchSize(12);
				variables.CsvFile.getCsvConfig().setTextQualifier('"');
			}

			return variables.CsvFile;
		</cfScript>
	</cfFunction>

	<cfFunction
		name		= "getParser"
		returnType	= "any"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfScript>
			if(structKeyExists(variables, "Parser"))
				return variables.Parser;

			local.CsvFile = getCsvFile();
			variables.Parser = local.CsvFile.getParser();
			return variables.Parser;
		</cfScript>
	</cfFunction>

	<cfFunction
		name		= "getRawStructOfArrays"
		returnType	= "any"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfScript>
			return getParser().getStructOfArrays();
		</cfScript>
	</cfFunction>

	<cfFunction
		name		= "geoXmlToSegmentArray"
		returnType	= "array"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfArgument name="geoXml" required="yes" type="xml" hint="" />
		<cfScript>
			local.returnArray = arrayNew(1);

			local.isMultiSegment = structKeyExists(arguments.geoXml, "MultiGeometry");

			if(local.isMultiSegment)
				local.segmentArray = arguments.geoXml.MultiGeometry.xmlChildren;
			else
				local.segmentArray = [arguments.geoXml.Polygon];

			for(local.sIndex=arrayLen(local.segmentArray); local.sIndex > 0; --local.sIndex)
			{
				local.boundaryDef = local.segmentArray[local.sIndex].outerBoundaryIs;

				if(structKeyExists(local.boundaryDef, "LinearRing"))
					local.coordinates = local.boundaryDef.LinearRing.coordinates.xmlText;
				else
					local.coordinates = local.boundaryDef.coordinates.xmlText;

				arrayPrepend(local.returnArray, local.coordinates);
			}


			return local.returnArray;
		</cfScript>
	</cfFunction>

	<cfFunction
		name		= "getStructOfArrays"
		returnType	= "struct"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfScript>
			local.rawStructOfArrays = getRawStructOfArrays();
			local.geometryArray = local.rawStructOfArrays.geometry;

			//destination loop (state,county,city)
			for(local.gIndex=arrayLen(local.geometryArray); local.gIndex > 0; --local.gIndex)
			{
				local.geoXmlString = local.geometryArray[local.gIndex];
				local.segLatLonArray = arrayNew(1);
				local.geoSegmentArray = geoXmlToSegmentArray(xmlParse(local.geoXmlString));
				//segment loop
				for(local.gsIndex=arrayLen(local.geoSegmentArray); local.gsIndex > 0; --local.gsIndex)
				{
					local.segString = local.geoSegmentArray[local.gsIndex];
					local.segArray = listToArray(local.segString, ' ');

					local.latLonStruct = {lat=arrayNew(1), lon=arrayNew(1)};
					//boundary lat lon loop
					for(local.llIndex=arrayLen(local.segArray); local.llIndex > 0; --local.llIndex)
					{
						local.latLonArray = listToArray(local.segArray[local.llIndex]);
						/* !!! KML has lat lon backwards */
							local.lat = local.latLonArray[2];
							local.lon = local.latLonArray[1];
						/* end: KML */

						arrayPrepend(local.latLonStruct.lat, local.lat);
						arrayPrepend(local.latLonStruct.lon, local.lon);
					}

					arrayPrepend(local.segLatLonArray, local.latLonStruct);
				}

				local.rawStructOfArrays.geometry[local.gIndex] = local.segLatLonArray;
			}

			return local.rawStructOfArrays;
		</cfScript>
	</cfFunction>

</cfComponent>