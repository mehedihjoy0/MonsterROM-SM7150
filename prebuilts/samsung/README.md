# Samsung prebuilt sources

`sources.json` is the canonical list of firmware sources for every directory in
this folder. The scheduled `Update prebuilt blobs` workflow audits Samsung's
FOTA feed first, then starts an expensive firmware download/extraction job only
for sources whose `.current` value is stale.

Run the same audit locally with:

```bash
python3 scripts/internal/check_prebuilt_updates.py
```

The audit deliberately follows Samsung's latest published Android firmware. It
does not pin the jobs to the One UI generation present when a prebuilt directory
was created, so One UI 8.5 and later releases are eligible. The existing
`update_prebuilt_blobs.sh` script still controls which files are copied: only
paths already present in the selected prebuilt directory are replaced.

Cross-generation updates are opened as separate draft pull requests and require
compatibility review. Several prebuilt jobs were previously removed at their
first stable One UI 8.5 release, while the qssi and essi donors remain on One UI
8.0. A successful extraction therefore proves only that the selected paths were
available; it does not prove that mixing those binaries with the older donor is
boot-safe.

`compatibility_boundary` records the generation at which that review became
necessary; it is not a claim that Samsung's FOTA XML reports a One UI label. The
audit also compares Samsung's chronological PDA build key. If the feed is older
than `.current`, or has the same build key with a different triplet, it reports
the difference for review and never schedules an automatic replacement.

An entry with `auto_update: false` is still checked and reported, but is omitted
from the workflow matrix. This is currently required for `a34xxx`, because a
model-matching FUS IMEI or serial number is not available. Add a verified
credential to its manifest entry and enable `auto_update` before trying to
download its firmware. Never change `.current` without extracting and replacing
the corresponding blobs.

This workflow updates supplemental prebuilt blobs only. It does not change the
full system-image donors in `unica/configs/qssi.sh` or `unica/configs/essi.sh`;
moving either donor to another One UI generation requires its own extraction,
patch review, build, and boot validation.
