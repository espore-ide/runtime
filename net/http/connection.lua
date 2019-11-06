-- httpserver-connection
-- Part of nodemcu-httpserver, provides a buffered connection object that can handle multiple
-- consecutive send() calls, and buffers small payloads to send once they get big.
-- For this to work, it must be used from a coroutine and owner is responsible for the final
-- flush() and for closing the connection.
-- Author: Philip Gladstone, Marcos Kirsch

local BufferedConnection = {}

local codez = {
   [200] = "OK",
   [400] = "Bad Request",
   [401] = "Unauthorized",
   [404] = "Not Found",
   [405] = "Method Not Allowed",
   [500] = "Internal Server Error",
   [501] = "Not Implemented",
   [503] = "Service Unavailable"
}

-- parameter is the nodemcu-firmware connection
function BufferedConnection:new(connection)
   local o = {}
   setmetatable(o, self)
   self.__index = self
   o.connection = connection
   o.size = 0
   o.data = {}
   return o
end

-- Returns true if there was any data to be sent.
function BufferedConnection:flush()
   if self.size > 0 then
      self.connection:send(table.concat(self.data, ""))
      self.data = {}
      self.size = 0
      return true
   end
   return false
end

function BufferedConnection:getpeer()
   return self.connection:getpeer()
end

function BufferedConnection:send(payload)
   local flushThreshold = 1400
   local newSize = self.size + payload:len()
   while newSize >= flushThreshold do
      --STEP1: cut out piece from payload to complete threshold bytes in table
      local pieceSize = flushThreshold - self.size
      local piece = payload:sub(1, pieceSize)
      payload = payload:sub(pieceSize + 1, -1)
      --STEP2: insert piece into table
      table.insert(self.data, piece)
      piece = nil
      self.size = self.size + pieceSize --size should be same as flushThreshold
      --STEP3: flush entire table
      if self:flush() then
         coroutine.yield()
      end
      --at this point, size should be 0, because the table was just flushed
      newSize = self.size + payload:len()
   end

   --at this point, whatever is left in payload should be < flushThreshold
   if payload:len() ~= 0 then
      --leave remaining data in the table
      table.insert(self.data, payload)
      self.size = self.size + payload:len()
   end
end

function BufferedConnection:sendHeader(code, mimeType, isGzipped, extraHeaders)
   local statusString = codez[code] or codez[501]
   mimeType = mimeType or "text/plain"

   self:send(
      "HTTP/1.0 " ..
         code .. " " .. statusString .. "\r\nServer: nodemcu-httpserver\r\nContent-Type: " .. mimeType .. "\r\n"
   )
   if isGzipped then
      self:send("Cache-Control: private, max-age=2592000\r\nContent-Encoding: gzip\r\n")
   end
   if (extraHeaders) then
      for i, extraHeader in ipairs(extraHeaders) do
         self:send(extraHeader .. "\r\n")
      end
   end

   self:send("Connection: close\r\n\r\n")
   return statusString
end

return BufferedConnection
