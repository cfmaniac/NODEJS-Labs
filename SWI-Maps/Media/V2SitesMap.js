V2SitesMap = new jOlOs.Class
({
	 name		: 'V2SitesMap'
	,accessors	: {CompetitorInfoSheetProxy:null}
	,Extends	: SwPolygonGeoDrawer
});

V2SitesMap.prototype.toggleControlPanel=function()
{
	jQuery('#ControlPanel').slideToggle(700,"easeOutBounce")
	return this
}

V2SitesMap.prototype.hideControlPanel=function()
{
	jQuery('#ControlPanel').slideUp(700,"easeOutBounce")
	return this
}

V2SitesMap.prototype.showControlPanel=function()
{
	jQuery('#ControlPanel').slideDown(700,"easeOutBounce")
	return this
}

V2SitesMap.prototype.showCompetitorInfoSheet = function()
{
	jQuery('#CompetitorSheetWrap').delay(1000).slideDown(500,'easeOutBounce')
	this.showControlPanel().fetchCompetitorInfoSheet()
	return this
}

V2SitesMap.prototype.fetchCompetitorInfoSheet = function()
{
	this.getCompetitorInfoSheetProxy().invoke()
	return this
}

V2SitesMap.prototype.focusOnCountry = function()
{
	var local = {}

	this.Super()

	/* resets */
		jQuery('.GeoNavBack').hide();
		jQuery('#CountyId').val('')
		jQuery('#CompetitorSheetWrap').slideUp(500,'easeOutBounce')
		jQuery('#CompetitorToggle').slideUp(500,'easeOutBounce')
		jQuery('#MapUpButton').slideUp(700,'easeOutBounce')
	/* end */

	local.Country = this.getGeoCountry()
	local.Owner = this

	jQuery('#GeoDataOverviewData').slideUp
	(
		500,'easeOutBounce',
		function()
		{
			jQuery(this).html('');

			local.Country.eachState
			(
				function(State)
				{
					local.Owner.showStateDataByGeoClass(State)
				}
			)

			jQuery(this).slideDown(500,'easeOutBounce');
		}
	)

	this.updateStateStatusDisplay()

	return this
}

V2SitesMap.prototype.focusOnCountyById = function(id)
{
	jQuery('#CountyId').val(id)
	jQuery('.GeoNavBack').show();
	jQuery('#GeoDataOverviewData').slideUp(500,'easeOutBounce');
	jQuery('#MapUpButton').slideDown(700,'easeOutBounce')
	this.Super(id)
}

V2SitesMap.prototype.processFetchedCompetitors = function(query)
{
	var local = {Map:this.getMap()}

	query = ColdFusion.extendQuery(query)

	if(query.getRecordCount() == 0)
	{
		if(confirm('No competitors have latitude & longitude defined. Would you like to see a competitor info sheet?'))
			this.showCompetitorInfoSheet();
	}else
		this.Super(query);

	this.onAjaxStop()
}

V2SitesMap.prototype.setStateId = function(id)
{
	var local = {}
	local.Select = jQuery('#StateId');
	local.Select.val(id);
	local.Option = local.Select[0].options[local.Select[0].selectedIndex];
	jQuery('.StateSpecifier').html(local.Option.innerHTML);
	return this;
}

V2SitesMap.prototype.focusOnStateById = function(id)
{
	var local = {}

	this.setStateId(id);
	this.Super(id);

	/* resets */
		jQuery('.GeoNavBack').show();
		jQuery('#CountyId').val('')
		jQuery('#CompetitorSheetWrap').slideUp(500,'easeOutBounce')
		jQuery('#ToggleCompetitors').checkboxradio('disable')
	/* end */
}

