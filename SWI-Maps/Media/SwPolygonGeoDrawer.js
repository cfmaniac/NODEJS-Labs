//CLASS
GeoState = new jOlOs.Class
({
	 name		: 'GeoState'
	,accessors	:
				{
					PopEst:null
					,Zips:null
				}
	,Extends	: GeoState
})



//CLASS
GeoCounty = new jOlOs.Class
({
	 name		: 'GeoCounty'
	,accessors	:
				{
					PopEst:null
					,Zips:null
					,ZipStruct:{defaultByMethod:function(){return {}}}
					,Competitors:null
				}
	,Extends	: GeoCounty
})



//CLASS
GeoZip = new jOlOs.Class
({
	 name		: 'GeoZip'
	,accessors	:
				{
					PopEst:null
					,Competitors:null
				}
	,Extends	: GeoZip
})







//CLASS
SwPolygonGeoDrawer = new jOlOs.Class
({
	 name		: 'SwPolygonGeoDrawer'
	,accessors	:
				{
					InfoWindowElementProxy:null
					,StateStatusProxy:null
					,CountyStatusProxy:null
					,CompetitorProxy:null
					,MarkerMemory:{defaultByMethod:function(){return new MarkerMemory()}}
				}
	,Extends	: PolygonGeoDrawer
})

SwPolygonGeoDrawer.prototype.onAjaxStart = function()
{
	jQuery('.NationalSalesMapAjaxLoadingIcon').html('<img src="/cfide/scripts/ajax/resources/cf/images/loading.gif" alt="loading..." width="15" height="15" border="0" />');
}

SwPolygonGeoDrawer.prototype.onAjaxStop = function()
{
	jQuery('.NationalSalesMapAjaxLoadingIcon').html('');
}

SwPolygonGeoDrawer.prototype.onAjaxError = function()
{
	jQuery('.NationalSalesMapAjaxLoadingIcon').html('<blink style="color:red">error</blink>');
}

SwPolygonGeoDrawer.prototype.fetchCompetitors = function()
{
	this.onAjaxStart()
	this.get('CompetitorProxy').invoke(null,this.getMethodCallback('processFetchedCompetitors'))
	return this
}

SwPolygonGeoDrawer.prototype.processFetchedCompetitors = function(query)
{
	var local = {Map:this.getMap()}

	query = ColdFusion.extendQuery(query)
	local.MarkerMemory = this.getMarkerMemory();
	local.InfoWindowElementProxy = this.getInfoWindowElementProxy()
	local.InfoWindow = this.getInfoWindow()

	query.each
	(
		function(STRUCT)
		{
			if(local.MarkerMemory.isDefined(STRUCT.BUSINESSID))
				var Gmm = local.MarkerMemory.getById(STRUCT.BUSINESSID);
			else
			{
				var Gmm = new SwGoogleMapMarker()
				.setInfoWindow( local.InfoWindow )
				.setInfoWindowElementProxy( local.InfoWindowElementProxy )
				.setLat(STRUCT.LAT)
				.setLon(STRUCT.LON)
				.setTitle(STRUCT.BUSINESSNAME)
				.setMap(local.Map)
				.setInfoHtml('<div class="GeoInfoWindowWrap" id="BusinessInfoWindowContent'+STRUCT.BUSINESSID+'" businessId="'+STRUCT.BUSINESSID+'"></div>')
				.setIconUrl('/Map/Media/building_old_16x16.gif')
				.setBusinessId(STRUCT.BUSINESSID)

				local.MarkerMemory.setById(Gmm, STRUCT.BUSINESSID)
			}

			Gmm.show()
		}
	)

	this.onAjaxStop()
}

SwPolygonGeoDrawer.prototype.showCountiesByStateId = function(id)
{
	var local = {}

	this.Super(id);

	this.updateCountyStatusDisplay();
}

SwPolygonGeoDrawer.prototype.geoClickProcessor = function(GeoObject)
{
	var local = {}

	local.geoId = GeoObject.getGeoId();
	//local.elementId = local.geoId+'_infoWindowBody';

	local.PolygonDrawer = this.getPolygonDrawerMemory().getById(local.geoId)[0];
	this.polygonClickProcessor(local.PolygonDrawer);
}

