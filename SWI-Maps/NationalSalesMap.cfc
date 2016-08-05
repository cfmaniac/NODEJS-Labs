<cfComponent
	Description	= ""
	Hint		= ""
	output		= "no"
	extends		= "Tagol.Javascript.RequestSwitch"
	accessors	= "yes"
>

	<cfProperty name="DomainId"		type="numeric" />
	<cfProperty name="MapElement"	type="Tagol.Html.GoogleMap" />
	<cfProperty name="GeoStartId"	type="numeric" />
	<cfProperty name="GeoStartType"	type="string" />

	<cfScript>
		setProcess('getMap');
		setProcessProperty('DomainId');
		//setProcessProperty('CountyId');
	</cfScript>

	<cfFunction
		name		= "loadJquery"
		returnType	= "any"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfScript>
			local.Cfl = new CFExpose.RequestKit.ClientFileLoader();


			local.Cfl.addScript('http://code.jquery.com/mobile/1.2.0-beta.1/jquery.mobile-1.2.0-beta.1.min.css');
//			local.Cfl.addScript('http://code.jquery.com/mobile/1.2.0-alpha.1/jquery.mobile-1.2.0-alpha.1.min.css');

//			local.Cfl.addScript('http://code.jquery.com/jquery-1.7.2.min.js');
			local.Cfl.addScript('https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js');
			local.Cfl.addScript('https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.16/jquery-ui.min.js');

			local.Cfl.addScript('http://code.jquery.com/mobile/1.2.0-beta.1/jquery.mobile-1.2.0-beta.1.min.js');

			return this;
		</cfScript>
	</cfFunction>

	<cfFunction
		name		= "getMap"
		returnType	= "string"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfScript>
			local.MapElement = getMapElement();
			local.Media = new Media();

			local.className = getClassName();
			local.JsClass = local.MapElement.getJsClass();
			local.JsClass.isLoadJquery(0);
			local.parentClassName = local.JsClass.getClassName();

			local.ElementProxy = getProcessElementProxy('getInfoByGeoId');
			local.ElementProxy.getUrlAddress().delete('domainId');
			local.ElementProxy.setElementId('');
			local.ElementProxy.getProxy().getPassthruData().setPassThruFormElement('NationalSalesMapForm');
			local.elementProxyOutput = local.ElementProxy.getOutput();

			local.controlPanelOutput = getControlPanelOutput();

			local.mapElementOutput = local.MapElement.getOutput();

			local.mapElementOutput &= local.elementProxyOutput;

			/* script dependencies */
				local.Cfl = new CFExpose.RequestKit.ClientFileLoader();
				local.Cfl.setUrlAddress(local.Media);

				local.Cfl.addScript('NationalSalesMap.css');

				loadJquery();

				new Tagol.Javascript.Kits.jOlOs().InputLayout();

				local.Cfl.addScript('SwPolygonGeoDrawer.js');
				local.Cfl.addScript('V2SitesMap.js');
				local.mapElementOutput &= local.Cfl.getOutput();
			/* end */

			local.GeoFetcher = getGeoFetcher();
			local.stateJson = local.GeoFetcher.getStateBoundaryJson();

			local.infoUrlAddress = getProcessUrlAddress('getInfoByGeoId');

			/* competitor proxies */
				/* query county */
					local.CompProxy = getGeoFetcher().getProcessProxy('getCompetitorJsonByCountyId');
					local.CompProxy.getUrlAddress().delete('domainId');
					local.CompProxy.getProxy().getPassthruData().setPassThruFormElement('NationalSalesMapForm');
					local.mapElementOutput &= local.CompProxy.getOutput();
				/* end */

				/* info sheet */
					local.CompetitorInfoSheetProxy = getProcessElementProxy('getCompetitorInfoSheet');
					local.CompetitorInfoSheetProxy
					.setElementId('CompetitorSheetDataWrap')
					.getProxy().getPassthruData().setPassThruFormElement('NationalSalesMapForm');
					local.CompetitorInfoSheetProxy.getUrlAddress().delete('domainId');
					local.mapElementOutput &= local.CompetitorInfoSheetProxy.getOutput();
				/* end */
			/* end: competitor query */

			/* state status proxy */
				local.StatusProxy = getGeoFetcher().getProcessProxy('getStateStatusJsonQuery');
				local.SProxy = local.StatusProxy.getProxy();
				local.SProxy.getCallbacks().setJsMethodCallback( '#local.className#.setStateStatusJsonQuery' );
				local.SProxy.getPassthruData().setPassThruFormElement('NationalSalesMapForm');
				local.StatusProxy.getUrlAddress().delete('domainId');
				local.stateStatusProxyName = local.StatusProxy.getClassName();
				local.mapElementOutput &= local.StatusProxy.getOutput();
			/* end */

			/* county proxies */
				/* simple data proxy */
					local.CountyProxy = getGeoFetcher().getProcessProxy('getCountyJsonByStateId');
					local.CountyProxy.getProxy().getPassthruData().setPassThruFormElement('NationalSalesMapForm');
					local.CountyProxy.getUrlAddress().delete('domainId');
					local.mapElementOutput &= local.CountyProxy.getOutput();
				/* end: simple data proxy */
				/* boundary proxy */
					local.CountyBoundaryProxy = getGeoFetcher().getProcessProxy('getCountyBoundaryJsonById');
					local.CountyBoundaryProxy.getUrlAddress().delete('domainId');
					local.mapElementOutput &= local.CountyBoundaryProxy.getOutput();
				/* end: boundary proxy */
				/* status proxy */
					local.StatusProxy = getGeoFetcher().getProcessProxy('getCountyStatusJsonQueryByStateId');
					local.SProxy = local.StatusProxy.getProxy();
					local.StatusProxy.getUrlAddress().delete('domainId');
					local.SProxy.getCallbacks().setJsMethodCallback( '#local.className#.setCountyStatusJsonQuery' );
					local.SProxy.getPassthruData().setPassThruFormElement('NationalSalesMapForm');

					local.countyStatusProxyName = local.StatusProxy.getClassName();

					local.mapElementOutput &= local.StatusProxy.getOutput();
				/* end: status proxy */
			/* end: county boundary proxy */

			/* zip proxies */
				/* simple data proxy */
					local.ZipProxy = getGeoFetcher().getProcessProxy('getZipJsonByCountyId');
					local.ZipProxy.getUrlAddress().delete('domainId');
					local.ZipProxy.getProxy().getPassthruData().setPassThruFormElement('NationalSalesMapForm');
					local.mapElementOutput &= local.ZipProxy.getOutput();
				/* end: simple data proxy */
				/* boundary proxy */
					local.ZipBoundaryProxy = getGeoFetcher().getProcessProxy('getZipBoundaryJsonById');
					local.ZipBoundaryProxy.getUrlAddress().delete('domainId');
					local.mapElementOutput &= local.ZipBoundaryProxy.getOutput();
				/* end: boundary proxy */
				/* status proxy */
					local.StatusProxy = getGeoFetcher().getProcessProxy('getZipStatusJsonQueryByCountyId');
					local.StatusProxy.getUrlAddress().delete('domainId');
					local.SProxy = local.StatusProxy.getProxy();
					local.SProxy.getCallbacks().setJsMethodCallback( '#local.className#.setZipStatusJsonQuery' );
					local.SProxy.getPassthruData().setPassThruFormElement('NationalSalesMapForm');

					local.zipStatusProxyName = local.StatusProxy.getClassName();

					local.mapElementOutput &= local.StatusProxy.getOutput();
				/* end: status proxy */
			/* end: zip boundary proxy */
		</cfScript>
		<cfSaveContent Variable="local.output">
			<cfOutput>
				<!--- loading table with hardcoded styles for loading purposes --->
					<table cellPadding="0" cellSpacing="0" border="0" style="position:absolute;height:100%;width:100%;" id="InitLoadingRow" style="font-size: 2.0em;">
						<tr>
							<td valign="center" style="background:url(/cfide/scripts/ajax/resources/cf/images/loading.gif) center no-repeat;text-align:center;font-size:0.8em;height:100%;width:100%;">
								<br /><br /><br />loading...
							</td>
						</tr>
					</table>
				<!--- end: loading table --->
				<table cellPadding="0" cellSpacing="0" border="0" style="height:100%;width:100%;visibility:hidden" id="InitHiddenRow">
					<tbody>
						<tr>
							<td>
								<form name="NationalSalesMapForm" id="NationalSalesMapForm" method="post">
									<input type="hidden" name="CountyId" id="CountyId" value="" />
									#getNavBar()#
								</form>
							</td>
						</tr>
						<tr>
							<td style="height:100%">
								<div style="height:100%;position:relative;">
									<!--- Control Panel --->
										#local.controlPanelOutput#
									<!--- end: Control Panel --->
									#local.mapElementOutput#
								</div>
							</td>
						</tr>
					</tbody>
				</table>
				<script type="text/javascript" language="Javascript">
					#local.parentClassName#Override = #local.parentClassName#;

					#local.parentClassName# = function()
					{
						#local.parentClassName#Override();

						//turn off jqm select menu transistions
						jQuery.mobile.defaultDialogTransition = 'none';

						#local.className# = new V2SitesMap()
						.setMap(#local.parentClassName#.getMap())
						.setStateStatusProxy(get#local.stateStatusProxyName#())
						.setCountyProxy( get#local.CountyProxy.getClassName()#() )
						.setCountyStatusProxy(get#local.countyStatusProxyName#())
						.setCountyBoundaryProxy( get#local.CountyBoundaryProxy.getClassName()#() )
						.setZipProxy( get#local.ZipProxy.getClassName()#() )
						.setZipStatusProxy(get#local.zipStatusProxyName#())
						.setZipBoundaryProxy( get#local.ZipBoundaryProxy.getClassName()#() )
						.setInfoWindowElementProxy( get#local.elementProxy.getClassName()#() )
						.setCompetitorProxy( get#local.CompProxy.getClassName()#() )
						.setCompetitorInfoSheetProxy( get#local.CompetitorInfoSheetProxy.getClassName()#() )

						/* inits */
							jQuery('##StateId')[0].options[0].selected = 1
							jQuery('##ToggleCompetitors').attr('checked',false).checkboxradio('disable')


							//init load states
							#local.className#.setStateJson(#local.stateJson#)

						<cfif !isNull(getGeoStartType()) >
							<cfSwitch expression="#getGeoStartType()#">
								<cfCase value="zip">
									#local.className#.focusOnZipById(#getGeoStartId()#)
								</cfCase>
								<cfCase value="county">
									#local.className#
									.focusOnCountyById(#getGeoStartId()#)
								</cfCase>
								<cfCase value="state">
									#local.className#.focusOnStateById(#getGeoStartId()#)
								</cfCase>
								<cfDefaultCase>
									#local.className#.focusOnCountry()
								</cfDefaultCase>
							</cfSwitch>
						<cfElse>
							#local.className#.focusOnCountry()
						</cfif>

							//init google info windows
							#local.className#.getPolygonDrawerMemory().getOne()[0].showInfoWindow().hideInfoWindow();

							jQuery('##InitLoadingRow').hide();
							jQuery('##InitHiddenRow').css('visibility','visible');
						/* end */
					}
				</script>
			</cfOutput>
		</cfSaveContent>
		<cfReturn local.output />
	</cfFunction>

	<cfFunction
		name		= "getControlPanelOutput"
		returnType	= "string"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfScript>
			local.Media = new Media();

			local.MapElement = getMapElement();
			local.JsClass = local.MapElement.getJsClass();
			local.className = getClassName();

			local.mapClassName = local.MapElement.getJsClass().getClassName();

			/* control buttons */
				local.Control = new Tagol.Html.Div()
				.setAttribute('id','MapControl')
				.setAttribute('class','MapControl')
				.setAttribute('onclick','#local.className#.toggleControlPanel();return false;');
				local.Control.setInnerHtml('<img src="#local.Media.getString()#table16x16.png" style="width:16px;height:16px;" />');
				local.JsClass.addControlElement(local.Control);

				local.Control = new Tagol.Html.Div()
				.setAttribute('id','MapUpButton')
				.setAttribute('title','Go Back Up in Map')
				.setAttribute('class','MapControl')
				.setAttribute('style','display:none')
				.setAttribute('onclick','#local.className#.back();return false;');
				local.Control.setInnerHtml('<img src="#local.Media.getString()#arrowUp16x16.png" style="width:16px;height:16px;" />');
				local.JsClass.addControlElement(local.Control);

				local.Control = new Tagol.Html.Div()
				.setAttribute('id','CompetitorToggle')
				.setAttribute('class','MapControl')
				.setAttribute('style','display:none')
				.setAttribute('onclick','#local.className#.fetchCompetitors();return false;');
				local.Control.setInnerHtml('<img src="#local.Media.getString()#building_old_16x16.gif" style="width:16px;height:16px;" />');
				local.JsClass.addControlElement(local.Control);

				local.CloseControl = new Tagol.Html.Div()
				.setAttribute('id','CloseMapControl')
				.setAttribute('class','CloseMapControl')
				.setAttribute('onclick','#local.className#.toggleControlPanel();return false;');
				local.CloseControl.setInnerHtml('<img src="#local.Media.getString()#close28x28.png" alt="x" style="width:28px;height:28px;" />');
			/* end */
		</cfScript>
		<cfSaveContent Variable="local.output">
			<cfOutput>
				<div id="ControlPanel" style="display:none;position:absolute;height:85%;border-bottom:2px solid black">
					<div class="ControlPanelInnerWrap">
						#local.CloseControl.getOutput()#
						<h4>Control Panel</h4>
						<div style="font-size:0.7em;">
							<div data-role="fieldcontain" style="text-align:center;">
								<fieldset data-role="controlgroup" data-type="horizontal">
									<input type="checkbox" id="ToggleRoads" data-mini="true" onchange="#local.mapClassName#.getMapTypeHandler().setRoad(this.checked).updateMap()" />
									<label for="ToggleRoads">
										<div style="width:130px">
											<img src="#local.Media.getString()#Highway18x18.png" alt="" style="width:18px;height:18px;vertical-align:middle;" />&nbsp;&nbsp;Display Roads
										</div>
									</label>
									<input type="checkbox" id="ToggleCompetitors" data-mini="true" onchange="#local.className#.showCompetitorInfoSheet()" disabled />
									<label for="ToggleCompetitors" style="position:relative">
										<div style="width:130px">
											<img src="#local.Media.getString()#building_old_16x16.gif" alt="" style="width:18px;height:18px;vertical-align:middle;" />&nbsp;&nbsp;Competitors
										</div>
									</label>
								</fieldset>
							</div>
						</div>
						<div id="CompetitorSheetWrap" style="display:none">
							<h3>
								<img src="#local.Media.getString()#building_old_16x16.gif" style="width:16px;height:16px;" />&nbsp;
								Competitor Info Sheet
							</h3>
							<div id="CompetitorSheetDataWrap"></div>
							<br />
						</div>
						<div id="GeoDataOverviewWrap">
							<h3>
								<img src="#local.Media.getString()#globe16x16.png" style="width:16px;height:16px;" />&nbsp;
								Geo Data Overview&nbsp;&nbsp;<a style="font-size:0.65em;" class="GeoNavBack" onclick="#local.className#.back()">(back)</a>
							</h3>
							<div id="GeoDataOverviewData"></div>
							<!--- GeoDataOverviewData Clones --->
								<div style="display:none">
									#getGeoDataCloneOutput()#
								</div>
							<!--- end --->
						</div>
					</div>
				</div>
			</cfOutput>
		</cfSaveContent>
		<cfReturn local.output />
	</cfFunction>
	<cfFunction
		name		= "getGeoDataCloneOutput"
		returnType	= "string"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfSaveContent Variable="local.cloneOutput">
			<span id="GeoDataClone" class="GeoDataCloneWrap">
				<span class="CloneInnerWrap">
					<h5 class="GeoDataLabel"></h5>
					<div class="GeoDetailDataWrap">
						<span title="Population Estimate">Pop:&nbsp;<span class="GeoDataPopEst"></span></span>&nbsp;
						<span class="GeoDataCompetitorsWrap" title="Competitors">Competitors:&nbsp;<span class="GeoDataCompetitors"></span></span>
						<div class="GeoDataZipWrap">
							<span title="Total Zip Codes">Zips Sold:&nbsp;<span class="GeoDataZipsSold">0</span>&nbsp;of&nbsp;<span class="GeoDataZips"></span></span>
						</div>
					</div>
				</span>
			</span>
		</cfSaveContent>
		<cfReturn reReplaceNoCase(local.cloneOutput, '\r|\t|\n', '', 'all') />
	</cfFunction>

	<cfFunction
		name		= "getMapElement"
		returnType	= "any"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfScript>
			if(structKeyExists(variables, 'MapElement'))
				return variables.MapElement;

			variables.MapElement = new Tagol.Html.GoogleMap();

			//deprecated
			variables.MapElement.setAttribute('id','MapWrap').setAttribute('class','MapPanelWrap');

			/* map js config */
				local.JsClass = variables.MapElement.getJsClass();

				local.mapOptions=
				{
					 InitZoom		= 4
					,MapType		= 'Custom'
					,apiKey 		= ''
					,isShowMapTypeControl=0
					,isShowStreetViewControl=0
				};
				local.JsClass.init(argumentCollection=local.mapOptions);

				local.JsClass.setCustomModes
				(
					 road			= 0
					,landscape		= 1
					,poi			= 1
					,locality		= 0
					,neighborhood	= 0
					,country		= 0
					,land_parcel	= 0
					,labels			= 0
					,province		= 0
					,transit		= 0
					,water			= 1
				);
			/* end */

			return variables.MapElement;
		</cfScript>
	</cfFunction>

	<cfFunction
		name		= "getInfoByGeoId"
		returnFormat= "plain"
		returnType	= "string"
		access		= "remote"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfArgument name="geoId" required="yes" type="string" hint="" />
		<cfScript>
			local.id = val(reReplaceNoCase(arguments.geoId, '[^0-9]', '', 'all'));
			local.type = left(arguments.geoId,len(arguments.geoId)-len(local.id));

			switch(local.type)
			{
				case 's':
					return getStateSummary(local.id);

				case 'co':
					return getCountySummary(local.id);

				case 'z':
					return getZipSummary(local.id);

				case 'b':
					return getBusinessSummary(local.id);
			}

			return 'getInfoByGeoId - #local.type# - #local.id#';
		</cfScript>
	</cfFunction>

	<cfFunction
		name		= "getBusinessSummary"
		returnType	= "string"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfArgument name="businessId" required="yes" type="numeric" hint="" />
		<cfScript>
			local.Business = entityLoadByPk('Business',arguments.businessId);
		</cfScript>
		<cfSaveContent Variable="local.output">
			<cfOutput>
				<div class="label">#local.Business.getBusinessName()#</div>
				<div class="body">
					<div class="GeoInfoChart InputLayoutWrap ColumnFloat StackInputLabel NoColor">
						<span class="InputLabelWrap">
							<span class="InputWrap">
								<a href="#local.Business.getProfile().getProfileAbsoluteLink()#" target="_blank">view profile</a>
							</span>
						</span>
					</div>
				</div>
			</cfOutput>
		</cfSaveContent>
		<cfReturn local.output />
	</cfFunction>

	<cfFunction
		name		= "getCountySummary"
		returnType	= "string"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfArgument name="countyId" required="yes" type="numeric" hint="" />
		<cfScript>
			local.Gf = getGeoFetcher();
			local.Gf.setDomainId( getDomainId() );
			local.summaryQuery = local.Gf.getCountySumarryQueryById(arguments.countyId);
		</cfScript>
		<cfSaveContent Variable="local.output">
			<cfOutput>
				<span class="GeoInfoChart InputLayoutWrap ColumnFloat StackInputLabel NoColor">
					<span class="InputLabelWrap">
						<label>Pop. Est.</label>
						<span class="InputWrap">#numberFormat(local.summaryQuery.PopulationEstimate)#</span>
					</span>
					<span class="InputLabelWrap">
						<label for="">Cities</label>
						<span class="InputWrap">
							<!---#numberFormat(local.summaryQuery.CityPurchaseCount)# sold of --->
							#numberFormat(local.summaryQuery.Cities)#
						</span>
					</span>
					<span class="InputLabelWrap CountyToZipTrigger" geoid="#arguments.countyId#">
						<label><a href="##">View Zips Sold</a></label>
						<span class="InputWrap">
							#numberFormat(local.summaryQuery.ZipPurchaseCount)# of #numberFormat(local.summaryQuery.ZipCount)#
						</span>
						
					</span>
					<span class="InputLabelWrap">
						<label>Price</label>
						<span class="InputWrap">
							<strong>#dollarFormat(local.summaryQuery.Countycost)#</strong>
							<!---#yesNoFormat(local.summaryQuery.IsAvailable)#--->
						</span>
					</span>
					
				</span>
				<div style="clear:both;padding-bottom:7px"></div>
				<cfif local.summaryQuery.ZipPurchaseCount >
					<cfScript>
						local.hql=
						'
							FROM	Business b
							WHERE	b.ExclusiveListing.ListingId
							IN		(
										SELECT	ListingId
										FROM	ExclusiveZipCode ezc
										WHERE	ezc.ExclusiveZipNumber
										IN		(
													SELECT	z.ZipNumber
													FROM	Zip z
													WHERE	z.County.CountyId = ?
												)
										AND		ezc.IsComputedActive = 1
									)
							AND		b.Domain.DomainId = ?
						';
						local.hql = CFMethods().cleanseHqlString(local.hql);
						local.Businesses = ormExecuteQuery(local.hql, [arguments.countyId, getDomainId()], false);
					</cfScript>
					<cfLoop array="#local.Businesses#" index="local.Business">
						<div>
							&bull;&nbsp;<a href="#local.Business.getProfile().getProfileAbsoluteLink()#" target="_blank">#local.Business.getBusinessName()#</a>
						</div>
					</cfLoop>
				</cfif>
			</cfOutput>
		</cfSaveContent>
		<cfReturn local.output />
	</cfFunction>

	<cfFunction
		name		= "getZipSummary"
		returnType	= "string"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfArgument name="ZipNumber" required="yes" type="numeric" hint="" />
		<cfScript>
			local.Gf = getGeoFetcher();
			local.Gf.setDomainId( getDomainId() );
			local.summaryQuery = local.Gf.getZipSumarryQueryById(arguments.zipNumber);
			
			
			
		</cfScript>
		<cfSaveContent Variable="local.output">
			<cfOutput>
				<span class="GeoInfoChart InputLayoutWrap ColumnFloat StackInputLabel NoColor">
					<span class="InputLabelWrap">
						<label>Pop. Est.</label>
						<span class="InputWrap">#numberFormat(local.summaryQuery.PopulationEstimate)#</span>
					</span>
					<span class="InputLabelWrap">
						<label>Available</label>
						<span class="InputWrap">
							#yesNoFormat(local.summaryQuery.IsAvailable)#
						</span>
					</span>
					
					<!---cfif local.summaryQuery.IsAvailable>
						<span class="InputLabelWrap">
						<label>Price</label>
						<span class="InputWrap">
							<strong>#dollarFormat(local.summaryQuery.cost)#</strong>
							<!---#yesNoFormat(local.summaryQuery.IsAvailable)#--->
						</span>
					</span>
					</cfif--->
					
				</span>
				<div style="clear:both;padding-bottom:7px"></div>
				<cfif !local.summaryQuery.IsAvailable >
					<cfScript>
						local.hql=
						'
							FROM		Business b
							JOIN FETCH	b.ExclusiveListing.ZipCodeArray zca
							WHERE		zca.ExclusiveZipNumber = ?
							AND			b.Domain.DomainId = ?
						';
						local.hql = CFMethods().cleanseHqlString(local.hql);
						local.Businesses = ormExecuteQuery(local.hql, [arguments.zipNumber, getDomainId()], false);
					</cfScript>
					<cfLoop array="#local.Businesses#" index="local.Business">
						<div>
							&bull;&nbsp;<a href="#local.Business.getProfile().getProfileAbsoluteLink()#" target="_blank">#local.Business.getBusinessName()#</a>
						</div>
					</cfLoop>
				</cfif>
			</cfOutput>
		</cfSaveContent>
		<cfReturn local.output />
	</cfFunction>

	<cfFunction
		name		= "getStateSummary"
		returnType	= "string"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfArgument name="stateId" required="yes" type="numeric" hint="" />
		<cfScript>
			local.Gf = getGeoFetcher();
			local.Gf.setDomainId( getDomainId() );
			local.summaryQuery = local.Gf.getStateSumarryQueryById(arguments.stateId);
		</cfScript>
		<cfSaveContent Variable="local.output">
			<cfOutput>
				<span class="GeoInfoChart StateInfoChart InputLayoutWrap ColumnBlock FloatInputLabel NoColor">
					<span class="InputLabelWrap">
						<label for="">Population Est.:</label>
						<span class="InputWrap">#numberFormat(local.summaryQuery.PopulationEstimate)#</span>
					</span>

					<span class="InputLabelWrap StateToCountyTrigger" geoid="#arguments.stateId#">
						<label for=""><a href="##">View Counties</a>:</label>
						<span class="InputWrap">
							#numberFormat(local.summaryQuery.CountyPurchaseCount)# sold of #numberFormat(local.summaryQuery.CountyCount)#
						</span>
					</span>

					<span class="InputLabelWrap">
						<label for="">Zips:</label>
						<span class="InputWrap">
							#numberFormat(local.summaryQuery.ZipPurchaseCount)# sold of #numberFormat(local.summaryQuery.ZipCount)#
						</span>
					</span>
				</span>
			</cfOutput>
		</cfSaveContent>
		<cfReturn local.output />
	</cfFunction>

	<cfFunction
		name		= "getNavBar"
		returnType	= "string"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfScript>
			local.className = getClassName();

			/* state select */
				local.StateSelect = new SiteMvc.Element.SelectState();

				local.StateSelect
				.setOption('0','U.S.A.')
				.setAttribute('name','StateId')
				.setAttribute('id','StateId')
				.setAttribute('data-native-menu','false')
				.setAttribute('data-overlay-theme','b')
				.setAttribute('onchange', 'setTimeout(#local.className#_stateChange, 300)')
				;
			/* end */

			/* vertical select */
				local.SelectVertical = new SiteMvc.Element.SelectVertical(BrandLabel='legal');
				local.SelectVertical
				.setAttribute('value',getDomainId())
				.setAttribute('name','DomainId')
				.setAttribute('id','DomainId')
				.setAttribute('data-native-menu','false')
				.isOptGroupMode(1)
				;

				local.SelectVertical.setAttribute('onchange','setTimeout(#local.className#_vertChange, 300)');
			/* end */
		</cfScript>
		<cfSaveContent Variable="local.output">
			<cfOutput>
				<div data-role="navbar">
					<ul>
						<li style="position:relative">
							<span class="NationalSalesMapAjaxLoadingIcon"></span>
							<a href="" onclick="jQuery('##StateId').selectmenu('open');return false">
								<span class="StateSpecifier">Select State</span>
							</a>
						</li>
						<li>
							<a href="" onclick="jQuery('##DomainId').selectmenu('open');return false">
								<span class="DomainSpecifier">Select Website</span>
							</a>
						</li>
					</ul>
				</div>
				<div style="display:none">
					#local.StateSelect.getOutput()##local.SelectVertical.getOutput()#
				</div>
				<script>
					#local.className#_stateChange = function()
					{
						#local.className#.focusOnStateById(jQuery('##StateId').val());
					}

					#local.className#_vertChange = function()
					{
						var local = {}
						local.Select = jQuery('##DomainId');
						local.Option = local.Select[0].options[local.Select[0].selectedIndex];
						local.val = local.Select.val();

						#local.className#.updateStatusDisplay(local.val);
						jQuery('.DomainSpecifier').html(local.Option.innerHTML)
					}
				</script>
			</cfOutput>
		</cfSaveContent>
		<cfReturn local.output />
	</cfFunction>

	<cfFunction
		name		= "getGeoFetcher"
		returnType	= "GeoFetcher"
		access		= "public"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfScript>
			if(!structKeyExists(variables, 'GeoFetcher'))
				variables.GeoFetcher = new GeoFetcher();

			return variables.GeoFetcher;
		</cfScript>
	</cfFunction>

	<cfFunction
		name		= "getCompetitorInfoSheet"
		returnType	= "string"
		returnFormat= "plain"
		access		= "remote"
		output		= "no"
		hint		= ""
		description	= ""
	>
		<cfArgument name="countyId" required="yes" type="numeric" hint="" />
		<cfScript>
			local.businessArray = getGeoFetcher().setDomainId( getDomainId() )
			.getCompetitorArrayByCountyId(countyId=arguments.countyId, maxRows=20);
			local.StringMethods = CFMethods().Strings();
		</cfScript>
		<cfSaveContent Variable="local.output">
			<cfOutput>
				<div class="ViewListingWrap">
					<cfLoop array="#local.businessArray#" index="local.Business">
						<span style="display:inline-block">
							<div style="display:table-cell">
								<a class="ViewListingButton" style="display:block" href="#local.Business.getProfile().getProfileAbsoluteLink()#" target="_blank">
									<div style="width:145px;padding:3px;">
										#local.StringMethods.slimString(local.Business.getBusinessName(),23)#
									</div>
								</a>
							</div>
						</span>
					</cfLoop>
				</div>
			</cfOutput>
		</cfSaveContent>
		<cfReturn local.output />
	</cfFunction>

</cfComponent>