#!/usr/bin/env python3
"""Upload an Android App Bundle to a Google Play track and roll it out.

Reusable across projects. Uses a Google Play service-account JSON key.

Usage:
  python3 play_publish.py \
      --aab build/app/outputs/bundle/release/app-release.aab \
      --package com.sagearbor.fitrival.app \
      --track internal \
      --service-account ~/.config/play/fitrival-sa.json \
      --notes "Bug fixes" \
      --status completed

Tracks: internal | alpha (closed) | beta (open) | production
Status: completed (live to the track) | draft (staged, roll out in Console)

Setup (one time, see docs/play-release.md):
  pip3 install -r scripts/requirements-publish.txt
"""
import argparse
import os
import sys

try:
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaFileUpload
except ImportError:
    sys.exit(
        "Missing deps. Run: pip3 install -r scripts/requirements-publish.txt"
    )

SCOPE = "https://www.googleapis.com/auth/androidpublisher"


def main() -> int:
    p = argparse.ArgumentParser(description="Publish an AAB to Google Play.")
    p.add_argument("--aab", help="Path to the .aab (omit when using --version-code)")
    p.add_argument("--version-code", type=int,
                   help="Promote an already-uploaded build (this version code) "
                        "to --track without re-uploading. Mutually exclusive "
                        "with --aab.")
    p.add_argument("--package", required=True, help="applicationId / package name")
    p.add_argument("--track", default="internal",
                   choices=["internal", "alpha", "beta", "production"])
    p.add_argument("--service-account", required=True,
                   help="Path to the service-account JSON key")
    p.add_argument("--notes", default="", help="Release notes (en-US)")
    p.add_argument("--status", default="completed",
                   choices=["completed", "draft"],
                   help="completed = live to track; draft = stage in Console")
    args = p.parse_args()

    if bool(args.aab) == bool(args.version_code):
        sys.exit("ERROR: pass exactly one of --aab (upload) or "
                 "--version-code (promote an existing build).")

    sa = os.path.expanduser(args.service_account)
    if not os.path.isfile(sa):
        sys.exit(f"ERROR: service-account key not found: {sa}")
    aab = os.path.expanduser(args.aab) if args.aab else None
    if aab and not os.path.isfile(aab):
        sys.exit(f"ERROR: AAB not found: {aab}")

    creds = service_account.Credentials.from_service_account_file(
        sa, scopes=[SCOPE])
    service = build("androidpublisher", "v3", credentials=creds,
                    cache_discovery=False)
    edits = service.edits()

    print(f"→ Opening edit for {args.package}")
    edit_id = edits.insert(packageName=args.package, body={}).execute()["id"]

    if aab:
        print(f"→ Uploading {os.path.basename(aab)} ({os.path.getsize(aab)//1048576} MB)")
        upload = edits.bundles().upload(
            packageName=args.package, editId=edit_id,
            media_body=MediaFileUpload(aab, mimetype="application/octet-stream",
                                       resumable=True),
        ).execute()
        version_code = upload["versionCode"]
        print(f"  uploaded versionCode {version_code}")
    else:
        version_code = args.version_code
        print(f"→ Promoting existing versionCode {version_code} (no upload)")

    release = {"versionCodes": [str(version_code)], "status": args.status}
    if args.notes:
        release["releaseNotes"] = [{"language": "en-US", "text": args.notes}]

    print(f"→ Assigning to '{args.track}' (status={args.status})")
    edits.tracks().update(
        packageName=args.package, editId=edit_id, track=args.track,
        body={"track": args.track, "releases": [release]},
    ).execute()

    # On already-reviewed apps, changesNotSentForReview=True commits without
    # auto-submitting for review. But a brand-new app still in first review
    # rejects that flag ("Changes are sent for review automatically..."), so
    # fall back to a plain commit (which auto-sends for review; internal-testing
    # releases still reach testers immediately while review is pending).
    from googleapiclient.errors import HttpError
    try:
        edits.commit(
            packageName=args.package,
            editId=edit_id,
            changesNotSentForReview=True,
        ).execute()
    except HttpError as e:
        if e.resp.status == 400 and b"changesNotSentForReview" in (e.content or b""):
            edits.commit(packageName=args.package, editId=edit_id).execute()
        else:
            raise
    print(f"✓ Done. versionCode {version_code} → {args.track} ({args.status}).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
