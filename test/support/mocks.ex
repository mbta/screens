injected_modules = [
  Screens.Alerts.Alert,
  Screens.Config.Cache,
  Screens.Elevator,
  Screens.Facilities.Facility,
  Screens.Headways,
  Screens.RoutePatterns.RoutePattern,
  Screens.Routes.Route,
  Screens.Stops.Stop,
  Screens.V2.Departure,
  Screens.V2.ScreenData.Parameters
]

for module <- injected_modules do
  module |> Module.concat("Mock") |> Mox.defmock(for: module)
end
