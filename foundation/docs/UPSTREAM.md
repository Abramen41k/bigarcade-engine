# Maintaining the Godot fork

The parent repository contains the authoritative overlay and a pinned upstream
lock. `bootstrap.py` clones that exact tag, verifies the locked commit is an
ancestor, creates `bigarcade/godot-foundation`, installs the module/branding and
commits the change. It refuses a dirty destination and never resets/rebases it.
The full fork source and an upstream-to-fork patch are included in the source
delivery for inspection without relying on the transient build directory.

To inspect an update without applying it:

```sh
python foundation/tools/check_upstream.py 4.7.2-stable
```

This fetches the explicit stable tag and writes a diff summary; it does not change
the lock or working branch. For a real upgrade:

1. Create a new parent review branch and a separate fork checkout. Preserve the
   current lock, build reports and source bundle.
2. Read upstream release notes, compiler requirements, license changes and API
   changes in touched module/editor/rendering areas.
3. Update the lock to a verified tag/SHA in the review branch. Reapply the small
   overlay to the new checkout; review version.py substitutions and removed files.
4. Compile the complete editor on Windows/Linux, run native and scene regressions,
   import assets and compare real desktop reference images and performance.
5. Commit lock/overlay changes together after review. Retain exact provenance and
   regression evidence; never force-push over the preserved 0.1 history.

Current changes outside the module are engine display identity and the optional
editor splash. No upstream renderer, physics or import implementation is patched.
If a future upstream defect needs a fix, keep it as a separate minimal commit with
a reproducible test so it can be proposed upstream and dropped once integrated.

A shallow upstream snapshot is sufficient to build but is not a complete historical
mirror of Godot. The source archive explicitly labels that limitation. The parent
history preserves BigArcade's available 0.1 and 0.2 work. No GitHub publishing was
possible because no repository was returned by the connected account.
