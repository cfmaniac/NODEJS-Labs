<cfScript>
	request.isWrapRequest = 0;

	local.passwordHash = left(hash(year(now())+week(now())),5);
	local.isAuthenticated=
	(
		(isDefined('password') AND local.passwordHash EQ password) 	OR	(request.UserRequest.isLocalNetwork())
	OR	(structKeyExists(request.clientInput, "isInhouseByPass")  AND	request.UserRequest.isInternalAddress() )
	OR (structKeyExists(request.clientInput, 'username') and request.clientinput.username is "sales@saleswanted.com" AND request.clientinput.password is "sales1234")
	
	)
	;
</cfScript>
<cfif local.isAuthenticated  >
	<cfInclude template="Map.cfm" />
<cfElse>
	<cfInclude template="AppleWebLogin.cfm" />
</cfif>