SwPolygonGeoDrawer.prototype.setClickProcessorByGeoClass = function(GeoClass)
{
	var local = {}

	this.geoClickProcessor(GeoClass);

	/* fire ajax */
		this.onAjaxStart();
		setTimeout(this.getSummaryCallbackByGeoClass(GeoClass),500);
	/* end */
}

SwPolygonGeoDrawer.prototype.getSummaryCallbackByGeoClass = function(GeoClass)
{
	var method = function()
	{
		var local = {};
		local.InfoWindowElementProxy = arguments.callee.Owner.getInfoWindowElementProxy();
		local.InfoWindowElementProxy.setElementId(arguments.callee.elementId);

		local.callback = arguments.callee.Owner.getMethodCall('elementIdInfoSumarryComplete',arguments.callee.elementId);
		local.errorMethod = arguments.callee.Owner.getMethodCall('onAjaxError');

		local.InfoWindowElementProxy.invoke({geoId:arguments.callee.geoId},local.callback, local.errorMethod);
	}
	method.Owner = this;
	method.geoId = GeoClass.getGeoId();
	method.elementId = GeoClass.getGeoId()+'_infoWindowBody';
	return method;
}

SwPolygonGeoDrawer.prototype.hideAllInfoWindows = function()
{
	this.Super()
	this.getMarkerMemory().each(function(){if(this.hideInfoWindow)this.hideInfoWindow()})
}

SwPolygonGeoDrawer.prototype.updateStatusDisplay = function()
{
	this.hideAllInfoWindows();

	var isUpdateStates = jQuery('#StateId').eq(0).val();
	isUpdateStates = parseInt(isUpdateStates);
	isUpdateStates = isNaN(isUpdateStates) || isUpdateStates == 0;

	if(isUpdateStates)
		this.updateStateStatusDisplay();
	else
		this.updateCountyStatusDisplay();
}

SwPolygonGeoDrawer.prototype.elementIdInfoSumarryComplete = function(elementId)
{
	var local = {}

	local.element = document.getElementById(elementId);

	/* state to county */
		local.clickMethod = function()
		{
			arguments.callee.Owner.focusOnStateById(jQuery(this).attr('geoid'))
		}
		local.clickMethod.Owner = this;

		jQuery('.StateToCountyTrigger[geoid]',local.element).each
		(
			function()
			{
				jQuery(this).click(local.clickMethod)
			}
		)
	/* end: state to county */

	/* county to zip */
		this.attachCountyToZipTriggerByElement( jQuery('.CountyToZipTrigger[geoid]',local.element) )
	/* end: county to zip */

	this.onAjaxStop();

	return this;
}

SwPolygonGeoDrawer.prototype.attachStateToCountyTriggerByElement = function(elm)
{
	var local = {}

	local.jElm = jQuery(elm);

	local.clickMethod = function()
	{
		arguments.callee.Owner.focusOnStateById(jQuery(this).attr('geoid'))
	}
	local.clickMethod.Owner = this;

	local.jElm.each
	(
		function()
		{
			jQuery(this).click(local.clickMethod).attr('isset','taste')
		}
	)
}

SwPolygonGeoDrawer.prototype.attachCountyToZipTriggerByElement = function(elm)
{
	var local = {}

	local.jElm = jQuery(elm);

	local.clickMethod = function()
	{
		arguments.callee.Owner.focusOnCountyById(jQuery(this).attr('geoid'))
	}
	local.clickMethod.Owner = this;

	local.jElm.each
	(
		function()
		{
			jQuery(this).click(local.clickMethod)
		}
	)
}

SwPolygonGeoDrawer.prototype.stateClickProcessor = function(State)
{
	var local = {}

	this.geoClickProcessor(State);

	/* fire ajax */
		this.onAjaxStart();
		setTimeout(this.getSummaryCallbackByGeoClass(State),500);
	/* end */
}

SwPolygonGeoDrawer.prototype.setPolygonDrawerByZip = function(PolygonDrawer, Zip)
{
	var local = {}

	this.Super(PolygonDrawer, Zip);
	local.geoId = Zip.getGeoId();

	if(Zip.getName()!=null)
		PolygonDrawer.setInfoWindowHtml('<div class="GeoInfoWindowWrap" geoid="'+local.geoId+'"><div class="label">'+Zip.getName()+'</div><div id="'+local.geoId+'_infoWindowBody" class="body fixedHeight">&nbsp;</div></div>');

	PolygonDrawer.setClickCallback( this.getMethodCall('setClickProcessorByGeoClass',Zip) );

	return this;
}

