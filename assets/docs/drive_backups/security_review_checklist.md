# **Security Review Checklist**

*Run this for every change that adds or alters client-to-server communication, saved data, purchases or player-visible text. Rule codes refer to the Safe and Scalable Roblox Rules doc.*

## **For each client-to-server remote**

> * Extra arguments rejected (select("\#", ...) check). SEC-1  
> * Every argument type checked with typeof. SEC-1  
> * Numbers: math.isfinite first, then range, integer check where needed. SEC-1  
> * Strings: length cap; ids looked up in a server table, never used to index Instances directly. SEC-1  
> * Tables: shape validated, no mixed or sparse arrays, size capped. SEC-1  
> * Instances: typeof, IsA, IsDescendantOf, distance or ownership. SEC-2  
> * Permission and state: is this player allowed to do this now (alive, offer pending, owns item, cooldown)? SEC-1  
> * Per-player rate limit on the server, cleaned up on PlayerRemoving. SEC-1, PERF-6  
> * Worst case at 1,000 calls per second is cheap and harmless.  
> * Result is based on server state only; nothing the client sent is relayed raw to other clients. SEC-6, SEC-8

## **Movement and position**

> * Any reward based on position (pickups, zones, damage range) uses the sanitized position. SEC-5  
> * Displacement per step is bounded by speed and latency allowance (once implemented). SEC-5

## **Prompts and detectors**

> * ProximityPrompt, ClickDetector, DragDetector and Touched handlers check distance and rate on the server.

## **Server to client**

> * No InvokeClient. SEC-3  
> * Unreliable payloads at or under the 900-byte project limit, timestamped. SEC-4  
> * Nothing secret replicated (drop weights, thresholds). SEC-7

## **Data**

> * Writes go through the data module with UpdateAsync and retries. DATA-1, DATA-2  
> * Schema version bumped and migration added if the shape changed. DATA-4  
> * New stores keyed by UserId and covered by an erasure template. DATA-5

## **Purchases and text**

> * ProcessReceipt idempotent; NotProcessedYet on failure. POL-1  
> * Random paid items disclose odds and check PolicyService, failing closed. POL-2  
> * Player-written text filtered on the server. POL-3

## **Sign-off**

| Change | Reviewer | Date | Findings |
| :---- | :---- | :---- | :---- |
|  |  |  |  |

