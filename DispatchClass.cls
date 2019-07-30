Class User.DispatchClass Extends CSPSecurity.REST
{

// Deactivate cors
Parameter HandleCorsRequest = 0;

/// XData UrlMap is used to route calls to the appropriate method
XData UrlMap
{
<Routes>
<Route Url="/get" Method="GET" Call="get" Cors="false"/>
</Routes>
}

ClassMethod get() As %Status
{
	write "Success!
  return $$$OK
}
}
