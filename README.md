# Kitsune-Byte — Repo cleanup

This repository had Vercel deployment support and a Vercel homepage link. The Vercel integration has been removed.

What I changed

- Removed the Vercel option from the deploy UI (lib/screens/deploy_screen.dart).
  - Commit: 17b548f08166ea65b2b30d51df2da6607d18d561
- Removed the Vercel deployment service and helper from lib/services/deploy/One_click_deploy.dart.
  - Commit: 5cb8c4cb3d23d2b69a3f9d742abc3aadd2cf1aff

Why

- You asked to remove Vercel configuration and support from the project. There were no Vercel config files (vercel.json, .vercel/) in the repo, but the code included a deployToVercel implementation and UI elements which are now removed.

Notes & next steps

- I could not (and did not) change repository settings such as the `homepage` field shown on GitHub (it previously pointed to https://kitsune-byte.vercel.app). Repository settings must be updated from the GitHub UI or via GitHub API if you want that changed.
- I did not find a README before; this file documents the cleanup and provides local commands to validate the repo.

Local validation (run on your machine)

Run these commands locally to update your clone, fetch dependencies, and run static analysis and tests:

1. Pull the changes:

   git pull origin main

2. Get Flutter dependencies:

   flutter pub get

3. Run the analyzer:

   flutter analyze

4. Run tests:

   flutter test

If you see issues in analyzer or failing tests, paste the output here and I will help fix them.

How to revert the changes (if needed)

To revert the two commits:

  git pull origin main
  git revert 5cb8c4cb3d23d2b69a3f9d742abc3aadd2cf1aff
  git revert 17b548f08166ea65b2b30d51df2da6607d18d561
  git push origin main

If you prefer changes on a review branch rather than direct commits to `main` next time, say `create branch <name>` and I will push to that branch.
