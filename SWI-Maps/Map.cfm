<cfScript>
	local.NationalSalesMap = new NationalSalesMap();
	local.NationalSalesMap.setUrlAddressStamp('/map/NationalSalesMap.cfc?method=getRemoteOutput');
	local.NationalSalesMap.getGeoFetcher().setUrlAddressStamp('/map/GeoFetcher.cfc?method=getRemoteOutput');

	/* request parameters */
		if(structKeyExists(request.clientInput, "zip"))
		{
			if(!structKeyExists(request.clientInput, 'geoStartType'))
				request.clientInput.geoStartType = 'zip';

			local.Zip = entityLoadByPk('Zip',request.clientInput.zip);
		}

		if(structKeyExists(request.clientInput, "geoStartType") AND structKeyExists(local, "Zip"))
		{
			switch(request.clientInput.geoStartType)
			{
				case 'state':
					local.NationalSalesMap.setGeoStartId(local.Zip.getState().getStateId());
					break;

				case 'county':
					local.NationalSalesMap.setGeoStartId(local.Zip.getCounty().getCountyId());
					break;

				default:
					local.NationalSalesMap.setGeoStartId(local.Zip.getZipNumber());
			}

			local.NationalSalesMap.setGeoStartType(request.clientInput.geoStartType);
		}


		local.NationalSalesMap.setDomainId( request.DomainVerbiage.getDomainId() );
	/* end */

	/* javascript dependents */
		local.jOlOs = new Tagol.Javascript.Kits.jOlOs();
		local.jOlOs.BrowserResets();
		local.jOlOs.BrowserDefaults();
	/* end */
</cfScript>
<!DOCTYPE html>
<html>
	<head>
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<style>
			html,body {width:100%;height:100%;font-family:Helvetica, arial; }
			.ui-page {height:100%;width:100%}
			.fixedHeight{font-size: 2.0em;}
		</style>
	</head>
	<body>
		<div data-role="page" style="width:100%;height:100%;">
			<!---
			<div data-role="header">
				<h1>My Title</h1>
			</div>
			--->
			<div data-role="content" style="padding:0px;height:100%;width:100%">
				<cfOutput>#local.NationalSalesMap.getOutput()#</cfOutput>
			</div>
		</div>
	</body>
</html>
