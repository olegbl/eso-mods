# Development notes

## Lua version

ESO's UI runs Havok Script, ZeniMax's fork of **Lua 5.1**. All addon code in
this repo must be Lua 5.1-compatible:

- No Lua 5.2+ features: no `goto`, no bitwise operators, no integer division
  (`//`), no `\z` string escapes.
- Syntax-check with `luac5.1 -p <file>` (Lua 5.1 specifically, not a newer
  version).
- The sandbox exposes no `io`, `os`, or `require`; use the ESO API and `zo_*`
  helpers instead of standard libraries.

## Language files

`GamePadHelper/lang/*.lua` (except `en.lua`) start with a UTF-8 BOM. ESO's
loader accepts it, but stock `luac` fails at byte 1 — strip the first 3 bytes
before parse-checking (`tail -c +4 file.lua | luac5.1 -p -`). Keep the BOM
when editing these files.
