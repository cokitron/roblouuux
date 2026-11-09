# roblouuux Game Docs: Start Here

*Documentation hub for roblouuux, a Haunted Graveyard survivor game (Vampire Survivors style) on Roblox. Last synced 2026-11-02 from the code and approved specifications.*

## What this game is

A co-op 3rd-person Haunted Graveyard survivor. Players stage in an elevated **Sanctuary Courtyard Lobby**, select their **Starting Weapon** (Arcanist's Staff, Crypt Cleaver, or Soulflame Lantern) via interactive pedestals or the Lobby Arsenal Modal, deploy through the **Runic Crypt Portal** into a procedurally randomized graveyard arena, steer through wrought-iron fence choke points in responsive 3rd-person while weapon attacks and protective auras trigger automatically, collect faceted Soul XP Crystals from 5 enemy types (Skeleton, Bat, Wisp, Spider, Golem), and pause time on level-up to pick from three upgrade cards drawn from their weapon's dedicated talent tree. The server simulates everything; clients only draw.

## Folders and documents

| Folder | Documents | Use it for |
| :---- | :---- | :---- |
| [01 Game Design](https://drive.google.com/drive/folders/1KCnpSnqPWgJCQ99O5sAMCqjBrUuMBPDj) | [Game Design Document](https://docs.google.com/document/d/1t4UT6mSyfz6qAPvWlYSy35f5fBKYhYgThuwF2ZXLSxw/edit), [Feature Spec: Starter Weapons and Weapon Talent Trees](https://docs.google.com/document/d/14ky3JFHhd6bHeQ8u3oAMZ0Re7b0el6u32HZ0YyUWX9A/edit), [Feature Spec: Haunted Sanctuary Lobby and Monetized Mid-Run Respawn](https://docs.google.com/document/d/1ce7jqX1vS1J124hh01I2dIXrvCD9Ct2NKrprs_sHz_0/edit) | Core loop, 3 Starter Weapons, weapon talent trees, Sanctuary Lobby wrapper, Soul Revive monetization, player stats, weapons, upgrades, enemies, procedural graveyard layout |
| [02 Architecture and Systems](https://drive.google.com/drive/folders/1aBbme0ISjqyu9ZeQp9d2F48SWgdppPEa) | [Architecture Overview](https://docs.google.com/document/d/1zgqYcAnbpbyfMgX4ZkcR_DXLOCMeIpeME9VniQd-840/edit), [Networking Protocol](https://docs.google.com/document/d/1nU_q0LUDHdX2_CClhurBB1V9JoYrpBal__AEzLzpToI/edit), [Development Workflow and Tooling](https://docs.google.com/document/d/1gN896DGisvkk-NA5C7kmdTO2vpuLY1Ji2tndC3hEuqs/edit), [Decision Record: Virtual Health Lifecycle and Monetized Mid-Run Respawn](https://docs.google.com/document/d/145nB_NYq5SxP_yKbCtfDKrkK50mIt3mYZf7vL5GkqbA/edit) | How the code is organized, what goes over the wire, ArtCraft 3D/PBR asset pipeline, how to build and verify, and architecture decision records |
| [03 Engineering Rules](https://drive.google.com/drive/folders/180KAEjJwog61211-JX7mFOmTsvHOzKUm) | [Safe and Scalable Roblox Rules](https://docs.google.com/document/d/14aPSOr8vxaxdJeuVkj60LdgC4iL5l_Rvai3WwemxsHw/edit), [Security Review Checklist](https://docs.google.com/document/d/1K6iFUESYOJb9uXmaKH7s4wf2K9Qa4NcFatTJfRYd14U/edit) | The engineering rules (`SEC/DATA/POL/PERF/PROC`) every change follows, and the checklist for reviewing remotes, data, and purchases |
| [04 Art and Assets](https://drive.google.com/drive/folders/1hH3Qnfp6U_NOH8gQ4PIEkIvLNAN8phBs) | [Asset Pipeline and Credits](https://docs.google.com/document/d/1tyr7FuwpmlfVOzf9sxL2mbJethCRdmewVh7PB5DX4iQ/edit) | Custom SolidCraft & TextureCraft graveyard/combat asset catalog, enemy template contract, and asset credits |
| [05 Production and Release](https://drive.google.com/drive/folders/1sEaxMzfKR74s-2e3Cw8DBCKb5E-_MujE) | [Product Management, Gamification and Monetization Rules](https://docs.google.com/document/d/1uaCAd_F9F8a_z3bd_A253bCIDvSzBjhtElVUUon8bQk/edit), [Roadmap and Known Limits](https://docs.google.com/document/d/1-D_cKYKGglsIo9gRkGjbgXm5eDlwwJYjExvuWGbVWxw/edit), [Release Checklist](https://docs.google.com/document/d/1jMID1BnnVgoRLBS1YJTBpj574reYGwqi9R6moFtjvRM/edit) | Product/growth/monetization ruleset (`DISC/LOOP/MON/PM`), milestones, known gaps, what to check before publishing. Playtest reports go here |
| [06 Research](https://drive.google.com/drive/folders/1DBdALyMEnft_X-l-sIO3Uwu7WffuWmYe) | [Roblox Best Practices Research (Nov 2026\)](https://docs.google.com/document/d/12cvkITLBjK1vZG-RLUtgLhpJP86RqRTySI-wRggjNSs/edit), [Roblox Product, Marketing, Gamification and Monetization Research (Nov 2026\)](https://docs.google.com/document/d/1WpJLUSRPLgA5h-9TsbPk35UUgGstkukvgT5hHFNbFSo/edit) | Sourced findings on security, data, performance, policy, discovery algorithm, gamification, retention, and monetization |
| [07 Templates](https://drive.google.com/drive/folders/1sMjUQAZW_gjT_6lVk9d9c9InTnafNBhL) | [Feature Spec](https://docs.google.com/document/d/1-yxbnJnoL-K3lhVlKhIHBZmB4chXOrbkJ2uNMJL1GiE/edit), [Playtest Report](https://docs.google.com/document/d/1me6Ujpb-FmjzVcfD6iT3hhEZ5Z3tn_kahneicqOYxqY/edit), [Decision Record](https://docs.google.com/document/d/1ISUX2hvLrXmvlQNtS2Pd_nSKXORJVTKMeMt86RzhcoA/edit) | Copy into the target folder before filling in |

## How these docs stay accurate

- The code in the repository is the source of truth. Each doc says when it was last synced with the code.  
- Claude Code and Antigravity follow the engineering rules in `.claude/rules/safe-scalable-roblox.md` (`SEC/DATA/POL/PERF/PROC`) and the product management rules in `.claude/rules/product-growth-monetization.md` (`DISC/LOOP/MON/PM`), and update the affected Drive docs whenever numbers, remotes, packets, enemies, upgrades, assets, or economy flows change (`PROC-4`).  
- Platform limits and policies change. Re-check the Research docs against create.roblox.com before launch work.

## Suggested reading order

1. [Game Design Document](https://docs.google.com/document/d/1t4UT6mSyfz6qAPvWlYSy35f5fBKYhYgThuwF2ZXLSxw/edit)  
2. [Feature Spec: Starter Weapons and Weapon Talent Trees](https://docs.google.com/document/d/14ky3JFHhd6bHeQ8u3oAMZ0Re7b0el6u32HZ0YyUWX9A/edit)  
3. [Feature Spec: Haunted Sanctuary Lobby and Monetized Mid-Run Respawn](https://docs.google.com/document/d/1ce7jqX1vS1J124hh01I2dIXrvCD9Ct2NKrprs_sHz_0/edit)  
4. [Architecture Overview](https://docs.google.com/document/d/1zgqYcAnbpbyfMgX4ZkcR_DXLOCMeIpeME9VniQd-840/edit)  
5. [Networking Protocol](https://docs.google.com/document/d/1nU_q0LUDHdX2_CClhurBB1V9JoYrpBal__AEzLzpToI/edit)  
6. [Safe and Scalable Roblox Rules](https://docs.google.com/document/d/14aPSOr8vxaxdJeuVkj60LdgC4iL5l_Rvai3WwemxsHw/edit)  
7. [Product Management, Gamification and Monetization Rules](https://docs.google.com/document/d/1uaCAd_F9F8a_z3bd_A253bCIDvSzBjhtElVUUon8bQk/edit)  
8. [Roadmap and Known Limits](https://docs.google.com/document/d/1-D_cKYKGglsIo9gRkGjbgXm5eDlwwJYjExvuWGbVWxw/edit)