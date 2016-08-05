<cfScript>
	local.AppleWebLogin = new Movic.Html.Process.AppleWebLogin();
	local.AppleWebLogin.setLoginLabel(request.DomainVerbiage.getDomainName());
	local.AppleWebLogin.setKeyLoginMode(0);
	local.AppleWebLogin.setUserNameLabel('Your Name');
	local.output = local.AppleWebLogin.getOutput();
</cfScript>
<cfOutput>#local.output#</cfOutput>