# AITravelApp

First iOS MVP for an AI travel app:

- Full-screen 3D map experience with custom POI annotations.
- Zoom-aware POI loading policy.
- Text and speech entry points for natural-language search.
- Local semantic parser that mirrors the backend AI contract.
- Route planning with ordered stops, estimated timing and map polyline.
- Location-based check-in prompt for active trip stops.

The current build uses Apple MapKit so the first version can run without third-party API keys. The app is structured so Mapbox, Foursquare, OpenTripMap, Yelp and an OpenAI-backed backend can replace the mock services behind `TravelAPIClient`.

## Open in Xcode

Open `AITravelApp.xcodeproj`, select an iPhone simulator, then run the `AITravelApp` scheme.

Minimum target: iOS 17.0.

## Structure

```text
AITravelApp/
  App/                 App entry, root view and feature orchestration
  Core/
    Models/            Place, parsed query, trip and check-in models
    Services/          Semantic search, POI API, planning, location, speech
    Utilities/         Geo math and zoom display policy
  Features/
    Map/               MKMapView 3D wrapper and route rendering
    Search/            Search bar, place list and place cards
    Trip/              Route plan sheet and stop rows
    CheckIn/           Check-in history UI
  Resources/           Asset catalog
AITravelAppTests/      Focused unit tests for parsing and planning
Docs/                  Architecture and backend contract notes
```

## Next Integration Points

1. Replace `MockTravelAPIClient` with a backend client for `/v1/pois`, `/v1/ai/search`, `/v1/trips/plan` and `/v1/checkins`.
2. Add Mapbox SDK inside `Features/Map` if you need Mapbox terrain, globe style and custom runtime styling.
3. Persist trips and check-ins using SwiftData or a backend user profile service.
4. Move semantic parsing from `SemanticSearchService.parse(text:)` to the backend LLM orchestrator.
