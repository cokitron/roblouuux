# Server rules
- Everything here runs with authority. Treat every RemoteEvent/RemoteFunction/ProximityPrompt/ClickDetector input as hostile: validate type, `math.isfinite`, range, class/location, permission, and per-player rate limit before use.
- Never trust a client-supplied player, price, damage, or item id. The `Player` argument itself is engine-supplied and safe.
- Persist player data through a single data module; do not scatter DataStore calls. Use `UpdateAsync` with retries and handle `nil`/throttle errors. Save on `PlayerRemoving` and `game:BindToClose`.
- Never tween with TweenService on the server (it replicates every frame). Tell the client to tween.
- Clean up per-player state on `PlayerRemoving`.
