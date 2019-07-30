# Anti-CSRF-CSP
A method for mitigating anti CSRF attacks on CSP derived api calls.

[![Gitter](https://img.shields.io/badge/Available%20on-Intersystems%20Open%20Exchange-00b2a9.svg)](https://openexchange.intersystems.com/package/Anti-CSRF-CSP)

IRIS provides us with anti **login** CSRF attack mitigation, however this is not the same as a CSRF attack, as login attacks only occur on the login form. There are currently no built-in tools to mitigate CSRF attacks on api calls and other forms, so this is a step in mitigating these attacks.

## Definition
See the following link from OWASP for the definition of a CSRF attack:

https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)

## Methodology

The method shown in this repo for mitigating these attacks is currently not proactive, but a minimum. By proactive, I mean that it is possible in the future for attackers to coerce a browser into creating arbituary custom headers and values. Because this is not currently possible, the mere presence of a custom header is enough to mitigate this risk. See the following for further explanation:

https://security.stackexchange.com/questions/23371/csrf-protection-with-custom-headers-and-without-validating-token

## Example

A rest call made to a CSP dispatch class extends the %CSP.REST class which gives us access to handling the headers before any intrusion. In the client code, we add the custom header to our request, along with junk data:

```javascript
$.ajax({
  beforeSend: function(request) {
  // Where we set the custom header. The value doesn't matter. In the future we want to set this and verify the values matches the servers'
    request.setRequestHeader("Grandmas-Cookies", Math.random());
  },
  url:serverURL+url+data,
  type: "GET",
  async: true,
  contentType: "application/json",
  dataType: "text",
  error: function(response) { 
    console.log(response);
  },
  success: successCallback
  });
```

Then on the server's Page function of the %CSP.REST extended class, we check for the presence of this header.

```sh
set header = %request.GetCgiEnv("HTTP_GRANDMAS_COOKIES")
// If blank, toss it out. Client browsers cannot be coerced into setting values of custom headers
if header = "" {
  Set tSC=..Http403()
	Quit
}
```

If the header isn't there or it has no value, the request is dropped.

## The Future

This method needs to move towards proactivity which means a CSRF token will need to be sent back and forth from client/server and validated. We're looking to utilize the session cookie information so that we don't reinvent the wheel with how CSP works. Here's more information on where this should be heading:

https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.md
