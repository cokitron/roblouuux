# Client rules
- The client renders and sends input. It never decides outcomes; it asks the server and reflects the result. Client-side checks are UX only.
- Assume StreamingEnabled: use `WaitForChild` with a timeout or `PersistentLoaded`, and tolerate parts streaming out.
- Tween, camera, effects and UI animation happen here.
- Throttle anything that fires a remote from user input.
- Disconnect connections and destroy instances you create when a UI/feature closes.
