local config = {


-->==========[ Debug ]==========<--
debug_mode = false,
debug_scale = 1/client:getGuiScale(), -- the thickness of the lines for debug lines, in BBunits


-->==========[ Rendering ]==========<--
clipping_margin = 64, -- The gap between the parent element to its children.


-->==========[ Labeling ]==========<--
debug_event_name = "_c",
internal_events_name = "__a",


-->==========[ System ]==========<--
path = (....."/"), -- the root path of GNUI
utils = require(....."/utils"),

-->==========[ External Libraries ]==========<--
event = require("libraries.eventLib"),
}

return config