SwPolygonGeoDrawer.prototype.setPolygonDrawerByCounty = function(PolygonDrawer, County)
{
	var local = {}

	this.Super(PolygonDrawer, County);
	local.geoId = County.getGeoId();

	if(County.getName()!=null)
		PolygonDrawer.setInfoWindowHtml('<div class="GeoInfoWindowWrap" geoid="'+local.geoId+'"><div class="label">'+County.getName()+'</div><div id="'+local.geoId+'_infoWindowBody" class="body fixedHeight">&nbsp;</div></div>');

	PolygonDrawer.setClickCallback( this.getMethodCall('setClickProcessorByGeoClass',County) );

	return this;
}

SwPolygonGeoDrawer.prototype.setPolygonDrawerByState = function(PolygonDrawer, State)
{
	var local = {}

	this.Super(PolygonDrawer, State);
	local.geoId = State.getGeoId();

	PolygonDrawer.setInfoWindowHtml('<div class="GeoInfoWindowWrap" geoid="'+local.geoId+'"><div class="label">'+State.getName()+'</div><div id="'+local.geoId+'_infoWindowBody" class="body fixedHeight">&nbsp;</div></div>');
	PolygonDrawer.setClickCallback( this.getMethodCall('stateClickProcessor',State) );

	return this;
}

SwPolygonGeoDrawer.prototype.updateStateStatusDisplay = function()
{
	this.onAjaxStart();
	this.getStateStatusProxy().invoke(null, this.getMethodCallback('setStateStatusJsonQuery'));
	return this;
}

SwPolygonGeoDrawer.prototype.updateZipStatusDisplay = function()
{
	this.onAjaxStart();
	this.getZipStatusProxy().invoke(null, this.getMethodCallback('setZipStatusJsonQuery'));
}

SwPolygonGeoDrawer.prototype.updateCountyStatusDisplay = function()
{
	this.onAjaxStart();
	this.getCountyStatusProxy().invoke(null, this.getMethodCallback('setCountyStatusJsonQuery'));
}

