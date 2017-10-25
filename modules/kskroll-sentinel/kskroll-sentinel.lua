local M = {}
M.layer = {}

function M.layer.finish(state, req, pkt)
  local req = kres.request_t(req)
  log('finish state: ' .. state)

  if bit.band(state, kres.DONE) == 0 then
        log('[trust-sentinel] not DONE')
	return state end -- not resolved yet, exit

  local qry = req:resolved()
  if qry.parent ~= nil then
	  log('[trust-sentinel] HAS parent')
	  return state end -- an internal query, exit

  local pkt = kres.pkt_t(pkt)
  secure = bit.band(pkt.wire[3], 0x20) ~= 0
  if not secure then
	  log('[trust-sentinel] AD not set')
	  return state end -- insecure answer, exit

  local qname = kres.dname2str(qry:name())
  local hexkeytag = string.match(qname, '.[iI][sS]%-[tT][aA]%-(%x+).')
  if not hexkeytag then
	  log('[trust-sentinel] QNAME did not match: ' .. qname)
	  return state end -- regex did not match, exit

  local qkeytag = tonumber(hexkeytag, 16)
  if not qkeytag then
	  return state end -- not a valid hex string, exit

  if qkeytag > 0xffff then -- TODO: what about < 0?
	  return state end -- too big keytag?!, exit
  log('[trust-sentinel] KEY TAG: ' .. qkeytag)

  local found = false
  for keyidx = 1, #trust_anchors.keysets['\0'] do
	  local key = trust_anchors.keysets['\0'][keyidx]
	  if qkeytag == key.key_tag then
		found = (key.state == "Valid")
	  	log('[trust-sentinel] FOUND keytag ' .. qkeytag .. ' state ' .. key.state)
	  end
  end

  if not found then
	  -- TA not found or valid yet, return NXDOMAIN
	  -- hack to replace rcode
	  pkt.wire[3] = bit.band(pkt.wire[3], 0xf0) + 2
  end
  return state -- do not break resolution process
end

return M
