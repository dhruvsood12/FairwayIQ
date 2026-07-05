# A *.xcuserstate ignore does not cover xcuserdata/

The repo ignored `*.xcuserstate` from the start, yet
`FairwayIQ.xcodeproj/xcuserdata/dhruvsood.xcuserdatad/xcschemes/xcschememanagement.plist`
stayed tracked from the first commit through the June 11 history purge and two
later hygiene sweeps. Three separate checks missed it because each grepped for
`xcuserstate` or `DerivedData` or `.build`, and this file matches none of
those patterns.

Lessons:
- Ignore the directory (`xcuserdata/`), not just the one file extension Xcode
  writes inside it.
- Hygiene greps written from the list of artifacts you expect will only find
  the artifacts you expect. Sweep with the broader parent pattern
  (`git ls-files | grep -i xcuserdata`) or list every tracked path under the
  project bundle and read it.
- The June 11 filter-repo pass purged exactly its named path (`.build/`) and
  nothing else; a rewrite is not a general cleanup.

Fixed in commit `chore(repo): stop tracking per-user Xcode scheme state`
(untrack the plist, add `xcuserdata/` to `.gitignore`). The shared scheme in
`xcshareddata/xcschemes/` is unaffected; the plist held only an `orderHint`.