/* parsing methods */
	SwPolygonGeoDrawer.prototype.setStateStatusJsonQuery = function(json)
	{
		this.onAjaxStop();
		return this.setStateStatusQuery( ColdFusion.JSON.decode(json) )
	}

	SwPolygonGeoDrawer.prototype.setStateStatusQuery = function(query)
	{
		var local = {};

		local.PolygonDrawerMemory = this.getPolygonDrawerMemory()
		local.query = ColdFusion.extendQuery(query)
		local.Owner = this

		local.eachMethod=function(struct)
		{
			local.PolygonDrawerMemory.eachById
			(
				function(PolygonDrawer)
				{
					PolygonDrawer.setFillColor(struct.FILLCOLOR)
					local.GeoClass = PolygonDrawer.getGeoClass()

					local.GeoClass.setPopEst(struct.POPEST)

					local.Owner.setStateFillColor(local.GeoClass,struct.FILLCOLOR)

/*
					jQuery('.GeoDataZipsSold', jParent).html(struct.ZIPSSOLD)
					jQuery('.GeoDataCompetitors', jParent).html(parseFloat(struct.COMPETITORS).toCommaFormat())
*/
				}
				,'s'+struct.STATEID
			)
		}

		local.query.each(local.eachMethod);

		return this;
	}

	SwPolygonGeoDrawer.prototype.setStateFillColor = function(State, fillColor)
	{
		var jParent = jQuery('[geoid='+State.getId()+']','#GeoDataOverviewData')
		jQuery('.GeoDataPopEst', jParent).html( parseInt(State.getPopEst()).toCommaFormat() )
		jQuery('.GeoDataCompetitorsWrap', jParent).hide()
		//jParent.addClass('StateToCountyTrigger')
		jQuery('.GeoDataLabel', jParent).css('color',fillColor)
	}

	SwPolygonGeoDrawer.prototype.setCountyStatusJsonQuery = function(json)
	{
		this.onAjaxStop();
		return this.setCountyStatusQuery( ColdFusion.JSON.decode(json) )
	}

	SwPolygonGeoDrawer.prototype.setZipStatusJsonQuery = function(json)
	{
		this.onAjaxStop();
		return this.setZipStatusQuery( ColdFusion.JSON.decode(json) )
	}

	SwPolygonGeoDrawer.prototype.focusOnCountry = function()
	{
		this.Super()
		this.getMarkerMemory().hideAll()
		return this
	}

	SwPolygonGeoDrawer.prototype.setCountyStatusQuery = function(query)
	{
		var local = {};

		local.OutputWrap = jQuery('#GeoDataOverviewData');
		local.PolygonDrawerMemory = this.getPolygonDrawerMemory();
		local.query = ColdFusion.extendQuery(query);

		local.eachMethod=function(struct)
		{
			local.PolygonDrawerMemory.eachById
			(
				function(PolygonDrawer)
				{
					var jParent = jQuery('[geoid='+PolygonDrawer.getGeoClass().getId()+']',local.OutputWrap)

					PolygonDrawer.setFillColor(struct.FILLCOLOR)

					jQuery('.GeoDataLabel', jParent).css('color',struct.FILLCOLOR)
					jQuery('.GeoDataZipsSold', jParent).html(struct.ZIPSSOLD)
					jQuery('.GeoDataCompetitors', jParent).html(parseFloat(struct.COMPETITORS).toCommaFormat())
				}
				,'co'+struct.COUNTYID
			)
		}

		local.query.each(local.eachMethod);

		return this;
	}

	SwPolygonGeoDrawer.prototype.setZipStatusQuery = function(query)
	{
		var local = {};

		local.jGeoDataOverviewData = jQuery('#GeoDataOverviewData');
		local.PolygonDrawerMemory = this.getPolygonDrawerMemory();
		local.query = ColdFusion.extendQuery(query);

		local.eachMethod=function(struct)
		{
			local.PolygonDrawerMemory.eachById
			(
				function(PolygonDrawer)
				{
					var jParent = jQuery('[geoid='+PolygonDrawer.getGeoClass().getGeoId()+']', local.jGeoDataOverviewData)

					PolygonDrawer.setFillColor(struct.FILLCOLOR)

					jQuery('.GeoDataLabel', jParent).css('color',struct.FILLCOLOR)
					//jQuery('.GeoDataZipsSold', jParent).html(struct.ZIPSSOLD)
					jQuery('.GeoDataCompetitors', jParent).html(parseFloat(struct.COMPETITORS).toCommaFormat())
				}
				,'z'+struct.ZIPNUMBER
			)
		}

		local.query.each(local.eachMethod);

		return this;
	}
/* end */




//CLASS
SwGoogleMapMarker = new jOlOs.Class
(
	{
		 name		: 'SwGoogleMapMarker'
		,accessors	: {BusinessId:null, InfoWindowElementProxy:null}
		,Extends	: GoogleMapMarker
	}
)

SwGoogleMapMarker.prototype.showInfoWindow = function()
{
	this.Super()

	if(this.getInfoWindowContentElement().html().length == 0)
		setTimeout(this.getMethodCall('populateInfoWindowHtml'),300);

	return this
}

SwGoogleMapMarker.prototype.populateInfoWindowHtml = function()
{
	var local = {}

	local.jElm = this.getInfoWindowContentElement()
	local.jElm.html('<img src="/cfide/scripts/ajax/resources/cf/images/loading.gif" alt="loading..." width="15" height="15" border="0" />')

	this.getInfoWindowElementProxy()
	.setElementId( this.getInfoWindowContentElementId() )
	.invoke({geoId:'b'+this.getBusinessId()})
}

SwGoogleMapMarker.prototype.getInfoWindowContentElementId = function()
{return 'BusinessInfoWindowContent'+this.getBusinessId()}

SwGoogleMapMarker.prototype.getInfoWindowContentElement = function()
{return jQuery('#'+this.getInfoWindowContentElementId())}





//CLASS
MarkerMemory = new jOlOs.Class
(
	{
		name:'MarkerMemory'
		,Extends:NamedMemory
	}
)

MarkerMemory.prototype.hideAll = function()
{
	return this.each(function(Marker){Marker.hide(null)})
}

MarkerMemory.prototype.hideAllInfoWindows = function()
{
	return this.each(function(Marker){Marker.hideInfoWindow(null)})
}
