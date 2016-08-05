<cfComponent
	Hint		= "Unify script loading and make browser safe for Ajax script loading"
	Description	= "Scripts/Media/Files Unified Modeling Language ... perhaps better know as a handy tool for looking scripts"
	Output		= "no"
	extends		= "CFExpose.RequestKit.Media"
	accessors	= "yes"
>
	<cfProperty name="baseHref"				type="string" />
	<cfProperty name="queryString"			type="string" />
	<cfProperty name="relativeScriptUrl"	type="string" />
	<cfProperty name="fileName"				type="string" />
	<cfProperty name="ClientFileLoader"		type="ClientFileLoader" />
</cfComponent>