V2SitesMap.prototype.showZipsByCountyId = function(id)
{
	var local = {}

	this.Super(id);

	local.polyArray = this.getPolygonDrawerMemory().getById('co'+id);
	local.County = local.polyArray[0].getGeoClass();

	jQuery('.GeoNavBack').show();
	jQuery('#CountyId').val(id)
	jQuery('#CompetitorToggle').delay(2000).slideDown(500,"easeOutBounce")
	jQuery('#MapUpButton').slideDown(700,'easeOutBounce')
	jQuery('#ToggleCompetitors').checkboxradio('enable')

	jQuery('#GeoDataOverviewData')
	.slideUp
	(500,'easeOutBounce',
		function()
		{
			local.jGeoDataOverviewData = jQuery('#GeoDataOverviewData').html('');

			local.County.eachZip
			(
				function(GeoZip)
				{

					local.CloneWrap = jQuery('#GeoDataClone').clone(0)
					local.CloneWrap.removeAttr('id')
					var popEst = parseFloat(GeoZip.getPopEst()).toCommaFormat();

					local.CloneWrap.attr('geoid', GeoZip.getGeoId())
					jQuery('.GeoDataLabel', local.CloneWrap).html( GeoZip.getName() )
					jQuery('.GeoDataPopEst', local.CloneWrap).html( popEst )
					jQuery('.GeoDataZipWrap', local.CloneWrap).hide()

					local.jGeoDataOverviewData.append(local.CloneWrap)

				}
			)

			local.jGeoDataOverviewData.slideDown(500,'easeOutBounce')
		}
	)

	this.updateZipStatusDisplay()

	return this
}

V2SitesMap.prototype.back = function()
{
	var local = {}

	local.countyId = jQuery('#CountyId').val();
	local.stateId = jQuery('#StateId').val()

	if(local.countyId.length)
		return this.focusOnStateById(local.stateId)

	return this.focusOnCountry();
}

V2SitesMap.prototype.showCountiesByStateId = function(id)
{
	var local = {}

	this.setStateId(id)

	local.State = this.getGeoCountry().getStateById(id);
	jQuery('#MapUpButton').slideDown(700,'easeOutBounce')
	local.jGeoDataOverviewData = jQuery('#GeoDataOverviewData').html('');
	jQuery('#CompetitorToggle').slideUp(500,"easeOutBounce")
	this.getMarkerMemory().hideAll()

	local.eachMethod = function(GeoClass)
	{
		local.CloneWrap = jQuery('#GeoDataClone').clone(0)
		local.CloneWrap.removeAttr('id')

		local.popEst = parseFloat(GeoClass.getPopEst()).toCommaFormat();

		local.CloneWrap
		.attr('geoid', GeoClass.getId())
		.addClass('CountyToZipTrigger')

		jQuery('.GeoDataLabel', local.CloneWrap).html( GeoClass.getName() )
		jQuery('.GeoDataPopEst', local.CloneWrap).html( local.popEst )
		jQuery('.GeoDataZipWrap', local.CloneWrap).show()
		jQuery('.GeoDataZips', local.CloneWrap).html( GeoClass.getZips() )

		arguments.callee.Owner.attachCountyToZipTriggerByElement(local.CloneWrap)

		local.jGeoDataOverviewData.append(local.CloneWrap)
	}
	local.eachMethod.Owner = this

	local.State.eachCounty(local.eachMethod)

	this.Super(id)

	local.jGeoDataOverviewData.slideDown(500,'easeOutBounce');
}

V2SitesMap.prototype.showStateDataByGeoClass = function(GeoClass)
{
	var local = {}

	local.GeoClass = GeoClass

	local.CloneWrap = jQuery('#GeoDataClone').clone(0)
	local.CloneWrap.removeAttr('id')

	//local.popEst = parseFloat(State.getPopEst()).toCommaFormat();

	local.CloneWrap
	.attr('geoid', local.GeoClass.getId())
	.addClass('StateToCountyTrigger')

	jQuery('.GeoDataLabel', local.CloneWrap).html( local.GeoClass.getName() )
	//jQuery('.GeoDataPopEst', local.CloneWrap).html( local.popEst )
	jQuery('.GeoDataZipWrap', local.CloneWrap).show()
	jQuery('.GeoDataZips', local.CloneWrap).html( local.GeoClass.getZips() )

	this.attachStateToCountyTriggerByElement(local.CloneWrap)

	jQuery('#GeoDataOverviewData').append(local.CloneWrap)
}
