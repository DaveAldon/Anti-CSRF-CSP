Class CSPSecurity.REST Extends %CSP.REST
{

// For mitigating CSRF attacks, we need to intercept the headers passed with an api call. This can be done by overriding the page function
/// This method matches the request and method and calls the dispatcher
ClassMethod Page(skipheader As %Boolean = 1) As %Status [ ProcedureBlock = 0 ]
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tAuthorized,tRedirected As %Boolean
    #dim tRedirectRoutine,tURL As %String = ""
    #dim %response As %CSP.Response
        
    Try {
        // CSRF header checking logic
        // Check the custom header for a value
	    Try {
		    set header = %request.GetCgiEnv("HTTP_GRANDMAS_COOKIES")
			  // If blank, toss it out. Client browsers cannot be coerced into setting values of custom headers
			  if header = "" {
				  Set tSC=..Http403()
				  Quit
			  }
			  // Troubleshooting code, sets a header with the value of the request header, and returns to client. We can use this to verify the server received the header
        // Do %response.SetHeader("RETURN_GRANDMAS_COOKIES",%request.GetCgiEnv("HTTP_RETURN_GRANDMAS_COOKIES"))
	    }
	    Catch (e) {
        	Set tSC=e.AsStatus()
        	Quit
    	}	
	    

        #; Ensure that we honor the requested charset 
        Set %response.CharSet=..#CHARSET

        #; Ensure that we honor the requested CONTENTTYPE
        If ..#CONTENTTYPE'="" Set %response.ContentType=..#CONTENTTYPE 

        #; Ensure that we honor the requested HTTP_ACCEPT_LANGUAGE 
        Set %response.Domain = ..#DOMAIN
        Do %response.MatchLanguage() 
        
        #; Record if device re-direction is already active
        Set tRedirected=##class(%Library.Device).ReDirectIO()
        
        #; Record the redirect routine
        Set tRedirectRoutine=$System.Device.GetMnemonicRoutine()
        
        #; Now switch to using THIS routine for device redirection
        Use $io::("^%SYS.cspServer2")
        
        #; Switch device redirection on (may already be on but thats ok)
        Do ##class(%Library.Device).ReDirectIO(1)
        
        #; Ensure that the application is defined (security check)
        If $$$GetSecurityApplicationsDispatchClass(%request.AppData)="" {
             
             #; Report not authorized
             Set tSC=..Http403()
             
             #; Done
             Quit
        }
        
        #; GgiEnvs are not defined in the CSP shell
        Set tURL=$Get(%request.CgiEnvs("CSPLIB"))
        If tURL="" Set tURL=%request.URL
        
        #; Ensure that any query string is not taken into account
        Set tURL=$Piece(tURL,"?")
          
        #; Do an access check
        Set tSC=..AccessCheck(.tAuthorized)
        If $$$ISERR(tSC) Quit

        If tAuthorized=0 {
            
            #; Don't want the session token
            Set %response.OutputSessionToken=0
            
            #; Set the Http Status
            Set %response.Status=..#HTTP401UNAUTHORIZED
            
            #; Done
            Quit
        }
        
        #; Dispatch the request
        Set tSC=..DispatchRequest(tURL,%request.Method)
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    If $$$ISERR(tSC) {
        
        #; Don't want the session token
        Set %response.OutputSessionToken=0
        
        Do ..Http500(##class(%Exception.StatusException).CreateFromStatus(tSC))
    }
    
    #; Ensure that at least something is written out as the body
    #; This will trigger the device redirect capture and force headers to be written
    #; (if not already done)
    Write ""
    
    #; Reset redirect device if necessary
    If tRedirected {
        
        #; Use the original redirected routine
        Use $io::("^"_tRedirectRoutine)
        
        #; Switch device redirection on
        Do ##class(%Library.Device).ReDirectIO(1)
    }
    
    #; Any errors should have been caught and reported
    Quit $$$OK
}

}
