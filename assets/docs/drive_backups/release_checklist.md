# **Release Checklist**

*Run before every publish to a public or beta audience. Synthesized from the Roblox Best Practices Research doc; it is not a single official Roblox list.*

## **Build**

> * StyLua and Selene clean.  
> * Unit tests pass.  
> * Code committed and tagged; place file saved and backed up.  
> * Docs updated (GDD numbers, Networking Protocol, Roadmap).

## **Playtest**

> * Studio local server with at least 2 players: console clean on server and clients.  
> * Full run to death and respawn; round reset when everyone dies or leaves.  
> * Mobile emulation (or a real phone): HUD readable, level-up buttons tappable, 60 FPS at the enemy cap.  
> * Server heartbeat holds 60 at the target player count; server memory under 50%.  
> * Data Ping close to Network Ping at the enemy cap.

## **Security**

> * Security Review Checklist done for every new or changed remote.  
> * Unreliable packets under the project limit (assert passes).

## **Data (once persistence exists)**

> * BindToClose saves finish within 30 seconds.  
> * Migrations tested against saves from the previous version.  
> * Right-to-erasure templates cover every user store.

## **Compliance**

> * Maturity and Compliance Questionnaire current for this version's content.  
> * All player-visible user text filtered.  
> * PolicyService gating fails closed (if paid random items or trading exist).  
> * ProcessReceipt idempotent; every listed developer product handled (if monetized).  
> * Asset credits up to date; no unaudited Toolbox assets.

## **Launch mechanics**

> * Experience description, icon and thumbnails current.  
> * Analytics events and onboarding funnel firing (check in a published test).  
> * For first launch: soft-launch via Experience Betas before leaving beta.  
> * Publish from Studio if meshes, unions or SurfaceAppearances changed.  
> * Watch the Safety Dashboard and error reports for 48 hours after release.

## **Release log**

| Date | Version | Changes | Checked by |
| :---- | :---- | :---- | :---- |
|  |  |  |  |

