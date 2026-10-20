# NutritionLogger — Agent Guide

Garmin Connect IQ trail activity recorder with nutrition counters. Technical guidance:
[development instructions](.agent/instructions.md). User setup: [README.md](README.md).
Preserve the distinction between technical and user-facing documentation.

## Documentation lifecycle

Keep specs and non-ADR docs current-state only, except `CHANGELOG.md`, the release-history SSOT.
Collect pending changes under `[Unreleased]`, preserve published release entries, and group them
by actual version and release date; never invent prior releases. ADRs own decision rationale:
before release they may be edited, merged, or squashed; after release preserve published ADRs
and record later decisions in a new ADR with `supersedes`. Apply `context-hygiene` before
documentation or spec writes; link to the owning SSOT rather than duplicating it. Git and Plane
own commit and work-item detail.
