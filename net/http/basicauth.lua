-- httpserver-basicauth.lua
-- Part of nodemcu-httpserver, authenticates a user using http basic auth.
-- Author: Sam Dieck

local basicAuth = {}

-- Parse basic auth http header.
-- Returns the username if header contains valid credentials,
-- nil otherwise.
function basicAuth.authenticate(header, loginCallback)
   local credentials_enc = header:match("Authorization: Basic ([A-Za-z0-9+/=]+)")
   if not credentials_enc then
      return nil
   end
   local credentials = encoder.fromBase64(credentials_enc)
   local user, pwd = credentials:match("^(.*):(.*)$")
   if loginCallback(user, pwd) then
      print('httpserver-basicauth: User "' .. user .. '": Authenticated.')
      return user
   else
      print('httpserver-basicauth: User "' .. user .. '": Access denied.')
      return nil
   end
end

function basicAuth.authErrorHeader(realm)
   return 'WWW-Authenticate: Basic realm="' .. realm .. '"'
end

return basicAuth
